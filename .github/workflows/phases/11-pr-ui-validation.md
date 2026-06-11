# Phase 11: UI Validation on PR

This command runs the UI Validation on PR phase for the experimental delivery pipeline.

## Role Contract

Validate UI behavior and Figma fidelity in the PR preview environment. Do not edit code. This is the final delivery validation before human review handoff.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence, browser observations, screenshots, preview URLs, or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit code, tests, snapshots, assets, PR metadata, package files, or git state. UI defects must become fix requests.

## Skill References

Use `validating-ui` for PR UI validation, `figma-mcp` for Figma specs, `playwright-mcp` for browser measurement and preview URL inspection, and `a11y-audit` for accessibility checks.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time; MCP-backed skills also need their server configured in the workflow frontmatter `mcp-servers:`. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import ../skills/validating-ui/SKILL.md}}
{{#runtime-import ../skills/figma-mcp/SKILL.md}}
{{#runtime-import ../skills/playwright-mcp/SKILL.md}}
{{#runtime-import ../skills/a11y-audit/SKILL.md}}

## Inputs

This phase runs from a `workflow_dispatch` event against the live PR opened in phase 8. The
ticket arrives as the `ticket` input and the PR number as `pr_number` (resolve it from the
`[delivery] <ticket>` title when empty). Read the PR preview/UI with the `playwright` and
`github` tools; restore the previous run's `pipeline-state.tgz` artifact into `.pipeline/` for
the context packet (`acceptance-criteria.json`, `figma-specs.json`, `validation-targets.md`),
`.pipeline/implementation-plan/validation-plan.json`, and the verdicts `07-ui-validation.json`
and `10-pr-qa.json` under `.pipeline/verdicts/` (see the artifact state contract in
`shared-preamble.md`).

## Required Work

1. Determine whether PR UI validation applies. It applies when UI changed, layout/styling changed, a component changed, or Figma exists.
2. Validate the PR preview UI, not only the local UI.
3. Validate desktop and mobile when user-facing or responsive.
4. Use Figma specs and computed browser measurements as the pass/fail source of truth.
5. Screenshots may support evidence but must not replace structured comparisons.
6. Try preview, local branch, direct route, data setup, flag override, and component-surface fallbacks before marking blocked.
7. Record final evidence suitable for PR handoff.
8. Do not patch code.

## Phase Checklist

- Applicability is decided from PR diff, local UI verdict, ACs, validation targets, and Figma availability.
- PR preview UI is validated before local fallback is accepted.
- Desktop and mobile checks run when user-facing or responsive.
- Figma validation uses extracted specs plus computed browser measurements; screenshots are secondary evidence.
- Final pass includes evidence suitable for human handoff and notes any residual preview limitation.

## Artifacts To Write

Write these files:

- `verdicts/11-pr-ui-validation.json`
- `phases/11-pr-ui-validation/output.json`
- optional `phases/11-pr-ui-validation/notes.md`
- optional screenshots/traces under the run directory as secondary evidence
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/11-pr-ui-validation.json","phases/11-pr-ui-validation/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/11-pr-ui-validation/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "not-applicable"` only when there is no UI impact and no Figma/UI validation target. Use `status: "pass"` when applicable checks pass. Use `status: "fail"` for PR UI defects. Use `status: "blocked"` only after recovery attempts are recorded.

Do not edit files. Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "pr-ui-validation",
	"status": "pass",
	"summary": "Applicable PR UI checks passed across required viewport/spec targets.",
	"inputs_read": ["pr/metadata.json", "context-packet/figma-specs.json", "verdicts/10-pr-qa.json"],
	"artifacts_written": ["verdicts/11-pr-ui-validation.json"],
	"evidence": [{ "type": "browser-validation", "description": "PR UI validation evidence is recorded.", "path": "verdicts/11-pr-ui-validation.json" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
