# Shared Delivery Pipeline Preamble (gh-aw dispatch chain)

This preamble defines the runtime contract for every phase when the pipeline runs
under [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/) with the
Copilot CLI engine inside GitHub Actions.

The pipeline is a **chain of per-phase workflows**. Each phase is its own workflow,
its own workflow run, and its own fresh agent context window. There is no external
runner and no single agent that walks every phase. A phase does exactly one phase's
work, then hands off to the next phase by dispatching another workflow.

```
[ticket] -> phase-01 -> phase-02 -> phase-03 -> phase-04 -> phase-05 -> phase-06 -> phase-07 -> phase-08 -> phase-09 -> phase-10 -> phase-11
              (analysis/plan)        (code)       (validators, may loop back to phase-03)       (opens PR)     (review the live PR)
```

## One Phase Per Run

- This run executes exactly one phase. Do not attempt later or earlier phases.
- Do this phase's work, write this phase's verdict and artifacts, then hand off.
- The hand-off calls the exact phase-specific safe-output tool named in this phase's
  hand-off instructions. That tool starts the next workflow as a separate run with
  a fresh context. You never run the next phase yourself.

## State Travels Between Runs as an Artifact

Each phase runs on a clean VM, so the previous phase's working tree and `.pipeline/`
directory are **not** present until you restore them. State is carried as a single
tarball artifact named `pipeline-state.tgz` that contains the `.pipeline/` directory plus
a `.pipeline/workspace.patch` snapshot of all accumulated code changes.

- **Inbound (do this first when `prev_run_id` is non-empty).**
  1. Prior state is ALREADY downloaded to `/tmp/prev` by a pre-step (you have NO `gh` auth in the sandbox — do NOT run `gh run download`; it will 404). The pre-step accepts only a successful bot-dispatched run from the expected predecessor workflow on the same repository, branch, and commit. It verifies the artifact SHA-256 digest and rejects unsafe ZIP/TAR entries before exposing the tarball.
  2. `tar -xzf "$(find /tmp/prev -type f -name pipeline-state.tgz | head -1)" -C .` to restore
     `.pipeline/`. Use `-type f`: `gh run download` creates a *directory* named after the
     artifact (`/tmp/prev/pipeline-state.tgz/`) with the real tarball inside it, so matching
     files only avoids handing the directory to `tar`.
  3. If `.pipeline/workspace.patch` exists, `git apply --whitespace=nowarn .pipeline/workspace.patch`
     so the working tree reflects all accumulated code changes from earlier phases.
  After this, treat everything already under `.pipeline/` as immutable input.
- **Outbound (do this last, before emitting safe outputs).**
  1. Make your phase's changes (edit code and/or write `.pipeline/` files).
  2. `git add -A && git diff --staged -- ':!.pipeline' ':!.github' > .pipeline/workspace.patch`
     to capture every accumulated **product** change as one cumulative patch (pipeline
     bookkeeping under `.pipeline/` and the workflow machinery under `.github/` are excluded).
  3. `mkdir -p /tmp/gh-aw && tar -czf /tmp/gh-aw/pipeline-state.tgz .pipeline`, then emit the
     `upload-artifact` safe output with the **absolute path** `/tmp/gh-aw/pipeline-state.tgz`.
     gh-aw auto-copies that absolute path into the upload staging area. Do **NOT** pass a bare
     filename like `pipeline-state.tgz` — bare names are looked up only in the (empty) staging
     dir and fail with `path does not exist in staging directory`. Do not use `$VAR` in the path.
- **Hand-off.** Call the exact phase-specific safe-output tool named in this phase's
  hand-off instructions. Pass `prev_run_id` equal to this run's ID (provided to you as
  `RUN_ID` in the workflow body), plus the unchanged `ticket`, the current `loop_count`,
  and `pr_number` once a PR exists. Pass these as top-level tool arguments, not as an
  `inputs` object, and never call the generic `dispatch_workflow` tool.

## Working Directory

- All pipeline working files live under `.pipeline/` in the checked-out workspace.
- Layout:
  - `.pipeline/context-packet/` — ticket, linked context, constraints, acceptance criteria.
  - `.pipeline/implementation-plan/` — plan, affected files, validation plan.
  - `.pipeline/verdicts/<NN>-<phase-id>.json` — one schema-valid verdict per phase.
  - `.pipeline/fix-requests/` — structured fix requests for the Implementer/Fixer.
  - `.pipeline/notes/` — optional human-readable notes per phase.
  - `.pipeline/workspace.patch` — cumulative `git diff` snapshot used to carry state.
