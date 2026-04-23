---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP

Prefer Atlassian MCP tools over opening Atlassian URLs in a browser or asking the user to paste content.

## Default Route

1. If the user gives an exact Jira key (for example `DSC-1986`), fetch it directly with `getJiraIssue`.
2. If the user gives a Confluence URL, extract the site hostname as `cloudId` and fetch the page directly if the URL contains a usable page ID.
3. If the user needs discovery and you do not know whether the answer is in Jira or Confluence, start with `search`, then use `fetch` on the returned ARI.
4. Use `searchJiraIssuesUsingJql` or `searchConfluenceUsingCql` only when you need precise filtering that `search` cannot express.

## Non-Obvious Rules

- Prefer Markdown output when you need readable text. Use ADF only when rich formatting matters.
- When the user provides an Atlassian URL such as `https://site.atlassian.net/...`, try `site.atlassian.net` as `cloudId` before calling `getAccessibleAtlassianResources`.
- Keep JQL/CQL searches small by default with `maxResults: 10` or `limit: 10`.
- Before transitioning a Jira issue, call `getTransitionsForJiraIssue` to get a valid transition ID.
- Before assigning a Jira issue by display name, call `lookupJiraAccountId`.
- Confluence tiny-link IDs from `/wiki/x/<id>` can be passed directly as `pageId`.

## Guardrails

- Do not open Jira or Confluence links in a browser when MCP can fetch them directly.
- Do not start with broad search when the user already gave an exact key, page ID, or URL.
- Use `search` as the default discovery tool; use JQL/CQL only for explicit or precision-filtered queries.
