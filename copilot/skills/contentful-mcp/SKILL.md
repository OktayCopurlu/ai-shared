---
name: contentful-mcp
description: 'Read content from Contentful CMS via the Contentful MCP server. USE FOR: reading content types, entries, assets, spaces, and environments. ALWAYS use when user asks about Contentful content, product data, or CMS entries. READ-ONLY — never create, update, or delete Contentful data.'
---

# Contentful MCP Server Usage (Read-Only)

When reading data from Contentful CMS, **always prefer using the Contentful MCP server tools** over other methods.

## CRITICAL: Read-Only Access

**NEVER create, update, or delete any Contentful data via MCP tools.** This skill is strictly for reading/querying content. Any write operations must be done manually through the Contentful web UI.

## Read Operations

- **Content types**: Query content type definitions and their fields
- **Entries**: Read content entries, product data, page configurations
- **Assets**: Look up media assets, images, and file metadata
- **Spaces**: Browse space structure and environments
- **Locales**: Check available locales and localized content

## Procedure

1. Load Contentful MCP tools via `tool_search_tool_regex` with pattern `contentful`
2. Use the appropriate read tool to query content
3. **Do NOT call any tool that creates, updates, publishes, or deletes content**
4. If the user asks to modify Contentful content, inform them it must be done manually in the Contentful web UI
