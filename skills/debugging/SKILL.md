---
name: debugging
description: "Structured debugging workflow: reproduce, localize, reduce, fix, guard. USE FOR: test failures, build breaks, unexpected behavior, runtime errors. Use when quality gates fail, a bug is reported, or behavior doesn't match expectations."
---

# Debugging — 5-Step Triage

Resist the urge to guess — follow the steps in order.

## The 5 Steps

### Step 1 — Reproduce
Reproduce the failure reliably before doing anything else.
- **Exit:** You can trigger the failure on demand with specific steps.
- If you cannot reproduce, check environment differences (CI vs. local), state from previous operations, or timing dependencies.

### Step 2 — Localize
Narrow where the failure originates. Bisect — do not read the entire codebase.
- Use targeted log statements at function boundaries, not everywhere.
- For unfamiliar code, use the `Explore` subagent to map module boundaries before diving in.
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
| "I know what the bug is, let me just fix it" | Skipping reproduction means you might fix the wrong thing. Reproduce first — it takes minutes. |
| "Adding a test for this is overkill" | The bug existed because there was no test. If it happened once, it can happen again. Guard it. |
| "Let me add some logs everywhere" | Scattershot logging wastes time. Localize first, then add targeted logs at the boundary. |
| "It works on my machine" | Environment differences are bugs too. Document what's different and fix the discrepancy. |
| "I'll just restart and try again" | Intermittent failures are real bugs. They're harder to find, not less important. |
| "The fix is too risky, let me work around it" | Workarounds become permanent. Fix the root cause now or file a ticket and fix it soon. |

## Red Flags

- Fixing without reproducing first
- Multiple "fix" attempts without localizing the root cause
- Workaround added without a follow-up ticket for the real fix
- Bug fix committed without a regression test
- Intermittent failure dismissed as "flaky" without investigation
- Stack trace not read — jumping to assumptions instead

## Verification

After completing the debugging workflow:

- [ ] The failure was reproduced reliably (Step 1)
- [ ] The root cause was localized to a specific file/function (Step 2)
- [ ] A minimal reproduction exists (Step 3, or skipped if trivial)
- [ ] The fix addresses the root cause, not a symptom (Step 4)
- [ ] A regression test guards against recurrence (Step 5)
- [ ] All existing tests pass
- [ ] The fix and test are committed together

## See Also

- `code-review` — when debugging uncovers code quality issues for review
- `references/testing-patterns.md` — for writing effective regression tests
