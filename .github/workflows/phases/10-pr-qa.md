# Phase 10: QA on PR

This command runs the QA on PR phase for the experimental delivery pipeline.

## Role Contract

Validate the PR in its preview or PR environment using ACs and validation targets. Do not edit code. Produce expected vs actual results and fix requests.

## Shared Pipeline Rules

Follow the gh-aw pipeline runtime contract in the imported `shared-preamble.md`. Critical rules: all pipeline working files live under `.pipeline/` in the workspace and that is the only runtime authority (there is no external runner), read prior-phase artifacts under `.pipeline/` as immutable inputs, write only this phase's listed artifacts, never invent evidence, preview URLs, QA results, or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending.

This is a validator phase. Do not edit code, tests, PR metadata, package files, or git state. PR-environment failures must become fix requests.

## Skill References

Use `manual-qa` for PR-environment QA structure, `github-mcp` for PR/preview metadata when available, and `playwright-cli` from bash for browser interaction or preview URL inspection. Verify tracking/analytics through observable browser-side console or network evidence.

### Skill imports (gh-aw)

In gh-aw a skill that is only mentioned is not read. Import the skills above so their content is injected at compile time; MCP-backed skills also need their server configured in the workflow frontmatter `mcp-servers:`. The `github-mcp` capability maps to the `github` skill and gh-aw's built-in GitHub tools. Pin `@main` to a tag or SHA for reproducible runs.

{{#runtime-import skills/manual-qa/SKILL.md}}
{{#runtime-import skills/github/SKILL.md}}

## Inputs

This phase runs from a `workflow_dispatch` event against the live PR opened in phase 8. The
ticket arrives as the `ticket` input and the PR number as `pr_number` (resolve it from the
`[delivery] <ticket>` title when empty). Read the PR with the `github` tools; restore the
previous run's `pipeline-state.tgz` artifact into `.pipeline/` for the context packet,
`.pipeline/implementation-plan/validation-plan.json`, and the verdicts `06-qa.json` and
`09-pr-code-review.json` under `.pipeline/verdicts/` (see the artifact state contract in
`shared-preamble.md`).

## Required Work

1. Find the PR preview URL from PR metadata, deployment checks, comments, or configured preview rules.
2. If no preview exists, try documented local/branch/component fallback surfaces and record attempts.
3. Run AC-aware QA in the PR environment.
4. Include regression checks for changed behavior and environment-specific risk.
5. When the ticket involves tracking or analytics, trigger the relevant user actions and verify event names, properties, payload values, timing, and negative cases against the ACs or linked specs using console logs, network requests, or required analytics tooling. Do not pass tracking QA without payload evidence.
6. When the ticket involves A/B tests, experiments, feature flags, or variants, verify both control and treatment behavior when reachable. Identify the source-of-truth assignment path and supported override mechanism from code, docs, runtime state, or tooling; do not invent cookie or storage keys. After applying an override, reload and verify the active variant through rendered UI, exposure/tracking payload, network response, or runtime state. A stored override key alone is not proof.
7. Record scenario, expected, actual, reproduction, environment, and AC IDs for failures.
8. Do not patch code.

## Phase Checklist

- Preview URL discovery attempts are recorded, including PR metadata, checks, comments, and configured rules.
- QA scenarios map to AC IDs and compare PR environment behavior against expected behavior.
- Tracking checks record event names, expected properties, observed payload evidence, and negative cases when tracking is in scope.
- Variant checks record control/treatment expectations, the confirmed override source, and proof that the active variant changed when A/B behavior is in scope.
- Recovery attempts cover preview, local branch, route, data setup, and flag overrides before blocked.
- Failures include environment, expected, actual, reproduction, and related AC IDs.
- Passing verdict notes any preview-specific residual risk.

## Artifacts To Write

Write these files:

- `verdicts/10-pr-qa.json`
- `phases/10-pr-qa/output.json`
- optional `phases/10-pr-qa/notes.md`
- optional fix request files under `fix-requests/`

Required artifact list: `["verdicts/10-pr-qa.json","phases/10-pr-qa/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/10-pr-qa/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` when PR QA passes. Use `status: "fail"` for PR-environment behavior failures. Use `status: "blocked"` only after preview/local recovery attempts are recorded.

Do not edit files. Do not end without writing `output.json`.

Example `output.json` blocked shape:

```json
{
	"schema_version": "1",
	"phase": "pr-qa",
	"status": "blocked",
	"summary": "No PR preview or documented fallback surface was reachable after recovery attempts.",
	"inputs_read": ["pr/metadata.json", "context-packet/", "implementation-plan/validation-plan.json"],
	"artifacts_written": ["verdicts/10-pr-qa.json"],
	"evidence": [{ "type": "preview-discovery", "description": "Preview discovery attempts are recorded.", "path": "verdicts/10-pr-qa.json" }],
	"fix_requests": [],
	"blockers": [{ "type": "needs-preview", "message": "PR preview URL was not available and fallback surfaces were not reachable.", "needed_from_human": "Provide a preview URL or the required access/flag override." }],
	"stale_artifacts": [],
	"next_recommendation": "pause-for-human"
}
```
