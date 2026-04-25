---
description: "Implement a Jira ticket: code changes, quality gates, manual QA, and UI validation. Use with a ticket key or link."
---

# Implementation

When the user provides the ticket key or link:

1. read the full Jira detail via Atlassian MCP
2. open and read the linked context required to implement or validate the change — Figma, Contentful, wiki pages, linked tickets, and any other relevant referenced URLs
   - prefer first-party MCP or a direct integration first for known systems
   - if no suitable first-party integration exists, choose the lightest workable path: fetch/read tools for public pages and `playwright-mcp` for browser flows that need interaction, authenticated state, or inspection
   - if the page needs login, workspace membership, or browser state, prefer an explicit authenticated browser path such as `playwright-mcp --extension` or `--cdp` instead of inventing ad-hoc browser profile handling
   - if the environment blocks the target domain or browser route, stop and report the blocker clearly instead of repeatedly scraping smart-link serialization or asking the user to paste protected content or credentials
   - when linked context is successfully opened, extract the implementation-relevant details before moving on
3. determine the target repository

Proceed to implementation after all required linked context has been reviewed.

## Code Changes

If the ticket is a code workflow:

1. enter the configured workspace
2. verify the repository matches the target determined in step 3
3. reuse an existing ticket branch for `in-progress` work when possible
4. create a new ticket branch for `todo` work when needed
5. ensure the branch name includes the Jira ticket key
6. load the `applying-coding-style` skill — apply it to all code written from this point forward
7. when behavior changes, read the existing test file first and decide test coverage intentionally:
   - identify the **domain invariants / business rules** the change must preserve (what must always be true — e.g. totals, pricing/rounding, auth boundaries, state transitions) and ensure at least one test would fail if a rule were violated, not just if the happy path breaks
   - if the change is permanent, shared, or expected to stay: add or update tests in the same pass
   - if the change is experiment-specific and likely temporary: test updates may be skipped to avoid wasting effort on short-lived code
   - do not remove or weaken existing meaningful coverage only because a change is experimental
8. if the ticket involves UI changes, run a **pre-implementation discovery** before writing code (see also `~/.ai-shared/references/search-first.md`):
   - search shared/design-system components for anything that matches the UI elements in the ticket or Figma
   - search the codebase for similar patterns already implemented elsewhere (e.g. same layout, same interaction, same data shape)
   - if a shared component exists, verify its prop/slot API covers the ticket's needs before deciding to use it, extend it, or build something new
   - if a similar pattern exists elsewhere, reuse the same approach rather than inventing a parallel one
9. if the UI work touches forms, dialogs, menus, navigation, keyboard interaction, focus handling, or error states, load the `a11y-audit` skill during implementation and apply it while building
10. if the ticket is large, cross-layer, or under-specified, apply the Task Shape and Context rules before implementation
11. read the minimum code context needed and begin implementation

### Task Shape and Context

Use `~/.ai-shared/references/work-shaping.md` when the ticket is large, cross-layer, or under-specified.

- For small, clear, single-slice work, skip shaping and implement directly after required context is reviewed.
- Keep the active implementation slice small enough to explore, implement, test, and review in one focused pass.
- If the work is still a layer-by-layer plan, pause implementation and reshape it into vertical slices.
- Use read-only subagents for broad exploration, then continue with only the concise findings needed for the current slice.
- Treat unresolved product, design, or architecture choices as human-in-loop blockers, not implementation details to invent.
- Treat AFK implementation output as a draft until quality gates, cross-check, and human QA/review are complete.

### Workspace Convention

Use the configured workspace root. Default to `~/Desktop/` when no other workspace root is explicitly configured.

To find a repository workspace:

1. look for a matching directory under the configured workspace root
2. if not found, clone from the `onrunning` GitHub org into the configured workspace root

Do not work in a repository outside the configured workspace root unless explicitly configured otherwise.

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
4. coding style review — review all changed files against the `applying-coding-style` skill (already loaded during implementation). Fix violations before continuing.

If shared packages were changed, widen the scope enough to cover the real impact.

Quality gates are complete when all mandatory checks pass, `applying-coding-style` violations are resolved, and no known validation failure remains.

