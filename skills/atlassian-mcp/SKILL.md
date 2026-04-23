---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP

Always prefer Atlassian MCP tools over fetching web pages or asking the user to paste content.

## Jira Operations

- **Reading issues**: Use `getJiraIssue` to fetch ticket details (summary, description, acceptance criteria, comments, status, etc.)
- **Searching issues**: Use `searchJiraIssuesUsingJql` to find relevant tickets
- **Creating issues**: Use `createJiraIssue` for new tickets
- **Updating issues**: Use `editJiraIssue` to modify existing tickets
- **Comments**: Use `addCommentToJiraIssue` to add comments
- **Work logs**: Use `addWorklogToJiraIssue` to log time
- **Issue links**: Use `createIssueLink` and `getIssueLinkTypes` for linking issues

## Confluence Operations

- **Reading pages**: Use `getConfluencePage` to fetch wiki content
- **Listing pages**: Use `getPagesInConfluenceSpace` to browse a space
- **Creating pages**: Use `createConfluencePage` for new pages
- **Updating pages**: Use `updateConfluencePage` to modify existing pages
- **Footer comments**: Use `getConfluencePageFooterComments`, `createConfluenceFooterComment`
- **Inline comments**: Use `getConfluencePageInlineComments`, `createConfluenceInlineComment`

## Viewing Jira Attachments (Images)

The Atlassian MCP tools cannot download attachment files directly. To view images:

1. Fetch the ticket with `getJiraIssue` — the `attachment` field has the download URL in `content`
2. Download via `curl` with basic auth using `$JIRA_USER_EMAIL` and `$JIRA_API_TOKEN` from `~/.zshrc`
3. Use `view_image` to inspect the downloaded file

## Procedure

1. Load Atlassian MCP tools via `tool_search_tool_regex` with pattern `mcp_atlassian`
2. If needed, use `getAccessibleAtlassianResources` to get the cloud ID
3. Call the appropriate tool for the operation
4. When the user references a Jira ticket ID (e.g., DSC-1986), fetch it directly — never try to open the URL in a browser
5. If the ticket has attachments with images, download and view them using the method above
