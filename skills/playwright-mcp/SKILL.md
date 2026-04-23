---
name: playwright-mcp
description: 'Web automation via Playwright MCP browser tools. USE FOR: filling forms, clicking buttons, navigating pages, interacting with web UIs, browser automation tasks. ALWAYS use when user asks to automate browser actions, fill out a form, click through a wizard, or interact with a website.'
---

# Playwright Browser Automation

Use this skill with the Playwright MCP server that exposes `browser_*` tools.
The server organizes tools into **core** (always available) and **opt-in capability groups** enabled via `--caps`.

## Capability Groups

| Flag | Tools enabled | Use case |
|------|--------------|----------|
| *(core)* | click, close, console_messages, drag, evaluate, file_upload, fill_form, handle_dialog, hover, navigate, navigate_back, network_requests, press_key, resize, run_code, select_option, snapshot, tabs, take_screenshot, type, wait_for | Standard automation |
| `--caps=storage` | cookie_*, localstorage_*, sessionstorage_*, set_storage_state, storage_state | Auth state, cookie management |
| `--caps=network` | route, route_list, unroute, network_state_set | Request interception, offline testing |
| `--caps=config` | get_config | Read server configuration |
| `--caps=devtools` | highlight, hide_highlight, pick_locator, generate_locator | Element inspection, locator generation |
| `--caps=vision` | mouse_click_xy, mouse_down, mouse_drag_xy, mouse_move_xy, mouse_up, mouse_wheel | Coordinate-based interaction (canvas, maps) |
| `--caps=pdf` | pdf_save | Save page as PDF |
| `--caps=testing` | verify_element_visible, verify_list_visible, verify_text_visible, verify_value | Built-in assertions |

Enable multiple: `--caps=storage,network,testing`

## Environment-Specific URLs

If the task involves project-specific local/staging/production URL mapping or preview authentication, load the relevant project reference before navigating.

## Core Workflow

1. **Open or switch context** — use `browser_navigate` or `browser_tabs` first if needed
2. **Snapshot first** — always run `browser_snapshot` before interacting to discover current refs
3. **Identify refs** — find the correct `ref=eXXX` for the target element in the accessibility tree
4. **Interact** — use the narrowest tool that fits: `browser_click`, `browser_fill_form`, `browser_type`, `browser_select_option`, `browser_press_key`, `browser_drag`
5. **Verify** — inspect the next `browser_snapshot`, URL, visible state, or console/network output if relevant
6. **Repeat** — after navigation or major DOM changes, take a fresh `browser_snapshot` before reusing refs

## Tool Selection

| Situation | Tool | Notes |
|-----------|------|-------|
| Open a page | `browser_navigate` | Use before the first snapshot |
| Standard text inputs | `browser_fill_form` | Best default for normal inputs and textareas |
| One-off text entry into focused/editable element | `browser_type` | Useful for fields that behave better with keystroke-style typing |
| Single click actions | `browser_click` | Use refs from `browser_snapshot`; also accepts CSS selectors |
| Native `<select>` | `browser_select_option` | Prefer over keyboarding when available |
| Keyboard submission | `browser_press_key` | Useful for Enter, Escape, Tab, arrows |
| Wait for UI updates | `browser_wait_for` | Prefer waiting for text/state changes over fixed delays |
| Rich text editors / contenteditable | `browser_evaluate` or `browser_run_code` | Use only when normal form tools cannot reach the editor |
| Drag and drop | `browser_drag` | For sortable lists and draggable UIs |
| File upload | `browser_file_upload` | Works for standard file inputs |
| Hover-only UI | `browser_hover` | Helpful for menus, tooltips, hidden actions |
| Dialogs / alerts / confirms | `browser_handle_dialog` | Use after an action triggers a browser dialog |
| Debug page behavior | `browser_console_messages` / `browser_network_requests` | Useful when clicks or submits fail silently |
| Visual verification | `browser_take_screenshot` | Use when snapshot semantics are not enough |
| Check element presence | `browser_verify_text_visible` | Requires `--caps=testing`; quick assertion without snapshot |
| Manage cookies / auth state | `browser_cookie_*`, `browser_storage_state` | Requires `--caps=storage` |
| Intercept requests | `browser_route` | Requires `--caps=network`; mock APIs or block resources |
| Test offline behavior | `browser_network_state_set` | Requires `--caps=network` |
| Canvas / coordinate interaction | `browser_mouse_click_xy` | Requires `--caps=vision`; for non-accessible elements |
| Generate locators | `browser_pick_locator` | Requires `--caps=devtools`; interactive locator discovery |
| Save page as PDF | `browser_pdf_save` | Requires `--caps=pdf` |
| Record video | `browser_start_video` / `browser_stop_video` | Record browser session; `browser_video_chapter` adds markers |
| Trace recording | `browser_start_tracing` / `browser_stop_tracing` | Capture Playwright trace for debugging |

