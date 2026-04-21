# ai-shared — Central AI Configuration

This folder is the single source of truth for all AI agent configuration — skills, prompts, agents, and global instructions. Other tools (Copilot, Codex, OpenCode) consume this via symlinks.

## Dependency Graph

How components connect — prompts trigger skills, skills reference each other, references serve as shared checklists.

```mermaid
graph LR
  %% ── Styles ──────────────────────────────────────────
  classDef prompt fill:#6366f1,stroke:#4f46e5,color:#fff
  classDef skill fill:#10b981,stroke:#059669,color:#fff
  classDef agent fill:#f59e0b,stroke:#d97706,color:#fff
  classDef ref fill:#94a3b8,stroke:#64748b,color:#fff
  classDef core fill:#ef4444,stroke:#dc2626,color:#fff

  %% ── Core ────────────────────────────────────────────
  INST[instructions.md]:::core

  %% ── Prompts (development lifecycle) ─────────────────
  P_SPEC[/spec/]:::prompt
  P_REFINE[/refine-ticket/]:::prompt
  P_SOLUTION[/solution-design/]:::prompt
  P_IMPL[/implementation/]:::prompt
  P_START[/start-working/]:::prompt
  P_TEST[/test/]:::prompt
  P_PR[/pr/]:::prompt
  P_REVIEW[/address-review/]:::prompt
  P_REVIEWPR[/review-pr/]:::prompt
  P_SPRINT[/sprint-review/]:::prompt
  P_UPDATE[/update-project-page/]:::prompt

  %% ── Skills ──────────────────────────────────────────
  S_STYLE([applying-coding-style]):::skill
  S_REVIEW([reviewing-code]):::skill
  S_GIT([git-workflow]):::skill
  S_DEBUG([debugging]):::skill
  S_TDD([test-driven-development]):::skill
  S_A11Y([a11y-audit]):::skill
  S_UIVAL([validating-ui]):::skill
  S_SEC([security-hardening]):::skill
  S_DOC([documentation]):::skill
  S_JIRA([jira-ticket]):::skill
  S_EVOLVE([skill-evolution]):::skill
  S_PW([playwright-mcp]):::skill
  S_CHROME([chrome-devtools-mcp]):::skill
  S_AMP([amplitude-analytics]):::skill
  S_ATLAS([atlassian-mcp]):::skill
  S_GH([github-mcp]):::skill
  S_CTF([contentful]):::skill
  S_GDRIVE([google-drive]):::skill

  %% ── Agents ──────────────────────────────────────────
  A_DEVIL{{devils-advocate}}:::agent
  A_GOAL{{goal-setter}}:::agent
  A_PROFILE{{profile-writer}}:::agent
  A_PROJDOC{{project-doc-expert}}:::agent
  A_RESEARCH{{research}}:::agent

  %% ── References ──────────────────────────────────────
  R_TEST[\testing-patterns\]:::ref
  R_A11Y[\accessibility-checklist\]:::ref
  R_PERF[\performance-checklist\]:::ref
  R_SEC[\security-checklist\]:::ref
  R_SEARCH[\search-first\]:::ref
  R_COG[\cognitive-debt\]:::ref
  R_ON[\on-frontend-urls\]:::ref

  %% ── Prompt → Skill / Agent / Reference ─────────────
  P_SPEC -. See Also .-> P_SOLUTION
  P_SPEC -. See Also .-> P_REFINE
  P_SPEC -. See Also .-> S_JIRA
  P_REFINE --> S_JIRA
  P_SOLUTION --> A_PROJDOC
  P_START --> P_IMPL
  P_IMPL --> S_STYLE
  P_IMPL --> S_A11Y
  P_IMPL --> S_UIVAL
  P_IMPL --> R_SEARCH
  P_TEST --> S_TDD
  P_TEST --> S_STYLE
  P_TEST --> R_TEST
  P_PR --> S_GIT
  P_REVIEW --> S_REVIEW
  P_REVIEWPR --> S_REVIEW
  P_REVIEWPR --> S_UIVAL
  P_REVIEWPR --> S_ATLAS
  P_REVIEWPR --> S_GH
  P_REVIEWPR --> S_PW
  P_REVIEWPR --> S_CHROME
  P_REVIEWPR -. optional .-> S_A11Y

  %% ── Skill → Skill ──────────────────────────────────
  S_REVIEW --> S_STYLE
  S_GIT --> S_REVIEW
  S_GIT --> S_STYLE
  S_GIT -. See Also .-> S_DEBUG
  S_DEBUG -. See Also .-> S_REVIEW
  S_DEBUG -. See Also .-> R_TEST
  S_DEBUG -. See Also .-> R_COG
  S_TDD -. See Also .-> S_DEBUG
  S_TDD -. See Also .-> S_STYLE
  S_TDD -. See Also .-> R_TEST
  S_UIVAL -. See Also .-> S_A11Y
  S_UIVAL -. See Also .-> S_PW
  S_UIVAL -. See Also .-> S_CHROME
  S_UIVAL -. See Also .-> S_AMP
  S_UIVAL -. See Also .-> R_PERF
  S_PW -. See Also .-> R_ON
  S_CHROME -. See Also .-> R_ON
  S_A11Y -. See Also .-> S_REVIEW
  S_A11Y -. See Also .-> S_UIVAL
  S_A11Y -. See Also .-> R_A11Y
  S_REVIEW -. See Also .-> R_A11Y
  S_REVIEW -. See Also .-> R_COG
  S_REVIEW -. See Also .-> R_PERF
  S_STYLE -. See Also .-> R_TEST
  S_SEC -. See Also .-> S_REVIEW
  S_SEC -. See Also .-> R_SEC
  S_DOC -. See Also .-> S_STYLE
  S_DOC -. See Also .-> S_JIRA
  S_DOC -. See Also .-> S_GIT
  S_EVOLVE -. See Also .-> S_STYLE
  S_EVOLVE -. See Also .-> R_COG
```

