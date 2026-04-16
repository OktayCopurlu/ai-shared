# Copilot CLI — BYOK & Local Models

> Source: [GitHub Changelog, 2026-04-07](https://github.blog/changelog/2026-04-07-copilot-cli-now-supports-byok-and-local-models)

GitHub Copilot CLI now supports Bring Your Own Key (BYOK) and local model backends. This removes the hard dependency on GitHub authentication and enables air-gapped usage.

## Supported Backends

| Backend | Config |
|---|---|
| Azure OpenAI | `COPILOT_AZURE_ENDPOINT` + `COPILOT_AZURE_API_KEY` |
| Anthropic | `COPILOT_ANTHROPIC_API_KEY` |
| OpenAI-compatible | `COPILOT_OPENAI_BASE_URL` + `COPILOT_OPENAI_API_KEY` |
| Offline / air-gapped | `COPILOT_OFFLINE=true` (uses local model only) |

## Key Changes

- GitHub authentication is now **optional** when a BYOK backend is configured.
- `COPILOT_OFFLINE=true` disables all network calls to GitHub, enabling fully air-gapped operation.
- Any OpenAI-compatible endpoint works (Ollama, LM Studio, vLLM, etc.).

## Relevance

- Teams behind corporate proxies or in regulated environments can now use Copilot CLI without GitHub auth.
- Pairs with OpenCode's existing multi-provider support — both tools can point to the same local or BYOK endpoint.
- Reduces vendor lock-in for CLI-based AI coding assistants.
