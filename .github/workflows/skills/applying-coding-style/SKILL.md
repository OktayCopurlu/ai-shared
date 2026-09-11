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
6. **Can the smallest local implementation do it?** Keep it inline with one caller. At two occurrences, assess whether duplication can drift; extract by the third occurrence or earlier when the maintenance risk is already clear.

This ladder reduces unnecessary code. It never permits skipping validation, error handling, security, or accessibility requirements.

- **DRY**: Two occurrences are a signal to assess duplication, not an automatic extraction rule. Consolidate when copies can drift; extract by the third occurrence
- **Prefer slots over prop creep**: If a new prop is only needed to customize rendering, check whether a slot is cleaner and more future-proof

### Vertical Spacing

- **One blank line between logical blocks**: Separate consecutive blocks — `if`/`else` chains, loops, `try`/`catch`, function declarations, `describe`/`it` blocks — with exactly one blank line
- **One blank line before a `return`** when the function body has more than one statement
- **Blank line after the import block** and after variable declaration groups that precede logic
- **Never stack blank lines**: two or more consecutive blank lines are noise; collapse them to one
- **No blank line at the start or end of a block body**: don't open a function, `if`, or class with an empty line
- **Don't use blank lines as section dividers**: if a function needs internal grouping to be readable, extract a function instead

## Change Discipline

- **Scope**: Modify only the code explicitly required to complete the task. Avoid refactoring unrelated code, even within the same file, unless explicitly instructed. Note improvements for later — don't fix them mid-task.
- **Test between changes**: Don't write 100+ lines without running tests. Make a change, verify it works (tests pass, build succeeds), then move on. Bugs compound when changes pile up untested.
- **Keep it compilable**: After every meaningful change, the project must build and existing tests must pass. Never leave the codebase in a broken state between edits.

## Working With Code

Coding agent or human prevent the "losing touch" failure mode where the codebase drifts past your understanding while looking fine on the surface.

- **Read every diff before accepting it**: If you haven't read the code, you haven't reviewed it, and you haven't done the work. Opening a PR with unreviewed agent output delegates your job to the reviewer.
- **Refactor continuously, not later**: Agents happily add near-duplicate code and layers of indirection. When the same shape appears twice, stop and assess whether it can drift; consolidate by the third occurrence or sooner when the risk is clear. If you can no longer hold the module in your head, throw the branch away and regenerate with a tighter prompt.
- **Decide design before prompting**: Agents treat "we'll figure out the API later" as permission to invent one. Make naming, module boundaries, and data-shape decisions yourself before asking for an implementation. Deferring feels cheap; the resulting divergence is expensive.
- **Don't delegate what you can't evaluate**: Agents are useful where you can check the result — failing test, compiler error, behavior you can exercise. They are dangerous where "correct" is subjective (API design, abstraction choice, product shape). In that zone, write it yourself or sketch it first.
- **Stop when tired**: Fatigue produces vague prompts, which produce sprawling diffs, which produce more fatigue. Notice the loop and close the laptop.


## Testing Style

- **Name tests by unit, scenario, and outcome**: Outer `describe('<unit>')`, nested `describe('when <scenario>')`, and `it('<present-tense behavior>')`. Never use "should" prefix, never put scenario conditions in `it`, and never join independent outcomes with "and".
- **All `when` in `describe`, NEVER in `it`**: Context and preconditions belong in `describe('when ...')`. `it` states only the observable outcome.
- **Do not join independent outcomes with `and`**: Split independently observable behaviors into separate `it` blocks. A conjunction is fine when it names one contract.
- **One assertion focus per test**: Ideally 1 `expect` per `it`. Multiple expects are only allowed when verifying complementary facets of the exact same property/contract on the same subject. Different outcomes require different `it` blocks.
- **Move shared arrange/act to `beforeEach` when clearer**: Extract non-trivial identical setup or trigger actions shared by multiple `it` blocks. Keep small scenario-specific setup inline when repetition preserves intent.
- **No multi-phase tests**: Never assert initial state, perform an action mid-test, and assert updated state in one `it`. Split into separate `describe` blocks (`when initialized` vs `when <action>`).
- **Strict `describe` scoping**: Place every test in the specific `describe('when ...')` block for its scenario. Never append new tests to whatever `describe` block happens to be at the bottom of the file.
- **No redundant phrasing**: Do not repeat the scenario from `describe` in `it`. Let the hierarchy read naturally.
- **Keep tests intention-revealing**: Each test should prove one behavior that matters, not restate implementation details
- **Review the test file after writing it**: Remove redundant, useless, or duplicate tests once the main coverage is in place
- **Prefer fewer high-signal tests over many overlapping ones**: If two tests prove the same behavior, keep the clearer one
- **Delete tests that prove nothing**: Tests that only assert the mock was called with the mock's own return value, or that snapshot an entire component without checking behavior, add maintenance cost without catching bugs
- **Kill flaky tests on sight**: If a test fails intermittently, fix the root cause (timing, shared state, network) or delete it. A flaky test that is skipped or retried is worse than no test — it erodes trust in the suite
- **Simplify setup**: If `beforeEach` is longer than the test itself, the setup is too heavy. Extract a factory function with sensible defaults and let each test override only what it cares about
- **Cover the critical path first**: Happy path + the most likely error path > exhaustive edge cases. Add edge case tests only when a bug proves the gap matters
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
- Consecutive blocks crammed together with no blank line, or padded with multiple blank lines
- Boolean variables without `is`/`has`/`should`/`can` prefix
- Tests with no `describe` grouping or asserting on mock internals
- Test titles containing "should", "when", or "if", or joining independent outcomes with "and"
- Multiple unrelated `expect` calls in one `it` instead of splitting by outcome
- Non-trivial identical setup repeated across multiple `it` blocks when `beforeEach` would be clearer
- Tests dumped into the wrong or unrelated parent `describe` block

## See Also

- `~/.ai-shared/references/testing-patterns.md` — test structure, anti-patterns, and patterns referenced by the Testing Style section
- `~/.ai-shared/references/refactoring-patterns.md` — structured simplification process and pattern tables for refactoring tasks