### Failure Policy

If a gate fails because of the implementation: fix it, rerun.

If a gate fails for a likely unrelated or flaky reason: record it, continue by default if confidently unrelated.

Pause only when it is unsafe to continue or the failure cannot be attributed.

## Smoke Test the Change

After quality gates pass and before cross-check, exercise the running code at least once. Tests proving "the unit works" do not prove "the change works wired up". This catches missing wiring, server startup crashes, mock/real divergence, and regressions automated tests did not cover.

Skip only if the change is a pure cosmetic refactor with no behavior change, or if the change is UI-only (use `validating-ui` instead).

Pick a method that matches the change:

| Change type | Smoke method |
|---|---|
| New or changed library function | `python -c` / `node -e` / `tsx` script that imports and calls it with realistic inputs |
| New or changed JSON / REST endpoint | start the dev server, run `curl` against the route, inspect status and payload |
| New or changed GraphQL field/resolver | run the actual query against the dev server, not the unit test mock |
| New or changed CLI command | run `--help` plus one realistic invocation |
| Server / build / worker change | restart the process, confirm it boots, hit a health endpoint or grep the expected log line |
| Config / dependency change | run the build and one downstream command that exercises the changed surface |

Rules:

- exercise the **running code**, not a mock, stub, or unit-test harness
- use real-shaped inputs and at least one edge case (empty, null, max length, unicode, unauthenticated)
- after a server, worker, or build change, restart and re-test — never trust the old process
- write throwaway scripts to `/tmp/` so they cannot be committed by accident
- if the smoke test exposes a defect, fix it and add a regression test before continuing — load `test-driven-development`

Smoke test is complete when at least one method has been run successfully against the actual change and any defects discovered have been fixed and guarded.

## Cross-Check

After the smoke test passes, compare the implementation against the ticket's full contract — not just the AC list.

1. for each AC item, confirm it is covered by the code changes
2. also check behaviors the spec defines beyond AC bullets — failure states, duplicate/repeat behavior, edge cases, and business invariants identified in step 7
3. if an AC item or contract behavior is not addressed, go back and implement it before continuing
4. if the implementation had to invent behavior because the spec did not settle it, flag that as a **spec gap** (not a code bug) and surface it in the PR description so the ticket or spec can be tightened

Cross-check is complete when every AC item and spec-defined behavior is accounted for, and any spec gaps are explicitly recorded.

## Manual QA

After cross-check, choose manual QA depth from the risk in the ticket, linked context, and local diff.

For medium or large changes, user-facing behavior, changed workflows, stateful logic, risky config, or any unclear blast radius: load the `manual-qa` skill and execute a focused manual QA run. Create a temporary QA plan, execute it, update the plan with results, and report the verdict. Include regression checks for changed files that are not directly explained by the ticket.

For small docs-only changes, harmless config metadata, or mechanical refactors with no observable behavior risk: do not manufacture a QA ceremony. Either run a cheap smoke check when there is an obvious one, or mark manual QA as not verified with a clear reason.

If the QA plan includes visible UI impact - e.g., component changes, layout shifts, styling updates, new UI elements, or a Figma link in the ticket - load the `validating-ui` skill and execute it as part of manual QA. If the ticket contains a Figma link, use it as the design reference.

If the changes are purely backend, config, or logic-only with no UI surface, run focused manual QA for the observable behavior when risk exists. If there is no practical observable path, mark the relevant checks as not verified with a reason.

### UI Validation

Determine whether the changes have visible UI impact - e.g., component changes, layout shifts, styling updates, new UI elements, or a Figma link in the ticket.

If yes: load the `validating-ui` skill and follow its checklist and verdict format. If the ticket contains a Figma link, use it as the design reference.

Treat UI validation as evidence gathering, not a replacement for human taste. If the change involves subjective UX, visual polish, product feel, or copy judgement, report what was verified and what still needs human review.

If manual QA already executed `validating-ui`, do not duplicate the same browser checks. Reuse the manual QA evidence and only run missing UI checks.

If the changes are purely backend, config, or logic-only with no UI surface: skip UI validation. Manual QA may be focused smoke coverage or explicitly not verified with a reason, based on risk.

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
