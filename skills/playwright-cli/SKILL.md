---
name: playwright-cli
description: "Browser automation via Playwright CLI for coding agents. USE FOR: concise browser flows, repetitive website tasks, command-driven automation, named browser sessions, storage state, and extension or CDP attachment when token efficiency matters. Prefer this when a coding agent needs browser automation without loading MCP tool schemas."
---

# Playwright CLI

Use Playwright CLI as the default browser path for most coding-agent work when token efficiency matters more than MCP-native introspection. It also supports auth/session reuse through attach, named sessions, storage state, and persistent profiles when needed.

## Routing

1. Prefer first-party integrations or connector-backed tools before generic browser automation.
2. Use Playwright CLI for most coding-agent browser tasks, especially command-driven flows, attached sessions, and reusable named sessions.
3. Use `playwright-mcp` when continuous browser context, rich page introspection, or longer stateful interaction matter more than token cost.
4. Use `chrome-devtools-mcp` when inspection, network, console, or tab verification is the main task.

## Installation

- Prefer a global `playwright-cli` command when available.
- If the global command is unavailable, check for a local install via `npx --no-install playwright-cli --version`.
- If neither path works, install it with `npm install -g @playwright/cli@latest`.
- Install bundled skills with `playwright-cli install --skills` so coding agents can discover the CLI workflow directly.

## Session Modes

- Default mode keeps browser state in memory between CLI calls until the browser closes.
- `--persistent` saves the profile to disk across browser restarts.
- `-s=<name>` or `PLAYWRIGHT_CLI_SESSION=<name>` isolates work per project or task.
- `attach --extension=chrome` reuses logged-in browser state through the Playwright extension.
- `attach --cdp=chrome` or `attach --cdp=<url>` connects to an existing Chromium browser via CDP.
- `show` opens the session dashboard for monitoring or manual assist.

## Core Workflow

1. Start with `playwright-cli open <url>` or `playwright-cli goto <url>`.
2. Use the auto-generated snapshot or call `playwright-cli snapshot` to obtain refs.
3. Interact with commands such as `click`, `fill`, `press`, `select`, `upload`, `check`, `uncheck`, and `drag`.
4. Reach for `state-save`, `state-load`, `route`, `console`, `network`, `tracing-*`, `video-*`, or `pdf` when needed.
5. Manage sessions with `list`, `show`, `close-all`, `kill-all`, or `delete-data`.

## Rules

- Prefer Playwright CLI over Playwright MCP for most coding-agent browser tasks unless the task needs a richer iterative MCP loop.
- Use named sessions to avoid cross-project session collisions.
- Use `--persistent` only when state must survive browser restarts.
- Prefer `attach --extension` or `attach --cdp` over inventing ad-hoc profile reuse when an existing logged-in browser should be reused.
- Use `snapshot --depth=<n>` or element snapshots to keep output focused.
- Use `--headed` only when a human needs to watch or help.
- Escalate to `playwright-mcp` or `chrome-devtools-mcp` when richer inspection or a persistent interactive loop is required.

## See Also

- `playwright-mcp` — richer persistent browser automation and MCP-native introspection
- `chrome-devtools-mcp` — runtime inspection, network, and console analysis
- `linked-context-routing` — route mixed linked resources before browser fallback
