# ai-shared — Central AI Configuration

This folder is the single source of truth for all AI agent configuration — skills, prompts, agents, and global instructions. Other tools (Copilot, Codex, OpenCode) consume this via symlinks.

## Structure

```
~/.ai-shared/
└── copilot/
    ├── copilot-instructions.md   # Global rules (verification, decisions, quality)
    ├── skills/                   # Reusable domain skills (loaded on demand)
    │   ├── google-drive/SKILL.md
    │   ├── jira-ticket/SKILL.md
    │   ├── pr-workflow/SKILL.md
    │   └── ...
    ├── agents/                   # Custom agent modes
    │   ├── devils-advocate.agent.md
    │   └── ...
    └── prompts/                  # Reusable prompt templates
        ├── code-review.prompt.md
        └── ...
```

## Symlinks

All tools point back here. **Never edit the symlinked copies — always edit the source in `~/.ai-shared/`.**

| Source (ai-shared)                | Symlink target                           | Tool            |
| --------------------------------- | ---------------------------------------- | --------------- |
| `copilot/copilot-instructions.md` | `~/.github/copilot-instructions.md`      | VS Code Copilot |
| `copilot/copilot-instructions.md` | `~/.codex/instructions.md`               | Codex           |
| `copilot/copilot-instructions.md` | `~/.config/opencode/instructions.md`     | OpenCode        |
| `copilot/skills/`                 | `~/.copilot/skills/`                     | VS Code Copilot |
| `copilot/skills/*`                | `~/.codex/skills/*` (per-skill symlinks) | Codex           |
| `copilot/skills/*`                | `~/.config/opencode/skills/*`            | OpenCode        |
| `copilot/agents/`                 | `~/.copilot/agents/`                     | VS Code Copilot |
| `copilot/prompts/`                | `~/.copilot/prompts/`                    | VS Code Copilot |

## Rules for agents

- **Creating/updating skills, prompts, or agents**: always write to `~/.ai-shared/copilot/...` — symlinks propagate automatically.
- **Adding a new skill**: create `~/.ai-shared/copilot/skills/<name>/SKILL.md`, then add per-skill symlinks to `~/.codex/skills/` and `~/.config/opencode/skills/`.
- **Global instructions**: edit `~/.ai-shared/copilot/copilot-instructions.md` — all tools pick up changes.
- This folder is git-tracked. Commit changes to preserve them.