- Where a phase says `output.json`, write `.pipeline/verdicts/<NN>-<phase-id>.json`. Where
  a phase references `state.json`, `context-packet/`, or `verdicts/<...>.json`, resolve
  them under `.pipeline/`. The historical `RUN_DIR`/`STATE_PATH`/`INPUT_PATH` inputs no
  longer exist; the ticket arrives as the `ticket` workflow input and prior state arrives
  via the downloaded artifact.

## Token Discipline — Read Only What the Ticket Needs

Your context window is re-sent on every turn, so every file you open is paid for again
and again. Wasteful reads are the single biggest cause of runaway token usage in this
pipeline. Keep your footprint tight:

- **Work only in the target.** All code analysis and edits happen on this repository's own
  files in the working tree (the repo root) and under `.pipeline/`. Do not explore to "find" it.
- **Never open this pipeline's own machinery.** Do not read `*.lock.yml` or the
  `.github/workflows/` sources. They are large generated/meta files with nothing to do
  with the ticket and will blow your budget.
- **No broad filesystem scans.** Do not run `find` / `ls -R` / `grep -r` across the repo
  root, `/home/runner`, `node_modules`, or build output. Scope every search to the one
  directory you actually need.
- **Read each file once.** Do not re-open a file you have already read this run; rely on
  what you already have in context.

## Output Contract

- Every phase writes `.pipeline/verdicts/<NN>-<phase-id>.json` before it ends, and that file must validate against the imported `phase-output.schema.json`.
- Use `schema_version: "1"` and the exact phase ID.
- `status: "fail"` must include at least one `fix_requests[]` item or blocker.
- `status: "blocked"` and `status: "protocol-error"` must include at least one blocker.
- Separate files under `.pipeline/fix-requests/` must validate against the imported `fix-request.schema.json` and include `schema_version: "1"`.

## Hand-off and the Fix Loop

- After writing your verdict, decide the hand-off from your own `status`:
  - **Phases 1–2 (analysis/plan):** on success dispatch the next phase. On `blocked`, do
    not dispatch; surface the blocker and `noop`.
  - **Phase 3 (implement):** dispatch `phase-04-test-review` once changes are staged and the
    patch is refreshed.
  - **Validator phases 4–7:** on `pass`, dispatch the next phase. On `fail`, dispatch
    `phase-03-implement` with `loop_count` incremented by 1 so the Implementer can fix the
    issues. Never exceed `max_fix_loops` (3). If `loop_count` already equals the cap and
    blockers remain, stop: post an `add-comment` summary and `noop` instead of looping.
  - **Phase 8 (create-pr):** open the PR via the `create-pull-request` safe output (title
    prefix `[delivery] ` + the ticket), then dispatch `phase-09-pr-code-review`. The PR
    number is not known at dispatch time (the safe-outputs job opens the PR afterwards), so
    it is not passed; later PR phases resolve it.
  - **PR phases 9–11:** resolve the live PR by searching open PRs whose title starts with
    `[delivery] ` and contains the ticket, post results via the `add-comment` safe output
    (with the resolved PR number), then dispatch the next PR phase (phase 11 ends the chain).
    PR phases run linearly and do not loop back to the build; a blocking finding is reported
    as a comment, not a re-dispatch of earlier phases.
- A phase only ever dispatches a workflow listed in its own `dispatch-workflow` config.

## Blocked and Missing Inputs

- If a required input, credential, URL, environment, design decision, or repo state is missing, write `status: "blocked"` with a blocker that states exactly what is needed from a human. Do not guess or fabricate, and do not dispatch the next phase.
- Surface blockers to humans through safe outputs, not direct writes:
  - Call the `missing-data` safe output to report data the run needs to proceed.
  - Call the `missing-tool` safe output when a required tool/MCP server is unavailable.
  - Use `add-comment` (when a PR exists) or `create-issue` to post a concise, actionable blocker summary.
- Never invent evidence, links, test results, browser observations, PR URLs, screenshots, or human answers.

## Talking to the Jira Ticket

