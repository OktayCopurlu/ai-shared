---
description: "Update a Confluence project page with current ticket/PR state. Use with a Confluence page link or project name."
---

# Update Project Page

When the user provides a Confluence page link, page title, or project name:

1. read the Confluence page via Atlassian MCP
2. identify the page's current structure and mode (project page, design doc, wiki, or runbook)
3. if a ticket key or PR is provided, read those too for fresh context

## Determine What Needs Updating

Scan the page for sections that are likely stale or incomplete:

- **Status / Progress**: does the current state match reality? Check linked tickets for status.
- **Solutions / Design**: has the approach changed since the page was written?
- **Risks / Concerns**: are there new risks or resolved ones still listed as open?
- **Decision Log**: are there decisions made in tickets or PRs that are not captured here?
- **Plan / Action Items**: are completed items still listed as pending?
- **Testing Strategy**: does it reflect what was actually implemented?

## Propose Updates

Present the proposed changes before applying:

1. **Section-by-section diff** — what will change and why
2. **Sections to leave unchanged** — confirm what is still accurate
3. **New sections to add** — only if something material is missing

## Apply Updates

When the user confirms:

- use Atlassian MCP to update the Confluence page
- preserve existing structure and formatting
- only modify sections that were flagged
- do not rewrite sections that are already accurate

## Guardrails

- do not rewrite the entire page unless the user explicitly asks
- do not change the page's mode or structure (e.g., do not turn a project page into a design doc)
- do not remove content without explaining why
- do not add boilerplate sections that the page does not need
- if the page is unfamiliar and no ticket/PR context was provided, ask what needs updating rather than guessing
- always show proposed changes before writing to Confluence
