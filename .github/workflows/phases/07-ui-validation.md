# Phase 7: AC + Figma UI Validation

This command runs the AC and Figma UI Validation phase for the experimental delivery pipeline.

## Role Contract

Validate local UI behavior and visual fidelity against ACs and Figma specs. Do not edit code. Produce precise findings and fix requests.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence or browser observations, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit code, tests, snapshots, assets, package files, or git state. UI defects must become fix requests.

## Skill References

Use `validating-ui` for browser-level UI validation, `a11y-audit` for accessibility semantics and keyboard/focus behavior, `figma-mcp` for Figma specs, and `playwright-mcp` for browser interaction and measurement.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time; MCP-backed skills also need their server configured in the workflow frontmatter `mcp-servers:`. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import OktayCopurlu/ai-shared/skills/validating-ui/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/a11y-audit/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/figma-mcp/SKILL.md@main}}
{{#runtime-import OktayCopurlu/ai-shared/skills/playwright-mcp/SKILL.md@main}}

## Inputs

This phase runs from a `workflow_dispatch` event: prior state is restored from the previous
run's `pipeline-state.tgz` artifact into `.pipeline/` (see the artifact state contract in
`shared-preamble.md`). Treat everything under `.pipeline/` as immutable prior-phase input — the
context packet (`acceptance-criteria.json`, `figma-specs.json`, `validation-targets.md`),
`.pipeline/implementation-plan/validation-plan.json`, the accumulated diff
(`.pipeline/workspace.patch`), and prior verdicts under `.pipeline/verdicts/`.

## Required Work

1. Determine whether UI validation applies. It applies when UI changed, layout/styling changed, a component changed, or Figma exists.
2. Use browser automation for local UI validation when a surface is available.
3. Validate desktop and mobile when the UI is responsive or user-facing.
4. Do not skip mobile after one failed attempt. Use Playwright viewport/device emulation and record recovery attempts.
5. Figma validation must use extracted specs: bounds, dimensions, spacing, typography, colors, borders, radius, layout, responsive behavior, content, states, and interactions.
6. Screenshots may support evidence but must not be the source of truth. Do not compare by eye as the primary method.
7. Compare rendered computed styles, DOM/layout measurements, and behavior against Figma specs and ACs.
8. If flags/data/routes hide the UI, use documented override paths or produce a blocker/fix request.
9. Do not patch code.

## Phase Checklist

- Applicability is decided from changed files, ACs, validation targets, and Figma availability.
- Desktop and mobile checks run when UI is user-facing or responsive.
- Figma comparison uses extracted specs and computed DOM/style/layout measurements, with screenshots only as secondary evidence.
- Recovery attempts for route/data/flag issues are recorded before blocked.
- Failures include expected vs actual measurements or behavior and produce fix requests.

## Artifacts To Write

Write these files:

- `verdicts/07-ui-validation.json`
- `phases/07-ui-validation/output.json`
- optional `phases/07-ui-validation/notes.md`
- optional screenshots/traces under the run directory as secondary evidence
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/07-ui-validation.json","phases/07-ui-validation/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/07-ui-validation/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "not-applicable"` only when there is no UI impact and no Figma/UI validation target. Use `status: "pass"` when applicable checks pass. Use `status: "fail"` for implementation defects. Use `status: "blocked"` only after recovery attempts are recorded.

Do not edit files. Do not end without writing `output.json`.

Example `output.json` not-applicable shape:

```json
{
	"schema_version": "1",
	"phase": "ui-validation",
	"status": "not-applicable",
	"summary": "No UI files, user-facing surfaces, layout/styling, or Figma validation targets apply to this change.",
	"inputs_read": ["context-packet/acceptance-criteria.json", "current-diff/changed-files.json"],
	"artifacts_written": ["verdicts/07-ui-validation.json"],
	"evidence": [{ "type": "applicability", "description": "Changed files and validation targets show no UI impact.", "path": "verdicts/07-ui-validation.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
