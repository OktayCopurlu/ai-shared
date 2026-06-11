# Phase 9: PR Code Review

This command runs the PR Code Review phase for the experimental delivery pipeline.

## Role Contract

Review the opened PR diff against ACs, context, implementation plan, and local validation evidence. Do not edit code. Produce PR-level findings and fix requests.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence, review comments, PR state, or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit files or mutate the PR. Required changes must become fix requests for the Implementer/Fixer.

## Skill References

Use `github-mcp` to read PR metadata/diff when available and `reviewing-code` for the 4-layer review. Add `security-hardening` when the PR touches sensitive boundaries.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time. The `github-mcp` capability maps to the `github` skill and gh-aw's built-in GitHub tools. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import skills/github/SKILL.md}}
{{#runtime-import skills/reviewing-code/SKILL.md}}
{{#runtime-import skills/security-hardening/SKILL.md}}

## Inputs

This phase runs from a `workflow_dispatch` event against the live PR opened in phase 8. The
ticket arrives as the `ticket` input and the PR number as `pr_number` (resolve it from the
`[delivery] <ticket>` title when empty). Read the PR diff and description with the `github`
tools; restore the previous run's `pipeline-state.tgz` artifact into `.pipeline/` for the
context packet, plan, and local verdicts under `.pipeline/verdicts/` (see the artifact state
contract in `shared-preamble.md`).

## Required Work

1. Read the PR description and PR diff.
2. Confirm the PR still maps to the context packet and ACs.
3. Review the full PR diff for correctness, test gaps, bounded refactors, and architecture signals.
4. Compare PR evidence against local artifacts. Flag missing or false evidence.
5. Produce fix requests for meaningful issues. Do not patch code.

## Phase Checklist

- PR metadata, PR description, and actual PR diff are read.
- PR evidence is checked against local artifacts for false or missing claims.
- Review uses the same 4-layer heuristic as local code review.
- Findings map to AC IDs where applicable and avoid subjective churn.
- Blocked verdict names the exact PR access, diff, or metadata issue.

## Artifacts To Write

Write these files:

- `verdicts/09-pr-code-review.json`
- `phases/09-pr-code-review/output.json`
- optional `phases/09-pr-code-review/notes.md`
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/09-pr-code-review.json","phases/09-pr-code-review/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/09-pr-code-review/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when the PR review finds no meaningful required changes. Use `status: "fail"` when fix requests are needed. Use `status: "blocked"` when the PR or diff cannot be read.

Do not edit files. Do not end without writing `output.json`.

Example `output.json` fail shape:

```json
{
	"schema_version": "1",
	"phase": "pr-code-review",
	"status": "fail",
	"summary": "PR diff introduced a meaningful regression risk that needs implementation changes.",
	"inputs_read": ["pr/metadata.json", "pr/description.md", "current-diff/", "verdicts/"],
	"artifacts_written": ["verdicts/09-pr-code-review.json", "fix-requests/PRCR-001.json"],
	"evidence": [{ "type": "pr-review", "description": "PR diff was reviewed against ACs.", "path": "verdicts/09-pr-code-review.json" }],
	"fix_requests": [{ "id": "PRCR-001", "source_phase": "pr-code-review", "severity": "high", "acceptance_criteria": ["AC-1"], "scenario": "PR diff regression", "expected": "PR behavior matches local validated behavior.", "actual": "PR diff changes the behavior in a risky path.", "reproduction": ["Inspect PR diff and affected path"], "suggested_direction": "Adjust implementation and replay the local safety loop." }],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "fix"
}
```
