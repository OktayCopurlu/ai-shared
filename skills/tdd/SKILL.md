---
name: tdd
description: "Test-driven development: write failing test, make it pass, refactor. USE FOR: implementing new functions, fixing bugs with regression tests, adding behavior to existing code. Use when writing tests before code or when asked to TDD a feature."
---

# Test-Driven Development

Write the test first. Make it pass. Clean up. Repeat.

## Philosophy

Tests verify **behavior through public interfaces**, not implementation details. A good test reads like a specification — it describes what the system does, not how. If you refactor internals and a test breaks but behavior hasn't changed, that test was wrong.

## When to Use

- Implementing a new function, utility, or composable
- Adding behavior to existing code where the expected output is clear
- Fixing a bug — write the failing test first, then fix
- When the user explicitly asks for TDD

**When NOT to use:** Exploratory prototyping where requirements are still fuzzy. UI layout changes where visual verification matters more than unit tests. Integration tests that need infrastructure setup beyond the current task scope.

## The Cycle

```
Red → Green → Refactor
```

### Red — Write a failing test

Write the simplest test that describes the next piece of behavior.

```typescript
it('returns the discounted price when a valid code is applied', () => {
  const result = applyDiscount({ price: 100, code: 'SAVE10' })
  expect(result).toBe(90)
})
```

Rules:
- Test one behavior per test
- Name the test with the expected behavior, not the implementation
- Run the test — confirm it fails for the right reason (not a syntax error)

### Green — Make it pass

Write the minimum code to make the test pass. Nothing more.

```typescript
function applyDiscount({ price, code }: { price: number; code: string }): number {
  if (code === 'SAVE10') return price * 0.9
  return price
}
```

Rules:
- Do not add code that isn't required by a failing test
- It's okay if the code is ugly — you'll refactor next
- Run the test — confirm it passes

### Refactor — Clean up

Improve the code without changing behavior. Tests stay green throughout.

- Remove duplication
- Improve naming
- Extract helpers if the function grew
- Run tests after each refactor step

## Test Writing Standards

### Structure

```typescript
describe('applyDiscount', () => {
  it('returns original price when no code is provided', () => { ... })
  it('returns discounted price for a valid percentage code', () => { ... })
  it('returns original price for an invalid code', () => { ... })
  it('throws when price is negative', () => { ... })
})
```

### Naming

- `describe` block: the unit being tested (function, composable, component)
- `it` block: the behavior in plain English — "returns X when Y", "throws when Z"
- Do not use "should" — it adds words without adding meaning

### What to test (priority order)

1. **Happy path** — the main expected behavior
2. **Edge cases** — empty inputs, zero, null, boundary values
3. **Error cases** — invalid inputs, missing data, network failures
4. **Integration points** — how units work together (sparingly)

### Test isolation

- Each test sets up its own data — no shared mutable state between tests
- Use factories or builders for complex test data
- Mock external dependencies (API calls, timers) — not internal modules
- Reset mocks in `beforeEach` or `afterEach`

## Bug Fix TDD

When fixing a bug, always start with a failing test:

```
1. Write a test that reproduces the bug (Red)
2. Confirm it fails for the same reason as the bug
3. Fix the bug (Green)
4. Confirm the test passes
5. Refactor if needed
```

This guarantees the bug stays fixed.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is horizontal slicing — treating Red as "write all tests" and Green as "write all code."

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

Why this fails:
- Tests written in bulk test *imagined* behavior, not *actual* behavior
- You test the shape of things (signatures, structures) rather than user-facing behavior
- Tests become insensitive to real changes — pass when behavior breaks, fail when behavior is fine
- You commit to test structure before understanding the implementation

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
