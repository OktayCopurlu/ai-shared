---
description: "Pre-refinement review of a Jira ticket. Use before a team refinement session to identify gaps, missing context, and open questions."
---

# Refine Ticket

When the user provides a ticket key or link:

1. read the full Jira detail via Atlassian MCP
2. open and read every link in the ticket — Figma, Contentful, wiki pages, linked tickets, and any other referenced URLs
3. load the `jira-ticket` skill — use its ticket structure, acceptance criteria rules, and review mode as the quality baseline for this review

## Review Checklist

Evaluate the ticket against these dimensions:

### Completeness

- is the context clear — what is happening today, why it is a problem, who is affected?
- are acceptance criteria present, testable, and implementation-free?
- is there a design link (Figma) if the ticket has UI impact?
- is there a dev note with enough engineering hints to start work?

### Scope

- is the ticket small enough for one engineer in one sprint?
- if too broad, suggest how to split it into smaller tickets
- are non-goals clear or inferable?

### Ambiguity

- are there unstated assumptions that could surprise the team?
- are edge cases or error states mentioned where relevant?
- are there open questions that need a PM/design answer before work starts?

### Dependencies

- does the ticket depend on other tickets, services, or teams?
- are those dependencies linked in Jira?
- is the execution order clear?

## Output

Produce a concise refinement brief:

1. **Verdict**: ready / needs work / blocked
2. **Gaps found**: list each gap with a specific suggestion (e.g., "AC missing for error state — add: When the API returns an error, a fallback message is shown")
3. **Open questions for refinement**: questions the team should discuss
4. **Suggested updates**: concrete rewrites or additions — not vague advice

If the ticket is ready, say so in one line and stop.

## Applying Updates

If the user asks to apply the suggested updates:

- use Atlassian MCP to update the ticket directly
- preserve existing content that is correct
- only modify or add what was flagged

## Guardrails

- do not invent requirements — only flag what is missing or unclear
- do not rewrite a ticket that is already clear and complete
- do not add implementation details to acceptance criteria
- do not guess acceptance criteria — flag the gap and suggest the user or PM fill it
- keep the refinement brief short enough to scan in under a minute
