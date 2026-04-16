---
name: contentful
description: 'Read content from Contentful CMS via MCP server or CLI. USE FOR: reading content types, entries, assets, spaces, and environments. ALWAYS use when user asks about Contentful content, product data, or CMS entries. READ-ONLY — never create, update, or delete Contentful data.'
---

# Contentful — Read Content from CMS

**NEVER create, update, or delete any Contentful data.** Read-only access only.

## Tool Selection

1. Try loading MCP tools via `tool_search_tool_regex` with pattern `contentful`
2. If MCP tools found → use MCP (do NOT call any write/publish/delete tools even though the server exposes them)
3. If no MCP tools → use CLI + curl below

## Gotchas — Official Contentful MCP Server (`@contentful/mcp-server`)

The official Contentful MCP server (v1.7+) exposes **both read and write tools** including `create_entry`, `update_entry`, `publish_entry`, `delete_entry`, `create_content_type`, `upload_asset`, etc. **Our policy is read-only. Never call write tools.**

Safe tools to use:
- `get_initial_context` — initialize connection and get usage instructions (call this first)
- `list_content_types`, `get_content_type` — content model discovery
- `search_entries`, `get_entry` — read entries with filtering
- `list_assets`, `get_asset` — browse assets
- `list_spaces`, `get_space`, `list_environments` — space/env context
- `list_locales`, `get_locale` — locale information
- `list_tags` — tag discovery

**Workflow**: Always call `get_initial_context` first — it initializes the connection and returns usage guidance from the server.

## CLI + curl Fallback

When no MCP tools are available:

```bash
# Content types (CLI v3)
contentful content-type list   # aliased as `ct list`
contentful space list
contentful environment list

# Entries and assets (CLI v3 has no entry/asset commands — use CMA API)
curl -s "https://api.contentful.com/spaces/{spaceId}/environments/{env}/entries?content_type={type}&limit=5" \
  -H "Authorization: Bearer $CONTENTFUL_CMA_TOKEN" | jq '.items[].fields'
```

- Token: `$CONTENTFUL_CMA_TOKEN` (set in `.zshrc`)
- Space and environment: read from `~/.contentfulrc.json` (`activeSpaceId`, `activeEnvironmentId`)
- Filter by field: add `&fields.key=someValue` to the query string

## Rules

- **Never** create, update, publish, or delete Contentful data — even if the MCP server offers those tools
- Prefer MCP when available — structured data, no shell overhead
- Call `get_initial_context` before other MCP tools to establish the connection
- Read `~/.contentfulrc.json` for space/environment defaults before asking the user
- Pipe curl output through `jq` for readability
