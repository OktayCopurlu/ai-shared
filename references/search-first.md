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
- [ ] Search docs, READMEs, and examples for references to the symbol — stale docs are worse than none
- [ ] Check recent git history: `git log --oneline -10 -- <file>`

## Before Renaming or Removing a Public API

- [ ] Map every caller: source, tests, docs, configs, examples, and cross-repo consumers
- [ ] Decide the cut-over strategy: rename in place, deprecate with a shim, or coordinated swap
- [ ] Update docs, examples, and changelog in the same change — never leave them for a follow-up

## Before Adding a Dependency

- [ ] Search the codebase for similar functionality already available
- [ ] Check bundle impact — 2KB utility or 200KB library?
- [ ] Check existing `package.json` for a library that already covers this

## Before Destructive or Irreversible Operations

Operations whose blast radius extends beyond the working tree need a pause point. Examples: `rm -rf`, `git push --force`, `git reset --hard`, branch deletion, database migrations, schema/auth/permission changes, external API calls with side effects.

- [ ] Name the exact operation, target, and blast radius before running it — vague intent produces wrong targets
- [ ] Confirm the operation is reversible — if not, snapshot, branch, or back up first
- [ ] Search for callers, references, and downstream consumers the change will break if the target disappears
- [ ] Prefer the narrowest equivalent: a file path over a directory, a single commit over a branch reset, a dry-run over an apply
- [ ] When running unattended, require an explicit acknowledgment phrase from the user before proceeding — silent vetoes hide intent, ceremonies preserve it
- [ ] Verify the actual outcome after the operation — destructive commands often "succeed" silently against the wrong target
