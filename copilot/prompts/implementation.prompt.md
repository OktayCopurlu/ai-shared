---
description: "Implement a Jira ticket: code changes, quality gates, UI validation, and OpenCode CLI handoff. Use with a ticket key or link."
---

# Implementation

When called from `start-working`, use the passed step-2 analysis and route as context. Do not re-read Jira.

When called standalone, the user provides the ticket key or link. Read the full Jira detail via Atlassian MCP and determine the target repository and whether UI validation is needed before proceeding.

## Code Changes

If the ticket is a code workflow:

1. enter the configured workspace
2. verify the repository matches the routing decision
3. reuse an existing ticket branch for `in-progress` work when possible
4. create a new ticket branch for `todo` work when needed
5. ensure the branch name includes the Jira ticket key
6. resolve linked context such as Figma, Contentful, or wiki pages when relevant
7. read the minimum code context needed and begin implementation

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

If shared packages were changed, widen the scope enough to cover the real impact.

Quality gates should also include a coding-style review against repository conventions and the active coding-style skill.

Quality gates are complete when all mandatory checks pass and no known validation failure remains unresolved.

### Failure Policy

If a gate fails because of the implementation: fix it, rerun.

If a gate fails for a likely unrelated or flaky reason: record it, continue by default if confidently unrelated.

Pause only when it is unsafe to continue or the failure cannot be attributed.

## UI Validation

If `needs UI validation = yes`, run browser validation after quality gates.

Load the `ui-validation` skill and follow its checklist and verdict format.

If `needs UI validation = no`, skip this step.

### Failure Policy

If browser validation fails because of the implementation: fix it, rerun.

If browser validation causes code changes: rerun quality gates before continuing.

## OpenCode CLI Handoff

After UI validation is complete (or skipped if not needed), trigger OpenCode CLI and exit.

Once handoff is triggered successfully, do not perform any further local edits in this workflow. The OpenCode CLI session owns the working tree from this point.

If UI validation was required (`needs UI validation = yes`) but was not run, go back and run it first.

### Launch Method

Open OpenCode CLI in a **separate Terminal window** so the user can watch its progress:

```
osascript -e 'tell application "Terminal" to do script "cd <repo-path> && opencode -p \"<handoff-prompt>\""'
```

Replace `<repo-path>` with the target repository workspace path and `<handoff-prompt>` with the assembled prompt.

Do not run OpenCode inline in the current process. The user must be able to observe the handoff agent independently.

### Handoff Prompt

Pass the handoff as a prompt argument to `opencode`. No intermediate files are written.

The prompt must include:

- Jira ticket key
- target repository
- ticket branch name
- short summary of what was implemented
- whether UI validation was done
- any known caveats or unresolved notes

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

- do not start implementation before the route is decided
- do not create a branch in the wrong repository
- do not replace missing required fields with guesses
- do not ask the user a live clarifying question during automated execution
- do not treat a half-finished local state as implementation complete
- do not skip mandatory failing gates
- do not treat UI validation as screenshot-only checking
