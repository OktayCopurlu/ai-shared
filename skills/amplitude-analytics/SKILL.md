---
name: amplitude-analytics
description: 'Query analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking, analytics, or Amplitude events.'
---

# Amplitude Analytics MCP Server Usage

When working with analytics and tracking, **always prefer using the Amplitude MCP server tools** to query and verify data.

## Use Cases

- **Verify tracking implementation**: Check if events are firing correctly after implementing tracking code
- **Debug tracking issues**: Investigate missing or incorrect event payloads
- **Review event schemas**: Look up event properties and expected values
- **Analyze user funnels**: Query funnel data to understand user behavior
- **Check event volumes**: Verify event counts after deployments

## Procedure

1. Load Amplitude MCP tools via `tool_search_tool_regex` with pattern `amplitude`
2. Use the appropriate tool to query events, charts, or user data
3. Cross-reference with tracking code in the codebase (look in `@on-store/utils/tracker/`)
4. When verifying tracking implementation, compare the event schema in Amplitude with the TypeScript types in the codebase
