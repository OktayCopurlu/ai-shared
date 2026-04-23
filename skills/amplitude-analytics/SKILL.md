---
name: amplitude-analytics
description: 'Query analytics data from Amplitude via the Amplitude MCP server. USE FOR: debugging tracking events, verifying analytics implementation, checking event payloads, reviewing user funnels. ALWAYS use when user asks about tracking, analytics, or Amplitude events.'
---

# Amplitude Analytics

Always prefer the Amplitude MCP server tools over manual API calls or asking the user to paste data.

## Routing

- **Amplitude MCP** for querying charts, experiments, session replays, and content
- **Codebase search** for verifying tracking implementation matches Amplitude schema
- **REST API via curl** only as fallback when MCP is unavailable (see vm0-ai pattern below)

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

| Tool | Use when |
|------|----------|
| `save_chart_edits` | Saving chart edits or converting temp charts to permanent |
| `create_dashboard` | Building dashboards with charts and layouts |
| `create_notebook` | Creating notebooks with charts and rich text |
| `create_experiment` | Setting up A/B tests with variants and metrics |
| `create_cohort` | Creating cohorts from user properties and behaviors |
| `create_flags` | Creating feature flags in batch |
| `create_metric` | Creating reusable KPI metrics |

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

- **OAuth-based**: The MCP server uses OAuth 2.0 with your Amplitude permissions. You only see data you already have access to.
- **Two regions**: US default (`mcp.amplitude.com/mcp`), EU (`mcp.eu.amplitude.com/mcp`). Use the region matching the user's data residency.
- **Dashboard filters**: Querying charts from dashboards may use default chart settings instead of saved dashboard filters.
- **Session replay window**: `get_session_replays` only covers the last 30 days.
- **`query_amplitude_data`**: Uses a two-mode discover/execute workflow — discover available events first, then execute the query.
- **Large results**: AI platforms may truncate large chart data. Break complex requests into smaller queries.

## Procedure

1. Use `search` or `get_from_url` to find relevant Amplitude content.
2. Use `get_charts` / `get_dashboard` / `get_experiments` to retrieve full definitions.
3. Use `query_chart` / `query_amplitude_data` / `query_experiment` to get actual data.
4. When verifying tracking implementation, cross-reference event schemas from Amplitude with TypeScript types in the codebase.
5. For debugging, use `get_session_replays` + `get_session_replay_events` to trace user interactions.
