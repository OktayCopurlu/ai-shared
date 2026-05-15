# Subagent-Driven Development

Use this when a task plan has more than one independent slice and the parent context is at risk of getting crowded with exploration noise, partial implementations, or unrelated tool output.

The pattern: each slice runs in a fresh subagent with a narrow brief, the parent stays clean, and every slice goes through a two-stage review before its work is accepted.

This is a pattern, not a workflow you need to run end-to-end every time. Pull only the parts that reduce real risk for the current task.

## When to Use

- The plan has 3+ independently buildable slices.
- Slices touch different files or layers and can run in parallel.
- The parent conversation is already large or will be after exploration.
- You want each slice reviewed before it influences the next one.

## When Not to Use

- Single-file change or a bugfix that fits one clean pass.
- Slices share so much state that fresh context would hurt more than it helps.
- The work is exploratory and the plan itself is still moving.

## Core Idea

A subagent is a fresh, narrowly-scoped agent invocation that:

- starts with the slice brief, the relevant files, and nothing else from the parent's chat history
- writes only what the slice requires
- returns a concise summary the parent can act on, not its full transcript

The parent stays in the planning and review role. It does not re-implement the slice or copy the subagent's full output into its own context.

## Slice Brief

Each subagent dispatch must include:

1. **Goal**: one sentence describing what this slice produces.
2. **Inputs**: the files, types, fixtures, or APIs the slice can read.
3. **Allowed writes**: the exact files or directories the slice is allowed to create or modify.
4. **Out of scope**: what the slice must not touch (other slices, unrelated refactors, dependency upgrades).
5. **Definition of done**: tests pass, behavior verified, lint clean — and any slice-specific evidence the reviewer needs.
6. **Return contract**: what the subagent reports back — usually a short summary, a list of changed files, and any open questions.

If any of these are missing, the parent is not ready to dispatch yet. Sharpen the plan first.

## Two-Stage Review

Every slice goes through two reviews before its work is accepted. They are different lenses and should not be collapsed into one pass.

### Stage 1 — Spec compliance

Question: does the slice do exactly what the brief said, and only that?

Check:

- the goal was met
- only allowed writes happened
- nothing in the out-of-scope list was touched
- the definition of done is satisfied with evidence
- the return contract was honored

Stage 1 is binary. If the answer is no, the slice goes back for correction before Stage 2 runs. Do not let code-quality polish hide a spec drift.

### Stage 2 — Code quality

Run the `reviewing-code` 4-layer heuristic against the slice's diff: surface correctness, test coverage, bounded refactor signals, and architecture attention signals. Layer 4 surfaces questions only — do not turn them into directives inside the slice.

Code-quality issues that block: failing tests, missing coverage for the slice's invariants, lint errors, secrets, debug noise.

Code-quality issues that do not block but should be flagged: bounded refactor opportunities outside the slice, architecture signals worth a wider conversation.

## Parallel vs Sequential

Run slices in parallel when:

- they touch disjoint files
- they share no in-flight types or fixtures
- their definition-of-done evidence does not depend on another slice landing first

Run slices sequentially when:

- one slice's types, schemas, or APIs are consumed by the next
- merging order matters for review or rollback
- a slice's failure would invalidate other in-flight work

When in doubt, sequential. Parallel slices that turn out to be coupled produce nasty merge and review surprises.

## Anti-Patterns

| Anti-pattern | Why it's bad |
|---|---|
| Dispatching a slice without an explicit allowed-writes list | The subagent edits unrelated files because nothing said it could not. |
| Skipping Stage 1 because the code looks good | Code quality polish hides spec drift; the slice ships the wrong thing well. |
| Re-implementing the slice in the parent because the subagent's diff is "almost right" | The parent context now contains both versions and review confidence drops. |
| Letting the subagent dump its full transcript back to the parent | The parent's context fills with exploration noise the planner did not need. |
| Running slices in parallel that share a schema or new type | Merge conflicts and contradicting designs land in two places at once. |
| Using a fresh subagent for a 10-line change | Overhead exceeds benefit; just do the change inline. |

## See Also

- `references/work-shaping.md` — vertical slicing and fresh-context principles this pattern builds on
- `skills/reviewing-code/SKILL.md` — the 4-layer review used in Stage 2
- `skills/test-driven-development/SKILL.md` — red/green/refactor inside each slice
- `prompts/zoom-out.prompt.md` — quick system-context map before dispatching slices that touch unfamiliar code
