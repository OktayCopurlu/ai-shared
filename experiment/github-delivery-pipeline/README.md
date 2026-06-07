# GitHub Delivery Pipeline (gh-aw)

A [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/) variant of
the 11-phase delivery pipeline. It runs in GitHub Actions against
`onrunning/on-frontend` using the **Copilot CLI** engine, so it reuses the
org-wide `COPILOT_GITHUB_TOKEN` instead of a self-managed LLM key.

The original local pipeline (`../delivery-pipeline/`) and its `runner.sh` stay as
they are. This folder is the GitHub-driven sibling, not a replacement.

## How it differs from the local pipeline

| | Local pipeline | This (gh-aw) |
|---|---|---|
| Runs on | Your machine | GitHub Actions |
| Engine | OpenCode CLI (`runner.sh`) | Copilot CLI |
| LLM auth | Your own key | Org `COPILOT_GITHUB_TOKEN` |
| Skills | Resolved by VS Code skill router | Explicitly imported (see below) |
| State | `runs/` on disk | Actions artifacts (`pipeline-state.tgz`) + safe-outputs |
| Phases | One agent walks all phases | One workflow + agent **per phase**, dispatch-chained |

## Layout

```text
github-delivery-pipeline/
  README.md                          # this file
  plan.md                            # design decision (per-phase chain) + adoption plan
  workflows/                         # generic per-phase workflow templates (placeholder hosts)
    phase-01-context-intake.md       # 11 per-phase workflows (workflow_dispatch)
    phase-02-plan.md                 #   each runs one phase in its own run, then
    ...                              #   dispatches the next phase via safe-output
    phase-11-pr-ui-validation.md
  copy-to-on-frontend/               # host-filled, ready-to-copy mirror for onrunning/on-frontend
    README.md                        #   secret audit + adoption notes
    .github/workflows/               #   the same 11 workflows, pre-filled (real hosts, Figma wired)
  phases/                            # the 11 phase prompts + shared-preamble (imported bodies)
  schemas/                           # JSON verdict schemas (unchanged from local pipeline)
  pipeline.json                      # phase order / config reference
```

`workflows/` holds the generic templates (commented `mcp-servers:`, placeholder
`network.allowed`). `copy-to-on-frontend/.github/workflows/` is the **derived**
set, pre-filled for `onrunning/on-frontend` — keep the two in sync until one is
generated from the other.

## Runtime model (read this first)

Each phase is its **own** gh-aw workflow with its **own** Copilot CLI agent and a
fresh, small context window. A phase does its work, then hands off to the next
phase with the `dispatch-workflow` safe output. There is no external `runner.sh`,
no `RUN_DIR`/`STATE_PATH` environment, and no single agent holding the whole
pipeline in context. Key consequences, all encoded in `phases/shared-preamble.md`:

- **One phase per run:** the chain is `01 → 02 → 03 → 04 → 05 → 06 → 07 →
  08 (opens the PR) → 09 → 10 → 11`. Phase _N_ dispatches phase _N+1_ and passes
  `ticket`, `prev_run_id` (= its own `github.run_id`), and `loop_count`.
- **State travels as an artifact:** every run starts on a clean VM. State is a
  single tarball `pipeline-state.tgz` containing the `.pipeline/` dir, including
  `.pipeline/workspace.patch` (the cumulative `git diff --staged`). Each agent
  downloads the previous run's artifact (`gh run download <prev_run_id>`),
  extracts it, `git apply`s the patch, does its work, re-snapshots the tarball,
  and emits `upload-artifact`. This needs `actions: read` permission.
- **Read-only agent:** the agent never pushes or opens PRs directly. Code lands
  via the accumulated `workspace.patch`; the PR is opened by phase 8's
  `create-pull-request` safe output; review feedback goes through `add-comment`.
- **The fix loop is a dispatch choice:** validator phases (04 test-review, 05
  code-review, 06 QA, 07 UI) declare two dispatch targets — the next phase and
  `phase-03-implement`. On pass they dispatch forward; on failure they dispatch
  back to implement with `loop_count + 1`. The loop is capped at
  `max_fix_loops` (3, from `pipeline.json`); at the cap with open blockers the
  agent posts a comment and stops (`noop`).
