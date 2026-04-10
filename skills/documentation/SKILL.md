---
name: documentation
description: "Write and maintain technical documentation: ADRs, READMEs, inline docs, and wiki pages. USE FOR: writing ADRs, updating READMEs, documenting architecture decisions, creating onboarding docs. Use when a decision needs recording, a module needs documenting, or docs are stale."
---

# Documentation

Standards for writing clear, maintainable technical documentation.

## When to Use

- Recording an architecture or technology decision (ADR)
- Writing or updating a README for a module or service
- Documenting a non-obvious pattern, convention, or workaround
- Creating onboarding or setup guides
- Updating wiki pages after a significant change

**When NOT to use:** Inline code comments (use `coding-style`). Jira tickets (use `jira-ticket`). Confluence project pages (use `project-doc-expert` agent).

## ADR — Architecture Decision Record

Use ADRs for decisions that are hard to reverse, affect multiple teams, or will confuse future developers without context.

### Template

```markdown
# ADR-NNN: <Decision Title>

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN
**Date:** YYYY-MM-DD
**Deciders:** <who was involved>

## Context

What is the situation? What forces are at play?
State facts, not opinions. Include constraints, requirements, and relevant history.

## Decision

What are we doing and why?
Be specific — name the technology, pattern, approach, or convention.

## Consequences

### Positive
- What gets better?

### Negative
- What gets worse or harder?
- What trade-offs are we accepting?

### Neutral
- What changes but isn't clearly better or worse?

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Option A | Reason |
| Option B | Reason |
```

### ADR Rules

- Number sequentially: `ADR-001`, `ADR-002`, etc.
- Keep the decision section to 1-3 paragraphs
- Never delete an ADR — mark it `Deprecated` or `Superseded` and link the replacement
- Write consequences honestly — every decision has downsides

## README Standards

A module/service README should answer these questions in order:

1. **What is this?** — One sentence.
2. **Quick start** — How to run it locally (commands, not prose).
3. **Architecture** — How the pieces fit together (keep it brief, link to deeper docs).
4. **Development** — Commands for build, test, lint, deploy.
5. **Environment** — Required env vars, config files, secrets.
6. **Troubleshooting** — Common issues and fixes.

### README Rules

- Lead with the most useful information
- Use code blocks for commands — never describe a command in prose when you can show it
- Keep it current — stale docs are worse than no docs
- Link to deeper resources instead of duplicating them

## Writing Principles

### Clarity

- Use short sentences. One idea per sentence.
- Use concrete examples instead of abstract descriptions.
- "This function retries failed API calls up to 3 times with exponential backoff" beats "This function handles error recovery."

### Audience

- Assume the reader is a competent developer who is new to this specific codebase.
- Do not explain language fundamentals. Do explain project-specific conventions.

### Maintenance

- Date your docs. Add a "Last updated" line to guides that drift.
- Prefer linking to canonical sources over copying content.
- When you change behavior, update the docs in the same PR.

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
