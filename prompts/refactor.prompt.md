---
description: "Refactor code for maintainability without changing behavior. Use when cleaning up, extracting, consolidating, or restructuring existing code."
---

# Refactor

## Required input

Before proceeding, confirm these with the user if not provided:

- **Refactor objective** — what to improve and why (e.g. "extract shared validation logic", "split 600-line component")
- **Scope** — which files, functions, or modules are in scope
- **Out of scope** — what must not be touched

## Constraints

- **Behavior preservation is non-negotiable.** If tests need updating to pass, you likely changed behavior — stop and reassess.
- No new features, no scope creep.
- Follow existing project conventions (load `applying-coding-style` skill).
- Load `references/refactoring-patterns.md` for process guardrails.

## Workflow

### 1. Scope lock

Restate for the user:
- What is being refactored
- What behavior must remain unchanged
- What is explicitly out of scope

Wait for confirmation before proceeding.

### 2. Assess current state

- Read the target code and surrounding context
- Identify dependencies, callers, and integration points
- Check existing test coverage for the affected area
- If test coverage is insufficient, write characterization tests first

### 3. Plan the change sequence

Order changes to minimize risk:
1. Types and interfaces first
2. Shared abstractions / extracted modules
3. Migrate callers one at a time
4. Remove obsolete code
5. Update tests

For changes touching more than 500 lines, prefer codemods or scripted transforms over manual edits.

### 4. Execute incrementally

For each step:
1. Make one focused change
2. Run tests, lint, and typecheck
3. Verify behavior is preserved
4. Move to next step only when green

Do not batch multiple refactoring moves into a single step.

### 5. Final verification

Run the full quality gate:
- All tests pass
- Lint clean
- Typecheck clean
- Build succeeds (if applicable)

### 6. Summary

Report:
- Files changed and what was refactored
- Behavior-preservation evidence (which tests cover it)
- Follow-up refactors identified but not done (keep scope tight)
