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
3. Reference `~/.ai-shared/references/testing-patterns.md` for structure, factories, and anti-patterns

### Test Structure & Grammar Rules

- **Hierarchy**: `describe('<Unit>')` ➔ `describe('when <scenario>')` ➔ `it('<present-tense verb>')`
- **All `when` in `describe`**: Context and preconditions belong in `describe('when ...')`, NEVER in `it`
- **No `should` prefix**: Use present tense (`it('renders...')`, `it('navigates to...')`, `it('returns...')`)
- **Do not join independent outcomes with `and`**: Split independently observable behaviors into separate `it` blocks; conjunctions naming one contract are fine
- **One assertion focus per `it`**: Ideally 1 `expect` per test; separate `it` for each expected outcome
- **Shared arrange/act in `beforeEach` when clearer**: Move non-trivial identical setup or trigger actions shared by multiple `it`s; keep short scenario-specific setup inline when clearer
- **No multi-phase tests**: Never assert initial state, perform an action mid-test, and assert updated state in one `it`
- **Scoping discipline**: Place tests in the specific `describe('when ...')` block for their scenario — never append to unrelated blocks
- **No brittle giant `toEqual`**: Assert only relevant fields via `toMatchObject({...})` or specific properties
- **No optional chaining in `expect`**: Never use `?.` inside `expect(...)`; assert defined first or tighten fixture types

### Priority

Write tests in this order:

1. **Regression test** for the specific bug or behavior change
2. **Happy path** for new functions or components
3. **Edge cases** — empty, null, boundary values
4. **Error cases** — invalid inputs, failed API calls

### Canonical Component Test Example

```typescript
import { renderSuspended } from '@nuxt/test-utils/runtime'
import { screen } from '@testing-library/vue'
import MyComponent from './MyComponent.vue'

describe('MyComponent', () => {
  describe('when rendered with title prop', () => {
    it('renders the title as a heading', async () => {
      await renderSuspended(MyComponent, {
        props: { title: 'Hello' },
      })

      expect(screen.getByRole('heading', { name: 'Hello' })).toBeVisible()
    })
  })
})
```

## Quality Check

After writing or running tests:

- [ ] All modified behavior has test coverage
- [ ] Tests pass locally
- [ ] Every `when` is in a `describe('when ...')` block, not in `it` titles
- [ ] No `should` prefix in any `it` title (active present tense used)
- [ ] No `and` joins independent outcomes in an `it` title (conjunctions naming one contract are fine)
- [ ] One assertion focus per `it` (ideally 1 `expect` per test)
- [ ] Non-trivial identical arrange/act is in `beforeEach` when that makes multiple `it`s clearer
- [ ] No multi-phase tests (initial state + action + updated state in one `it`)
- [ ] Tests are correctly scoped under matching `describe` blocks (not appended to unrelated blocks)
- [ ] No optional chaining (`?.`) inside `expect(...)`
- [ ] No brittle giant `toEqual` assertions on large objects
- [ ] No skipped tests — unskip or delete them; do not leave `.skip` without user approval
- [ ] Test names describe behavior, not implementation