- **The PR opens at phase 8, not early:** phases 9-11 review the *live* PR. The
  PR number is not known when phase 8 dispatches (the safe-outputs job opens the
  PR after the agent finishes), so phases 9-11 resolve it by searching open PRs
  whose title starts with `[delivery] ` and contains the ticket. PR phases run
  linearly (no loop back to build); blocking findings are posted as comments.
- **No silent runs:** if a run takes no GitHub action, the agent calls the
  `noop` safe output. Missing inputs/tools are surfaced via `missing-data` /
  `missing-tool`.

## Skills are imported, not mentioned

This is the key gh-aw difference. In VS Code a skill name like `reviewing-code`
is resolved automatically. **gh-aw has no skill router** — a skill that is only
named in a prompt is plain text and is never read.

So every phase prompt imports the skills it needs with a gh-aw directive:

```markdown
{{#runtime-import OktayCopurlu/ai-shared/skills/reviewing-code/SKILL.md@main}}
```

Because `OktayCopurlu/ai-shared` is public, this cross-repo import works without a
token. The content is injected at `gh aw compile` time and pinned by `@main`
(swap for a tag or SHA for reproducible runs).

The phase prompts keep their original "use skill X when Y" guidance for the
conditional logic, and add the import directives so the content is actually present.

## MCP and tools

Some skills (`atlassian-mcp`, `figma-mcp`, `playwright-mcp`, `github`,
`contentful`, `google-drive`) describe how to use MCP
tools. Importing their docs is not enough — the tools themselves must be
configured in the workflow frontmatter under `mcp-servers:` with the right CI
secrets. Every phase workflow ships commented `mcp-servers:` placeholders for this.

### Auth in CI (important)

Locally these MCP servers authenticate with interactive OAuth (a browser window
opens). CI runners have no browser, so each server must use a **non-interactive,
token-based secret** stored as a GitHub Actions secret and passed as a header:

- **Figma:** create a personal access token and pass it as
  `Authorization: "Bearer ${{ secrets.FIGMA_MCP_TOKEN }}"`.
- **Atlassian:** the official remote (`mcp.atlassian.com`) is **OAuth-2.1 only**
  and will not accept a bearer PAT in CI. Two CI-safe options:
  1. Skip the MCP and use Jira REST. This is how the pipeline works: a **pre-step**
     (frontmatter `steps:`, runs before the read-only agent, on the runner host
     with full network) fetches the ticket with the credential and writes
     `jira-in/ticket.json`; the agent then reads that file (it never holds the
     token). The symmetric write path is the `post-steps:` that post comments /
     transition the ticket from `jira-out/`. Most robust.
  2. Run a self-hosted Atlassian MCP container that accepts a token, and point
     `mcp-servers.atlassian.url` at it.

  Jira **Cloud** REST auth is HTTP basic `email:api-token`, so the pipeline also
  needs `JIRA_USER_EMAIL` next to `JIRA_API_TOKEN` — the token alone cannot
  authenticate (bearer/PAT auth is Server/Data Center only). Use a **shared
  service/bot account**, not a personal one: repo secrets are a single shared
  identity, so every run's Jira comment and *In Review* transition is attributed
  to whoever owns the token. In `onrunning/on-frontend` the `JIRA_API_TOKEN`
  secret already exists but is unused by any workflow — confirm its owner account
  before reuse and set `JIRA_USER_EMAIL` to that account.

Never rely on a developer's local OAuth session for a CI run — it does not carry
over to the runner.

Built-in coverage (no MCP server needed):

- GitHub read + PR delivery: gh-aw `github:` tools + `safe-outputs`, so the
  `github`/`github-mcp` capability is covered.
- Browser automation: the `playwright:` built-in tool (used by QA / UI phases).
- Repo build/test/lint: `bash: [":*"]`. This is intentionally broad so the
  Implementer/Validator phases can run the target repo's commands; narrow it to
  an explicit allowlist if those commands are fixed.

Which phase needs which MCP server: Atlassian (1, 10), Figma (1, 7, 11),
Playwright built-in (6, 7, 10, 11), Contentful + Google Drive
(1, when the ticket references them).

### Where validation runs (pre-PR vs PR)

The pipeline never starts the app on a dev server in CI, so no local `.env` /
env-decryption secret is required. UI/QA validation lives in two places:

- **Phases 6 (QA) and 7 (UI) run before the PR exists**, so there is no live
  surface. They validate **statically**: the accumulated diff, Figma specs, and
  unit/component tests. "Local UI validation" here means *when a surface is
  available* — in CI there usually is none, so live measurements are deferred.
