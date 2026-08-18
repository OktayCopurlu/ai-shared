---
name: test-driven-development
description: "Enforce a vertical Red-Green-Refactor loop. Use when the user requests TDD, when a workflow explicitly requires test-first implementation, or when adding behavior with a regression test before production code. Not for review-only test coverage analysis."
---

# Test-Driven Development

Apply one vertical cycle at a time. Do not write a batch of tests followed by a batch of implementation.

## Required Loop

1. **Red:** Write one behavioral test and run it. Confirm it fails for the intended missing behavior, not because of syntax, setup, or an unrelated failure.
2. **Green:** Make the smallest production change that passes that test, then run the relevant suite.
3. **Refactor:** Improve the code and test without changing behavior; keep the suite green.
4. Repeat for the next behavior.

For bug fixes, the Red step must reproduce the reported failure before the fix. If a regression test is infeasible, explain why and use the narrowest repeatable reproduction available.

## Test Design

Load `~/.ai-shared/references/testing-patterns.md` for naming, priority, mocks, fixtures, Vue stubs, accessibility contracts, and false-positive checks. Follow repository-local test conventions when they conflict with the shared reference.

Keep the test focused on observable behavior. Mock external boundaries rather than internal modules, isolate mutable state, and derive expected values from fixtures.

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, Vue component testing
- `applying-coding-style` — naming, formatting, and change discipline for test files
