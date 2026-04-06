# ai-shared — Central AI Configuration

This folder is the single source of truth for all AI agent configuration — skills, prompts, agents, and global instructions. Other tools (Copilot, Codex, OpenCode) consume this via symlinks.

## Structure

```
~/.ai-shared/
├── instructions.md       # Global rules (verification, decisions, quality)
├── skills/               # Reusable domain skills (loaded on demand)
│   ├── google-drive/SKILL.md
│   ├── jira-ticket/SKILL.md
│   ├── pr-workflow/SKILL.md
│   └── ...
├── agents/               # Custom agent modes
│   ├── devils-advocate.agent.md
│   └── ...
├── prompts/              # Reusable prompt templates
│   ├── code-review.prompt.md
│   └── ...
└── research/             # Research-specific skills
    └── skills/
```

## Symlinks

All tools point back here. **Never edit the symlinked copies — always edit the source in `~/.ai-shared/`.**

| Source (ai-shared) | Symlink target | Tool |
|---|---|---|
| `instructions.md` | `~/.github/copilot-instructions.md` | VS Code Copilot |
| `instructions.md` | `~/.codex/instructions.md` | Codex |
| `instructions.md` | `~/.config/opencode/instructions.md` | OpenCode |
| `skills/` | `~/.copilot/skills/` | VS Code Copilot |
| `skills/*` | `~/.codex/skills/*` (per-skill symlinks) | Codex |
| `skills/` | `~/.config/opencode/skills/` | OpenCode |
| `agents/` | `~/.copilot/agents/` | VS Code Copilot |
| `prompts/` | `~/.copilot/prompts/` | VS Code Copilot |
| `prompts/` | `~/.codex/prompts/` | Codex |
| `research/skills/` | `~/.copilot/research/skills/` | VS Code Copilot |

## Rules for agents

- **Creating/updating skills, prompts, or agents**: always write to `~/.ai-shared/...` — symlinks propagate automatically.
- **Adding a new skill**: create `~/.ai-shared/skills/<name>/SKILL.md`, then add a per-skill symlink to `~/.codex/skills/`.
- **Global instructions**: edit `~/.ai-shared/instructions.md` — all tools pick up changes.
- This folder is git-tracked. Commit changes to preserve them.
