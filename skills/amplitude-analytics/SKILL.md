---
name: amplitude-analytics
description: 'Query analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking, analytics, or Amplitude events.'
---

# Amplitude Analytics

Always prefer the Amplitude MCP server tools to query and verify tracking data.

## Amplitude MCP Server

Amplitude provides an official MCP server at `https://mcp.amplitude.com/mcp` with 40+ tools covering:

- **Charts & Dashboards** — query existing charts, create ad-hoc analyses, list dashboards
- **Event Explorer** — search events by name, inspect event properties and schemas
- **Cohorts** — list, create, and query user cohorts
- **Experiments** — view A/B test results, check experiment status, analyze variants
- **Feature Flags** — list flags, check flag status and targeting rules
- **Session Replays** — search and retrieve session replay data
- **User Profiles** — look up user properties and event history
- **Ad-hoc Queries** — run custom queries against event data

Setup: Configure the MCP server in your editor/agent config with the Amplitude API credentials.

Docs: [amplitude.com/docs/amplitude-ai/amplitude-mcp](https://amplitude.com/docs/amplitude-ai/amplitude-mcp)

## Procedure

1. Load Amplitude MCP tools via `tool_search_tool_regex` with pattern `amplitude`
2. Use the appropriate tool to query events, charts, or user data
3. Cross-reference with tracking code in the codebase (look in `@on-store/utils/tracker/`)
4. When verifying tracking implementation, compare the event schema in Amplitude with the TypeScript types in the codebase

## Common Tasks

### Debugging a tracking event
1. Search for the event name in Amplitude using event explorer tools
2. Check the event properties and their types
3. Find the corresponding tracking call in the codebase (`@on-store/utils/tracker/`)
4. Compare the payload shape with the Amplitude schema

### Verifying a funnel
1. Query the chart or dashboard that tracks the funnel
2. Check conversion rates between steps
3. If rates look wrong, inspect individual events at each funnel step

### Checking experiment results
1. Use experiment tools to fetch the experiment by name or ID
2. Review variant allocation and statistical significance
3. Cross-reference with feature flag targeting rules if applicable
