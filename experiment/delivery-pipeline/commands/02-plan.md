# Phase 2: Implementation Planning

This command runs the Implementation Planning phase for the experimental delivery pipeline.

## Role Contract

Read immutable artifacts and inspect the target repository in a constrained, read-only way. Produce a concrete implementation plan. Do not edit code.

## Shared Pipeline Rules

Read `commands/shared-preamble.md` if available. Enforce these critical rules even if it is unavailable: treat runner-provided paths as the only runtime authority, read previous artifacts as immutable inputs, write only this phase's listed artifacts, never invent evidence or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending. If required context or repository state is missing, use `status: "blocked"` with an actionable blocker instead of guessing.

This phase is read-only. Do not change source files, tests, package files, or git state.

## Skill References

Read guidance from `applying-coding-style`, `test-driven-development`, `a11y-audit`, `security-hardening`, and `validating-ui` as planning inputs only when the ticket touches those domains. Treat that guidance as constraints to carry into the plan, affected-files, and validation artifacts: expected coding style, test coverage, accessibility, security, UI fidelity, and recovery requirements. Do not run implementation, test-writing, review, browser validation, security-hardening, or fixer workflows in this phase.

## Inputs

Read:

- `state.json`
- `context-packet/`
- `human-inputs/`
- previous phase outputs under `phases/`
- target repository instructions, scripts, nearby code, shared components, and existing tests when needed

## Required Work

1. Confirm the target repository and likely working area.
2. Read repo instructions and package scripts needed for implementation and validation.
3. Search for existing patterns, shared/design-system components, data helpers, feature flag helpers, test patterns, and similar implementations.
4. Shape the work into vertical slices.
5. Decide the test strategy, including domain invariants and business rules that should fail if broken.
6. Decide QA and UI validation targets from the ACs, linked context, and Figma specs.
7. Identify unresolved product/design/architecture decisions. Do not invent answers.

## Phase Checklist

- Target repo instructions, scripts, ownership boundaries, and current branch safety are inspected before planning.
- Existing patterns are searched before proposing new abstractions.
- Plan slices are small enough for the Implementer/Fixer to execute and validate.
- `affected-files.json` names likely files/modules and why they matter.
- `validation-plan.json` maps AC IDs to unit, QA, UI, PR, and regression checks.
- Unresolved decisions are blockers, not assumptions.

## Artifacts To Write

Write these files:

- `implementation-plan/plan.md`
- `implementation-plan/affected-files.json`
- `implementation-plan/validation-plan.json`
- `phases/02-plan/output.json`
- optional `phases/02-plan/notes.md`

Required artifact list: `["implementation-plan/plan.md","implementation-plan/affected-files.json","implementation-plan/validation-plan.json","phases/02-plan/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/02-plan/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` only when the implementer can start. Use `status: "blocked"` for missing repository, unresolved scope decisions, inaccessible context, or unsafe repo state.

Do not edit source files. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "plan",
	"status": "pass",
	"summary": "Implementation plan, affected files, and validation plan are ready for implementation.",
	"inputs_read": ["state.json", "context-packet/"],
	"artifacts_written": ["implementation-plan/plan.md", "implementation-plan/affected-files.json", "implementation-plan/validation-plan.json"],
	"evidence": [{ "type": "repo-inspection", "description": "Relevant patterns and scripts were inspected.", "path": "implementation-plan/affected-files.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
