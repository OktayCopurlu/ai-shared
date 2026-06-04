---
name: contentful
description: 'Read content from Contentful CMS via the `contentful` CLI and CMA API. USE FOR: reading content types, entries, assets, spaces, and environments. ALWAYS use when user asks about Contentful content, product data, or CMS entries. READ-ONLY — never create, update, or delete Contentful data. NOT FOR: modifying CMS content or managing Contentful configuration.'
---

# Contentful — Read Content from CMS

**NEVER create, update, or delete any Contentful data.** Read-only access only.

## Routing

- **`contentful` CLI** for spaces, environments, and content types.
- **CMA REST API via `curl`** for entries and assets (the CLI has no read commands for these).
- **Contentful MCP server** only for read-only discovery when exposed in the current session. Current official MCP releases include broad create/update/publish/archive/delete tools; do not treat MCP confirmation prompts as permission to mutate.

## Auth & config

- Token: `$CONTENTFUL_CMA_TOKEN` (set in `.zshrc`), also stored as `managementToken` in `~/.contentfulrc.json`.
- Defaults: read `activeSpaceId` and `activeEnvironmentId` from `~/.contentfulrc.json` before asking the user.
- Verify with `contentful space list` (lists accessible spaces; the active one is marked `[active]`).

## Commands

```bash
# Spaces, environments, content types (CLI v3)
contentful space list
contentful environment list
contentful content-type list            # aliased as `ct list`
contentful content-type get --id <typeId>

# Entries and assets (no CLI read command — use the CMA API)
SPACE=$(jq -r .activeSpaceId ~/.contentfulrc.json)
ENV=$(jq -r .activeEnvironmentId ~/.contentfulrc.json)

curl -s "https://api.contentful.com/spaces/$SPACE/environments/$ENV/entries?content_type=<type>&limit=5" \
  -H "Authorization: Bearer $CONTENTFUL_CMA_TOKEN" | jq '.items[].fields'

curl -s "https://api.contentful.com/spaces/$SPACE/environments/$ENV/assets?limit=5" \
  -H "Authorization: Bearer $CONTENTFUL_CMA_TOKEN" | jq '.items[].fields'
```

- Filter entries by field: add `&fields.key=someValue` to the query string.
- Fetch a single entry: `.../entries/{entryId}`.

## Rules

- **Never** create, update, publish, archive, or delete Contentful data — even though `$CONTENTFUL_CMA_TOKEN` is a management token with write scope. Only ever issue `GET` requests and read-only CLI subcommands.
- Do not run `contentful` subcommands that mutate (e.g. `content-type create/update/delete`, `space create`, `merge`, `import`).
- If a Contentful MCP delete tool returns a two-phase confirmation preview/token, stop there. Do not make the confirming second call unless the user explicitly changes this skill's read-only constraint for the current task.
- Treat MCP `PROTECTED_ENVIRONMENTS` as defense in depth, not as the boundary. Unprotected environments can still accept writes, so this skill's read-only rule remains the controlling policy.
- Read `~/.contentfulrc.json` for space/environment defaults before asking the user.
- Pipe `curl` output through `jq` for readability.
