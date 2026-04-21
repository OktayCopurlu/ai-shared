# Refactoring Patterns

Load this reference when refactoring, simplifying, or cleaning up existing code. Complements the `applying-coding-style` skill with concrete identification patterns and a structured process.

## Before You Touch Anything (Chesterton's Fence)

If you see code that looks wrong or overly complex, understand **why** it exists before changing it:

1. What is this code's responsibility?
2. What calls it? What does it call?
3. What are the edge cases and error paths?
4. Are there tests that define expected behavior?
5. Check git blame: what was the original context?

If you cannot answer these, read more context first. Do not simplify code you do not understand.

## Structural Complexity Patterns

| Signal | Simplification |
|--------|----------------|
| Deep nesting (3+ levels) | Extract conditions into guard clauses or helper functions |
| Long functions (50+ lines) | Split into focused functions with descriptive names |
| Nested ternaries | Replace with if/else chains or lookup objects |
| Boolean parameter flags (`doThing(true, false)`) | Replace with options objects or separate functions |
| Repeated conditionals (same `if` in multiple places) | Extract to a well-named predicate function |

## Naming Cleanup Patterns

| Signal | Simplification |
|--------|----------------|
| Generic names (`data`, `result`, `temp`, `val`) | Rename to describe the content: `userProfile`, `validationErrors` |
| Abbreviated names (`usr`, `cfg`, `btn`) | Use full words unless universally understood (`id`, `url`, `api`) |
| Misleading names (function named `get` that mutates) | Rename to reflect actual behavior |
| Comments explaining "what" (`// increment counter`) | Delete the comment; rename if needed |
| Comments explaining "why" (`// Safari bug workaround`) | Keep these; they carry intent code cannot express |

## Redundancy Patterns

| Signal | Simplification |
|--------|----------------|
| Duplicated logic (same 5+ lines in multiple places) | Extract to a shared function |
| Dead code (unreachable branches, commented-out blocks) | Remove after confirming it is truly dead |
| Unnecessary wrappers (adds no value over the inner call) | Inline the wrapper |
| Over-engineered patterns (factory-for-a-factory, strategy-with-one-strategy) | Replace with the direct approach |
| Redundant type assertions (casting to an already-inferred type) | Remove the assertion |

## The Refactoring Process

1. **One change at a time.** Make a single simplification, run tests, verify.
2. **Separate refactoring from feature work.** A PR that refactors AND adds a feature is two PRs.
3. **Every changed line traces to the task.** Do not "improve" adjacent code unless asked.
4. **Remove only what YOUR changes orphaned.** Imports, variables, or functions that your change made unused should be cleaned up. Pre-existing dead code is a separate task.
5. **Revert if the result is harder to read.** Not every simplification attempt succeeds.

## The Rule of 500

If a refactoring would touch more than 500 lines, invest in automation (codemods, AST transforms, find-and-replace scripts) rather than making changes by hand. Manual edits at that scale are error-prone and exhausting to review.

## Red Flags (Stop and Reconsider)

- Simplification that requires modifying tests to pass (you likely changed behavior)
- "Simplified" code that is longer or harder to follow than the original
- Renaming to match personal preference rather than project conventions
- Removing error handling because "it makes the code cleaner"
- Batching many simplifications into one large commit
