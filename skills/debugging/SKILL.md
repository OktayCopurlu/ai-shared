---
name: debugging
description: "Structured debugging workflow: reproduce, localize, reduce, fix, guard. USE FOR: test failures, build breaks, unexpected behavior, runtime errors. Use when quality gates fail, a bug is reported, or behavior doesn't match expectations."
---

# Debugging — 5-Step Triage

Systematic approach to finding and fixing bugs. Resist the urge to guess — follow the steps.

## Philosophy

Bugs are information gaps — the code does something you didn't expect. Debugging closes that gap by narrowing the search space systematically. Guessing skips the narrowing and often fixes the wrong thing. The cost of reproducing and localizing always pays for itself.

## When to Use

- A test fails during quality gates
- A build breaks unexpectedly
- Runtime behavior doesn't match expectations
- A bug report needs investigation
- Something "just stopped working"

**When NOT to use:** Known issues with a documented fix. Cosmetic issues where the fix is obvious.

## The 5 Steps

### Step 1 — Reproduce

Before debugging anything, reproduce the failure reliably.

- Get the exact error message, stack trace, or unexpected output
- Determine the minimal steps to trigger the issue
- Note the environment: browser, Node version, OS, branch, dependencies
- If the failure is intermittent, identify conditions that make it more likely (timing, data, concurrency)

**Exit criteria:** You can trigger the failure on demand with specific steps.

If you cannot reproduce:
- Check if it's environment-specific (CI vs. local, Node version, OS)
- Check if it depends on state from a previous test or operation
- Check if it's timing-dependent (race conditions, async operations)

### Step 2 — Localize

Narrow down where the failure originates. Do not read the entire codebase — bisect.

**Strategies:**
- **Stack trace:** Follow the error trace to the originating file and line
- **Binary search:** Comment out half the code path, see if the failure persists, repeat
- **Git bisect:** `git bisect start`, `git bisect bad`, `git bisect good <commit>` — find the commit that introduced the bug
- **Console/log isolation:** Add targeted log statements at function boundaries, not everywhere
- **Diff comparison:** If it worked before, diff the current state against the last known good state
- **Explore subagent:** For unfamiliar code areas, use the `Explore` subagent to map the relevant module boundaries and call chains before diving in

**Exit criteria:** You know which file, function, and roughly which lines cause the failure.

### Step 3 — Reduce

Create the simplest possible reproduction of the bug.

- Strip away unrelated code, dependencies, and setup
- If it's a component issue, reproduce in isolation (unit test, minimal component)
- If it's an API issue, reproduce with a minimal request
- The reduced case should fail for exactly the same reason

**Why this matters:** Reduced cases reveal the root cause. Complex reproductions hide it.

**Exit criteria:** You have a minimal test case or code snippet that demonstrates the bug clearly.

### Step 4 — Fix

Fix the root cause, not the symptom.

- Fix at the source — not by adding workarounds downstream
- If the fix requires changing shared code, check the impact on other consumers
- Make the smallest correct change — do not bundle refactors with bug fixes
- Run the reproduction test to confirm the fix resolves the issue
- Run the full test suite to confirm no regressions

**Exit criteria:** The reproduction case passes. All existing tests pass. The fix addresses the root cause.

### Step 5 — Guard

Prevent the bug from recurring.

- Write a regression test that would have caught this bug (if one doesn't exist)
- The test should fail without the fix and pass with it
- If the bug was caused by missing validation, add the validation
- If the bug was caused by an assumption, document the assumption (or remove it)

**Exit criteria:** A test exists that fails without the fix. The fix and guard are committed together.

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
