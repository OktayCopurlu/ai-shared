---
name: mcp-server-development
description: "Design and build new Model Context Protocol servers. USE FOR: requests to create an MCP server, wrap an API/local tool as MCP, expose tools/resources/prompts to an AI client, package MCPB/local stdio servers, or choose MCP deployment and tool-design patterns. NOT FOR: using an existing MCP integration such as GitHub, Atlassian, Figma, Contentful, Amplitude, or Playwright."
---

# MCP Server Development

Build new MCP servers by choosing the right deployment shape before scaffolding code. A wrong early choice creates security, auth, and distribution rewrites later.

## When To Use

- The user asks to create, build, scaffold, package, or publish an MCP server.
- The user wants to wrap a REST, GraphQL, CLI, local process, filesystem, desktop app, database, or internal service for AI tools.
- The task is about designing MCP tools, resources, prompts, elicitation, MCP apps/widgets, or MCPB packaging.
- Do not use this when operating an already-configured connector; use the specific adapter skill instead.

## Discovery Before Code

Ask for missing answers in one short batch, then proceed if the initial request already covers them:

Before scaffolding, establish what it connects to, who will use it, how many actions it needs, whether UI/input is required, and what auth exists.

1. What does it connect to: cloud API, local process, filesystem, desktop app, hardware, database, or pure computation?
2. Who will use it: just the author, a team, external users, or a marketplace/directory audience?
3. How many actions are needed: a small focused surface, or dozens/hundreds of API operations?
4. Does it need mid-call user input, rich UI, or only text/JSON results?
5. What auth exists upstream: none, API key, OAuth, SSO, or user-local credentials?

## Deployment Decision

Choose one path and state why:

| Use case | Default choice | Why |
| --- | --- | --- |
| Cloud/SaaS API, shared users, OAuth, or easy updates | Remote Streamable HTTP | One hosted deployment, proper redirect/token handling, no local install burden |
| Must read local files, drive desktop apps, access localhost, hardware, or OS APIs | MCPB or local stdio prototype | Runs with user-local access; package as MCPB before distribution |
| Personal prototype only | Local stdio | Fastest feedback loop, but not a distribution strategy |
| Rich picker, chart, preview, dashboard, or custom confirmation UI | MCP app/widget on top of the server | UI is additive; the base server still exposes tools/resources |

For remote HTTP, default to the official TypeScript SDK or Python FastMCP unless the project stack clearly points elsewhere. For local/distributed servers, explain the MCPB upgrade path and the lack of a manifest-level sandbox.

## Primitive Design

Use MCP primitives deliberately:

- **Tools** for model-invoked actions or computations. Keep names action-oriented, schemas tight, and descriptions explicit about side effects.
- **Resources** for read-only context that the host or user can browse, fetch, or subscribe to.
- **Prompts** for user-invoked reusable workflows or templates.
- **Elicitation** for short host-rendered forms, confirmations, or selections; check client capability and provide fallback.
- **MCP apps/widgets** only when elicitation is insufficient: large searchable lists, visual previews, charts, maps, diffs, or live dashboards.

For a small surface, expose one tool per action. For a large API, prefer `search_actions` plus `execute_action`, optionally promoting the 3-5 highest-value actions to dedicated tools.

## Guardrails

- For stdio servers, never log to stdout; stdout is reserved for JSON-RPC messages. Log to stderr or files.
- For Streamable HTTP, validate `Origin`, bind local servers to localhost by default, use auth for non-local access, and support the negotiated MCP protocol/version headers.
- Validate every tool input and sanitize outputs before they are passed back to the model.
- Split read and write tools where possible, mark read-only tools with annotations when the SDK supports them, and require explicit confirmation for destructive or billable operations.
- Do not pass upstream tokens through blindly. Validate token audience and scopes for the MCP server boundary.
- For local servers, validate paths against an approved root, prevent traversal, avoid broad filesystem/network access, and treat spawned commands as high-risk.
- Keep secrets in environment variables, keychains, or server-side stores; never commit API keys or local tokens into MCP config examples.

## Verification

Before calling the server done:

- Run the project tests or typecheck/build commands for the chosen stack.
- Use MCP Inspector to connect to the server, inspect capability negotiation, list tools/resources/prompts, call at least one happy path, and call at least one invalid-input path.
- For stdio, verify no startup banner or normal log text is written to stdout.
- For HTTP, verify auth/headers, CORS or exposed `Mcp-Session-Id` where browser clients need it, and rejection of unsafe origins in production mode.
- For widgets, verify the tool returns meaningful text/JSON when the host ignores widget metadata.

## See Also

- `security-hardening` - activate alongside this when auth, external APIs, user input, local files, or sensitive data are involved
- `github-mcp`, `atlassian-mcp`, `figma-mcp`, `contentful`, `amplitude-analytics`, `playwright-mcp` - use these for operating existing connectors instead of building a new server
