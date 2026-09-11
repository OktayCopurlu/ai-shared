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

- **Name tests by unit, scenario, and outcome**: Outer `describe('<unit>')`, nested `describe('when <scenario>')`, and `it('<present-tense behavior>')`.
- **All `when` in `describe`, NEVER in `it`**: Scenario conditions and prerequisites belong in `describe('when ...')`. Never put `when` or `if` in an `it` title.
- **No `should` prefix in `it`**: Use active present tense (`it('renders...')`, `it('navigates to...')`, `it('returns...')`). Never write `it('should...')`.
- **Do not join independent outcomes with `and`**: Split independently observable behaviors or steps into separate `it` blocks. A conjunction is fine when it names one contract.
- **One assertion focus per `it`**: Ideally 1 `expect` per `it`. Multiple expects are only permitted if verifying complementary facets of the exact same contract on the same subject (e.g. `role` and `aria-live` on a single element). Never test multiple controls, items, or actions in one `it`.
- **Shared arrange/act in `beforeEach` when clearer**: Move non-trivial identical setup or trigger actions shared by multiple `it` blocks into `beforeEach`. Keep small scenario-specific setup inline when repetition preserves intent.
- **No multi-phase tests**: Never assert initial state, perform an action mid-test, and assert updated state in the same `it`. Split into `describe('when initialized')` and `describe('when <action>')` with the action in `beforeEach`.
- **Scoping discipline**: Always place new tests within the `describe('when <scenario>')` block matching that scenario. Never append tests to whatever `describe` block happens to be at the bottom of the file.
- **No redundant phrasing**: Do not repeat the scenario from `describe` inside `it` (e.g. `describe('when close button is clicked')` ➔ `it('closes the panel')`, NOT `it('closes the panel on close button click')`).
- **Test priority**: happy path → business rules / invariants → edge cases → error cases
- **Each test sets up its own data**: no shared mutable state across tests
- **Mock external dependencies only**: APIs, timers, third-party libraries — never mock internal modules
- **For Vue child components**: prefer `stubs: { Child: true }` over hand-rolled stub components, and assert on `findComponent({ name }).props(...)` rather than text rendered by the stub
- **Derive expected values from the fixture**: do not duplicate fixture values as hardcoded strings in assertions
- **No brittle giant `toEqual`**: assert only relevant fields via `toMatchObject({...})` or specific properties when testing transformations
- **No optional chaining in expectations**: `expect(x?.y).toBe(...)` hides false-positive `undefined === undefined`; tighten fixture types or assert defined first
- **If `beforeEach` is longer than the test body**: use a factory with sensible defaults (`buildOrder({ status: 'pending' })`)
- **Extract test helpers only when duplication causes maintenance pain**: keep them in the same file, not a shared grab bag
- **Assert properties and invariants alongside specific values**: ask "what must always be true about the output?"

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

- `it` title contains "should", "when", or "if", or joins independent outcomes with "and"
- One `it` with multiple unrelated assertions or testing distinct outcomes instead of one behavior per `it`
- Non-trivial identical arrange/act repeated across multiple `it` blocks when `beforeEach` would be clearer
- Multi-phase test asserting initial state, triggering action, and asserting updated state in a single `it`
- Test appended to an unrelated parent `describe` block instead of a matching scenario block
- Redundant phrasing repeating the scenario inside the `it` title
- Test written after the implementation and only tests the happy path
- Test name describes implementation instead of behavior
- Shared mutable state between tests
- Skipping the refactor step
- `beforeEach` that sets up more state than any single test needs
- Tests that only assert equality to hardcoded values without checking invariants
- Hand-rolled stub component whose template re-implements production logic (`:href="disabled ? undefined : url"`) — the test now verifies the stub
- Brittle giant `toEqual` object matching that breaks on unrelated schema additions
- Hardcoded SKUs/URLs/IDs duplicated from the fixture in assertions
- `expect(x).toBe(fixture.a?.b?.c)` — optional chaining hides false-positive `undefined === undefined`

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, Vue component testing
- `debugging` — bug fix TDD overlaps with Step 5 (Guard)
- `applying-coding-style` — naming, formatting, and change discipline for test files
