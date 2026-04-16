# Codex 0.121.0 — Plugin Marketplace & MCP Apps

> Source: [OpenAI Codex Releases](https://github.com/openai/codex/releases), 2026-04-15

Codex 0.121.0 introduces a plugin marketplace, expanded MCP support, and memory model controls.

## Plugin Marketplace

- `codex marketplace add <plugin>` — install plugins from the official registry.
- `codex marketplace list` — browse available plugins.
- Plugins are sandboxed and version-pinned.

## MCP Enhancements

- **MCP Apps**: long-running MCP servers that persist across sessions.
- **Namespaced registration**: multiple MCP servers can expose same-named tools without collision.
- **Parallel-call opt-in**: servers can declare parallel tool invocation support.

## Memory & Model

- TUI: `Ctrl+R` history search across sessions.
- Memory mode controls: `--memory-reset`, `--memory-delete <key>`.
- Default memory model upgraded to **GPT-5.4**.

## Other

- Secure devcontainer execution via bubblewrap sandboxing.
- Realtime API integration for streaming tool outputs.

## Relevance

- MCP namespaced registration aligns with how OpenCode and VS Code handle multi-server MCP setups.
- Plugin marketplace pattern is similar to OpenCode's skill/plugin system — potential for cross-tool plugin discovery.
- Memory controls may inform future skill or agent memory patterns in this repo.
