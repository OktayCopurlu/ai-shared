---
name: playwright-mcp
description: 'Web automation via Playwright MCP browser tools. USE FOR: filling forms, clicking buttons, navigating pages, interacting with web UIs, browser automation tasks. ALWAYS use when user asks to automate browser actions, fill out a form, click through a wizard, or interact with a website.'
---

# Playwright Browser Automation

Use this skill with the Playwright MCP server that exposes `browser_*` tools such as
`browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_type`,
`browser_select_option`, `browser_press_key`, `browser_wait_for`,
`browser_evaluate`, and `browser_file_upload`.

## Environment-Specific URLs

If the task involves project-specific local/staging/production URL mapping or preview authentication, load the relevant project reference before navigating.

## Core Workflow

1. **Open or switch context** - use `browser_navigate` or `browser_tabs` first if needed
2. **Snapshot first** - always run `browser_snapshot` before interacting to discover current refs
3. **Identify refs** - find the correct `ref=eXXX` for the target element in the accessibility tree
4. **Interact** - use the narrowest tool that fits: `browser_click`, `browser_fill_form`, `browser_type`, `browser_select_option`, `browser_press_key`, `browser_drag`
5. **Verify** - inspect the next `browser_snapshot`, URL, visible state, or console/network output if relevant
6. **Repeat** - after navigation or major DOM changes, take a fresh `browser_snapshot` before reusing refs

## Tool Selection

| Situation | Tool | Notes |
|-----------|------|-------|
| Open a page | `browser_navigate` | Use before the first snapshot |
| Standard text inputs | `browser_fill_form` | Best default for normal inputs and textareas |
| One-off text entry into focused/editable element | `browser_type` | Useful for fields that behave better with keystroke-style typing |
| Single click actions | `browser_click` | Use refs from `browser_snapshot` |
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

## Available Tools In This Setup

- `browser_click` — supports `selector` param as alternative to `ref`
- `browser_close`
- `browser_console_messages` — filter by level: `error`, `warning`, `info`, `debug`
- `browser_drag`
- `browser_evaluate` — run JS on page or a specific element via `ref`
- `browser_file_upload`
- `browser_fill_form` — fill multiple fields at once (textbox, checkbox, radio, combobox, slider)
- `browser_handle_dialog`
- `browser_hover`
- `browser_install`
- `browser_navigate`
- `browser_navigate_back`
- `browser_network_requests` — supports `filter` (URL regexp), `requestBody`, `requestHeaders`, `static` params
- `browser_press_key`
- `browser_resize`
- `browser_run_code` — execute arbitrary Playwright code snippets
- `browser_select_option`
- `browser_snapshot` — supports `depth` param to limit tree depth
- `browser_tabs` — list, new, close, select
- `browser_take_screenshot` — supports element screenshots via `ref`, `fullPage`, `jpeg`/`png` format
- `browser_type`
- `browser_wait_for` — wait for text appear/disappear or fixed time

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

### Authenticated preview access

If the target environment uses preview or staging auth, follow the project-specific reference and use the credentialed URL with `browser_navigate`:
```
browser_navigate → https://<USER>:<PASS>@<preview-host>/<path>
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

## Alternatives

- **Playwright CLI** (`@playwright/cli`, [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)) — a CLI-based alternative to Playwright MCP, designed to be more token-efficient for coding agents. Uses text commands instead of MCP tool calls. Consider for batch automation or when MCP overhead is high.

## See Also

- project-specific environment references such as `~/.ai-shared/references/on-frontend-urls.md`
