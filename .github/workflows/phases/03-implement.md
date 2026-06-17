# Phase 3: Implementation

This command runs the Implementation phase for the experimental delivery pipeline.

## Role Contract

Implement the requested change and any structured fix requests. You are the only phase expected to intentionally change source code. Keep changes scoped to the context packet, implementation plan, and fix requests.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending. If repo state, requirements, credentials, or branch safety make implementation unsafe, use `status: "blocked"` with an actionable blocker.

This is the only code-editing phase before PR creation. Keep edits scoped to the plan and unresolved fix requests.

## Skill References

Apply `applying-coding-style` for code edits. Use `test-driven-development` for new behavior or bug fixes with regression coverage, and `a11y-audit` for UI semantics and interactions. For UI work, use `validating-ui` fidelity and recovery expectations while implementing and recording focused local checks; the full browser/UI validation verdict belongs to Phase 7. Use `security-hardening` when changes touch user input, auth, external services, stored data, or secrets.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import skills/applying-coding-style/SKILL.md}}
{{#runtime-import skills/test-driven-development/SKILL.md}}
{{#runtime-import skills/a11y-audit/SKILL.md}}
{{#runtime-import skills/validating-ui/SKILL.md}}
{{#runtime-import skills/security-hardening/SKILL.md}}

## Inputs

This phase runs from a `workflow_dispatch` event: prior state is restored from the previous
run's `pipeline-state.tgz` artifact into `.pipeline/` (see the artifact state contract in
`shared-preamble.md`). Treat everything under `.pipeline/` as immutable prior-phase input — the
context packet, plan, fix requests under `.pipeline/fix-requests/`, the accumulated diff
(`.pipeline/workspace.patch`), and earlier verdicts under `.pipeline/verdicts/` — plus target
repository instructions and relevant code/tests.

## Required Work

1. Verify the target repository and branch are correct before editing.
2. Start from `implementation-plan/affected-files.json` and open those files first; read the relevant existing code and tests before changing them. Trust the plan's file list — do not re-explore the repository from scratch. Widen the search only when a file you genuinely need is missing from the plan, and keep it targeted (no broad `find`/`grep -r` across the repo root).
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
