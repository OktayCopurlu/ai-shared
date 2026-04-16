---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP

Always prefer Atlassian MCP tools over fetching web pages or asking the user to paste content.

## Content Formats

Tools accept a `contentFormat` parameter:
- **`adf`** (default): Atlassian Document Format — full fidelity with mentions, panels, Smart Links
- **`markdown`**: Simplified text — easier to read/write but loses some formatting

Use `responseContentFormat` on read operations to control output format. Prefer `markdown` for readability when full fidelity isn't needed.

## Procedure

1. When a link is provided (e.g. `https://site.atlassian.net/*`), try passing the site hostname as cloudId first. Otherwise use `getAccessibleAtlassianResources`.
2. When the user references a Jira ticket ID (e.g., DSC-1986), fetch it directly — never try to open the URL in a browser.
3. For cross-product search (finding content across Jira and Confluence), prefer Rovo `search` over separate JQL/CQL queries.
4. When creating or updating content, use `markdown` contentFormat unless ADF features (panels, mentions, Smart Links) are needed.
5. Use `getJiraIssueTypeMetaWithFields` before creating issues to discover required and custom fields.
6. When linking issues, use `getIssueLinkTypes` first to discover available link type names.

## Tips

- **JQL**: `assignee = currentUser() AND status != Done ORDER BY updated DESC`
- **CQL**: `type = page AND space = "TEAM" AND title ~ "onboarding"`
- For bulk operations, prefer JQL/CQL search to find matching items, then operate on results.
