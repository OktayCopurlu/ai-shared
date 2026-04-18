---
name: debugging
description: "Structured debugging workflow: reproduce, localize, reduce, fix, guard. USE FOR: test failures, build breaks, unexpected behavior, runtime errors. Use when quality gates fail, a bug is reported, or behavior doesn't match expectations."
---

# Debugging — 5-Step Triage

Resist the urge to guess — follow the steps in order.

## The 5 Steps

### Step 1 — Reproduce
Reproduce the failure reliably before doing anything else. If you cannot reproduce, check environment differences, leftover state, or timing dependencies.
- **Exit:** You can trigger the failure on demand.

### Step 2 — Localize
Narrow where the failure originates. Bisect — do not read the entire codebase.

Pick the isolation technique that fits the situation:

| Technique | How | When to use |
|---|---|---|
| Binary search | Comment out or bypass half the code path, check if failure persists, repeat | Large codebase, unclear location |
| Input reduction | Simplify the input until the bug disappears, then add back the trigger | Complex inputs, data-dependent bugs |
| Dependency elimination | Mock or remove external deps one at a time | Could be in a dependency or integration |
| Version bisect | `git bisect` to find the commit that introduced the regression | Known-good prior state exists |
| Targeted logging | Add log statements at function entry/exit boundaries (not everywhere) | Need to trace runtime execution flow |

For unfamiliar code, use the `Explore` subagent to map module boundaries before diving in.
- **Exit:** You know which file, function, and roughly which lines cause the failure.

### Step 3 — Reduce
Create the simplest possible reproduction. Skip if the reproduction is already trivial.
- **Exit:** A minimal test case or snippet that demonstrates the bug clearly.

### Step 4 — Fix
Fix the root cause, not the symptom.
- Fix at the source — no workarounds downstream.
- Smallest correct change — do not bundle refactors with bug fixes.
- **Exit:** Reproduction passes. Full test suite passes. Root cause addressed.

### Step 5 — Guard
Prevent recurrence.
- Write a regression test that fails without the fix and passes with it.
- Commit the fix and guard together.
- **Exit:** A test guards against recurrence.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know what the bug is, let me just fix it" | Skipping reproduction means you might fix the wrong thing. |
| "It works on my machine" | Environment differences are bugs too. |
| "I'll just restart and try again" | Intermittent failures are real bugs — harder to find, not less important. |

## Red Flags

- Fixing without reproducing first
- Multiple "fix" attempts without localizing the root cause
- Bug fix committed without a regression test

## See Also

- `reviewing-code` — when debugging uncovers code quality issues for review
- `references/testing-patterns.md` — for writing effective regression tests
- `references/cognitive-debt.md` — when the bug is in agent-generated code you never read; run the walkthrough workflow before trying to localize
