# Phase 3: Implementation

This command runs the Implementation phase for the experimental delivery pipeline.

## Role Contract

Implement the requested change and any structured fix requests. You are the only phase expected to intentionally change source code. Keep changes scoped to the context packet, implementation plan, and fix requests.

## Shared Pipeline Rules

Read `commands/shared-preamble.md` if available. Enforce these critical rules even if it is unavailable: treat runner-provided paths as the only runtime authority, read previous artifacts as immutable inputs, write only this phase's listed artifacts, never invent evidence or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending. If repo state, requirements, credentials, or branch safety make implementation unsafe, use `status: "blocked"` with an actionable blocker.

This is the only code-editing phase before PR creation. Keep edits scoped to the plan and unresolved fix requests.

## Skill References

Apply `applying-coding-style` for code edits. Use `test-driven-development` for new behavior or bug fixes with regression coverage, and `a11y-audit` for UI semantics and interactions. For UI work, use `validating-ui` fidelity and recovery expectations while implementing and recording focused local checks; the full browser/UI validation verdict belongs to Phase 7. Use `security-hardening` when changes touch user input, auth, external services, stored data, or secrets.

## Inputs

Read:

- `state.json`
- `context-packet/`
- `implementation-plan/`
- `fix-requests/`
- previous verdicts under `verdicts/`
- previous phase outputs under `phases/`
- target repository instructions and relevant code/tests

## Required Work

1. Verify the target repository and branch are correct before editing.
2. Read the relevant existing code and tests before changing files.
3. Apply the implementation plan and any unresolved fix requests.
4. Follow local coding style and existing patterns.
5. For behavior changes, add or update tests unless the plan explicitly marks the change as short-lived experiment code and explains why test updates are intentionally skipped.
6. Preserve domain invariants and business rules identified by the plan.
7. For UI work, reuse shared/design-system components when appropriate and apply Figma specs as structured values, not eyeballed screenshots.
8. Run focused checks that are cheap and relevant. Full QA, code-review, and UI-validation verdicts belong to later phases.
9. Record the current diff and changed files.

## Phase Checklist

- Repo instructions and branch state were checked before editing.
- Every code change traces to an AC, implementation-plan item, or fix request.
- Validator feedback is addressed in code/tests, not hidden by changing verdict artifacts.
- Relevant focused checks ran when practical, and failures are recorded honestly.
- `current-diff/diff.patch`, `changed-files.json`, and `summary.md` reflect the actual current diff.

## Artifacts To Write

Write these files:

- `current-diff/diff.patch`
- `current-diff/changed-files.json`
- `current-diff/summary.md`
- `phases/03-implement/output.json`
- optional `phases/03-implement/notes.md`

Required artifact list: `["current-diff/diff.patch","current-diff/changed-files.json","current-diff/summary.md","phases/03-implement/output.json"]`.

If a fix request is completed, mention it in `current-diff/summary.md` and `output.json` evidence.

## Output Rules

The final file must be valid JSON at `phases/03-implement/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when the diff is coherent enough for test review. Use `status: "blocked"` for unsafe repo state, missing credentials, inaccessible required context, or contradictory requirements.

Do not create a PR in this phase. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "implement",
	"status": "pass",
	"summary": "Scoped implementation is complete and ready for test review.",
	"inputs_read": ["context-packet/", "implementation-plan/", "fix-requests/"],
	"artifacts_written": ["current-diff/diff.patch", "current-diff/changed-files.json", "current-diff/summary.md"],
	"evidence": [{ "type": "diff", "description": "Current implementation diff was recorded.", "path": "current-diff/diff.patch" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
