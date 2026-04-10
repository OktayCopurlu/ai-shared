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

## Tool Selection

| What to check | Tool / Approach | Tips |
|---|---|---|
| Console errors & warnings | `getConsoleMessages` | Filter by `error` level first; warnings often reveal hydration or deprecation issues |
| Network requests | `getNetworkRequests` | Filter by status (4xx/5xx), check request/response payloads, look for CORS errors |
| DOM structure | `inspectElement`, `querySelectorAll` | Use CSS selectors to target specific elements; check computed styles |
| Reactive state | `evaluateExpression` | Access Vue devtools: `__vue_app__`, component data, Pinia stores |
| Performance | `startProfiling` / `stopProfiling` | Profile specific interactions, not full page loads; look for long tasks > 50ms |
| Storage | `evaluateExpression` | `localStorage.getItem('key')`, `document.cookie`, `sessionStorage` |
| Layout issues | `getComputedStyle`, `getBoundingClientRect` | Compare expected vs actual dimensions; check for overflow |

## Debugging Patterns

### Console triage

1. Filter errors first — ignore warnings until errors are resolved
2. Read the full stack trace before jumping to code
3. Check if the error is from your code or a dependency
4. Hydration mismatches: compare server-rendered HTML with client-side DOM

### Network debugging

1. Check status code first (4xx = client error, 5xx = server error)
2. Inspect request headers — missing auth tokens, wrong Content-Type
3. Compare request payload against API contract/types
4. Check response body for error messages
5. Look for CORS errors in console alongside failed network requests

### Vue/Nuxt state inspection

```javascript
// Access the Vue app instance
document.querySelector('#__nuxt').__vue_app__

// Access Pinia store (from browser console)
document.querySelector('#__nuxt').__vue_app__.config.globalProperties.$pinia

// Check component props and data
// Use Vue DevTools extension or evaluate in console
```

### Performance profiling

1. Profile a specific user action (click, navigation), not the whole session
2. Look for: long tasks (>50ms), layout thrashing, excessive re-renders
3. Check the Network tab for slow or blocking requests
4. Compare against Core Web Vitals targets in `references/performance-checklist.md`

## Rules

- Always start with the console — most issues leave a trace there
- Do not guess at state — evaluate expressions to see actual values
- If the page shows a blank screen, check console errors first, then network failures
- Take a methodical approach: console → network → DOM → state → performance
