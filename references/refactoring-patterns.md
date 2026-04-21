# Refactoring Patterns

Load this reference when refactoring, simplifying, or cleaning up existing code. Complements the `applying-coding-style` skill with process guardrails and the `search-first` reference with pre-change due diligence.

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
