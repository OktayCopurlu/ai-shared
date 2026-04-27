---
name: playwright-mcp
description: 'Web automation via Playwright MCP browser tools. USE FOR: filling forms, clicking buttons, navigating pages, interacting with web UIs, browser automation tasks. ALWAYS use when user asks to automate browser actions, fill out a form, click through a wizard, or interact with a website.'
---

# Playwright Browser Automation

Use this skill with the Playwright MCP server after deciding MCP is the right browser path.
Exact function names can vary by host surface; examples below use Playwright MCP-style `browser_*` names when that surface is exposed.
The server organizes tools into **core** tools plus a small set of opt-in capability groups enabled via `--caps`.

## Routing

1. Prefer first-party integrations for structured systems such as Jira, GitHub, Figma, or Google Docs.
2. If browser work is short and auth/session reuse is not the hard part, `playwright-cli` can be the lighter path.
3. Use Playwright MCP when authenticated browser reuse via `--extension`, repeated snapshots, or longer stateful interaction matter.
4. Use `chrome-devtools-mcp` when inspection, console, or network debugging is the main goal.

## Session Modes

- `--extension` connects to an existing Chrome or Edge browser through the Playwright MCP Bridge extension and reuses that browser state.
- `--user-data-dir <path>` opts into a persistent profile on disk.
- If `--user-data-dir` is omitted, the server creates a temporary user data directory.
- `--isolated` keeps the browser profile in memory and does not save it to disk.

## Authenticated Sites

If the target page may require login, paywall access, or workspace membership, prefer `--extension` when a suitable logged-in browser already exists.
Do not assume persistent auth by default; persistence only exists when `--user-data-dir` or another explicit config provides it.
If the page is still blocked, verify the attached tab and browser state before calling the page unreadable.

## Capability Groups

| Flag | Tools enabled | Use case |
|------|--------------|----------|
| *(core)* | click, close, console_messages, drag, evaluate, file_upload, fill_form, handle_dialog, hover, navigate, navigate_back, network_requests, press_key, resize, run_code, select_option, snapshot, tabs, take_screenshot, type, wait_for | Standard automation |
| `--caps=devtools` | highlight, hide_highlight, pick_locator, generate_locator | Element inspection, locator generation |
| `--caps=vision` | mouse_click_xy, mouse_down, mouse_drag_xy, mouse_move_xy, mouse_up, mouse_wheel | Coordinate-based interaction (canvas, maps) |
| `--caps=pdf` | pdf_save | Save page as PDF |

Enable multiple: `--caps=devtools,vision`

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
| Canvas / coordinate interaction | `browser_mouse_click_xy` | Requires `--caps=vision`; for non-accessible elements |
| Generate locators | `browser_pick_locator` | Requires `--caps=devtools`; interactive locator discovery |
| Save page as PDF | `browser_pdf_save` | Requires `--caps=pdf` |

## Opt-in Tools (enabled via `--caps`)

These tools are **not** in the default tool set. Check your server config before relying on them.

**`--caps=devtools`** — locator tooling: `browser_highlight` / `browser_hide_highlight`, `browser_pick_locator`, `browser_generate_locator`.

**`--caps=vision`** — coordinate-based mouse: `browser_mouse_click_xy`, `browser_mouse_down`, `browser_mouse_up`, `browser_mouse_move_xy`, `browser_mouse_drag_xy`, `browser_mouse_wheel`. Use for canvas, maps, or anything the accessibility tree can't reach.

**`--caps=pdf`** — `browser_pdf_save`.

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

### Authenticated preview access (HTTP basic auth)

If the target environment is protected by HTTP basic auth (common for staging/preview), embed credentials in the URL:

```
browser_navigate → https://<USER>:<PASS>@<preview-host>/<path>
```

Follow the project-specific reference for the actual credentials.

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
- If a short command sequence will do and the required session state is already available, use `playwright-cli` instead
- Do not assume persistent state unless the session config makes it explicit
- Prefer `--extension` for login-required pages when a suitable logged-in browser already exists
- Use `browser_wait_for` instead of arbitrary delays
- If the page is a login wall, verify whether the extension-managed browser state is correct before calling the page blocked
- If a form has custom components (not native `<input>`), check if `browser_fill_form` works; fall back to `browser_type` or `browser_evaluate` if not
- For authenticated preview or staging URLs, follow the project's documented access pattern instead of guessing credentials or hostnames
- Use `browser_network_requests` with `filter` param to narrow results (e.g., `filter: "/api/.*"`)
- Use `browser_snapshot` with `depth` param when only top-level structure is needed (saves tokens)
- Use `browser_run_code` for complex multi-step Playwright operations that would be verbose with individual tool calls

## Alternatives

- **Playwright CLI** (`@playwright/cli`, [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)) — a CLI-based alternative to Playwright MCP, designed to be more token-efficient for coding agents. Uses text commands instead of MCP tool calls. Consider for batch automation or when MCP overhead is high.

## See Also

- project-specific environment references such as `~/.ai-shared/references/on-frontend-urls.md`
