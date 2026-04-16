# Agent Skills Standard — Cross-Tool Reference

> Last updated: 2026-04-16
> Sources: agentskills.io/specification, VS Code docs (agent-skills, custom-instructions, hooks, plugins), OpenCode docs (rules, agents, skills, permissions, plugins, custom-tools)

## Overview

Agent Skills are an open standard (agentskills.io) for portable AI agent capabilities. A skill is a directory with a `SKILL.md` file containing YAML frontmatter + Markdown instructions. 30+ tools support the format including VS Code Copilot, Claude Code, OpenCode, Cursor, Gemini CLI, and OpenAI Codex.

Our repo already conforms — all 18 skills in `skills/` have valid `name` and `description` frontmatter.

---

## SKILL.md Spec (agentskills.io)

### Required frontmatter

| Field         | Constraints                                               |
| ------------- | --------------------------------------------------------- |
| `name`        | 1-64 chars, lowercase alphanumeric + hyphens, must match directory name |
| `description` | 1-1024 chars, describes what + when to use               |

### Optional frontmatter

| Field           | Purpose                                    |
| --------------- | ------------------------------------------ |
| `license`       | License name or file reference             |
| `compatibility` | Environment requirements (max 500 chars)   |
| `metadata`      | Arbitrary key-value map                    |
| `allowed-tools` | Space-separated pre-approved tools (experimental) |

### Directory structure

```
skill-name/
  SKILL.md          # Required: metadata + instructions
  scripts/          # Optional: executable code
  references/       # Optional: documentation
  assets/           # Optional: templates, resources
```

### Progressive disclosure

1. **Metadata** (~100 tokens) — `name` + `description` loaded at startup for all skills
2. **Instructions** (<5000 tokens recommended) — full SKILL.md body loaded on activation
3. **Resources** (as needed) — files in scripts/, references/, assets/ loaded on demand

Keep SKILL.md under 500 lines. Move detailed reference material to separate files.

### Validation

```bash
# Using the skills-ref library
skills-ref validate ./my-skill
```

---

## Discovery Paths by Tool

| Tool            | Skill discovery paths                                      |
| --------------- | ---------------------------------------------------------- |
| VS Code Copilot | `.github/skills/`, `.claude/skills/`, `.agents/skills/`    |
| Claude Code     | `.claude/skills/`, `~/.claude/skills/`                     |
| OpenCode        | `.opencode/skills/`, `~/.config/opencode/skills/`, `.claude/skills/` (compat) |
| Cursor          | `.cursor/skills/`                                          |
| Codex           | `.codex/skills/` (via AGENTS.md reference)                 |

---

## Cross-Tool Customization Landscape

### Instruction files

| Format                          | VS Code | OpenCode | Claude Code |
| ------------------------------- | ------- | -------- | ----------- |
| `AGENTS.md`                     | Yes     | Yes (primary) | No     |
| `CLAUDE.md`                     | Yes     | Yes (fallback) | Yes (primary) |
| `.github/copilot-instructions.md` | Yes  | No       | No          |
| `.instructions.md` (file-based) | Yes    | No       | No          |
| `opencode.json` instructions    | No      | Yes      | No          |

### Agent definitions

| Feature            | VS Code              | OpenCode                     |
| ------------------ | -------------------- | ---------------------------- |
| Custom agents      | `.agent.md` files    | `~/.config/opencode/agents/*.md` or `.opencode/agents/` |
| Agent frontmatter  | tools, model, handoffs, hooks | description, mode, model, permission, steps |
| Subagents          | Yes (depth 5)        | Yes (task tool)              |
| Handoffs           | Yes (agent-to-agent) | No (explicit via task)       |

### Hooks / Lifecycle events

| Feature      | VS Code                    | OpenCode                     |
| ------------ | -------------------------- | ---------------------------- |
| Hook system  | `.github/hooks/*.json`     | Plugins (JS/TS)              |
| Events       | 8 lifecycle events         | 20+ event types              |
| Scope        | Agent-scoped or global     | Global or per-plugin         |

VS Code hooks: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PreCompact, SubagentStart, SubagentStop, Stop

OpenCode plugin events: tool.execute.before/after, session.created/idle/compacted, message.updated, permission.asked/replied, shell.env, file.edited, etc.

### Permissions

| Feature        | VS Code              | OpenCode                     |
| -------------- | -------------------- | ---------------------------- |
| Permission model | Default/Bypass/Autopilot | allow/ask/deny per tool   |
| Granular rules | Not configurable     | Object syntax with wildcards |
| Per-agent      | Via agent definition | Via agent `permission` block |

### Memory

| Feature        | VS Code                          | OpenCode          |
| -------------- | -------------------------------- | ------------------ |
| Local memory   | Yes (user/repo/session scopes)   | No built-in        |
| Cloud memory   | Copilot Memory (GitHub-hosted)   | No                  |
| Persistence    | `/memories/` directory           | N/A                 |

### Monitoring

| Feature        | VS Code                     | OpenCode          |
| -------------- | --------------------------- | ------------------ |
| OTel support   | Yes (traces, metrics, events) | Yes (OTLP export) |
| Exporters      | otlp-http, otlp-grpc, console, file | OTLP endpoint |

---

## Implications for This Repo

1. **Skills are compliant** — All 18 skills have valid `name` + `description` frontmatter matching the agentskills.io spec
2. **Consider `compatibility` field** — Some skills are OpenCode-specific (e.g., atlassian-mcp, chrome-devtools-mcp) and would benefit from noting tool requirements
3. **Consider `allowed-tools` field** — Skills that need specific tools (e.g., playwright-mcp needs browser tools) could declare them
4. **Progressive disclosure** — Skills with large reference files already follow this pattern (references/ subdirectories)
5. **Cross-tool discovery** — Skills in `~/.config/opencode/skills/` are automatically discovered by OpenCode; for VS Code Copilot discovery, symlink or copy to `.github/skills/`
