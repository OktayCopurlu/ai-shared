---
name: documentation
description: "Write and maintain technical documentation: ADRs, READMEs, inline docs, and wiki pages. USE FOR: writing ADRs, updating READMEs, documenting architecture decisions, creating onboarding docs. Use when a decision needs recording, a module needs documenting, or docs are stale."
---

# Documentation

Standards for technical documentation in this project.

## ADR Rules

Use ADRs for decisions that are hard to reverse, affect multiple teams, or will confuse future developers.

- Use standard ADR format: Context → Decision → Consequences → Alternatives Considered
- Number sequentially: `ADR-001`, `ADR-002`, etc.
- Keep the decision section to 1-3 paragraphs
- Never delete an ADR — mark it `Deprecated` or `Superseded` and link the replacement
- Write consequences honestly — every decision has downsides (positive, negative, neutral)

## README Standards

A module/service README answers these questions in order:

1. **What is this?** — One sentence.
2. **Quick start** — How to run it locally (commands, not prose).
3. **Architecture** — How pieces fit together (brief, link deeper docs).
4. **Development** — Commands for build, test, lint, deploy.
5. **Environment** — Required env vars, config files, secrets.
6. **Troubleshooting** — Common issues and fixes.

Rules: lead with the most useful info, use code blocks for commands, keep current, link instead of duplicating.

## Writing Rules

- Date your docs — add "Last updated" to guides that drift.
- Update docs in the same PR as the behavior change.
- Link to canonical sources instead of copying content.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The code is self-documenting" | Code says what it does, not why. Decisions, trade-offs, and context still need docs. |
| "I'll write the docs after the feature ships" | Post-ship docs rarely happen. Write alongside the code. |
| "Nobody reads docs anyway" | People read docs when they're stuck. That's exactly when docs matter most. |
| "An ADR is overkill for this" | If you debated the decision for more than 10 minutes, it deserves an ADR. |
| "I'll just put it in Slack" | Slack is write-only memory. Docs persist. Put it where the next person will look. |

## Red Flags

- Architecture decision made with no written record
- README has a "Getting Started" section with outdated commands
- Docs reference removed features or deprecated APIs
- Inline comments explain "what" instead of "why"
- Setup guide requires tribal knowledge not written anywhere

## Verification

After writing documentation:

- [ ] A new reader could follow the doc without asking questions
- [ ] Commands in the doc actually work when copy-pasted
- [ ] No stale references to removed features or old APIs
- [ ] ADR includes consequences (positive and negative)
- [ ] Links point to real, accessible resources

## See Also

- `coding-style` — inline comment and naming standards
- `jira-ticket` — ticket writing standards (not the same as docs)
- `git-workflow` — PR descriptions are a form of documentation