## Available Tools — Core (always on)

- `browser_click` — click element by ref or CSS selector; supports `doubleClick`, `button`, `modifiers`
- `browser_close` — close the page
- `browser_console_messages` — filter by level: `error`, `warning`, `info`, `debug`; `all` flag for full session
- `browser_drag` — drag between two elements by ref
- `browser_evaluate` — run JS on page or a specific element via `ref`
- `browser_file_upload` — upload files by absolute path
- `browser_fill_form` — fill multiple fields at once (textbox, checkbox, radio, combobox, slider)
- `browser_handle_dialog` — accept/dismiss browser dialogs
- `browser_hover` — hover over element
- `browser_navigate` — go to URL
- `browser_navigate_back` — go back in history
- `browser_network_requests` — supports `filter` (URL regexp), `requestBody`, `requestHeaders`, `static` params
- `browser_press_key` — press keyboard key
- `browser_resize` — resize browser window
- `browser_run_code` — execute arbitrary Playwright code snippets
- `browser_select_option` — select dropdown option
- `browser_snapshot` — accessibility snapshot; supports `depth` param to limit tree depth
- `browser_tabs` — list, new, close, select tabs
- `browser_take_screenshot` — supports element screenshots via `ref`, `fullPage`, `jpeg`/`png` format
- `browser_type` — type text into element; `slowly` for keystroke mode, `submit` to press Enter after
- `browser_wait_for` — wait for text appear/disappear or fixed time

## Available Tools — Recording

- `browser_start_video` / `browser_stop_video` — record browser session video
- `browser_video_chapter` — add chapter marker with title overlay during recording
- `browser_start_tracing` / `browser_stop_tracing` — capture Playwright trace
- `browser_resume` — resume paused execution

## Available Tools — Storage (`--caps=storage`)

- `browser_cookie_list` / `browser_cookie_get` / `browser_cookie_set` / `browser_cookie_delete` / `browser_cookie_clear`
- `browser_localstorage_list` / `browser_localstorage_get` / `browser_localstorage_set` / `browser_localstorage_delete` / `browser_localstorage_clear`
- `browser_sessionstorage_list` / `browser_sessionstorage_get` / `browser_sessionstorage_set` / `browser_sessionstorage_delete` / `browser_sessionstorage_clear`
- `browser_storage_state` — export full storage state (cookies + localStorage)
- `browser_set_storage_state` — restore storage state from file

## Available Tools — Network (`--caps=network`)

- `browser_route` — intercept requests matching a URL pattern; fulfill, abort, or modify
- `browser_route_list` — list active routes
- `browser_unroute` — remove a route
- `browser_network_state_set` — toggle network offline mode

## Available Tools — DevTools (`--caps=devtools`)

- `browser_highlight` / `browser_hide_highlight` — visually highlight elements on page
- `browser_pick_locator` — interactive locator picker
- `browser_generate_locator` — generate locator for element