- **Phases 10 (PR-QA) and 11 (PR-UI) run after phase 8 opens the PR** and are the
  authoritative live checks. They browse the real preview `on-shop-<PR#>.on.com`
  with Playwright + `PREVIEW_BASIC_AUTH`. The preview is built and deployed by
  on-frontend's **own** CD (`yarn on-shop build` with `ENV_SECRETS_KEY` → Docker
  → ECR → GitOps/k8s), not by this pipeline — the pipeline only consumes it.

Running a localhost dev server in phases 6–7 is possible only inside on-frontend
(where `ENV_SECRETS_KEY` and `yarn on-shop dev` exist) and adds cost on every
run; since the preview already covers live checks at 10–11, phases 6–7 stay
static by design.

## Adoption steps

1. In `onrunning/on-frontend`, run `gh aw init` (enables authoring + tooling).
2. Copy the 11 pre-filled `copy-to-on-frontend/.github/workflows/phase-*.md`
   files into `on-frontend/.github/workflows/` — they are the host-filled version
   of the generic `workflows/phase-*.md` templates (see
   `copy-to-on-frontend/README.md`).
3. Uncomment and fill the `mcp-servers:` blocks for the phases you need, add any
   extra hosts to `network.allowed`, and create the referenced CI secrets.
4. Compile them: `gh aw compile` (generates the locked `.lock.yml` files). The
   `dispatch-workflow` validation requires every target phase workflow to be
   present, so compile them together.
5. Commit each `.md` + its `.lock.yml`, and confirm `COPILOT_GITHUB_TOKEN` is
   available to the repo/org.
6. Trigger `phase-01-context-intake` with the `ticket` input. The chain advances
   itself phase by phase. Phase 8 carries a `dry_run` input (default `true`): on
   a dry run it stages the PR request and calls `noop` instead of opening a PR
   and stops the chain; set `dry_run: false` to open a real PR and let phases
   9-11 run against it.

## Status

Scaffold for gh-aw v0.78.1. Eleven per-phase workflows, dispatch-chained, with
artifact-based state passing.

- **Chaining** uses the `dispatch-workflow` safe output (`phase-N` dispatches
  `phase-N+1`). Validator phases also list `phase-03-implement` as a target for
  the fix loop. `dispatch-workflow` validates at compile time that every named
  target workflow exists and declares `workflow_dispatch`, so all 11 must be
  compiled together.
- **State** is the `pipeline-state.tgz` artifact carrying `.pipeline/` and the
  cumulative `.pipeline/workspace.patch`. Each agent restores it from
  `prev_run_id` (needs `actions: read`), applies the patch, and re-uploads.
- `safe-outputs:` and `tools:` used: `dispatch-workflow`, `upload-artifact`,
  `create-pull-request` (phase 8 only), `add-comment` (PR phases 9-11, with
  `target: "*"` so the agent supplies the resolved PR number),
  `noop`/`missing-data`/`missing-tool`; `github`, `playwright`, `bash`, `edit`,
  `web-fetch`. `web-search` is omitted (the `copilot` engine does not support it;
  `web-fetch` covers known URLs).
- All imports use the current `{{#runtime-import ...}}` content-injection syntax.
- `dry_run` (phase 8 input) is handled at the prompt level (the agent calls
  `noop` and skips the dispatch instead of emitting `create-pull-request`);
  gh-aw's `staged:` only accepts a literal boolean, so it is not wired to it.
- `phases/shared-preamble.md` and all 11 phase prompts use the dispatch+artifact
  contract (`.pipeline/` working dir, artifact state, per-phase hand-off).
- The PR opens at phase 8; phases 9-11 resolve and review the live PR.

Known non-fatal warning: `playwright:` uses MCP mode, which gh-aw marks
deprecated in favour of `mode: cli`. MCP mode still compiles and runs; it is
kept so the UI/QA phases stay aligned with the shared `playwright-mcp` skill.
Adopters who run a dev server in CI may prefer `mode: cli` (reaches `localhost`,
no Docker) and should update those prompts to call `playwright-cli` in bash.

Before first real run, still required from the adopter: fill `mcp-servers:` +
secrets, confirm `network.allowed` hosts, and pin `@main` imports to a tag/SHA
for reproducibility (and push this folder to `main` so the cross-repo imports
resolve).
