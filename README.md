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

| Source (ai-shared) | Symlink target                           | Tool            | Notes                                                           |
| ------------------ | ---------------------------------------- | --------------- | --------------------------------------------------------------- |
| `instructions.md`  | `~/.github/copilot-instructions.md`      | VS Code Copilot | Auto-loaded every conversation                                  |
| `instructions.md`  | `~/.codex/instructions.md`               | Codex           | Auto-loaded every conversation                                  |
| `instructions.md`  | `~/.config/opencode/instructions.md`     | OpenCode        | Auto-loaded every conversation                                  |
| `skills/`          | `~/.copilot/skills/`                     | VS Code Copilot | Directory symlink; skills loaded on demand via `<skills>` block |
| `skills/*`         | `~/.codex/skills/*` (per-skill symlinks) | Codex           | Requires per-skill symlinks; no directory symlink support       |
| `skills/`          | `~/.config/opencode/skills/`             | OpenCode        | Directory symlink; on-demand loading                            |
| `agents/`          | `~/.copilot/agents/`                     | VS Code Copilot | Copilot only — Codex and OpenCode do not support custom agents  |
| `prompts/`         | `~/.copilot/prompts/`                    | VS Code Copilot | Slash-command prompts; Copilot + Codex only                     |
| `prompts/`         | `~/.codex/prompts/`                      | Codex           | Slash-command prompts                                           |
| `research/skills/` | `~/.copilot/research/skills/`            | VS Code Copilot | Copilot only — research agent skills                            |

## Rules for agents

- **Creating/updating skills, prompts, or agents**: always write to `~/.ai-shared/...` — symlinks propagate automatically.
- **Adding a new skill**: create `~/.ai-shared/skills/<name>/SKILL.md`, then add a per-skill symlink to `~/.codex/skills/`.
- **Global instructions**: edit `~/.ai-shared/instructions.md` — all tools pick up changes.
- This folder is git-tracked. Commit changes to preserve them.

## Skill authoring checklist

Every skill SKILL.md must have:

1. **YAML frontmatter** with `name` and `description` (description includes trigger phrases)
2. **When to use / when not to use** — either explicit sections or clearly covered in the description and body
3. **Guardrails** — what the skill must not do, or constraints on its output

Optional but recommended for procedural skills: output format, required inputs, failure/ambiguity policy.

## Validation

Run `./validate.sh` after making changes to catch broken symlinks, missing frontmatter, empty files, and duplicate names.
