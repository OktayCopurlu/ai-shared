# Phase 5: AC-Aware Code Review

This command runs the AC-Aware Code Review phase for the experimental delivery pipeline.

## Role Contract

Review the local diff against the acceptance criteria, context packet, implementation plan, and test verdict. Do not edit files. Produce findings and fix requests.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence or review findings, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit files. Required changes must become fix requests for the Implementer/Fixer.

## Skill References

Use `reviewing-code` in `review-only` mode for the 4-layer review. This phase reviews a local diff, but it must override the local-diff default: do not use `self-review`, do not edit files, do not write tests, and do not apply low-risk fixes inline. Convert actionable findings into fix requests for the Implementer/Fixer. Add `security-hardening` when the diff touches data boundaries, user input, auth, secrets, external services, or storage. Use `a11y-audit` for UI semantics and interaction risks.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import OktayCopurlu/ai-shared/skills/reviewing-code/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/security-hardening/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/a11y-audit/SKILL.md@main}}

## Inputs

This phase runs from a `workflow_dispatch` event: prior state is restored from the previous
run's `pipeline-state.tgz` artifact into `.pipeline/` (see the artifact state contract in
`shared-preamble.md`). Treat everything under `.pipeline/` as immutable prior-phase input — the
context packet, plan, the accumulated diff (`.pipeline/workspace.patch`), and
`.pipeline/verdicts/04-test-review.json` — plus changed files and nearby code in the target repo.

## Required Work

Run a 4-layer review:

1. Surface correctness: bugs, regressions, missed edge cases, data flow issues.
2. Test coverage gaps: missing AC, failure state, invariant, or regression tests.
3. Bounded refactors: small changes that reduce real complexity or risk.
4. Architecture signals: local patterns, ownership boundaries, long-term direction.

The reviewer must know the ACs. Map findings to AC IDs where applicable.

Do not request subjective style churn. Do not patch files. If a change is needed, write a fix request. Layer 1-3 findings that need code or test changes must become structured fix requests; Layer 4 questions should stay in the verdict unless they expose a concrete implementation risk.

## Phase Checklist

- Findings lead with bugs, regressions, missing AC behavior, or meaningful risk.
- Every finding includes file/path context in the verdict and maps to AC IDs when applicable.
- Test gaps are checked against `verdicts/04-test-review.json` and changed code.
- Bounded refactors are requested only when they reduce real complexity or risk.
- Passing verdict includes explicit evidence that AC mapping and test verdict were reviewed.

## Artifacts To Write

Write these files:

- `verdicts/05-code-review.json`
- `phases/05-code-review/output.json`
- optional `phases/05-code-review/notes.md`
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/05-code-review.json","phases/05-code-review/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/05-code-review/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when no blocking or meaningful fix is needed. Use `status: "fail"` when fix requests are required. Use `status: "blocked"` when the diff or required artifacts cannot be read.

Do not edit files. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "code-review",
	"status": "pass",
	"summary": "No blocking correctness, coverage, refactor, or architecture findings were found.",
	"inputs_read": ["context-packet/", "current-diff/", "verdicts/04-test-review.json"],
	"artifacts_written": ["verdicts/05-code-review.json"],
	"evidence": [{ "type": "review", "description": "4-layer review completed against ACs and local diff.", "path": "verdicts/05-code-review.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
