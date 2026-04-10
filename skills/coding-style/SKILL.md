---
name: coding-style
description: 'Personal code writing standards for naming, comments, and cleanliness. USE FOR: writing new code, reviewing code, refactoring. ALWAYS apply when generating or editing TypeScript, Vue, or SCSS files. Use when user says "write clean code", "fix naming", "remove comments", or "code quality".'
---

# Coding Style — Personal Standards

These rules apply to ALL code I write or modify. They override generic conventions when there is a conflict.

## Naming

- **Names are documentation**: Choose variable, function, and constant names that eliminate the need for comments
  - `FALLBACK_LABELS` not `MOCK_LABELS` + a JSDoc explaining it's a fallback
  - `isEligibleForScales()` not `checkProduct()` + a comment saying "checks if product can show scales"
  - `formatPriceWithCurrency()` not `format()` + inline comment
- **Boolean variables/props**: Prefix with `is`, `has`, `should`, `can` (e.g. `isVisible`, `hasError`)
- **Functions**: Use verb phrases that describe what they do (e.g. `getScaleData`, `trackExposure`)
- **Constants**: Use UPPER_SNAKE_CASE with a name that conveys purpose, not implementation (e.g. `ELIGIBLE_SUBTYPES` not `ROAD_RUNNING_SET`)
- **Avoid generic names**: No `data`, `info`, `item`, `result`, `temp`, `val` unless scope is < 3 lines

## Comments

### Never write these:
- **JSDoc blocks** on internal functions — the name and types are the documentation
- **Inline comments** — if the code needs explaining, rename things or extract a function. Do NOT add inline comments that restate what the code does, annotate conditions, or label sections
- **TODO / FIXME / HACK** — create a Jira ticket instead; if a ticket reference is essential, use a single-line `// DSC-XXXX` with no prose
- **Commented-out code** — it lives in git history; delete it
- **"Why not" comments** — don't explain why you didn't choose an alternative approach
- **Section dividers** — no `// ---- Helpers ----` or `/* === Config === */`

### Only write these (rarely):
- **Why comments**: When the reason for a non-obvious decision isn't captured in a ticket (e.g. `// Safari doesn't support ResizeObserver in iframes`)
- **Workaround comments**: When working around a framework/library bug, link the issue (e.g. `// Nuxt hydration mismatch workaround: https://github.com/nuxt/nuxt/issues/XXXX`)
- **Regex explanations**: Complex regex patterns deserve a one-line description of what they match

## Unused Code

- **No `_` prefix for unused params** — either use the parameter or restructure to not receive it
- **No dead code** — delete unused functions, variables, imports, and types immediately
- **No feature flags for removed features** — clean up the entire code path when a flag is retired

## Code Shape

- **DRY — Don't Repeat Yourself**: When the same logic appears in two or more places, extract it into a shared helper, variable, or function. Duplicated conditions, ternaries, or formatting calls are a code smell — consolidate them at the source
- **Guard clauses over nesting**: Early returns, not nested `if/else`
- **One concept per function**: If you need a comment to separate sections within a function, extract a function instead
- **Flat over nested**: Prefer `array.filter().map()` over nested loops with accumulators
- **Explicit over clever**: Readable code > shorter code. No ternary chains, no comma operators, no void expressions
- **Prefer slots over prop creep**: If a new prop is only needed to customize rendering, stop and check whether passing a slot is cleaner and more future-proof than adding another prop. For example, if a component needs custom labels or content regions, a slot may be a better API than more props.

## Simplification

- **Inline single-use helpers**: If a function is called exactly once and its body is short enough to read in place, inline it. A named function only earns its keep when it is reused or when the name genuinely clarifies intent beyond what the code already says
- **Flatten nested conditionals**: When `if` blocks nest more than two levels, invert conditions and return early. Convert `if (a) { if (b) { if (c) { ... } } }` into sequential guard clauses
- **Simplify boolean expressions**: `return condition` not `if (condition) return true; else return false;`. No double negation (`!!value`) when the consumer already expects a truthy check
- **Remove unnecessary abstractions**: If a "pattern" (factory, strategy, builder) has only one concrete implementation and no realistic second use case, flatten it into plain code

## Testing Style

- **Use `describe` blocks for each `when ...` case**: Group test cases by scenario with a clear `describe('when ...')` wrapper rather than mixing unrelated assertions at the top level
- **Keep tests intention-revealing**: Each test should prove one behavior that matters, not restate implementation details
- **Review the test file after writing it**: Remove redundant, useless, or duplicate tests once the main coverage is in place
- **Prefer fewer high-signal tests over many overlapping ones**: If two tests prove the same behavior, keep the clearer one
- **Delete tests that prove nothing**: Tests that only assert the mock was called with the mock's own return value, or that snapshot an entire component without checking behavior, add maintenance cost without catching bugs
- **Kill flaky tests on sight**: If a test fails intermittently, fix the root cause (timing, shared state, network) or delete it. A flaky test that is skipped or retried is worse than no test — it erodes trust in the suite
- **Simplify setup**: If `beforeEach` is longer than the test itself, the setup is too heavy. Extract a factory function with sensible defaults and let each test override only what it cares about
- **Cover the critical path first**: Happy path + the most likely error path > exhaustive edge cases. Add edge case tests only when a bug proves the gap matters
- **One assertion focus per test**: A test can have multiple `expect` calls, but they should all verify the same behavior from different angles — not test unrelated side effects in the same block
- **No test-only production code**: Do not add methods, flags, or exports to production code solely to make it testable. Rethink the boundary instead

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The comment explains what the code does" | If the code needs a comment to explain what it does, rename the variable or extract a function. Comments restate; names document. |
| "JSDoc is best practice" | JSDoc on internal functions adds noise. The function name + TypeScript types are the documentation. JSDoc is for public library APIs. |
| "I'll clean up the naming later" | Later never comes. Name it right now — 30 seconds of thought prevents permanent confusion. |
| "This helper might be useful elsewhere" | Single-use abstractions are overhead, not leverage. Inline it. Extract only when the third caller appears. |
| "The test is simple, it doesn't need a describe block" | `describe('when ...')` blocks cost nothing and make test output scannable. Always group by scenario. |
| "Commented-out code is useful as reference" | That's what git history is for. Dead code confuses everyone who reads the file after you. |
| "A TODO is fine for now" | TODOs are where good intentions go to die. Create a Jira ticket or fix it now. |

## Red Flags

- JSDoc blocks appearing on internal functions
- Inline comments restating what the next line does
- Variables named `data`, `info`, `result`, `temp` in non-trivial scope
- Commented-out code surviving review
- Boolean variables without `is`/`has`/`should`/`can` prefix
- Nested conditionals deeper than 2 levels
- `!!value` used where a truthy check already suffices
- Single-use helper functions that obscure rather than clarify
- Tests with no `describe` grouping or asserting on mock internals

## Verification

After applying coding-style to a file or PR:

- [ ] No JSDoc blocks on internal functions
- [ ] No inline comments restating code behavior
- [ ] No commented-out code
- [ ] No generic names (`data`, `temp`, `result`) in scope > 3 lines
- [ ] Boolean variables/props use `is`/`has`/`should`/`can` prefix
- [ ] Functions use verb phrases
- [ ] No nesting deeper than 2 levels (guard clauses used)
- [ ] Tests grouped by `describe('when ...')`
- [ ] No dead code, unused imports, or unused variables
