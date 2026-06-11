# GitHub Agentic Workflows (gh-aw) Delivery Pipeline Plan

Last updated: 2026-06-05

## Goal

Run the 11-phase delivery pipeline from GitHub Actions against `onrunning/on-frontend`
using [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/), so we
reuse the org-wide `COPILOT_GITHUB_TOKEN` and gh-aw guardrails instead of
self-managing an LLM key and a custom runner shell.

## Why gh-aw

- Org-wide `COPILOT_GITHUB_TOKEN` is already provisioned — no per-repo LLM secret.
- gh-aw runs a real coding agent (Copilot CLI by default; Claude / Codex / OpenCode selectable via `engine:`) in a sandboxed Actions container.
- Built-in guardrails: read-only token for the agent, network firewall, safe-outputs gate, threat-detection scan before any write.
- Workflows are authored in Markdown and compiled to a locked `.lock.yml` by `gh aw compile`.

## Engine Decision

| Option | Secret | Notes |
|---|---|---|
| `copilot` (default) | `COPILOT_GITHUB_TOKEN` | Broadest gh-aw feature support; recommended starting point |
| `claude` | `ANTHROPIC_API_KEY` | `max-turns` control for long reasoning; needs separate secret |
| `opencode` (experimental) | `COPILOT_GITHUB_TOKEN` | Closest to the current `runner.sh` engine, but experimental in gh-aw |

Start with `engine: copilot` to use the existing org token. Revisit `opencode`
only if a phase depends on OpenCode-specific behavior.

## Proposed Shape

| Piece | Location | Responsibility |
|---|---|---|
| Per-phase agentic workflows (`.md` + `.lock.yml`) | `onrunning/on-frontend` `.github/workflows/` | One workflow per phase: trigger, engine, permissions, safe-outputs, tools, and the dispatch to the next phase |
| Phase prompts / skills / schemas | Central `ai-shared` repo (public) | 11-phase instructions, reused via gh-aw imports |
| Target code | `onrunning/on-frontend` | Branch/PR implementation and validation target |
| Run state | GitHub Actions artifacts (`pipeline-state.tgz`) + safe-outputs | `.pipeline/` tarball + cumulative `workspace.patch`, verdicts, screenshots/traces |

