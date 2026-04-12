---
name: tdd
description: "Test-driven development: write failing test, make it pass, refactor. USE FOR: implementing new functions, fixing bugs with regression tests, adding behavior to existing code. Use when writing tests before code or when asked to TDD a feature."
---

# Test-Driven Development

Write the test first. Make it pass. Clean up. Repeat.

## The Cycle: Red → Green → Refactor

### Red — Write a failing test
- Test **one behavior** per test
- Name with expected behavior, not implementation: `'returns discounted price for a valid code'` not `'calls calculateTotal'`
- Do not use "should" — it adds words without meaning
- Run the test — confirm it fails for the right reason (not a syntax error)

### Green — Make it pass
- Write the minimum code to pass. Nothing more.
- Do not add code that isn't required by a failing test.

### Refactor — Clean up
- Improve naming, remove duplication, extract helpers
- Tests stay green throughout
- Run tests after each refactor step

## Your Rules

- `describe` block: the unit being tested (function, composable, component)
- `it` block: behavior in plain English — "returns X when Y", "throws when Z"
- Test priority: happy path → edge cases → error cases → integration points (sparingly)
- Each test sets up its own data — no shared mutable state
- Mock external dependencies (API calls, timers) — not internal modules

## Bug Fix TDD

1. Write a test that reproduces the bug (Red)
2. Confirm it fails for the same reason
3. Fix the bug (Green)
4. Confirm the test passes
5. Refactor if needed

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.**

```
WRONG (horizontal):   test1, test2, test3 → impl1, impl2, impl3
RIGHT (vertical):     test1→impl1 → test2→impl2 → test3→impl3
```

Each cycle should respond to what you learned from the previous one.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll write tests after the implementation" | Tests written after tend to test the implementation, not the behavior. Write first for better design. |
| "TDD is too slow" | TDD is slower per line of code. It's faster per shipped feature because you catch bugs immediately. |
| "I need to see the implementation first to know what to test" | If you can't describe the expected behavior, you're not ready to implement. |
| "This is too simple to need TDD" | Simple functions are the easiest to TDD. Start here to build the habit. |
| "Mocking everything makes tests brittle" | Mock boundaries (APIs, filesystem), not internals. TDD naturally pushes toward better boundaries. |

## Red Flags

- Test written after the implementation and only tests the happy path
- Test name describes implementation ("calls calculateTotal") instead of behavior ("returns correct total")
- Multiple behaviors tested in one test
- Shared mutable state between tests
- Test passes but doesn't fail when the feature code is removed
- Skipping the refactor step

## Verification

After a TDD cycle:

- [ ] Test was written before the implementation code
- [ ] Test failed for the right reason (Red)
- [ ] Implementation is minimal — only what the test requires (Green)
- [ ] Code was cleaned up without changing behavior (Refactor)
- [ ] All tests still pass after refactoring
- [ ] Test names describe behavior, not implementation

## See Also

- `references/testing-patterns.md` — test structure, anti-patterns, Vue component testing
- `debugging` — bug fix TDD overlaps with Step 5 (Guard)
- `coding-style` — naming, formatting, and change discipline for test files
