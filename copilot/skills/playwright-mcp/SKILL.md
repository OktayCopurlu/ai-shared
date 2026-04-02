---
name: playwright-mcp
description: 'Web automation via Playwright MCP browser tools. USE FOR: filling forms, clicking buttons, navigating pages, interacting with web UIs, browser automation tasks. ALWAYS use when user asks to automate browser actions, fill out a form, click through a wizard, or interact with a website.'
---

# Playwright Browser Automation

Use this skill with the Playwright MCP server that exposes `browser_*` tools such as
`browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_type`,
`browser_select_option`, `browser_press_key`, `browser_wait_for`,
`browser_evaluate`, and `browser_file_upload`.

## on-frontend URLs

- **Local dev**: `http://localhost:5050`
- **Production**: `https://www.on.com`
- **Staging / Preview**: Require HTTP basic auth — embed credentials in the URL: `https://on:trend@on-shop-<PR_NUMBER>.on-running.com/...`

Examples:
- `https://www.on.com/en-ch/shop/mens/low` → `http://localhost:5050/en-ch/shop/mens/low`
- `https://www.on.com/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851` → `http://localhost:5050/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851`
- Preview: `https://on:trend@on-shop-8895.on-running.com/en-ch/products/...`

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

- `browser_click`
- `browser_close`
- `browser_console_messages`
- `browser_drag`
- `browser_evaluate`
- `browser_file_upload`
- `browser_fill_form`
- `browser_handle_dialog`
- `browser_hover`
- `browser_install`
- `browser_navigate`
- `browser_navigate_back`
- `browser_network_requests`
- `browser_press_key`
- `browser_resize`
- `browser_run_code`
- `browser_select_option`
- `browser_snapshot`
- `browser_tabs`
- `browser_take_screenshot`
- `browser_type`
- `browser_wait_for`

## Snapshot Rules

- Treat `browser_snapshot` as the source of truth for current refs
- Do not guess refs or reuse stale refs after navigation, tab switches, modal opens, or large DOM updates
- Prefer refs with clear roles and labels over brittle visual guesses
- If the page changes significantly, take a new snapshot before the next action
