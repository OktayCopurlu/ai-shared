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

## Testing Style

- **Use `describe` blocks for each `when ...` case**: Group test cases by scenario with a clear `describe('when ...')` wrapper rather than mixing unrelated assertions at the top level
- **Keep tests intention-revealing**: Each test should prove one behavior that matters, not restate implementation details
- **Review the test file after writing it**: Remove redundant, useless, or duplicate tests once the main coverage is in place
- **Prefer fewer high-signal tests over many overlapping ones**: If two tests prove the same behavior, keep the clearer one
