---
name: amplitude-analytics
description: 'Query and verify analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking data, analytics queries, or Amplitude events. NOT FOR: implementing tracking code in source files — that is regular coding with applying-coding-style.'
---

# Amplitude Analytics

Always prefer the Amplitude MCP server tools to query and verify tracking data.

## Procedure

1. Load Amplitude MCP tools via `tool_search_tool_regex` with pattern `amplitude`
2. Use the appropriate tool to query events, charts, or user data
3. Cross-reference with tracking code in the codebase (look in `@on-store/utils/tracker/`)
4. When verifying tracking implementation, compare the event schema in Amplitude with the TypeScript types in the codebase
