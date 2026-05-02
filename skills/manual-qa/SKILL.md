---
name: manual-qa
description: "Manual QA execution workflow. USE FOR: creating and running QA checks from Jira tickets, PR diffs, local changes, preview URLs, or regression risk. Use when asked for manual QA, QA plan, QA checklist, test instructions, or functional/regression validation beyond automated tests."
---

# Manual QA

Create a temporary QA plan, execute it, and report evidence. Do not stop at writing the plan unless there is no runnable environment or access is blocked.

## When To Use

- After implementing a ticket, before final PR handoff.
- During PR review when ticket requirements and PR changes need functional validation.
- For a single PR when the user invokes manual QA with a PR URL or PR number.
- When the user asks for manual QA, QA plan, test instructions, or regression checks.
- When code changed outside the explicit ticket scope and needs regression coverage.

Do not use this as a replacement for automated tests, type checks, lint, or `validating-ui`. Use it to cover the human-facing functional checks those gates do not prove.

## Workflow

1. Gather the smallest complete context:
   - ticket summary, acceptance criteria, and linked design/spec references
   - local diff or PR diff, including files unrelated to the ticket
   - for single PR mode, PR description, comments, CI status, linked ticket, changed files, and preview URL
   - preview URL, local URL, feature flags, variants, and required test data
   - previous validation results and known blockers
2. Pick QA depth from risk and available runtime:
   - `smoke`: CI is failing but preview is reachable, the change is docs/config/build-only, or runtime access is limited. Verify only that the relevant surface loads or the lightest observable behavior still works.
   - `focused`: default for normal PRs and ticket work. Cover the primary ticket scenarios plus targeted regression checks from the diff.
   - `full`: use for checkout, auth, pricing, routing, tracking, experiments, shared components, broad data mappers, or changes with high blast radius. Cover primary flows, important states, variants, and adjacent consumers.
   - If unsure, choose `focused` and explain any checks that are not verified.
3. Classify risk from both requirements and changed files:
   - primary ticket flow
   - error, empty, loading, disabled, and repeat states
   - shared components, composables, stores, mappers, GraphQL queries, tracking, routing, auth, checkout, pricing, localization, and feature flags
   - any changed area that is not mentioned by the ticket
4. Write a temporary QA run plan before executing checks.
   - Default path: `$TMPDIR/manual-qa/<ticket-or-branch>-<timestamp>.md`
   - If `$TMPDIR` is unavailable, use a host-provided temporary directory outside the repo.
   - Do not commit the temporary plan.
   - Include each check with `Status: planned` before execution.
   - Include the selected QA depth and why it was chosen.
5. Execute the plan yourself.
   - For visible UI impact, load `validating-ui` and execute browser validation as part of this QA run.
   - For forms, dialogs, menus, navigation, keyboard interaction, focus handling, or error states, load `a11y-audit` for the relevant checks.
   - For browser interaction, load `playwright-mcp` and use the app directly where possible.
   - For tracking, verify event names, triggers, and payloads through browser console logs or network requests.
   - For non-UI work, exercise the observable behavior through the lightest runnable path: CLI, API, dev server, focused script, or existing test harness.
6. Update the temporary plan as checks complete.
   - Use `Pass`, `Fail`, `Blocked`, or `Not verified`.
   - Record concrete evidence: URL, viewport, input data, observed output, console/network result, command output, or blocker.
7. Report the final QA result.
   - Summarize primary scenarios, regression checks, failures, blockers, and not-verified items.
   - Include the temporary plan path for traceability.
   - If anything failed because of the implementation, fix it and rerun the affected QA checks.

## Regression Heuristics

Always add regression checks when the diff touches:

- shared UI components or design-system wrappers: validate at least one other consumer
- composables, stores, hooks, helpers, or mappers: validate one adjacent flow that uses the same abstraction
- GraphQL/API queries or response mapping: validate expected data shape and one existing consumer path
- feature flags or experiments: validate enabled and disabled states when controllable
- routing, auth, checkout, pricing, localization, or tracking: validate the changed flow plus the nearest high-risk adjacent behavior
- files not explained by the ticket: add a regression check for the user-facing behavior they affect, or mark the risk as not verified

## Output Format

```md
## Manual QA

- Plan: <temporary plan path>
- Source: <ticket / PR / local diff>
- Environment: <preview/local URL or command path>
- Depth: smoke | focused | full - <reason>

### Verdict: Pass | Pass with notes | Fail | Blocked

### Executed Checks
| Check | Status | Evidence |
|---|---|---|

### Regression Checks
| Area | Status | Evidence |
|---|---|---|

### Not Verified
- <item> - <reason>
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I wrote a QA plan, so QA is done." | The plan is only the checklist. Manual QA is complete only after checks are executed or explicitly blocked. |
| "UI validation covers QA." | UI validation covers browser/rendering evidence. Manual QA also covers ticket intent, regression risk, data states, and non-UI behavior. |
| "The ticket did not mention this changed file." | Ticket-unrelated changes are exactly where regression risk hides. Add a targeted check or mark it not verified. |
| "Automated tests passed." | Passing tests do not prove preview behavior, flags, data wiring, tracking payloads, or adjacent UI regressions. |

## Red Flags

- Final answer contains only a plan with no executed checks.
- QA ignores changed files outside the ticket scope.
- UI-affecting changes skip browser evidence.
- Regression checks are generic rather than tied to actual changed files.
- Items are marked pass without evidence.

## Verification

After manual QA:

- [ ] Temporary QA plan was created before execution.
- [ ] QA depth was selected and justified.
- [ ] Each planned check has a final status.
- [ ] Ticket acceptance criteria are covered or listed as not verified.
- [ ] Diff-driven regression risks are covered or listed as not verified.
- [ ] UI validation was run when visible UI changed.
- [ ] Failures and blockers are separated from not-verified items.

## See Also

- `validating-ui` - browser-level visual and runtime validation
- `a11y-audit` - accessibility checks for interactive UI
- `playwright-mcp` - browser automation
- `~/.ai-shared/references/manual-qa-checklist.md` - QA planning template and risk checklist
