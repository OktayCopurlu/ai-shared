---
name: chrome-devtools-mcp
description: 'Debug runtime issues via Chrome DevTools MCP server. USE FOR: inspecting network requests, console errors, DOM state, performance profiling, JavaScript debugging. ALWAYS use when user asks to debug a runtime issue, check network calls, or inspect the browser state.'
---

# Chrome DevTools MCP

Use Chrome DevTools MCP when you need to inspect a live Chrome page directly.

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
- Do not turn this skill into a general debugging checklist. It exists to route the agent to the right MCP tools.
