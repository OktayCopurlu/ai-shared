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
