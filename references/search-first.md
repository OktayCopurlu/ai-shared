# Search-First Checklist

Research before coding. The cost of searching is minutes; the cost of duplicating or breaking existing code is hours.

## Before Writing New Code

- [ ] Search for existing utilities — the codebase likely has a helper for it
- [ ] Find an existing pattern for a similar feature — follow it, don't invent a new one
- [ ] Read the relevant type definitions — don't guess the data shape
- [ ] Check if the project already uses an equivalent dependency before adding one
- [ ] Read the test file if it exists — tests document expected behavior better than comments

## Before Modifying Existing Code

- [ ] Read the full relevant section of the file, not just the target line
- [ ] Read the test file — understand what's currently asserted
- [ ] Search for callers — will your change break consumers?
- [ ] Check recent git history: `git log --oneline -10 -- <file>`

## Before Adding a Dependency

- [ ] Search the codebase for similar functionality already available
- [ ] Check bundle impact — 2KB utility or 200KB library?
- [ ] Check existing `package.json` for a library that already covers this
