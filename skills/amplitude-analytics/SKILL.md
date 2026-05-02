---
name: amplitude-analytics
description: 'Query and verify analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking data, analytics queries, or Amplitude events. NOT FOR: implementing tracking code in source files — that is regular coding with applying-coding-style.'
---

# Amplitude Analytics

Always prefer the Amplitude MCP server tools to query and verify tracking data.

## Procedure

1. Use the Amplitude MCP tools exposed in the current session. If the host groups tools behind activation, activate the Amplitude category that matches the task before calling the exact query or retrieval tool.
2. Start from project/workspace context when the project ID is not already known.
3. Use the narrowest suitable tool to query events, charts, users, cohorts, experiments, session replays, or datasets.
4. Cross-reference with tracking code in the codebase (look in `@on-store/utils/tracker/` when working in on-store repos).
5. When verifying tracking implementation, compare the event schema in Amplitude with the TypeScript types in the codebase.
