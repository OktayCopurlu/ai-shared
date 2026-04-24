---
name: test-driven-development
description: 'Test-driven development: write failing test, make it pass, refactor. USE FOR: implementing new functions, fixing bugs with regression tests, adding behavior to existing code. Use when writing tests before code or when asked to TDD a feature. NOT FOR: debugging existing failures without writing new code (debugging), or reviewing test coverage in existing code (reviewing-code layer 2).'
---

# Test-Driven Development

Write the test first. Make it pass. Clean up. Repeat.

## The Cycle: Red → Green → Refactor

- **Red**: Write one failing test for one behavior. Run it — confirm it fails for the right reason, not a syntax error.
- **Green**: Write the minimum code to pass. Nothing more.
- **Refactor**: Improve naming, remove duplication. Tests stay green throughout.

## Your Rules

- `describe` block: the unit being tested. `it` block: behavior in plain English — no "should" prefix
- Test priority: happy path → business rules / invariants → edge cases → error cases
- Each test sets up its own data — no shared mutable state
- Mock external dependencies (API calls, timers) — not internal modules
- If `beforeEach` is longer than the test body, use a factory with sensible defaults: `buildOrder({ status: 'pending' })`
- Extract test helpers only when duplication causes maintenance pain — keep them in the same file, not a shared grab bag
- Assert properties and invariants alongside specific values — ask "what must always be true about the output?"

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
| "I need to see the implementation first to know what to test" | If you can't describe the expected behavior, you're not ready to implement. |
| "Mocking everything makes tests brittle" | Mock boundaries (APIs, filesystem), not internals. TDD naturally pushes toward better boundaries. |
| "DRY means I should extract all shared setup" | Tests are read 10x more than written. Repeat setup when it makes intent clearer — extract only when duplication causes maintenance pain. |
| "If the expected output matches, the code is correct" | Output equality catches regressions but misses invariant violations. Assert properties (sorted, unique, within range) alongside specific values. |

## Red Flags

- Test written after the implementation and only tests the happy path
- Test name describes implementation instead of behavior
- Shared mutable state between tests
- Skipping the refactor step
- `beforeEach` that sets up more state than any single test needs
- Tests that only assert equality to hardcoded values without checking invariants

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, Vue component testing
- `debugging` — bug fix TDD overlaps with Step 5 (Guard)
- `applying-coding-style` — naming, formatting, and change discipline for test files
