# ExecPlan — Living Sections for Multi-Hour Work

A TodoWrite list tracks *what* to do. It does not capture *what surprised you* or *why you chose this approach over the alternative*. When a task spans several files and more than about an hour, keep an **ExecPlan**: a single markdown file that evolves as you work and is preserved in the PR.

## When to Keep an ExecPlan (Triggers)

Open one — not just a todo list — when **any** of these are true:

- The work is multi-step, spans several files, or is expected to take more than ~1 hour.
- A new feature, non-trivial refactor, migration, or cross-module change.
- You expect to hit unknowns that will shape the approach mid-way (perf tradeoffs, lib quirks, schema shape).
- A later reviewer (or future-you) will need to resume the task from the plan alone.

If you skip the ExecPlan on a qualifying task, state the reason in your response.

## Four Required Living Sections

Every ExecPlan has these four sections. They are updated **during** the work, not written at the end. The rest of the plan (Purpose, Context, Steps, Acceptance) is static.

### 1. Progress

Checkbox list with timestamps. Update at every pause.

```md
## Progress
- [x] (2026-04-21 10:12Z) Inventory current callers of `Foo.run()`.
- [x] (2026-04-21 11:03Z) Extract `run_loop` into `run_internal/`.
- [ ] Wire new streaming path and mirror non-streaming branch.
- [ ] Partial: migrate snapshot tests (done: 3; remaining: 7).
```

Rules:
- Timestamp completed items. "Partial" is allowed — spell out done/remaining.
- The next actionable item stays clearly unchecked before you pause.

### 2. Surprises & Discoveries

Unexpected behavior, perf notes, library quirks, or inverse/unapply semantics that changed the approach — captured *when you hit them*, with short evidence.

```md
## Surprises & Discoveries
- Observation: `session.rewind()` does not undo tool-execution side effects.
  Evidence: `tests/test_rewind.py::test_tool_side_effect` fails after rewind; log shows tool call persisted.
- Observation: pyright treats `TypedDict` total=False keys as required under strict mode.
  Evidence: `make typecheck` output excerpt.
```

Rules:
- Every entry must pair an observation with concrete evidence (test output, log line, diff, file path). No bare claims.
- If a discovery triggers an approach change, also log the reversal in Decision Log.

### 3. Decision Log

Each decision with **rationale** and date/author. Record the choice at the moment it is made — not retroactively.

```md
## Decision Log
- Decision: Keep positional argument order on `RunConfig`; append new `tool_budget` field at the end.
  Rationale: Public API positional compat contract; existing callers use positional form.
  Date/Author: 2026-04-21 / @you
- Decision: Rewrite unreleased schema v4 instead of migrating.
  Rationale: Not shipped in any release tag; no external consumers.
  Date/Author: 2026-04-21 / @you
```

Rules:
- Decisions that overturn earlier decisions must link to the earlier entry, not delete it.
- One decision per entry. If the rationale is longer than two sentences, move detail to an ADR and link it (see `documentation` skill).

### 4. Outcomes & Retrospective

Written at the end. Compares what shipped to the original Purpose, names remaining gaps, and lists lessons learned.

```md
## Outcomes & Retrospective
- Shipped: streaming/non-streaming parity for tool calls; `run_internal/` split.
- Gap: snapshot migration incomplete for `realtime_session` — tracked in #1234.
- Lesson: Mirror changes between `run_single_turn` and `run_single_turn_streamed` in the same commit; separating them regressed parity three times.
```

Rules:
- Write it before marking the task complete, not after the PR merges.
- Gaps must be linked to a follow-up ticket or labeled "won't do" with reason.

## Where the ExecPlan Lives

- Default: a single markdown file next to the code or under a dedicated plans directory (e.g. `docs/plans/<short-slug>.md`, `.agent/exec_plans/<id>.md`). Commit it with the work.
- For smaller work where a separate file is overkill, include the four sections in the PR description.
- Reference the plan path from the PR description so reviewers can follow the living history, not just the final diff.

## Anti-Patterns

- **Writing the retrospective first.** If Outcomes is filled in before the code is working, you are rationalizing, not reflecting.
- **Empty Surprises section on a non-trivial task.** Means surprises were not captured as they happened — they rarely show up if harvested later.
- **Decisions without rationale.** "Decided to use X" is not a log entry. The *why* is the whole point.
- **Letting Progress drift.** A stale Progress section is worse than none: it lies to the next contributor about the real state.
- **Merging the plan file as a throwaway.** Keep it so future work can resume from it.

## Red Flags

- Two consecutive sessions with no Progress update.
- A PR description that contradicts the ExecPlan's Outcomes section.
- Decision Log entries added only in the final commit (retroactive rationalization).
- The same surprise shows up in two different tasks because it was never captured the first time.

## See Also

- `documentation` skill — when a Decision Log entry deserves promotion to an ADR.
- `cognitive-debt` reference — for the comprehension gap that untracked decisions cause.
- `debugging` skill — Surprises & Discoveries overlaps with the localize/reduce phase.

## Sources

- OpenAI, `openai/openai-agents-python` — [AGENTS.md](https://github.com/openai/openai-agents-python/blob/main/AGENTS.md) and [PLANS.md](https://github.com/openai/openai-agents-python/blob/main/PLANS.md) define the ExecPlan skeleton and four living sections.
- `rogerlew/wepppy` — [AGENTS.md](https://github.com/rogerlew/wepppy/blob/main/AGENTS.md) — ExecPlan required for complex features; living sections must stay current.
- `Hanny658/vc-plan` — [AGENTS.md](https://github.com/Hanny658/vc-plan/blob/main/AGENTS.md) — session startup protocol built around the four sections.
- `poruru-code/hermes-gateway-proxy` — [AGENTS.md](https://github.com/poruru-code/hermes-gateway-proxy/blob/main/AGENTS.md) — living-document maintenance rule.
- `trevor-nichols/agentrules-architect` — [EP-20260313-001 archived plan](https://github.com/trevor-nichols/agentrules-architect/blob/main/.agent/exec_plans/archive/2026/03/13/EP-20260313-001_phase1-project-profile-agents/EP-20260313-001_phase1-project-profile-agents.md) — concrete example of the skeleton in use.
- `getsentry/sentry-cocoa` — [develop-docs/AGENTS.md](https://github.com/getsentry/sentry-cocoa/blob/main/develop-docs/AGENTS.md) — ADR-style `DECISIONS.md` with date, contributors, context, rationale, links.
