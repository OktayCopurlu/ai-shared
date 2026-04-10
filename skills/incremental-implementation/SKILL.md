---
name: incremental-implementation
description: "Build in thin vertical slices: implement, test, verify, commit. USE FOR: any change touching more than one file, multi-step features, or when tempted to write 100+ lines before testing. Use when implementing features from a task breakdown."
---

# Incremental Implementation

Build one slice at a time. Each slice leaves the system in a working, testable state.

## When to Use

- Implementing any multi-file change
- Building a new feature from a task breakdown
- Refactoring existing code across multiple files
- Any time you're tempted to write more than ~100 lines before testing

**When NOT to use:** Single-file, single-function changes where the scope is already minimal.

## The Increment Cycle

```
Implement → Test → Verify → Commit → Next slice
```

For each slice:

1. **Implement** the smallest complete piece of functionality
2. **Test** — run the test suite (or write a test if none exists)
3. **Verify** — confirm the slice works (tests pass, build succeeds)
4. **Commit** — save progress with a descriptive message
5. **Move to the next slice**

## Slicing Strategies

### Vertical Slices (Preferred)

Build one complete path through the stack:

```
Slice 1: Data layer + API + basic UI for "create"
    → Tests pass, user can create via UI

Slice 2: Data layer + API + UI for "list"
    → Tests pass, user can see their items

Slice 3: Data layer + API + UI for "edit"
    → Tests pass, user can modify items
```

Each slice delivers working end-to-end functionality.

### Contract-First Slicing

When backend and frontend develop in parallel:

```
Slice 0: Define types/interfaces/API contract
Slice 1a: Backend implementation + API tests
Slice 1b: Frontend with mock data matching contract
Slice 2: Integration and E2E test
```

### Risk-First Slicing

Tackle the most uncertain piece first:

```
Slice 1: Prove the risky integration works (highest uncertainty)
Slice 2: Build features on proven foundation
Slice 3: Add polish and edge case handling
```

If Slice 1 fails, you discover it before investing in the rest.

## Implementation Rules

### Simplicity First

Before writing code: "What is the simplest thing that could work?"

After writing code:
- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Am I building for hypothetical future requirements, or the current task?

Three similar lines of code is better than a premature abstraction. Implement the obvious version first. Optimize only after correctness is proven.

### Scope Discipline

Touch only what the task requires.

Do NOT:
- "Clean up" code adjacent to your change
- Refactor imports in files you're not modifying
- Remove comments you don't fully understand
- Add features not in the spec because they "seem useful"

If you notice something worth improving outside your task scope, note it — don't fix it.

### One Thing at a Time

Each increment changes one logical thing. Don't mix concerns. Refactors, features, and bug fixes are separate increments.

### Keep It Compilable

After each increment, the project must build and existing tests must pass. Don't leave the codebase broken between slices.

### Feature Flags for Incomplete Features

If a feature isn't ready for users but you need to merge increments:

```typescript
const ENABLE_NEW_FEATURE = process.env.FEATURE_FLAG === 'true';

if (ENABLE_NEW_FEATURE) {
  // New work-in-progress UI
}
```

This lets you merge small increments without exposing incomplete work.

## Increment Checklist

After each increment, verify:

- [ ] The change does one thing and does it completely
- [ ] All existing tests still pass
- [ ] The build succeeds
- [ ] Type checking passes
- [ ] Linting passes
- [ ] The new functionality works as expected
- [ ] The change is committed with a descriptive message

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's faster to do it all at once" | It feels faster until something breaks and you can't find which of 500 changed lines caused it. |
| "These changes are too small to commit separately" | Small commits are free. Large commits hide bugs and make rollbacks painful. |
| "I'll test it all at the end" | Bugs compound. A bug in Slice 1 makes Slices 2–5 wrong. Test each slice. |
| "This refactor is small enough to include" | Refactors mixed with features make both harder to review and debug. Separate them. |
| "Let me just quickly add this too" | Scope creep starts with "just." Finish the current slice first. |
| "I'll add the feature flag later" | If the feature isn't complete, it shouldn't be user-visible. Add the flag now. |

## Red Flags

- More than 100 lines written without running tests
- Multiple unrelated changes in a single increment
- Build or tests broken between increments
- Large uncommitted changes accumulating
- Building abstractions before the third use case
- Touching files outside the task scope "while I'm here"

## Verification

After completing all increments for a task:

- [ ] Each increment was individually tested and committed
- [ ] The full test suite passes
- [ ] The build is clean
- [ ] The feature works end-to-end as specified
- [ ] No uncommitted changes remain

## See Also

- `debugging` — when an increment breaks something
- `coding-style` — apply to all code written during implementation
- `code-review` — run before creating the PR
