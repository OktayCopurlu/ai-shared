---
description: "Draft a solution design for a Jira ticket. Reads ticket context, linked resources, and produces a technical design doc section or standalone design."
---

# Solution Design

When the user provides a ticket key, link, or topic:

1. read the full Jira detail via Atlassian MCP (if a ticket is provided)
2. open and read every link in the ticket — Figma, Contentful, wiki pages, linked tickets, and any other referenced URLs
3. if a Confluence project page exists, read it to understand the broader project context

## Draft the Design

Use the `project-doc-expert` agent's Technical Design mode. The design should cover:

- **Context / Problem** — what is being solved and why
- **Proposed Approach** — the recommended implementation with enough detail for an engineer to start
- **Alternatives Considered** — at least one alternative with trade-offs (skip only if the approach is obviously the only option)
- **Risks / Edge Cases** — what could go wrong, failure modes
- **Open Questions** — anything that needs a team decision before implementation

Omit sections that do not apply. Do not pad with empty or boilerplate sections.

### Scope Calibration

Match the depth to the ticket size:

- **Small ticket** (1-2 AC items, single component): 1-page inline design — Context, Approach, Risks. No need for a separate Confluence page.
- **Medium ticket** (3-6 AC items, touches multiple files/packages): full design with all sections above.
- **Large ticket** (cross-team, new architecture, data model changes): full design plus Data Model, API/Contract Changes, Rollout Plan, Observability.

## Output Options

Ask the user where the design should go:

1. **Inline in chat** — for quick review before publishing
2. **Update existing Confluence page** — add or replace the Solutions section via Atlassian MCP
3. **Create new Confluence page** — create a standalone design doc via Atlassian MCP

Default to inline if the user does not specify.

## Guardrails

- do not invent requirements — design against what the ticket actually says
- do not propose architecture changes beyond what the ticket scope needs
- do not write a solution design for a ticket that already has one unless the user asks to rewrite it
- if the ticket is too vague to design against, say so and suggest refining the ticket first
- keep the design practical — optimize for "can an engineer start work from this?" not for completeness
