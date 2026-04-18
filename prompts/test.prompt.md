---
description: "Run or write tests for the current change. Covers unit tests, component tests, and test coverage checks."
---

# Test

Run or write tests related to the current work.

## Determine Scope

1. Identify what changed — check `git diff --name-only` or the current task context
2. Find existing tests for modified files — look in `__tests__/`, `*.spec.ts`, `*.test.ts` adjacent to the source
3. Classify the work:
   - **Changed files have existing tests** → run them, then extend if new behavior was added
   - **Changed files have no tests** → write tests for the new/modified behavior
   - **Bug fix** → write a regression test first (TDD style), then verify the fix

## Run Tests

```bash
# Run tests for specific files
yarn vitest run <path-to-test-file>

# Run tests matching a pattern
yarn vitest run --reporter=verbose -t "<test-name-pattern>"

# Run all tests in a directory
yarn vitest run src/components/checkout/

# Run with coverage for changed files
yarn vitest run --coverage <path-to-test-file>
```

If no test runner command is obvious, check `package.json` scripts for `test`, `vitest`, or `jest`.

## Write Tests

When writing new tests:

1. Load the `test-driven-development` skill — follow Red → Green → Refactor
2. Load the `applying-coding-style` skill — apply naming and structure conventions
3. Reference `references/testing-patterns.md` for structure, factories, and anti-patterns

### Priority

Write tests in this order:

1. **Regression test** for the specific bug or behavior change
2. **Happy path** for new functions or components
3. **Edge cases** — empty, null, boundary values
4. **Error cases** — invalid inputs, failed API calls

### Vue Component Tests

```typescript
import { mountSuspended } from '@nuxt/test-utils/runtime'
import MyComponent from './MyComponent.vue'

describe('MyComponent', () => {
  it('renders the title from props', async () => {
    const wrapper = await mountSuspended(MyComponent, {
      props: { title: 'Hello' },
    })
    expect(wrapper.text()).toContain('Hello')
  })
})
```

## Quality Check

After writing or running tests:

- [ ] All modified behavior has test coverage
- [ ] Tests pass locally
- [ ] No skipped tests — unskip or delete them; do not leave `.skip` without user approval
- [ ] Test names describe behavior, not implementation
