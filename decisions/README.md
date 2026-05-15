# Decision Journal

Append-only log of non-trivial personal technical decisions. One file per year (e.g. `2026.md`).

Format and philosophy: see `~/.ai-shared/references/decision-journal.md`.

## Quick Format Reminder

```
2026-05-15 — Picked Zustand for state management (project: X)
- Context: form-heavy app, small team, no SSR
- Alternatives: Redux (boilerplate too heavy), Context (perf risk on deep trees)
- Trade-off: smaller ecosystem
- Revisit: if state shape gets gnarly or team doubles
```

Five fields: **What / Context / Alternatives / Trade-off / Revisit.** The last one is the most valuable — decisions decay when their context changes.

## Privacy

These entries are personal. If `~/.ai-shared` is ever shared or made public, consider gitignoring `decisions/*.md` (keep this README tracked).
