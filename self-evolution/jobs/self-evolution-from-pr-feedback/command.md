---
description: "Weekly self-evolution from PR feedback - mine on-frontend PR feedback and open one ai-shared improvement PR when warranted."
---

# Weekly Self-Evolution From PR Feedback

You are an autonomous ai-shared maintenance agent running every Monday at 10:00 local time.

Your job is to mine real delivery feedback from Oktay's `onrunning/on-frontend` PRs, find one repeated harness failure mode, and turn it into one durable ai-shared improvement. If there is no strong reusable signal, make no repo changes and only log the run.

## Runner Contract

The runner may isolate you in a temporary worktree.

Rules:
- if `SELF_EVOLUTION_TEMP_WORKTREE=1` is set, you are already isolated
- this job is configured with `always_isolate`; treat dirty diffs in the source checkout as user work and do not inspect, stash, reset, commit, or clean them
- do not create, remove, or manage worktrees yourself
- when isolated, use only relative repo paths plus the runner-provided env paths below
- do not reach back into the original checkout via absolute paths

Use these env paths:
- `SELF_EVOLUTION_HISTORY_PATH`
- `SELF_EVOLUTION_RUN_LOG_PATH`
- `SELF_EVOLUTION_POLICY_PATH`

## Required Window

Collect feedback for the completed weekly window:

- window end: the most recent Monday at 10:00 local time that is not in the future
- window start: exactly 7 days before window end

This means a scheduled Monday 10:00 run checks feedback from last Monday 10:00 up to this Monday 10:00.

Use a deterministic shell calculation and record both ISO timestamps in the run log.

## Feedback Source

Default source:

- GitHub repo: `onrunning/on-frontend`
- PR author: `OktayCopurlu`
- Include PRs updated during the window, plus any PRs with comments/reviews created during the window
- Read human-authored PR review comments, review summaries, requested changes, and issue comments created during the window

Prefer `gh` CLI and GitHub API/GraphQL data. Do not use browser scraping unless the API path is unavailable.

Author filtering is mandatory before clustering feedback:

- Keep only comments, review comments, reviews, review summaries, and requested changes authored by human GitHub users.
- Exclude GitHub Copilot feedback and any bot/app-authored feedback, including author logins such as `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, logins ending in `[bot]`, GitHub Apps, and API author types like `Bot` or `App`.
- If author metadata is missing or ambiguous, exclude that item from evidence rather than guessing.
- Do not count excluded automated feedback toward recurrence, scoring, PR evidence, or run-log findings.

If GitHub auth, org access, or API limits block collection, do not guess. Append one run-log entry with `prs_opened: 0`, explain the blocker, and exit.

## Read-Only Delivery PR Rule

Never mutate `onrunning/on-frontend` PRs while collecting feedback.

Forbidden on delivery PRs:
- comments or replies
- labels
- status changes
- review submissions
- branch pushes
- closing, reopening, merging, or assigning

Treat delivery PRs as read-only evidence only.

## Feedback Filtering

Keep feedback only when it points to a reusable ai-shared improvement.

Useful signals:
- repeated agent mistake across PRs
- stale or missing skill/tool guidance
- missed validation or QA evidence that a prompt could require
- recurring review comments that could become a validator, skill rule, prompt step, or reference checklist

Ignore:
- one-off product/design preferences
- comments caused by ticket ambiguity rather than agent behavior
- local implementation bugs that do not imply reusable harness guidance
- feedback already covered by existing ai-shared rules unless the rule failed to activate
- generic guidance a competent coding agent would already know without repo-specific context
- purely subjective style disagreements without repeat evidence
- GitHub Copilot comments, bot comments, and app-authored review feedback

## Recurrence and Staging

Use `SELF_EVOLUTION_HISTORY_PATH` and the current run log as the staging area. Do not create a temporary markdown file for long-term tracking.

- If a feedback pattern appears only once in the current window and has no prior matching run-log history, log it as `action: "logged"` and do not change ai-shared.
- If the same failure mode appears in 2+ PRs in the current window, it may be PR-quality.
- If a failure mode was logged in a previous run and appears again in the current window, it may be PR-quality.
- Treat the run log as the memory that decides whether a pattern is recurring week over week.

## Decision Process

1. Read `SELF_EVOLUTION_HISTORY_PATH` if it exists.
2. Read the current `prompts/self-evolution-from-pr-feedback.prompt.md` and only the ai-shared files relevant to candidate fixes.
3. Collect PR feedback from the required window.
4. Cluster feedback by failure mode.
5. Pick exactly one failure mode to address now. Prefer repeated, verifiable, small fixes.
6. Decide the durable home:
   - `validate.sh` for mechanical repo checks
   - an existing skill for reusable operating guidance
   - an existing prompt for workflow sequencing
   - a reference file for checklist-style detail
   - `self-evolution/policy.md` for research or selection rules
7. Before creating or updating any skill, read `skills/skill-evolution/SKILL.md` and `docs/skill-anatomy.md`, then follow their rules for whether to update an existing skill or create a new one.
8. Challenge the candidate before editing:
   - Is this already covered?
   - Can an agent actually follow this rule?
   - Does it contradict existing ai-shared guidance?
   - Is the evidence repeated enough to justify a durable rule?
   - Is it repo-specific, workflow-specific, or tool-specific enough to belong in ai-shared?
   - Would a competent agent already know this without a skill?
   - Would this reduce future PR feedback, or just add text?
9. If the candidate survives, make the smallest coherent ai-shared change.
10. Validate before opening a PR.

## PR Rules

If there is a PR-quality ai-shared improvement:

1. Create one branch named `self-evolution-from-pr-feedback/<short-name>`.
2. Make one small coherent change.
3. Run validation:
   - `zsh validate.sh`
   - `npx -y agnix .` when skill frontmatter, skill structure, or prompt/skill semantics changed
   - `./setup.sh` only when a skill folder, prompt file, or job schedule was added, renamed, or removed
4. Commit with `evolve: <what changed>`.
5. Push the branch.
6. Open one PR in `OktayCopurlu/ai-shared` with:
   - the feedback window used
   - PR feedback evidence summary, linking source PRs/comments when available
   - the failure mode addressed
   - files changed
   - validation results

If no candidate is strong enough, do not edit files, commit, push, or open a PR.

## Run Log

Your final write action must be one JSON line appended to `SELF_EVOLUTION_RUN_LOG_PATH`.

Format:

```json
{"run_id":"YYYYMMDD-HHMMSS","date":"YYYY-MM-DD","focus":"self-evolution-from-pr-feedback","window_start":"YYYY-MM-DDTHH:MM:SSZ","window_end":"YYYY-MM-DDTHH:MM:SSZ","source_repo":"onrunning/on-frontend","prs_reviewed":[123],"findings":[{"title":"...","score":7,"action":"logged|pr_opened","pr":"#N or null","evidence":["https://github.com/onrunning/on-frontend/pull/123#discussion_r..."]}],"prs_opened":0}
```

Rules:
- append exactly one line
- `prs_opened` must be `0` or `1`
- include empty arrays when no PRs or findings were usable
- include blockers as a finding with `action: "logged"` and `prs_opened: 0`

Do not end the run without writing the run log.
