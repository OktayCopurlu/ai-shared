---
name: chrome-devtools-mcp
description: 'Debug runtime issues via Chrome DevTools MCP server. USE FOR: inspecting network requests, console errors, DOM state, performance profiling, JavaScript debugging. ALWAYS use when user asks to debug a runtime issue, check network calls, or inspect the browser state.'
---

# Chrome DevTools MCP Server Usage

When debugging runtime issues in the browser, **always prefer using the Chrome DevTools MCP server tools** to inspect application state directly.

## Use Cases

- **Console errors**: Read console logs and errors to diagnose runtime issues
- **Network requests**: Inspect API calls, GraphQL queries, response payloads, and status codes
- **DOM inspection**: Check rendered HTML, computed styles, and element state
- **JavaScript debugging**: Evaluate expressions in the browser context
- **Performance**: Profile page load, rendering, and script execution
- **Storage**: Inspect localStorage, sessionStorage, cookies

## Procedure

1. Ensure the local dev server is running (`yarn on-shop dev:safe`)
2. Open the page in Chrome that you want to debug
3. Load Chrome DevTools MCP tools via `tool_search_tool_regex` with pattern `chrome-devtools`
4. Use the appropriate tool to inspect the issue:
   - Check console for errors
   - Monitor network requests for failed API calls
   - Inspect DOM elements for rendering issues
   - Evaluate JavaScript expressions to check reactive state
5. Cross-reference findings with the source code to identify the root cause