## Available Tools — Vision (`--caps=vision`)

- `browser_mouse_click_xy` — click at coordinates; supports `button`, `clickCount`, `delay`
- `browser_mouse_down` / `browser_mouse_up` — press/release mouse button
- `browser_mouse_move_xy` — move mouse to coordinates
- `browser_mouse_drag_xy` — drag between coordinates
- `browser_mouse_wheel` — scroll via mouse wheel

## Available Tools — Testing (`--caps=testing`)

- `browser_verify_element_visible` — assert element is visible
- `browser_verify_list_visible` — assert list of elements visible
- `browser_verify_text_visible` — assert text is visible on page
- `browser_verify_value` — assert element has expected value

## Available Tools — Other opt-in

- `browser_get_config` (`--caps=config`) — read server configuration
- `browser_pdf_save` (`--caps=pdf`) — save page as PDF

## Snapshot Rules

- Treat `browser_snapshot` as the source of truth for current refs
- Do not guess refs or reuse stale refs after navigation, tab switches, modal opens, or large DOM updates
- Prefer refs with clear roles and labels over brittle visual guesses
- If the page changes significantly, take a new snapshot before the next action

## Common Patterns

### Form filling

```
1. browser_navigate → target page
2. browser_snapshot → find form field refs
3. browser_fill_form → fill each field using refs
4. browser_snapshot → verify values are set
5. browser_click → submit button ref
6. browser_snapshot → verify success state
```

### Multi-step wizard / checkout

```
1. Navigate to step 1
2. For each step:
   a. browser_snapshot → identify current step, find input refs
   b. Fill / click as needed
   c. browser_snapshot → confirm step advanced
3. Verify final confirmation page
```

### Cookie consent / modal dismissal

```
1. browser_snapshot → look for dialog/modal refs
2. browser_click → accept/dismiss button
3. browser_snapshot → confirm modal is gone
4. Continue with the actual task
```

### Authenticated session via storage state

```
1. browser_set_storage_state → load saved auth state (requires --caps=storage)
2. browser_navigate → target page (already authenticated)
3. browser_snapshot → verify logged-in state
```

### API mocking with route interception

```
1. browser_route → intercept /api/endpoint, fulfill with mock response (requires --caps=network)
2. browser_navigate → target page
3. browser_snapshot → verify page renders with mocked data
4. browser_unroute → clean up when done
```

### Debugging failed interactions

When a click or fill doesn't work:
1. `browser_console_messages` — check for JS errors blocking interaction
2. `browser_network_requests` — check if an API call failed
3. `browser_snapshot` — check if the element is still in the DOM
4. Try `browser_wait_for` — the element may not be ready yet
5. Try `browser_evaluate` — interact via JS as a fallback

## Rules

- Always snapshot before interacting — never guess refs
- After navigation or DOM changes, take a fresh snapshot
- Use `browser_wait_for` instead of arbitrary delays
- If a form has custom components (not native `<input>`), check if `browser_fill_form` works; fall back to `browser_type` or `browser_evaluate` if not
- For authenticated preview or staging URLs, follow the project's documented access pattern instead of guessing credentials or hostnames
- Use `browser_network_requests` with `filter` param to narrow results (e.g., `filter: "/api/.*"`)
- Use `browser_snapshot` with `depth` param when only top-level structure is needed (saves tokens)
- Use `browser_run_code` for complex multi-step Playwright operations that would be verbose with individual tool calls
- Tools now accept CSS selectors in addition to ref handles — useful when refs are unstable

## Alternatives

- **Playwright CLI** (`@playwright/cli`, [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)) — a CLI-based alternative to Playwright MCP, designed to be more token-efficient for coding agents. Uses text commands instead of MCP tool calls. Consider for batch automation or when MCP overhead is high.

## See Also

- project-specific environment references such as `~/.ai-shared/references/on-frontend-urls.md`
