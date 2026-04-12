# ai-shared — Central AI Configuration

This folder is the single source of truth for all AI agent configuration — skills, prompts, agents, and global instructions. Other tools (Copilot, Codex, OpenCode) consume this via symlinks.

## Structure

```
~/.ai-shared/
├── instructions.md       # Global rules (verification, decisions, quality)
├── skills/               # Reusable domain skills (loaded on demand)
│   ├── a11y-audit/             # Build & review UI for accessibility
│   ├── amplitude-analytics/    # Query Amplitude analytics data
│   ├── atlassian-mcp/          # Jira + Confluence via MCP
│   ├── chrome-devtools-mcp/    # Debug runtime issues via DevTools
│   ├── code-review/            # 4-layer heuristic code review
│   ├── coding-style/           # Personal code writing standards
│   ├── contentful/             # Read Contentful CMS (MCP + CLI)
│   ├── debugging/              # 5-step bug triage workflow
│   ├── documentation/          # ADRs, READMEs, technical docs
│   ├── git-workflow/           # Full git & PR pipeline
│   ├── github-mcp/             # GitHub operations via MCP
│   ├── google-drive/           # Fetch Google Sheets/Docs
│   ├── jira-ticket/            # Write, review, update tickets
│   ├── playwright-mcp/         # Browser automation via Playwright
│   ├── security-hardening/     # OWASP, auth, secrets, dependencies
│   ├── tdd/                    # Test-driven development cycle
│   └── ui-validation/          # Browser-level UI validation
├── agents/               # Custom agent modes
│   ├── devils-advocate.agent.md
│   ├── goal-setter.agent.md
│   ├── profile-writer.agent.md
│   ├── project-doc-expert.agent.md
│   └── research.agent.md
├── prompts/              # Slash-command prompts (development lifecycle)
│   ├── spec.prompt.md              # Define — clarify what to build
│   ├── solution-design.prompt.md   # Plan — technical design
│   ├── implementation.prompt.md    # Build — implement a ticket
│   ├── start-working.prompt.md     # Build — full delivery workflow
│   ├── address-review.prompt.md    # Ship — triage review comments
│   ├── test.prompt.md              # Test — run or write tests
│   ├── refine-ticket.prompt.md     # Define — pre-refinement review
│   └── update-project-page.prompt.md # Ship — update Confluence
├── references/           # Shared checklists (referenced by skills)
│   ├── accessibility-checklist.md
│   ├── performance-checklist.md
│   ├── security-checklist.md
│   └── testing-patterns.md
├── docs/                 # Contributor documentation
│   └── skill-anatomy.md         # Format spec for writing skills
└── research/             # Research-specific skills
    └── skills/
```

## Symlinks

All tools point back here. **Never edit the symlinked copies — always edit the source in `~/.ai-shared/`.**

| Source (ai-shared)    | Symlink target                                     | Tool            | Notes                                                                                                                         |
| --------------------- | -------------------------------------------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `instructions.md`     | `~/.github/copilot-instructions.md`                | VS Code Copilot | Auto-loaded every conversation                                                                                                |
| `instructions.md`     | `~/.codex/instructions.md`                         | Codex           | Auto-loaded every conversation                                                                                                |
| `instructions.md`     | `~/.config/opencode/AGENTS.md`                     | OpenCode        | Global rules file; OpenCode reads `AGENTS.md` not `instructions.md`                                                           |
| `skills/`             | `~/.copilot/skills/`                               | VS Code Copilot | Directory symlink; skills loaded on demand via `<skills>` block                                                               |
| `skills/*`            | `~/.codex/skills/*` (per-skill symlinks)           | Codex           | Requires per-skill symlinks; no directory symlink support                                                                     |
| `skills/`             | `~/.config/opencode/skills/`                       | OpenCode        | Directory symlink; on-demand loading                                                                                          |
| `agents/`             | `~/.copilot/agents/`                               | VS Code Copilot | Copilot + OpenCode; Codex does not support custom agents                                                                      |
| `agents/`             | _(not symlinked)_                                  | OpenCode        | **Not compatible** — OpenCode agents require different frontmatter (`mode`, `model`, `permission` object) and `.md` extension |
| `prompts/`            | `~/Library/Application Support/Code/User/prompts/` | VS Code Copilot | Slash-command prompts; VS Code reads from its own user data folder                                                            |
| `prompts/`            | `~/.codex/prompts/`                                | Codex           | Slash-command prompts                                                                                                         |
| `prompts/*.prompt.md` | `~/.config/opencode/commands/*.md` (per-file)      | OpenCode        | Renamed symlinks; `implementation.prompt.md` → `/implementation`                                                              |
| `research/skills/`    | `~/.copilot/research/skills/`                      | VS Code Copilot | Copilot only — research agent skills                                                                                          |

## Rules for agents

- **Creating/updating skills, prompts, or agents**: always write to `~/.ai-shared/...` — symlinks propagate automatically.
- **Adding a new skill**: create `~/.ai-shared/skills/<name>/SKILL.md`, then add a per-skill symlink to `~/.codex/skills/`.
- **Global instructions**: edit `~/.ai-shared/instructions.md` — all tools pick up changes.
- This folder is git-tracked. Commit changes to preserve them.

## Skill authoring checklist

There are two skill families in this repo:

1. **Workflow skills** — process-heavy skills like `debugging`, `code-review`, `tdd`, `git-workflow`
2. **Tool skills** — tool-adapter skills like `contentful`, `playwright-mcp`, `atlassian-mcp`

Every skill SKILL.md must have:

1. **YAML frontmatter** with `name` and `description` (description includes trigger phrases)
2. **An H1 title**
3. **At least one substantive H2 section** — for example `When to Use`, `Procedure`, `Tool Selection`, `Rules`, or `Guardrails`
4. **Clear activation guidance** — either an explicit `When to Use` section or equivalent trigger language in the description/body

Workflow skills should usually also have:

1. **Common Rationalizations**
2. **Red Flags**
3. **Verification**
4. **See Also**

Tool skills may use a leaner format when that is clearer. For those, `Tool Selection`, `Procedure`, `Rules`, and mutation guardrails are often more useful than forcing the full workflow template.

See [docs/skill-anatomy.md](docs/skill-anatomy.md) for the full format spec with examples.

## Validation

Run `./validate.sh` after making changes to catch broken symlinks, missing frontmatter, minimum skill structure issues, empty files, and duplicate names.