The agent never holds the Jira token. Reads are pre-fetched for you; writes go
through a deterministic step that runs after you with the credential.

**Reading the ticket (phases 1 and 10).** A pre-step fetches the ticket with the
Jira credential and writes it to `jira-in/ticket.json` before you start. When that
file exists, treat it as the authoritative ticket source and parse the standard
Jira REST v2 fields from it: `.key`, `.fields.summary`, `.fields.description`,
`.fields.status.name`, `.fields.comment.comments[]`, `.fields.issuelinks[]`, and
`.fields.attachment[]` (Figma/Confluence/Drive links usually live in the
description or comments). Do **not** try to call an Atlassian MCP or curl Jira
yourself — in CI you hold no token. If `jira-in/ticket.json` is missing or empty,
the fetch failed: keep the issue key from the `ticket` input, use any other linked
context, and if the ticket body is genuinely required write `status: "blocked"`
with a blocker saying the Jira fetch failed (check `JIRA_USER_EMAIL` /
`JIRA_API_TOKEN`).

**Writing back to the ticket** uses small intent files; the deterministic
post-step performs the REST call. Three behaviors:

- **Issue key (phase 1).** Right after you resolve the ticket, write the normalized
  Jira issue key (e.g. `DSC-1234`, not a URL) to `.pipeline/jira/issue-key.txt`. It
  travels in `pipeline-state.tgz`, so every later phase and post-step can use it.
- **Comment on a blocker or important update (any phase).** When a phase is `blocked`,
  or you have a concise human-facing update that belongs on the ticket, write the
  message as plain text/Markdown to `jira-out/comment.md`. After you end, the post-step
  posts it as a comment on the ticket. Keep it short and actionable; never include
  secrets, tokens, or preview basic-auth creds.
- **Move to In Review (final phase only).** In phase 11, if the whole pipeline passed
  with no blocking findings, write `In Review` to `jira-out/transition.txt`. The
  post-step then transitions the ticket to In Review. If anything is blocked, do not
  write this file.

Rules:

- `jira-in/` (read) and `jira-out/` (write) are both ephemeral, run-local scratch.
  Neither is part of `.pipeline/`, neither is tarred into `pipeline-state.tgz`, and
  neither must ever be `git add`ed or shipped in the PR. Each run only posts the
  file it wrote this run, so comments never duplicate.
- These write files are optional. If you have nothing to say to the ticket, do not create them.
- If the Jira secrets are not configured, the post-step skips quietly — writing the files
  is always safe.

## Evidence and Secret Hygiene

- Record only evidence you actually obtained (command output, real URLs you inspected, real screenshots/traces). Reference files under `.pipeline/` rather than pasting large payloads.
- Never include secrets, tokens, raw auth headers, cookies, or private payloads in verdicts, notes, PR text, comments, fix requests, or any safe output. Summarize sensitive material and point to a local path under `.pipeline/`.
- Strip preview/staging basic-auth credentials from every user-visible artifact (PR body, comments, issues, summaries).

## Writes Happen Through Safe Outputs

- The agent runs with a read-only GitHub token. It does not push branches, open PRs, or dispatch workflows directly — those happen through safe outputs after the agent ends.
- To carry state forward, `tar -czf /tmp/gh-aw/pipeline-state.tgz .pipeline` and emit `upload-artifact` with the absolute path `/tmp/gh-aw/pipeline-state.tgz` (the tarball of `.pipeline/`).
- To advance the chain, call the exact phase-specific safe-output tool named in the current
  phase's hand-off instructions. Never call the generic `dispatch_workflow` tool.
- To deliver code (phase 8 only), request PR creation via the `create-pull-request` safe output. Exclude `.pipeline/` and `jira-out/` from the PR commit so only real product changes ship.
- To comment on or review a PR, use the `add-comment` safe output with the resolved PR number — never post directly.
- If a run reaches a stop condition with no GitHub action to take, call the `noop` safe output with a short explanation so the run does not complete silently.

## Fix Request Contract

Use fix requests only for work the Implementer/Fixer should do. Each request must
include ID, source phase, severity, related AC IDs, scenario, expected behavior,
actual behavior, reproduction steps, and suggested direction. Validator phases
must not patch code or tests directly — they record fix requests and dispatch
`phase-03-implement`.
