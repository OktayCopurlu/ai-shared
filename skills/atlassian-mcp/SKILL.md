---
name: atlassian-mcp
description: 'Interact with Jira tickets and Confluence wiki pages via the Atlassian MCP server. USE FOR: reading/creating/updating Jira issues, searching Jira with JQL, reading/creating/updating Confluence pages, adding comments. ALWAYS use when user references a Jira ticket (e.g. DSC-1986, B2C-12345) or Confluence page.'
---

# Atlassian MCP

Always prefer Atlassian MCP tools over fetching web pages or asking the user to paste content.

## Cross-System Search (Rovo)

- **Rovo Search**: Use `search` to search across Jira, Confluence, and Compass simultaneously — best default for finding content when you don't know which system has it
- **Fetch by ARI**: Use `fetch` to get full details of a Jira issue or Confluence page by its Atlassian Resource Identifier (ARI) returned from search results

## Jira Operations

- **Reading issues**: Use `getJiraIssue` to fetch ticket details (summary, description, acceptance criteria, comments, status, etc.)
- **Searching issues**: Use `searchJiraIssuesUsingJql` to find relevant tickets with JQL
- **Creating issues**: Use `createJiraIssue` for new tickets
- **Updating issues**: Use `editJiraIssue` to modify existing tickets
- **Transitions**: Use `getTransitionsForJiraIssue` to list available status transitions, then `transitionJiraIssue` to move an issue through its workflow
- **Comments**: Use `addCommentToJiraIssue` to add comments
- **Work logs**: Use `addWorklogToJiraIssue` to log time
- **Issue links**: Use `getIssueLinkTypes` to discover link types, then `createIssueLink` to link issues
- **Remote links**: Use `getJiraIssueRemoteIssueLinks` to get external links on an issue
- **Projects**: Use `getVisibleJiraProjects` to list accessible projects
- **Issue types**: Use `getJiraProjectIssueTypesMetadata` to list issue types for a project, `getJiraIssueTypeMetaWithFields` to get field metadata for a specific issue type
- **User lookup**: Use `lookupJiraAccountId` to find account IDs by name (needed for assignee fields)

## Confluence Operations

- **Reading pages**: Use `getConfluencePage` to fetch wiki content (pages or blog posts)
- **Searching**: Use `searchConfluenceUsingCql` to find content with CQL queries
- **Listing pages**: Use `getPagesInConfluenceSpace` to browse a space
- **Spaces**: Use `getConfluenceSpaces` to list available spaces
- **Child pages**: Use `getConfluencePageDescendants` to get child pages of a page
- **Creating pages**: Use `createConfluencePage` for new pages or blog posts
- **Updating pages**: Use `updateConfluencePage` to modify existing pages
- **Footer comments**: Use `getConfluencePageFooterComments` to read, `createConfluenceFooterComment` to add
- **Inline comments**: Use `getConfluencePageInlineComments` to read, `createConfluenceInlineComment` to add (supports text selection highlighting)
- **Comment replies**: Use `getConfluenceCommentChildren` to read replies to a comment

## Identity

- **User info**: Use `atlassianUserInfo` to get the current authenticated user
- **Cloud ID**: Use `getAccessibleAtlassianResources` to discover cloud IDs when needed

## Content Format

Most read/write tools accept a `contentFormat` parameter:
- `"adf"` (default) — Atlassian Document Format JSON, full fidelity with mentions, panels, Smart Links
- `"markdown"` — simplified text, easier to read and generate

Prefer `"markdown"` for reading content you need to understand. Use `"adf"` when you need to preserve rich formatting or when writing content with mentions/panels.

## Gotchas

- **Cloud ID shortcut**: When a user provides a link like `https://site.atlassian.net/...`, pass `site.atlassian.net` as the `cloudId` directly — only call `getAccessibleAtlassianResources` if that fails
- **Search first**: Use `search` (Rovo Search) as the default discovery tool — it searches across Jira, Confluence, and Compass in one call. Use JQL/CQL only when you need precise filtering
- **maxResults/limit**: Always set `maxResults: 10` or `limit: 10` for JQL and CQL searches to avoid excessive token usage — increase only if the user needs more
- **Ticket ID patterns**: When the user references a Jira ticket ID (e.g., DSC-1986), fetch it directly with `getJiraIssue` — never try to open the URL in a browser
- **Transitions require ID**: Always call `getTransitionsForJiraIssue` first to get valid transition IDs before calling `transitionJiraIssue`
- **User assignment**: Use `lookupJiraAccountId` to resolve display names to account IDs before setting assignees
- **Confluence page IDs**: Tiny link IDs from `/wiki/x/` URLs (e.g., `Fc1bBw`) can be passed directly as `pageId`

## Procedure

1. If needed, use `getAccessibleAtlassianResources` to get the cloud ID (or extract from user-provided URLs)
2. For discovery, start with `search` (Rovo Search) to find content across systems
3. For specific operations, call the appropriate tool listed above
4. When creating or updating content, prefer `"markdown"` content format for simplicity
