# Phase 8: Create PR

This command runs the Create PR phase for the experimental delivery pipeline.

## Role Contract

Create the pull request using the implemented branch and accumulated artifacts. Do not invent evidence. Do not change source code except for necessary git metadata operations such as commit/push.

## Shared Pipeline Rules

Read `commands/shared-preamble.md` if available. Enforce these critical rules even if it is unavailable: treat runner-provided paths as the only runtime authority, read previous artifacts as immutable inputs, write only this phase's listed artifacts, never invent evidence, PR URLs, validation results, or human answers, never include secrets/tokens/auth headers/cookies in artifacts or PR text, and always write schema-valid `output.json` before ending.

This phase may perform necessary git/PR operations only. Do not modify source code, do not amend unless explicitly instructed by human input, and do not force-push.

## Skill References

Use `git-workflow` for local branch/commit/push behavior and `github-mcp` for PR operations when available. Use the `git-workflow` PR Description Template exactly: optional Preview/Jira links at the top, `### Description`, optional `### Verification`, `### Test Instructions`, and optional `### Note`. Do not add extra standalone sections such as AC Coverage, Key Changes, Risks, Tests, QA, or UI Validation unless the target repo already documents them as its PR contract.

Preserve PR evidence from the local verdict artifacts only. Fold AC coverage, test evidence, QA evidence, UI validation evidence, known gaps, preview links, and spec gaps into the allowed template sections as concise reviewer-facing evidence. Do not include CI/lint/typecheck/test command summaries in the PR body; CI runs tests, and reviewer-visible evidence should come from artifacts, preview/baseline links, screenshots, reproductions, or linked specs. Do not include AI-assistant attribution in commit messages, PR text, or generated artifacts.

## Inputs

Read:

- `state.json`
- `context-packet/`
- `implementation-plan/`
- `current-diff/`
- final local verdicts: `04`, `05`, `06`, `07`
- target repository git state

## Required Work

1. Verify the target repo and branch.
2. Verify local safety phases have passed or are not applicable with reasons.
3. Stage only files relevant to the ticket and verify the staged diff is in scope before committing.
4. Create a clear commit if needed. Do not amend unless explicitly instructed by the run state or human input.
5. Push the branch.
6. Create a PR with a reviewer-friendly title and a body that follows the `git-workflow` template exactly.
7. Include artifact-backed AC coverage, test evidence, QA evidence, UI validation evidence, known gaps, and spec gaps only inside the allowed template sections.
8. Request the configured automated review if available.
9. Record PR metadata.

## Phase Checklist

- Repo, branch, remote, and uncommitted changes are inspected before commit/push.
- Only ticket-relevant files are staged and committed; unrelated generated noise or formatting churn is excluded.
- PR body evidence is copied from artifacts only; missing evidence is listed as a gap, not invented.
- PR body follows the `git-workflow` template sections exactly and does not include command-summary sections.
- AC coverage, tests, QA, UI validation, known gaps, and preview information are included when available inside the allowed sections.
- Commit messages and PR text contain no AI-assistant attribution.
- `pr/metadata.json` includes URL/number and any preview/deployment details found.
- Unsafe git/auth/remote state returns `blocked` with exact human action needed.

## Artifacts To Write

Write these files:

- `pr/metadata.json`
- `pr/description.md`
- `phases/08-create-pr/output.json`
- optional `phases/08-create-pr/notes.md`

Required artifact list: `["pr/metadata.json","pr/description.md","phases/08-create-pr/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/08-create-pr/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when the PR exists and metadata is recorded. Use `status: "blocked"` for missing auth, unsafe git state, missing remote, or repository ambiguity.

Do not create unrelated commits. Do not force-push. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "create-pr",
	"status": "pass",
	"summary": "PR was created or updated and metadata was recorded.",
	"inputs_read": ["current-diff/", "verdicts/", "implementation-plan/"],
	"artifacts_written": ["pr/metadata.json", "pr/description.md"],
	"evidence": [{ "type": "pr", "description": "PR metadata was recorded.", "path": "pr/metadata.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
