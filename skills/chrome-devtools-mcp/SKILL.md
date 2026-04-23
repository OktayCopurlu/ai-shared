---
name: chrome-devtools-mcp
description: 'Debug runtime issues via Chrome DevTools MCP server. USE FOR: inspecting network requests, console errors, DOM state, performance profiling, JavaScript debugging. ALWAYS use when user asks to debug a runtime issue, check network calls, or inspect the browser state.'
---

# Chrome DevTools MCP Server Usage

When debugging runtime issues in the browser, **always prefer using the Chrome DevTools MCP server tools** to inspect application state directly.

## Use Cases

- **Console errors**: Read console logs and errors to diagnose runtime issues
- **Network requests**: Inspect API calls, GraphQL queries, response payloads, and status codes
- **DOM inspection**: Check rendered HTML structure and element state via accessibility snapshots
- **JavaScript debugging**: Evaluate expressions in the browser context
- **Performance**: Profile page load, rendering, and script execution via traces and Lighthouse
- **Memory**: Take heap snapshots to detect memory leaks
- **Extensions**: Install, reload, and debug Chrome extensions

## Environment Access

If debugging a project-specific preview or staging environment, load the relevant project reference first so you use the correct host, auth pattern, and access method.

## Core Concepts

**Browser lifecycle**: The browser starts automatically on the first tool call using a persistent Chrome profile. Configure via CLI args: `npx chrome-devtools-mcp@latest --help`. Use `--categoryExtensions` to enable extension tools.

**Page selection**: Tools operate on the currently selected page. Use `list_pages` to see available pages, then `select_page` to switch context.

**Element interaction**: Use `take_snapshot` to get the page structure with element `uid`s. Each element has a unique `uid` for interaction. If an element isn't found, take a fresh snapshot — the page may have changed.

## Procedure

1. Ensure the local dev server is running
2. Open the page in Chrome that you want to debug
3. Use the appropriate tool to inspect the issue:
   - Check console for errors
   - Monitor network requests for failed API calls
   - Take a snapshot for DOM/rendering issues
   - Evaluate JavaScript to check reactive state
4. Cross-reference findings with the source code to identify the root cause

## Tool Selection

| What to check | Tool | Tips |
|---|---|---|
| Console errors & warnings | `list_console_messages` | Filter by level; check errors first, then warnings |
| Single console message detail | `get_console_message` | Get full stack trace and payload of a specific message |
| Network requests | `list_network_requests` | Filter by status (4xx/5xx), check request/response payloads, look for CORS errors |
| Network request detail | `get_network_request` | Inspect headers, body, timing for a specific request |
| DOM structure | `take_snapshot` | Accessibility-tree view with `uid` refs; use `filePath` for large pages |
| Reactive state | `evaluate_script` | Access Vue devtools: `__vue_app__`, component data, Pinia stores |
| Performance trace | `performance_start_trace` / `performance_stop_trace` | Profile specific interactions, not full page loads; look for long tasks > 50ms |
| Performance insights | `performance_analyze_insight` | Get analysis of a recorded trace |
| Lighthouse audit | `lighthouse_audit` | Run a full Lighthouse audit for performance, accessibility, best practices |
| Memory leaks | `take_memory_snapshot` | Compare heap snapshots before/after to find retained objects |
| Visual verification | `take_screenshot` | When snapshot semantics are not enough; use `filePath` for large screenshots |
| Storage | `evaluate_script` | `localStorage.getItem('key')`, `document.cookie`, `sessionStorage` |
| Click / interact | `click` | Use `uid` from `take_snapshot` |
| Fill input | `fill`, `fill_form` | Single field or multiple fields at once |
| Type text | `type_text` | Keystroke-style input into focused element |
| Keyboard | `press_key` | Key combinations like `Control+S`, `Enter`, `Tab` |
| Hover | `hover` | Trigger menus, tooltips, hidden actions |
| Drag and drop | `drag` | Use `from_uid` and `to_uid` from snapshot |
| File upload | `upload_file` | Use `uid` of the file input + local `filePath` |
| Dialog handling | `handle_dialog` | Accept or dismiss browser dialogs |
| Navigate | `navigate_page` | Go to URL, back, forward, or reload |
| Page management | `list_pages`, `select_page`, `new_page`, `close_page` | Multi-tab debugging |
| Wait for content | `wait_for` | Wait for text, element, URL, or network idle |
| Emulate device | `emulate` | Test mobile viewports, user agents, touch |
| Resize | `resize_page` | Test specific viewport dimensions |

## Debugging Patterns

### Console triage

1. `list_console_messages` — filter errors first, ignore warnings until errors are resolved
2. `get_console_message` — read the full stack trace before jumping to code
3. Check if the error is from your code or a dependency
4. Hydration mismatches: compare server-rendered HTML with client-side DOM

### Network debugging

1. `list_network_requests` — check status codes first (4xx = client error, 5xx = server error)
2. `get_network_request` — inspect headers (missing auth tokens, wrong Content-Type)
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

1. `performance_start_trace` — start recording before the user action
2. Perform the specific action (click, navigation)
3. `performance_stop_trace` — stop and save the trace
4. `performance_analyze_insight` — analyze the trace for bottlenecks
5. Look for: long tasks (>50ms), layout thrashing, excessive re-renders
6. `lighthouse_audit` — run for comprehensive performance/accessibility scoring

### Memory leak detection

1. `take_memory_snapshot` — baseline before the suspected action
2. Perform the action that may leak (navigate away, open/close modal, etc.)
3. `take_memory_snapshot` — compare retained objects
4. Look for growing detached DOM nodes, event listeners, closures

### Extension debugging

1. `install_extension` — install unpacked extension by path
2. `list_extensions` — get extension IDs
3. `trigger_extension_action` — open popup or side panel
4. `evaluate_script` with `serviceWorkerId` — check background state
5. `take_snapshot` — verify content script injections on the page

## Efficient Data Retrieval

- Use `filePath` parameter for large outputs (screenshots, snapshots, traces)
- Use pagination and filtering to minimize data transfer
- Set `includeSnapshot: false` on input actions unless you need updated page state

## Rules

- Always start with the console — most issues leave a trace there
- Do not guess at state — use `evaluate_script` to see actual values
- If the page shows a blank screen, check console errors first, then network failures
- Take a methodical approach: console → network → DOM → state → performance
- Use `take_snapshot` before interacting with elements — never guess `uid` refs
- After navigation or DOM changes, take a fresh snapshot before reusing refs
- For preview or staging environments, follow the project's documented access pattern instead of guessing credentials or hostnames

## Troubleshooting

If `chrome-devtools-mcp` is insufficient, guide users to use Chrome DevTools UI:
- https://developer.chrome.com/docs/devtools
- https://developer.chrome.com/docs/devtools/ai-assistance

For launch or connection errors, refer to the Chrome DevTools MCP troubleshooting guide on GitHub.

## See Also

- project-specific environment references such as `~/.ai-shared/references/on-frontend-urls.md`
