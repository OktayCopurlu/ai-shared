---
name: applying-coding-style
description: "Apply the user's naming, comment, YAGNI, and change-discipline preferences. Use when writing, editing, or reviewing TypeScript, Vue, or SCSS, and for requests about naming, comments, readability, or code quality. Not for architecture, security, or test-strategy decisions."
---

# Coding Style — Personal Standards

These rules apply to ALL code I write or modify. They override generic conventions when there is a conflict.

## Naming

- **Names are documentation**: Choose variable, function, and constant names that eliminate the need for comments
  - `FALLBACK_LABELS` not `MOCK_LABELS` + a JSDoc explaining it's a fallback
  - `isEligibleForScales()` not `checkProduct()` + a comment saying "checks if product can show scales"
  - `formatPriceWithCurrency()` not `format()` + inline comment

### Variables and Props

- **Boolean variables/props**: Prefix with `is`, `has`, `should`, `can` (e.g. `isVisible`, `hasError`)

### Functions

- **Functions**: Use verb phrases that describe what they do (e.g. `getScaleData`, `trackExposure`)

### Constants

- **Constants**: Use UPPER_SNAKE_CASE with a name that conveys purpose, not implementation (e.g. `ELIGIBLE_SUBTYPES` not `ROAD_RUNNING_SET`)

### Generic Names

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

### YAGNI Decision Ladder

Before adding code, evaluate these options in order and stop at the first one that satisfies the requirement:

1. **Does this need to exist?** If the request does not require a change, do not add one.
2. **Is it already in the codebase?** Use the existing behavior, component, utility, or configuration.
3. **Can the standard library do it?** Prefer it over new code or a dependency.
4. **Can the native platform do it?** Prefer browser, framework, or runtime primitives.
5. **Is an installed dependency suitable?** Use it before adding another dependency.
6. **Can the smallest local implementation do it?** Keep it inline for one caller. Extract only when reuse or a clear domain boundary justifies the abstraction; three callers is the default threshold.

This ladder reduces unnecessary code. It never permits skipping validation, error handling, security, or accessibility requirements.

- **DRY**: Two similar fragments are a signal to compare, not an automatic extraction rule. Extract when they represent the same domain behavior and the shared abstraction is simpler than the duplication.
- **Prefer slots over prop creep**: If a new prop is only needed to customize rendering, check whether a slot is cleaner and more future-proof

## Change Discipline

- **Scope**: Modify only the code explicitly required to complete the task. Avoid refactoring unrelated code, even within the same file, unless explicitly instructed. Note improvements for later — don't fix them mid-task.
- **Test between changes**: Don't write 100+ lines without running tests. Make a change, verify it works (tests pass, build succeeds), then move on. Bugs compound when changes pile up untested.
- **Keep it compilable**: After every meaningful change, the project must build and existing tests must pass. Never leave the codebase in a broken state between edits.

## Testing Style

- Follow `~/.ai-shared/references/testing-patterns.md` for test structure and detailed anti-patterns.
- Keep tests intention-revealing and focused on observable behavior.
- Do not add production methods, flags, or exports solely to make tests easier.

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
- Tests that assert on mock internals instead of observable behavior

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, and patterns referenced by the Testing Style section
- `~/.ai-shared/references/refactoring-patterns.md` — structured simplification process and pattern tables for refactoring tasks
