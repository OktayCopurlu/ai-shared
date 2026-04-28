---
name: documentation
description: 'Write and maintain technical documentation: ADRs, READMEs, inline docs, and wiki pages. USE FOR: writing ADRs, updating READMEs, documenting architecture decisions, creating onboarding docs. Use when a decision needs recording, a module needs documenting, or docs are stale. NOT FOR: Jira ticket writing (jira-ticket), or code comments and naming conventions (applying-coding-style).'
---

# Documentation

Standards for technical documentation in this project.

## ADR Rules

- Never delete an ADR — mark it `Deprecated` or `Superseded` and link the replacement
- Write consequences honestly — every decision has downsides
- If you debated a decision for more than 10 minutes, it deserves an ADR

## README Standards

A module/service README answers: What is this? → Quick start → Architecture → Development → Environment → Troubleshooting. Lead with the most useful info, use code blocks for commands, link instead of duplicating.

## Writing Rules

- Date your docs — add "Last updated" to guides that drift.
- Update docs in the same PR as the behavior change.
- Link to canonical sources instead of copying content.

## Maintenance Matrix

A maintenance matrix maps change dependencies: "when X changes, also update Y." Without one, contributors (human or agent) miss co-dependent files and leave docs, configs, or registrations stale.

**When to create one:** Any project with cross-file registration patterns (routes, module re-exports, config files, feature flags, shared types consumed by multiple packages).

**Format:** A table in the project's `AGENTS.md`, `copilot-instructions.md`, or a dedicated `CONTRIBUTING.md` section:

| Change Made | Files to Update |
|---|---|
| New API route added | `src/routes/index.ts`, route tests, OpenAPI spec, README API section |
| New shared component | Component file, barrel export, Storybook story, component docs |
| Environment variable added | `.env.example`, deployment config, CI workflow, README setup section |
| Database schema changed | Migration file, ORM model, seed data, affected API handlers and their tests |
| Dependency added/removed | `package.json`, lockfile, CI cache config, license check if OSS |

**Rules for the matrix:**
- List real file paths, not categories — agents need exact targets
- Include tests and docs alongside source files — these are the most commonly forgotten
- Keep it next to the build/test instructions so agents find it early
- Update the matrix itself when the project structure changes

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The code is self-documenting" | Code says what, not why. Decisions and trade-offs still need docs. |
| "I'll just put it in Slack" | Slack is write-only memory. Put it where the next person will look. |

## Red Flags

- Architecture decision made with no written record
- README with outdated commands
- Setup guide requires tribal knowledge not written anywhere

## See Also

- `applying-coding-style` — inline comment and naming standards
- `jira-ticket` — ticket writing standards (not the same as docs)
- `git-workflow` — PR descriptions are a form of documentation
- `~/.ai-shared/references/writing-style.md` — prose quality rules for all agent-written text
- `~/.ai-shared/references/search-first.md` — the "Before Renaming or Removing" section complements the maintenance matrix
