# Phase 1: Context Intake

This command runs the Context Intake phase for the experimental delivery pipeline.

## Role Contract

Read the ticket and all linked implementation context. Write stable facts into the run directory. Do not write product code, do not plan the implementation beyond identifying blockers, and do not invent missing requirements.

## Shared Pipeline Rules

Read `commands/shared-preamble.md` if available. Enforce these critical rules even if it is unavailable: treat runner-provided paths as the only runtime authority, read previous artifacts as immutable inputs, write only this phase's listed artifacts, never invent evidence or human answers, never include secrets/tokens/auth headers/cookies in artifacts, and always write schema-valid `output.json` before ending. If required context is inaccessible, use `status: "blocked"` with an actionable blocker instead of guessing.

Separate fix request files are not expected from this phase. If the intake cannot complete because information is missing, use blockers rather than implementation fix requests.

## Skill References

Use the relevant context-reading skills when links or source types appear: `atlassian-mcp` for Jira/Confluence, `linked-context-routing` for URLs, `figma-mcp` for Figma, `contentful` for CMS entries, and `google-drive` for Google Docs/Sheets. If a required tool path is unavailable, record the access/tooling blocker.

## Inputs

The runner message provides:

- `RUN_DIR`
- `STATE_PATH`
- `INPUT_PATH`
- optional `TARGET_REPO`

Read:

- `input.json`
- `state.json`
- any existing files under `human-inputs/`

## Required Work

1. Read the ticket from the input. If it is a Jira ticket or link, use the available Atlassian/Jira path.
2. Read all linked context required by the ticket: Figma, Contentful, Confluence/wiki pages, linked tickets, experiments, preview URLs, docs, and other URLs.
3. For Figma links, extract structured specs. Do not pass only the URL. Include bounds, width, height, layout, spacing, typography, colors, borders, radius, effects, content, states, interactions, responsive behavior, and frame screenshots as secondary context when available.
4. Normalize acceptance criteria into stable IDs such as `AC-1`, `AC-2`.
5. Record constraints, non-goals, risks, rollout/flag details, and validation targets.
6. If required linked context is inaccessible or a human-owned decision blocks progress, write a blocker and return `blocked`.

## Phase Checklist

- Ticket source, title, description, comments, and ACs are captured without adding requirements that are not present.
- Linked Jira/Confluence/Figma/Contentful/URL context is either extracted into artifacts or listed as a blocker with what access/input is needed.
- `acceptance-criteria.json` uses stable `AC-N` IDs and validates against `schemas/acceptance-criteria.schema.json`.
- `figma-specs.json` validates against `schemas/figma-specs.schema.json` and must include structured screens or components when Figma context is available.
- Figma specs are structured when Figma exists; a simple URL is not enough.
- Validation targets identify local, QA, UI, PR, flag, data, browser, and viewport needs where applicable.

## Artifacts To Write

Write these files:

- `context-packet/ticket.md`
- `context-packet/acceptance-criteria.json`
- `context-packet/linked-context.md`
- `context-packet/figma-specs.json` when Figma exists; otherwise write `{ "available": false, "reason": "no Figma link found" }`
- `context-packet/constraints.md`
- `context-packet/open-questions.md`
- `context-packet/validation-targets.md`
- `phases/01-context-intake/output.json`
- optional `phases/01-context-intake/notes.md`

Required artifact list: `["context-packet/ticket.md","context-packet/acceptance-criteria.json","context-packet/linked-context.md","context-packet/figma-specs.json","context-packet/constraints.md","context-packet/open-questions.md","context-packet/validation-targets.md","phases/01-context-intake/output.json"]`.

## Output Rules

The final file must be valid JSON at `phases/01-context-intake/output.json` using `schemas/phase-output.schema.json`.

Set `schema_version` to `"1"`. The `phase` field must match this command phase ID.

Use `status: "pass"` only when the context packet is complete enough for planning. Use `status: "blocked"` when access, credentials, missing ticket data, or product/design decisions block planning.

Do not end without writing `output.json`.

Example `output.json` pass shape:

```json
{
	"schema_version": "1",
	"phase": "context-intake",
	"status": "pass",
	"summary": "Ticket context, acceptance criteria, linked context, constraints, and validation targets were captured.",
	"inputs_read": ["input.json", "state.json"],
	"artifacts_written": ["context-packet/ticket.md", "context-packet/acceptance-criteria.json", "context-packet/linked-context.md", "context-packet/figma-specs.json", "context-packet/constraints.md", "context-packet/open-questions.md", "context-packet/validation-targets.md"],
	"evidence": [{ "type": "ticket", "description": "Source ticket and linked context were read.", "path": "context-packet/ticket.md" }],
	"fix_requests": [],
	"blockers": [],
	"stale_artifacts": [],
	"next_recommendation": "continue"
}
```
