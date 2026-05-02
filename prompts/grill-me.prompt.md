---
description: "Interview the user to reach shared understanding before writing a spec or plan. Use when requirements are fuzzy, broad, or full of hidden product decisions."
---

# Grill Me — Alignment Interview

Use this before `spec` when the request is still rough, strategically important, or likely to hide product, design, architecture, rollout, or testing decisions.

Do not use this for a small ticket with clear acceptance criteria, a single-file bugfix, or a task where the next implementation step is already obvious. In those cases, continue directly to `spec` or `implementation`.

The goal is not to produce a plan yet. The goal is to reach shared understanding.

## Process

1. Restate the problem in one short paragraph.
2. If repo context matters, use a read-only exploration pass or subagent and summarize only the relevant constraints.
3. Ask one question at a time.
4. For every question, include:
   - the decision being made
   - the recommended answer
   - the trade-off behind the recommendation
5. Walk the design tree in dependency order: goal, users, scope, data, UX, failure states, rollout, analytics, testing, and non-goals.
6. When an answer requires a PM, designer, domain expert, or team decision, say so clearly and mark it as unresolved.
7. Stop when remaining questions would not materially change the first vertical implementation slice.

## Output

When alignment is reached, summarize:

- **Decisions made**
- **Open questions**
- **Out of scope**
- **Recommended next step**: usually `spec`, `solution-design`, or a prototype/investigation

Do not write the full spec unless the user asks you to continue into `spec`.

## Guardrails

- Do not ask a batch of questions unless the user asks for a questionnaire.
- Do not stretch the interview once the next useful slice is clear.
- Do not invent answers for product or domain decisions.
- Do not rush to planning while core assumptions are still unresolved.
- Do not optimize the final plan during this step; alignment comes first.
