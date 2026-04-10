---
name: contentful
description: 'Read content from Contentful CMS via MCP server or CLI. USE FOR: reading content types, entries, assets, spaces, and environments. ALWAYS use when user asks about Contentful content, product data, or CMS entries. READ-ONLY — never create, update, or delete Contentful data.'
---

# Contentful — Read Content from CMS

Read-only access to Contentful CMS. Prefer MCP when available, fall back to CLI + curl.

## CRITICAL: Read-Only Access

**NEVER create, update, or delete any Contentful data.** Write operations must be done manually through the Contentful web UI.

## Tool Selection

1. Try loading MCP tools via `tool_search_tool_regex` with pattern `contentful`
2. If MCP tools are found → use MCP (do NOT call any write/publish/delete tools)
3. If no MCP tools → use CLI + curl as described below

## CLI + curl

### What the CLI can do

```bash
contentful content-type list   # list content types (aliased as `ct list`)
contentful space list           # list spaces
contentful environment list     # list environments
```

### What the CLI cannot do

CLI v3 has **no** `entry list`, `entry get`, `asset list`, or `asset get`. Use the CMA API via curl instead.

### Reading entries and assets via curl

```bash
# Base URL pattern
curl -s "https://api.contentful.com/spaces/{spaceId}/environments/{env}/entries?content_type={type}&limit=5" \
  -H "Authorization: Bearer $CONTENTFUL_CMA_TOKEN" | jq '.items[].fields'
```

- Token: `$CONTENTFUL_CMA_TOKEN` (set in `.zshrc`)
- Space and environment: read from `~/.contentfulrc.json` (`activeSpaceId`, `activeEnvironmentId`)
- Filter by field: add `&fields.key=someValue` to the query string
- Discover content types first with `contentful ct list`, then query entries

## Rules

- Never create, update, publish, or delete Contentful data
- Prefer MCP when available — structured data, no shell overhead
- Read `~/.contentfulrc.json` for space/environment defaults before asking the user
- Pipe curl output through `jq` for readability
