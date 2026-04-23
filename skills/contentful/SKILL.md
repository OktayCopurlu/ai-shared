---
name: contentful
description: 'Read content from Contentful CMS via MCP server or CLI. USE FOR: reading content types, entries, assets, spaces, and environments. ALWAYS use when user asks about Contentful content, product data, or CMS entries. READ-ONLY — never create, update, or delete Contentful data. NOT FOR: modifying CMS content or managing Contentful configuration.'
---

# Contentful — Read Content from CMS

**NEVER create, update, or delete any Contentful data.** Read-only access only.

## Tool Selection

Check if Contentful MCP tools are available in your current session (e.g. `get_initial_context`, `list_content_types`). If available, use MCP. If not, use the CLI + curl fallback below.

## Gotchas — Official Contentful MCP Server (`@contentful/mcp-server`)

The official Contentful MCP server (v1.7+) exposes **both read and write tools**. **Our policy is read-only. Never call write tools.**

### Safe tools (read-only)

| Category | Tools |
|---|---|
| Context | `get_initial_context` |
| Content Types | `list_content_types`, `get_content_type` |
| Entries | `search_entries`, `get_entry` |
| Assets | `list_assets`, `get_asset` |
| Spaces & Environments | `list_spaces`, `get_space`, `list_environments` |
| Locales | `list_locales`, `get_locale` |
| Tags | `list_tags` |
| AI Actions | `get_ai_action`, `list_ai_actions`, `get_ai_action_invocation` |

### Forbidden tools — do NOT call

| Category | Tools | Why |
|---|---|---|
| Content Types | `create_content_type`, `update_content_type`, `publish_content_type`, `unpublish_content_type`, `delete_content_type` | Mutates content model |
| Entries | `create_entry`, `update_entry`, `publish_entry`, `unpublish_entry`, `delete_entry` | Mutates content |
| Assets | `upload_asset`, `update_asset`, `publish_asset`, `unpublish_asset`, `delete_asset` | Mutates assets |
| Environments | `create_environment`, `delete_environment` | Destructive infrastructure change |
| Locales | `create_locale`, `update_locale`, `delete_locale` | Mutates locale config |
| Tags | `create_tag` | Mutates taxonomy |
| AI Actions | `create_ai_action`, `update_ai_action`, `publish_ai_action`, `unpublish_ai_action`, `delete_ai_action`, `invoke_ai_action` | Mutates or triggers AI workflows |

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
