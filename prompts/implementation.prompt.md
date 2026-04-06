---
description: "Implement a Jira ticket: code changes, quality gates, and UI validation. Use with a ticket key or link."
---

# Implementation

When the user provides the ticket key or link:

1. read the full Jira detail via Atlassian MCP
2. open and read every link in the ticket — Figma, Contentful, wiki pages, linked tickets, and any other referenced URLs
3. determine the target repository

Proceed to implementation after all linked context has been reviewed.

## Code Changes

If the ticket is a code workflow:

1. enter the configured workspace
2. verify the repository matches the target determined in step 3
3. reuse an existing ticket branch for `in-progress` work when possible
4. create a new ticket branch for `todo` work when needed
5. ensure the branch name includes the Jira ticket key
6. load the `coding-style` skill — apply it to all code written from this point forward
7. if the ticket involves UI changes, run a **pre-implementation discovery** before writing code:
   - search shared/design-system components for anything that matches the UI elements in the ticket or Figma
   - search the codebase for similar patterns already implemented elsewhere (e.g. same layout, same interaction, same data shape)
   - if a shared component exists, verify its prop/slot API covers the ticket's needs before deciding to use it, extend it, or build something new
   - if a similar pattern exists elsewhere, reuse the same approach rather than inventing a parallel one
8. read the minimum code context needed and begin implementation

### Workspace Convention

All repositories live under `~/Desktop/`.

To find a repository workspace:

1. look for a matching directory under `~/Desktop/`
2. if not found, clone from the `onrunning` GitHub org into `~/Desktop/`

Do not work in a repository outside `~/Desktop/` unless explicitly configured otherwise.

### Branch Rules

- branch names must include the Jira ticket key
- reuse an existing ticket branch when it is clearly the active work branch
- default base branch is `main`; if `main` does not exist, use `master`
- before creating a new ticket branch, update the base branch with the latest remote state
- if neither `main` nor `master` exists, pause instead of guessing

### Implementation Quality

Do not optimize for the smallest diff. Optimize for the most correct implementation.

- prefer the real source of truth over a superficial patch
- if the right fix belongs in mapping, transformation, API usage, or GraphQL selection, make it there
- avoid unnecessary refactors, but do not avoid necessary structural changes just to keep the diff small

### Implementation Completion

Implementation is complete when:

- the ticket scope has been implemented in the correct repository and ticket branch
- required linked context has been incorporated
- no known core change is still missing
- the working tree is coherent enough to continue into quality gates

## Quality Gates

After implementation, run quality gates before anything else.

Use repository-defined commands. Do not invent custom validation commands.

Recommended order:

1. lint
2. type checks
3. unit tests
4. coding-style review — review all changed files against the `coding-style` skill (already loaded during implementation). Fix violations before continuing.

If shared packages were changed, widen the scope enough to cover the real impact.

Quality gates are complete when all mandatory checks pass, coding-style violations are resolved, and no known validation failure remains.

### Failure Policy

If a gate fails because of the implementation: fix it, rerun.

If a gate fails for a likely unrelated or flaky reason: record it, continue by default if confidently unrelated.

Pause only when it is unsafe to continue or the failure cannot be attributed.

## Cross-Check

After quality gates pass, compare the implementation against the ticket's acceptance criteria.

For each AC item, confirm it is covered by the code changes. If an AC item is not addressed, go back and implement it before continuing.

Cross-check is complete when every AC item is accounted for.

## UI Validation

After cross-check, determine whether the changes have visible UI impact — e.g., component changes, layout shifts, styling updates, new UI elements, or a Figma link in the ticket.

If yes: load the `ui-validation` skill and follow its checklist and verdict format. If the ticket contains a Figma link, use it as the design reference.

If the changes are purely backend, config, or logic-only with no UI surface: skip this step.

### Failure Policy

If browser validation fails because of the implementation: fix it, rerun.

If browser validation causes code changes: rerun quality gates before continuing.

## Blocker Handling

This is an automation. Do not stop to ask the user live questions during execution.

When execution is blocked:

1. stop work on the current ticket
2. return `pause-for-human`
3. explain the blocker clearly
4. include what was checked before pausing
5. let the workflow controller move on to another actionable ticket if one exists

Pause for: contradictory requirements, inaccessible linked context, repository ambiguity, unsafe local repo state, missing credentials.

Do not pause only because the correct implementation touches multiple files or shared interfaces.

## Guardrails

- do not start implementation before the target repository is confirmed
- do not create a branch in the wrong repository
- do not replace missing required fields with guesses
- do not ask the user a live clarifying question during automated execution
- do not treat a half-finished local state as implementation complete
- do not skip mandatory failing gates
- do not treat UI validation as screenshot-only checking
