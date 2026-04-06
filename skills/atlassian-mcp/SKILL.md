---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP Server Usage

When interacting with Jira tickets or Confluence wiki pages, **always prefer using the Atlassian MCP server tools** over other methods (e.g., fetching web pages, asking the user to paste content).

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

## Procedure

1. Load Atlassian MCP tools via `tool_search_tool_regex` with pattern `mcp_atlassian`
2. If needed, use `getAccessibleAtlassianResources` to get the cloud ID
3. Call the appropriate tool for the operation
4. When the user references a Jira ticket ID (e.g., DSC-1986), fetch it directly — never try to open the URL in a browser