Because `ai-shared` is public, gh-aw can pull phase prompts and shared
instructions through [imports](https://github.github.com/gh-aw/reference/imports/)
without vendoring them into `on-frontend`.

## Mapping the 11 Phases

The current phases stay the same; only the execution layer changes from
`runner.sh` + OpenCode to gh-aw + Copilot CLI.

1. context-intake
2. plan
3. implement
4. test-review
5. code-review
6. qa
7. ui-validation
8. create-pr
9. pr-code-review
10. pr-qa
11. pr-ui-validation

Two viable structures were considered:

- **Single workflow, multi-phase prompt** — one Markdown workflow walks the agent through all phases in one large context.
- **Per-phase workflows chained** — each phase is its own workflow with its own agent and a small, focused context.

**Decision (implemented): one workflow + one agent per phase, dispatch-chained.**
The goal is a small context window with high quality per step, so every phase is
its own gh-aw workflow (`phase-01-context-intake.md` … `phase-11-pr-ui-validation.md`).
Phase _N_ does its work and hands off to phase _N+1_ with the `dispatch-workflow`
safe output, passing `ticket`, `prev_run_id`, and `loop_count`. State travels
between the clean per-run VMs as a `pipeline-state.tgz` artifact (the `.pipeline/`
dir plus the cumulative `.pipeline/workspace.patch`). The chain is sequential
`01 → … → 08 (opens the PR) → 09 → 10 → 11`. Validator phases (4-7) instead
dispatch back to `phase-03-implement` on failure (capped by `max_fix_loops`),
forming the fix loop. The PR opens at phase 8; because its number is not known at
dispatch time, phases 9-11 resolve the live PR by its `[delivery] <ticket>` title.
Each phase emits the same JSON verdict contract.

## Folder Plan

Keep the existing OpenCode pipeline untouched and add a gh-aw variant beside it:

```text
experiment/
  delivery-pipeline/          # existing OpenCode + runner.sh (unchanged)
  github-delivery-pipeline/   # new gh-aw variant
    workflows/
      phase-01-context-intake.md       # 11 per-phase workflows (workflow_dispatch),
      phase-02-plan.md                 #   each dispatches the next phase via safe-output
      ...
      phase-11-pr-ui-validation.md
    phases/                   # phase prompts + shared-preamble (imported bodies)
    schemas/                  # reused JSON verdict schemas
    README.md
```

The phase prompts and schemas can be copied from `delivery-pipeline/` to avoid
drift during the migration, then de-duplicated once the gh-aw path is the source
of truth.

## First Pilot

1. `gh aw init` in `onrunning/on-frontend` (enables authoring + MCP tooling).
2. Add all 11 per-phase agentic workflows under `.github/workflows/`
   (`phase-01-context-intake.md` … `phase-11-pr-ui-validation.md`).
3. Frontmatter: `engine: copilot`; every phase uses `on: workflow_dispatch` with
   inputs `ticket`, `prev_run_id`, `loop_count` (phase 8 also `dry_run`; PR phases
   also `pr_number`), read-only `permissions` + `actions: read`, and `safe-outputs`
   `upload-artifact` + `dispatch-workflow` (phase 8 adds `create-pull-request`; PR
   phases add `add-comment`).
4. Body: import phase prompts from public `ai-shared`, restore prior state from the
   `pipeline-state.tgz` artifact, do the phase work, write the per-phase JSON
   verdict under `.pipeline/`, re-snapshot the artifact, and dispatch the next phase.
5. `gh aw compile` (compile all 11 together so `dispatch-workflow` targets resolve),
   commit each `.md` + `.lock.yml`, confirm `COPILOT_GITHUB_TOKEN` is visible to the repo.
6. Trigger `phase-01-context-intake` with a `ticket`; the chain advances itself.
   Use phase 8's `dry_run: true` to stage the PR without opening it, then
   `dry_run: false` for a real end-to-end run on a low-risk ticket.

## Ticket Assignment

Start with manual trigger:

```text
ticket = DSC-1234
target repo = onrunning/on-frontend
```

Later, Jira can drive the same workflow through a `repository_dispatch` trigger
(e.g. a Jira Automation rule on label/comment/status), or via gh-aw command
triggers on issues/PRs.

## Skills and Cross-Repo References

gh-aw has no automatic skill-routing layer like VS Code. A skill that is only
**linked or mentioned** inside a phase prompt is plain text to the Copilot CLI
agent — it will not follow the link and read it. Skills must be **explicitly
imported** so their content is pulled into the workflow at compile time.

Because `ai-shared` is public, gh-aw cross-repo imports work directly:

- **Frontmatter import** (whole file, pinned by `@ref`):

  ```yaml
  imports:
    - OktayCopurlu/ai-shared/skills/reviewing-code/SKILL.md@main
  ```

- **Body import** (inject content at a position in the prompt):

  ```markdown
  {{#runtime-import OktayCopurlu/ai-shared/skills/reviewing-code/SKILL.md@main}}
  ```

Both resolve at `gh aw compile`, pin to a branch/tag/SHA via `@ref`, and cache
under `.github/aw/imports/`.

| Reference style in a phase prompt | Works in gh-aw? |
|---|---|
| Markdown link to a `SKILL.md` | No — not auto-read |
| `{{#import owner/ai-shared/skills/...@ref}}` | Yes — content embedded |
| Frontmatter `imports:` entry | Yes — pulled at compile |
| Agent web-fetch of a raw GitHub URL | Possible but non-deterministic; needs `network.allowed` + web-fetch |

**Action:** when porting phase prompts into `github-delivery-pipeline/`, convert
every "read skill X" mention into a real gh-aw `{{#import ...@ref}}` directive or
a frontmatter `imports:` entry. Pin to a tag/SHA for reproducible runs.

## QA and UI Validation

QA/UI phases can run if the workflow provides what local validation needs:
dependencies, app build/dev server or preview URL, browser support (gh-aw
[Playwright tool](https://github.github.com/gh-aw/reference/playwright/)),
required env vars, test access, and experiment/flag override paths.

If those are missing, the phase must return `blocked` with a clear request
instead of inventing validation evidence.

## Figma Context

Local VS Code MCP access does not exist in Actions. For gh-aw:

- Configure a Figma MCP server entry under `mcp-servers:` with CI secrets, or
- Extract Figma specs through a lightweight script into `context-packet/figma-specs.json`, or
- Treat Figma as best-effort for the MVP and continue with AC/browser validation when specs are unavailable.

## Safe Outputs and Guardrails

- Agent runs with a read-only token; branch pushes and PR creation go through `safe-outputs`, not direct agent writes.
- Keep secrets out of the agent runtime (gh-aw isolates them in downstream jobs).
- Use `network.allowed` to scope outbound access (GitHub, Jira, Figma, preview hosts).
- Strip any preview/staging basic-auth credentials from user-visible outputs (PRs, comments, summaries).

## Open Decisions

| Decision | Initial Recommendation |
|---|---|
| Which engine? | `copilot` (use org `COPILOT_GITHUB_TOKEN`); revisit `opencode` only if needed |
| Single multi-phase workflow vs per-phase workflows? | **Done:** one workflow + one agent per phase, dispatch-chained (small context, high quality); PR opens at phase 8 and phases 9-11 review the live PR |
| Where do phase prompts live? | Public `ai-shared`, pulled via gh-aw imports; no vendoring into `on-frontend` |
| Where does long-lived run state live? | GitHub Actions artifacts + safe-outputs for MVP |
| Jira trigger now or later? | Later, after manual trigger is proven |
| Is the OpenCode `runner.sh` retired? | Keep in parallel until the gh-aw pilot is validated |
| Should Figma be required for every run? | No, only block when the ticket explicitly requires Figma fidelity |
