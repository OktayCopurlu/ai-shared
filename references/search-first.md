# Search-First Checklist

Research before coding. Referenced by `implementation` prompt.

## The Rule

Before writing or modifying any code, verify what already exists. The cost of searching is minutes; the cost of building something that already exists, conflicts with existing patterns, or misses a utility is hours.

## Before Writing New Code

- [ ] **Search for existing utilities**: `grep_search` for function/helper names related to your task. The codebase likely has a util for it.
- [ ] **Find an existing pattern**: Search for a similar feature already implemented. Follow its structure rather than inventing a new one.
- [ ] **Check types/interfaces**: Read the relevant type definitions before implementing. Don't guess the shape of data.
- [ ] **Check imports**: Before adding a new dependency, verify if the project already uses something equivalent.
- [ ] **Read the test**: If a test file exists for your target file, read it first — tests document expected behavior better than comments.

## Before Modifying Existing Code

- [ ] **Read the file** you'll change — the whole relevant section, not just the target line
- [ ] **Read the test file** for that module — understand what's currently asserted
- [ ] **Search for callers**: Who uses this function/component? Will your change break consumers?
- [ ] **Search for similar changes**: Has someone already solved this differently elsewhere?
- [ ] **Check recent git history**: `git log --oneline -10 -- <file>` — is this file under active change?

## Before Adding a Dependency

- [ ] **Search the codebase** for similar functionality already available
- [ ] **Check bundle impact**: Is this a 2KB utility or a 200KB library?
- [ ] **Check existing package.json**: Does the project already have a library that covers this?

## When to Go Deeper

Escalate from quick search to thorough exploration when:
- The task involves an unfamiliar area of the codebase
- The change spans multiple modules or services
- You're unsure about the data flow or state management
- The error trace leads through code you haven't read before
