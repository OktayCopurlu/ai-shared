---
name: amplitude-analytics
description: 'Query analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking, analytics, or Amplitude events.'
---

# Amplitude Analytics

Always prefer the Amplitude MCP server tools over manual API calls or asking the user to paste data.

## Routing

- **Amplitude MCP** for querying charts, experiments, session replays, and content
- **Codebase search** for verifying tracking implementation matches Amplitude schema
- **REST API via curl** only as fallback when MCP is unavailable

## Available Tools

### Discovery and Context

| Tool | Use when |
|------|----------|
| `search` | Finding charts, dashboards, notebooks, experiments, events, properties, or cohorts by keyword |
| `get_from_url` | User pastes an Amplitude URL — extracts the full object definition |
| `get_context` | Need current user, org, or accessible projects |
| `get_project_context` | Need project timezone, currency, session definition, or AI context |

### Content Retrieval

| Tool | Use when |
|------|----------|
| `get_charts` | Fetching full chart definitions by ID (events, properties, config) |
| `get_dashboard` | Fetching dashboards and all their chart IDs |
| `get_cohorts` | Fetching cohort definitions and audience criteria |
| `get_experiments` | Fetching experiment state, variants, and decision details |
| `get_event_properties` | Exploring properties for a specific event |
| `get_users` | Looking up user data from a project |
| `get_flags` | Fetching feature flag definitions and variants |
| `get_deployments` | Listing API keys for flags and experiments |
| `get_agent_results` | Retrieving AI agent analysis results |

### Session Replay

| Tool | Use when |
|------|----------|
| `get_session_replays` | Searching replays filtered by user properties or events (last 30 days) |
| `list_session_replays` | Listing replays with time-range pagination |
| `get_session_replay_events` | Getting processed interaction timelines from a recording |

### Query and Analysis

| Tool | Use when |
|------|----------|
| `query_chart` | Querying a single chart by ID for its data |
| `query_charts` | Querying up to 3 charts concurrently |
| `query_amplitude_data` | Running ad-hoc segmentation, funnels, or retention (discover/execute workflow) |
| `query_experiment` | Getting experiment variant performance and statistical significance |
| `render_chart` | Rendering a visual chart from a query definition |

### Creation

Write tools (use only when explicitly asked to create Amplitude content): `save_chart_edits`, `create_dashboard`, `create_notebook`, `create_experiment`, `create_cohort`, `create_flags`, `create_metric`.

### Feedback

| Tool | Use when |
|------|----------|
| `get_feedback_insights` | Retrieving grouped feedback themes (requests, bugs, complaints, praise) |
| `get_feedback_comments` | Searching raw feedback comments |
| `get_feedback_mentions` | Getting comments tied to a specific insight |
| `get_feedback_sources` | Listing connected feedback integrations |
| `get_feedback_trends` | Getting tracked feedback trends over time |

### AI Agent Analytics

| Tool | Use when |
|------|----------|
| `query_agent_analytics_metrics` | Aggregating quality, cost, performance, and error metrics |
| `query_agent_analytics_sessions` | Filtering AI agent sessions by quality, cost, or topic |
| `query_agent_analytics_spans` | Inspecting individual LLM calls or tool invocations |
| `get_agent_analytics_conversation` | Retrieving full conversation transcripts |
| `search_agent_analytics_conversations` | Full-text search across agent conversations |
| `get_agent_analytics_schema` | Discovering available fields, rubrics, and filter values |

## Gotchas

- **Two regions**: US default (`mcp.amplitude.com/mcp`), EU (`mcp.eu.amplitude.com/mcp`). Use the region matching the user's data residency.
- **Dashboard filters**: Querying charts from dashboards may use default chart settings instead of saved dashboard filters.
- **Session replay window**: `get_session_replays` only covers the last 30 days.
- **`query_amplitude_data`**: Two-mode discover/execute workflow — discover available events first, then execute the query.

## Procedure

1. Use `search` or `get_from_url` to find relevant Amplitude content.
2. Use `get_charts` / `get_dashboard` / `get_experiments` to retrieve full definitions.
3. Use `query_chart` / `query_amplitude_data` / `query_experiment` to get actual data.
4. When verifying tracking implementation, cross-reference event schemas from Amplitude with TypeScript types in the codebase.
5. For debugging, use `get_session_replays` + `get_session_replay_events` to trace user interactions.
