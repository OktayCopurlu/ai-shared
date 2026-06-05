# Phase 8: Create PR

This command runs the Create PR phase for the experimental delivery pipeline.

## Role Contract

Request creation of the pull request from the implemented changes and accumulated artifacts. Do not invent evidence. Under gh-aw the agent has a read-only GitHub token: stage commits in the workspace and emit the PR through the `create-pull-request` safe output. The PR itself is created by a separate permission-controlled job after this run finishes, so you will not have a live PR URL during the run. Do not change source code except for staging the already-implemented diff.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence, PR URLs, validation results, or human answers, never include secrets/tokens/auth headers/cookies in artifacts or PR text, and always write schema-valid `output.json` before ending.

This phase stages the implemented changes and requests PR creation via the `create-pull-request` safe output. Do not modify source code beyond staging, do not amend unless explicitly instructed by human input, do not push branches directly, and never call `gh`/`git push` to open the PR.

## Skill References

Use `git-workflow` for commit hygiene and PR body shape, and `github` for PR conventions. Use the `git-workflow` PR Description Template exactly: optional Preview/Jira links at the top, `### Description`, optional `### Verification`, `### Test Instructions`, and optional `### Note`. Do not add extra standalone sections such as AC Coverage, Key Changes, Risks, Tests, QA, or UI Validation unless the target repo already documents them as its PR contract.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time. PR delivery uses the gh-aw `create-pull-request` safe output (not direct `gh`/`git push`). Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import OktayCopurlu/ai-shared/skills/git-workflow/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/github/SKILL.md@main}}

Preserve PR evidence from the local verdict artifacts only. Fold AC coverage, test evidence, QA evidence, UI validation evidence, known gaps, preview links, and spec gaps into the allowed template sections as concise reviewer-facing evidence. Do not include CI/lint/typecheck/test command summaries in the PR body; CI runs tests, and reviewer-visible evidence should come from artifacts, preview/baseline links, screenshots, reproductions, or linked specs. Do not include AI-assistant attribution in commit messages, PR text, or generated artifacts.

## Inputs

This phase runs from a `workflow_dispatch` event: prior state is restored from the previous
run's `pipeline-state.tgz` artifact into `.pipeline/` (see the artifact state contract in
`shared-preamble.md`). Treat everything under `.pipeline/` as immutable prior-phase input — the
context packet, plan, the accumulated diff (`.pipeline/workspace.patch`), and the final local
verdicts `04`-`07` under `.pipeline/verdicts/` — plus the target repository git state.

## Required Work

1. Verify local safety phases (`04`-`07`) have passed or are explicitly not applicable with reasons; if a required phase failed, return `blocked` instead of requesting a PR.
2. Stage only files relevant to the ticket and verify the staged diff is in scope before committing.
3. Create one clear commit for the staged changes. Do not amend unless explicitly instructed by the run state or human input.
4. Compose a reviewer-friendly PR title and a body that follows the `git-workflow` template exactly, with artifact-backed AC coverage, test evidence, QA evidence, UI validation evidence, known gaps, and spec gaps folded only into the allowed template sections.
5. Emit the `create-pull-request` safe output with that title and body (draft as configured by the workflow). The separate safe-outputs job opens the PR; do not push or call `gh pr create`.
6. Record the requested PR title, body, base/head branch, and draft flag locally. Note that the PR number/URL is assigned by the safe-outputs job and is not available in this run.

## Phase Checklist

- Working-tree changes are inspected before committing.
- Only ticket-relevant files are staged and committed; unrelated generated noise or formatting churn is excluded.
- PR body evidence is copied from artifacts only; missing evidence is listed as a gap, not invented.
- PR body follows the `git-workflow` template sections exactly and does not include command-summary sections.
- AC coverage, tests, QA, UI validation, known gaps, and preview information are included when available inside the allowed sections.
- Commit messages and PR text contain no AI-assistant attribution.
- The `create-pull-request` safe output is emitted exactly once with the composed title and body.
- `pr/request.json` records the requested title, body path, base/head branch, and draft flag (no fabricated URL/number).
- Unsafe git state, failed prerequisite phases, or out-of-scope diffs return `blocked` with exact human action needed.

## Artifacts To Write

Write these files (all under `.pipeline/`):

- `pr/request.json` (requested title, body path, base/head branch, draft flag)
- `pr/description.md`
- `phases/08-create-pr/output.json`
- optional `phases/08-create-pr/notes.md`

Required artifact list: `["pr/request.json","pr/description.md","phases/08-create-pr/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/08-create-pr/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when the changes are committed and the `create-pull-request` safe output has been emitted with the recorded title/body. Use `status: "blocked"` for unsafe git state, failed prerequisite phases, out-of-scope diffs, or repository ambiguity.

Do not create unrelated commits. Do not push or open the PR directly. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "create-pr",
	"status": "pass",
	"summary": "Changes committed and PR creation requested via the create-pull-request safe output.",
	"inputs_read": ["current-diff/", "verdicts/", "implementation-plan/"],
	"artifacts_written": ["pr/request.json", "pr/description.md"],
	"evidence": [{ "type": "pr", "description": "PR creation request recorded; PR opened by safe-outputs job.", "path": "pr/request.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
