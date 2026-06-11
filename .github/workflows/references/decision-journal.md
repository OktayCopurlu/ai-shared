# Decision Journal — Lightweight ADR for Yourself

Append-only log of non-trivial technical decisions: the *why*, the alternatives you rejected, the trade-off you accepted, and when to revisit. Not a full ADR — those go in the project repo when the decision is team-wide. This is your personal "future-me, here is what past-me was thinking."

Full log lives at: `~/.ai-shared/decisions/{year}.md` (one file per year, append-only).

## Entry Format

~5 lines per entry. Aim for "could I reconstruct my reasoning 6 months from now?" — not "could a stranger audit this?"

```
2026-05-15 — Picked Zustand for state management (project: X)
- Context: form-heavy app, small team, no SSR
- Alternatives: Redux (boilerplate too heavy for our size), Context (perf risk on deep trees)
- Trade-off: smaller ecosystem, but enough for our needs
- Revisit: if state shape gets gnarly or team doubles in size
```

## When to Log a Decision

- **Picked one tool / library / pattern over another** when more than one was viable.
- **Took a deliberate shortcut** ("good enough for now"). Log the cost, so you know what you owe later.
- **Said no to a request or pattern.** The reason will fade; capture it.
- **Designed an interface, contract, or boundary** that other code will rely on.
- **Diverged from a team convention or industry default.** You will be asked why.

## When NOT to Log

- Obvious / forced choices (only one viable option, framework default, etc.).
- Routine code-level decisions (variable naming, file location). The code itself is the record.
- Decisions that already have a full ADR / RFC elsewhere — link to it instead of re-writing.

## The Five Fields

1. **What** — the decision in one sentence.
2. **Context** — what made this decision necessary (constraints, scale, team, deadline).
3. **Alternatives** — what else was on the table and why each was rejected. Keep it to bullets.
4. **Trade-off** — what you knowingly gave up to get the thing you wanted.
5. **Revisit** — the condition or date when this decision should be re-examined.

The "Revisit" field is the most under-used and most valuable. Decisions decay — they were correct under conditions that may no longer hold.

## Cadence

- **At the moment of decision** — not later. The reasoning is freshest now and will not survive a week of context-switching.
- **Quarterly scan (10 min):** read the year's file, mark anything where the "Revisit" condition has been met. Either ratify, replace, or write a follow-up entry.
- **Before a big refactor / migration:** scan the relevant past entries. You may find you are about to redo a decision you already made.

## Why Not Full ADRs in Confluence

Full ADRs are great when the team owns the decision. This journal is for *your* decisions — the ones too small for a Confluence page but too consequential to forget. When one of these grows into a team-level decision, promote it: copy the entry into a proper ADR, link back.
