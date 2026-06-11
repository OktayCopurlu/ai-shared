# Phase 4: Unit Test + Test Review

This command runs the Unit Test and Test Review phase for the experimental delivery pipeline.

## Role Contract

Run and review unit tests. Identify missing or weak test coverage. Do not edit source or test files. Produce fix requests for the Implementer/Fixer.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence or test results, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit code, tests, snapshots, package files, or git state. Required changes must become fix requests for the Implementer/Fixer.

## Skill References

Use local testing-pattern guidance, such as `references/testing-patterns.md` when available, to judge whether tests cover the behavior that matters. This phase reviews and runs tests only: do not write tests, do not start red/green implementation loops, and do not invoke fixer behavior. Use `debugging` only to localize failures enough to write a precise fix request; do not patch the failure yourself.

### Skill imports (gh-aw)

In gh-aw a skill or reference that is only mentioned is not read. Import the guidance below so its content is injected at compile time. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import references/testing-patterns.md}}
{{#runtime-import skills/debugging/SKILL.md}}

## Test Quality Rules

Tests should prove observable behavior, AC coverage, domain invariants, failure states, state transitions, and regression risk. Flag snapshot-only tests, implementation-only assertions, unasserted mocks, oversized multi-behavior tests, hardcoded fixture duplication, optional-chaining false positives, and UI tests that skip role/name/label queries when an accessibility contract exists.

## Inputs

This phase runs from a `workflow_dispatch` event: prior state is restored from the previous
run's `pipeline-state.tgz` artifact into `.pipeline/` (see the artifact state contract in
`shared-preamble.md`). Treat everything under `.pipeline/` as immutable prior-phase input — the
context packet, plan, the accumulated diff (`.pipeline/workspace.patch`), and earlier verdicts
under `.pipeline/verdicts/` — plus relevant test files and package scripts in the target repo.

## Required Work

1. Use repository-defined test commands. Do not invent custom validation commands when repo commands exist.
2. Run relevant unit tests. Widen scope when shared packages or shared behavior changed.
3. Review changed and nearby tests for meaningful invariant/business-rule coverage, not just happy-path snapshots.
4. Verify tests would fail if the AC behavior or identified invariants were broken.
5. If tests fail or coverage is weak, produce structured fix requests. Do not patch tests yourself.
6. If tests are not applicable, explain why with evidence.

## Phase Checklist

- Repository-defined commands were preferred over ad hoc commands.
- Test results include command, scope, exit status, and relevant output summary.
- Coverage review checks ACs, invariants, failure states, and regression risk.
- Weak tests produce fix requests with expected vs actual test coverage gaps.
- `not-applicable` is used only with evidence that no meaningful test surface exists.

## Artifacts To Write

Write these files:

- `verdicts/04-test-review.json`
- `phases/04-test-review/output.json`
- optional `phases/04-test-review/notes.md`
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/04-test-review.json","phases/04-test-review/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/04-test-review/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when tests pass and test quality is adequate. Use `status: "fail"` when implementation or tests need changes. Use `status: "blocked"` when tests cannot run for environment/access reasons.

Do not edit code or tests. Do not end without writing `output.json`.

Example `output.json` fail shape:

```json
{
	"schema_version": "1",
	"phase": "test-review",
	"status": "fail",
	"summary": "Focused tests pass, but AC-2 lacks a regression test for the required error state.",
	"inputs_read": ["implementation-plan/validation-plan.json", "current-diff/"],
	"artifacts_written": ["verdicts/04-test-review.json", "fix-requests/TR-001.json"],
	"evidence": [{ "type": "test-command", "description": "Relevant unit test command completed.", "path": "verdicts/04-test-review.json" }],
	"fix_requests": [{ "id": "TR-001", "source_phase": "test-review", "severity": "medium", "acceptance_criteria": ["AC-2"], "scenario": "Required error state regression coverage", "expected": "A failing test protects the behavior.", "actual": "No test exercises the error state.", "reproduction": ["Inspect changed tests"], "suggested_direction": "Add a focused regression test before implementation proceeds." }],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "fix"
}
```
