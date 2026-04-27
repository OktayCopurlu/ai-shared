---
name: chrome-devtools-mcp
description: 'Debug runtime issues via Chrome DevTools MCP server. USE FOR: inspecting network requests, console errors, DOM state, performance profiling, JavaScript debugging. ALWAYS use when user asks to debug a runtime issue, check network calls, or inspect the browser state.'
---

# Chrome DevTools MCP

Use Chrome DevTools MCP when you need to inspect a live Chrome page directly.

## Routing

- Prefer `playwright-cli` for concise action-heavy browser workflows when auth/session reuse is already handled.
- Prefer `playwright-mcp` when you need longer stateful automation or extension-backed attachment plus page interaction.
- Use Chrome DevTools MCP when inspection is the primary goal.

## Login-Required Pages

If the target page is private or redirected to sign-in, rely on the extension-managed browser state instead of inventing a separate profile-reuse workflow.
Use DevTools MCP to verify which tab is live and whether the page is actually authenticated.
If inspection still shows a login wall, report the blocker precisely or let the user complete login in the extension-managed browser context before continuing.

## Environment Access

If debugging a project-specific preview or staging environment, load the relevant project reference first so you use the correct host, auth pattern, and access method.
For preview or staging environments, follow the project's documented access pattern instead of guessing credentials or hostnames.

## Default Route

1. Start with `list_console_messages` for runtime errors.
2. If the issue may involve API calls, use `list_network_requests`, then `get_network_request` for a specific request.
3. If the issue may involve rendered UI or missing elements, use `take_snapshot`.
4. If you need actual browser state, use `evaluate_script`.
5. If there are multiple tabs, use `list_pages` and `select_page` before further inspection.

## Non-Obvious Rules

- `take_snapshot` returns element `uid`s. Use those `uid`s for actions such as `click`, `fill`, `hover`, `drag`, and `upload_file`.
- After navigation or major DOM changes, take a fresh snapshot before reusing `uid`s.
- Tools operate on the currently selected page. Do not assume the correct tab is selected.
- For large outputs, prefer `filePath` when supported.
- Extension tools are optional; do not rely on them unless they are available in the current session.

## Guardrails

- Do not guess browser state when `evaluate_script`, console output, network data, or snapshots can show the real value.
- Do not describe DevTools UI workflows when MCP can inspect the page directly.

## See Also

- `playwright-cli` — concise browser automation for coding agents
- `playwright-mcp` — interact with the page once the correct authenticated tab is available
- project-specific environment references such as `references/on-frontend-urls.md`
