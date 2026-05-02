---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP

Prefer Atlassian MCP tools over opening Atlassian URLs in a browser or asking the user to paste content.

## Default Route

1. If the user gives an exact Jira key (for example `DSC-1986`), fetch it directly with `getJiraIssue` using `issueIdOrKey`.
2. If the user gives a Confluence URL, extract the site hostname as `cloudId` and fetch the page directly if the URL contains a usable page ID.
3. If the user needs discovery and you do not know whether the answer is in Jira or Confluence, start with `search`, then use `fetch` on the returned ARI.
4. Use `searchJiraIssuesUsingJql` or `searchConfluenceUsingCql` only when you need precise filtering that `search` cannot express.

## Jira Issue Reading

- For an exact Jira key like `DSC-2209`, use `getJiraIssue` directly with `issueIdOrKey: "DSC-2209"`.
- If `search` returns a Jira issue ARI, use `fetch` with that ARI as the fallback route.
- Do not use Confluence page tools, `getIssueLinkTypes`, or remote-link tools to read a Jira issue body; those are for pages or link metadata.

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
## Viewing Jira Attachments (Images)

The Atlassian MCP tools cannot download attachment files directly. To view images:

1. Fetch the ticket with `getJiraIssue` — the `attachment` field has the download URL in `content`
2. Download via `curl` with basic auth using `$JIRA_USER_EMAIL` and `$JIRA_API_TOKEN` from `~/.zshrc`
3. Use `view_image` to inspect the downloaded file

## Procedure

1. Use the Atlassian MCP tools exposed in the current session. If the host groups tools behind activation, activate the Jira, Confluence, or search category that matches the task before calling the exact operation.
2. If needed, use `getAccessibleAtlassianResources` to get the cloud ID.
3. Call the appropriate tool for the operation.
4. When the user references a Jira ticket ID (e.g., DSC-1986), fetch it directly - never try to open the URL in a browser.
5. If the ticket has attachments with images, download and view them using the method above.