**Legend:** <span style="color:#ef4444">■</span> Core · <span style="color:#6366f1">■</span> Prompts · <span style="color:#10b981">■</span> Skills · <span style="color:#f59e0b">■</span> Agents · <span style="color:#94a3b8">■</span> References — solid arrows = loads/uses, dashed arrows = See Also

## Structure

```
~/.ai-shared/
├── instructions.md       # Global rules (verification, decisions, quality)
├── skills/               # Reusable domain skills (loaded on demand)
│   ├── a11y-audit/             # Build & review UI for accessibility
│   ├── amplitude-analytics/    # Query Amplitude analytics data
│   ├── atlassian-mcp/          # Jira + Confluence via MCP
│   ├── applying-coding-style/  # Personal code writing standards
│   ├── chrome-devtools-mcp/    # Debug runtime issues via DevTools
│   ├── contentful/             # Read Contentful CMS (MCP + CLI)
│   ├── debugging/              # 5-step bug triage workflow
│   ├── documentation/          # ADRs, READMEs, technical docs
│   ├── git-workflow/           # Full git & PR pipeline
│   ├── github-mcp/             # GitHub operations via MCP
│   ├── google-drive/           # Fetch Google Sheets/Docs
│   ├── jira-ticket/            # Write, review, update tickets
│   ├── playwright-mcp/         # Browser automation via Playwright
│   ├── reviewing-code/         # 4-layer heuristic code review
│   ├── security-hardening/     # OWASP, auth, secrets, dependencies
│   ├── skill-evolution/        # Learn, stage, codify reusable skills
│   ├── test-driven-development/ # Test-driven development cycle
│   └── validating-ui/          # Browser-level UI validation
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
│   ├── pr.prompt.md                # Ship — commit, push, create PR
│   ├── address-review.prompt.md    # Ship — triage review comments
│   ├── review-pr.prompt.md         # Review — full PR review against ticket
│   ├── test.prompt.md              # Test — run or write tests
│   ├── refine-ticket.prompt.md     # Define — pre-refinement review
│   ├── sprint-review.prompt.md     # Report — generate and email sprint review PDFs
│   └── update-project-page.prompt.md # Ship — update Confluence
├── references/           # Shared checklists (referenced by skills)
│   ├── accessibility-checklist.md
│   ├── cognitive-debt.md
│   ├── error-messages.md
│   ├── on-frontend-urls.md
│   ├── performance-checklist.md
│   ├── search-first.md
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
- **Adding a new prompt**: create `~/.ai-shared/prompts/<name>.prompt.md`, then run `./setup.sh` so OpenCode per-command symlinks are refreshed.
- **Adding a new skill**: create `~/.ai-shared/skills/<name>/SKILL.md`, then add a per-skill symlink to `~/.codex/skills/`.
- **Global instructions**: edit `~/.ai-shared/instructions.md` — all tools pick up changes.
- This folder is git-tracked. Commit changes to preserve them.

## Skill authoring checklist

There are two skill families in this repo:

1. **Workflow skills** — process-heavy skills like `debugging`, `reviewing-code`, `test-driven-development`, `git-workflow`
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

## Secrets

This repo is **public**. Never commit credentials, tokens, or passwords directly in skill/agent/prompt files.

Secrets are stored in a local `.secrets` file in `~/.ai-shared/.secrets`, which is gitignored. This is the shared AI config repo, not the target project workspace. Skills should reference this path explicitly so agents do not look for secrets in the app repo they are currently editing.

**After cloning, create your own `.secrets` file:**

```bash
cp .secrets.example .secrets
# Edit .secrets with your actual values
```

Format (`KEY=VALUE`, one per line):

```
STAGING_USER=...
STAGING_PASS=...
```

When writing or updating skills that need credentials, reference `~/.ai-shared/.secrets` with variable names — never hardcode values.

## Validation

Run `./validate.sh` after making changes to catch broken symlinks, missing frontmatter, minimum skill structure issues, empty files, and duplicate names.

When you add a new prompt or skill, run:

```bash
./setup.sh
./validate.sh
```
