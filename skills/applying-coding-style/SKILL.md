---
name: applying-coding-style
description: 'Personal code writing standards for naming, comments, and cleanliness. USE FOR: writing new code, reviewing code style, refactoring for readability. ALWAYS apply when generating or editing TypeScript, Vue, or SCSS files. Use when user says "write clean code", "fix naming", "remove comments", or "code quality". NOT FOR: architecture decisions (reviewing-code layer 4), security patterns (security-hardening), or test strategy (test-driven-development).'
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

- **DRY**: When the same logic appears in 2+ places, extract it. Duplicated conditions, ternaries, or formatting calls are a code smell
- **Prefer slots over prop creep**: If a new prop is only needed to customize rendering, check whether a slot is cleaner and more future-proof

## Change Discipline

- **Scope**: Touch only what the task requires. Don't "clean up" adjacent code, refactor imports in unrelated files, or add features not in the spec. Note improvements for later — don't fix them mid-task.
- **Test between changes**: Don't write 100+ lines without running tests. Make a change, verify it works (tests pass, build succeeds), then move on. Bugs compound when changes pile up untested.
- **Keep it compilable**: After every meaningful change, the project must build and existing tests must pass. Never leave the codebase in a broken state between edits.

## Working With Code

Coding agent or human prevent the "losing touch" failure mode where the codebase drifts past your understanding while looking fine on the surface.

- **Read every diff before accepting it**: If you haven't read the code, you haven't reviewed it, and you haven't done the work. Opening a PR with unreviewed agent output delegates your job to the reviewer.
- **Refactor continuously, not later**: Agents happily add near-duplicate code and layers of indirection. When the same shape appears twice, stop and consolidate — don't promise yourself a cleanup pass. If you can no longer hold the module in your head, throw the branch away and regenerate with a tighter prompt.
- **Decide design before prompting**: Agents treat "we'll figure out the API later" as permission to invent one. Make naming, module boundaries, and data-shape decisions yourself before asking for an implementation. Deferring feels cheap; the resulting divergence is expensive.
- **Don't delegate what you can't evaluate**: Agents are useful where you can check the result — failing test, compiler error, behavior you can exercise. They are dangerous where "correct" is subjective (API design, abstraction choice, product shape). In that zone, write it yourself or sketch it first.
- **Stop when tired**: Fatigue produces vague prompts, which produce sprawling diffs, which produce more fatigue. Notice the loop and close the laptop.


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
| "The comment explains what the code does" | Rename the variable or extract a function instead. |
| "I'll clean up the naming later" | Later never comes. Name it right now. |
| "This helper might be useful elsewhere" | Inline it. Extract only when the third caller appears. |

## Red Flags

- JSDoc blocks on internal functions
- Inline comments restating what the next line does
- Variables named `data`, `info`, `result`, `temp` in non-trivial scope
- Commented-out code surviving review
- Boolean variables without `is`/`has`/`should`/`can` prefix
- Tests with no `describe` grouping or asserting on mock internals

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, and patterns referenced by the Testing Style section
