---
description: "Implement a Jira ticket: code changes, quality gates, manual QA, and UI validation. Use with a ticket key or link."
---

# Implementation

When the user provides the ticket key or link:

1. read the full Jira detail via Atlassian MCP
2. open and read the linked context required to implement or validate the change — Figma, Contentful, wiki pages, linked tickets, and any other relevant referenced URLs. Use the `linked-context-routing` skill to pick the right tool, and `playwright-mcp` for authenticated browser flows. If the environment blocks access, stop and report the blocker. Extract implementation-relevant details before moving on.
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
   - when a Figma reference exists, use `figma-mcp` to extract exact design tokens **before** writing styles: spacing, padding, margin, gap, font-size, line-height, font-weight, color, border-radius, border-width. Prefer existing design-system variables; only fall back to Figma's raw values when no variable matches. Do not eyeball values from a screenshot. See `~/.ai-shared/references/ui-fidelity-check.md` for the verification rules that will be applied during validation.
9. if the UI work touches forms, dialogs, menus, navigation, keyboard interaction, focus handling, or error states, load the `a11y-audit` skill during implementation and apply it while building
10. if the ticket is large, cross-layer, or under-specified, apply the Task Shape and Context rules before implementation
11. read the minimum code context needed and begin implementation

### Task Shape and Context

For large, cross-layer, or under-specified tickets, follow `~/.ai-shared/references/work-shaping.md` to break work into vertical slices before implementing. Skip shaping for small, clear, single-slice work. Treat unresolved product/design/architecture choices as human-in-loop blockers, not details to invent.

### Workspace and Branch Rules

Follow the `git-workflow` skill for workspace location, branch naming (must include Jira key), base branch selection, and remote sync before branching.

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

## Cross-Check

After quality gates pass, compare the implementation against the ticket's full contract — not just the AC list.

1. for each AC item, confirm it is covered by the code changes
2. also check behaviors the spec defines beyond AC bullets — failure states, duplicate/repeat behavior, edge cases, and business invariants identified in step 7
3. if an AC item or contract behavior is not addressed, go back and implement it before continuing
4. if the implementation had to invent behavior because the spec did not settle it, flag that as a **spec gap** (not a code bug) and surface it in the PR description so the ticket or spec can be tightened

Cross-check is complete when every AC item and spec-defined behavior is accounted for, and any spec gaps are explicitly recorded.

## Manual QA

After cross-check, choose manual QA depth from the risk in the ticket, linked context, and local diff.

For medium or large changes, user-facing behavior, changed workflows, stateful logic, risky config, or any unclear blast radius: load the `manual-qa` skill and execute a focused manual QA run. Create a temporary QA plan, execute it, update the plan with results, and report the verdict. Include regression checks for changed files that are not directly explained by the ticket.

For small docs-only changes, harmless config metadata, or mechanical refactors with no observable behavior risk: do not manufacture a QA ceremony. Either run a cheap smoke check when there is an obvious one, or mark manual QA as not verified with a clear reason.

If the changes have visible UI impact — component changes, layout shifts, styling updates, new UI elements, or a Figma link in the ticket — load the `validating-ui` skill and follow its checklist and verdict format as part of manual QA. If the ticket contains a Figma link, use it as the design reference. Treat UI validation as evidence gathering, not a replacement for human taste; report what was verified and what still needs human review for subjective UX, visual polish, or copy.

Do not skip manual QA or UI validation after one failed attempt to reach the target UI. If localhost will not open, the preview is missing, the changed section is not visible, the route is wrong, the locale/data state differs, or a flag/experiment hides the UI, follow the `validating-ui` Validation Recovery Protocol before marking anything blocked or not verified. Try reasonable preview/local/route/data/flag/component-surface fallbacks and record the attempts.

If the changes are purely backend, config, or logic-only with no UI surface, run focused manual QA for the observable behavior when risk exists. If there is no practical observable path, mark the relevant checks as not verified with a reason.

### Failure Policy

If manual QA or UI validation fails because of the implementation: fix it, rerun. If the fix causes code changes, rerun quality gates before continuing.

If manual QA or UI validation cannot reach the target environment, treat that as a validation recovery problem first, not an automatic skip. Only report `Blocked` or `Not verified` after the recovery attempts are recorded.

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

## Senior Reflection

After reporting the implementation result, append a short **"🎯 Senior Reflection"** block at the very end of the response — 3–4 bullets max, rotating the lens based on the ticket type. Pull questions from `~/.ai-shared/references/senior-fundamentals.md`. Do not answer the questions yourself; surface them so the user can act on them as the human owner of the work.

Default rotation for implementation work — pick the lenses that fit:

- **Ownership** — Which metric will this move? Where and when will you check it post-ship (Sentry, analytics, user feedback)?
- **Problem Framing** — Did the implementation surface anything that suggests we're solving the wrong problem, or solving it the wrong way?
- **Spec Gaps** — Were there behaviors I had to invent because the spec was silent? Worth flagging back to the ticket?
- **Technical Communication** — Does the PR description explain *why*, alternatives considered, and trade-offs — not just *what* changed?
- **Scope / Saying No** — Did scope creep during implementation? Anything that should be a follow-up ticket instead of bundled here?

Keep the block terse. The goal is a daily nudge toward senior-level behaviors, not a checklist ceremony.

## Wins Log Nudge

After the Senior Reflection block, append a single-line prompt:

> 📝 **Wins log?** If this shipped something with real impact, glue work, or mentorship — add 1 line to `~/.ai-shared/wins/{year}.md`. Format: `YYYY-MM-DD — did X, with Y impact`. See `~/.ai-shared/references/wins-log.md`.

Do not write the entry yourself — the user owns what counts as a win. Skip this nudge if the implementation was trivial (typo fix, dependency bump, no observable outcome).

## Decision Journal Nudge

If the implementation involved a non-trivial technical decision (picked one tool/pattern over another, took a deliberate shortcut, diverged from convention, designed a contract other code will rely on), append a single-line prompt after the Wins Log nudge:

> 🧭 **Decision journal?** This involved a real trade-off. Consider 5 lines in `~/.ai-shared/decisions/{year}.md` (What / Context / Alternatives / Trade-off / Revisit). See `~/.ai-shared/references/decision-journal.md`.

Do not write the entry yourself. Skip this nudge if there was only one viable approach or the choice was the framework default.

## Guardrails

- do not start implementation before the target repository is confirmed
- do not create a branch in the wrong repository
- do not replace missing required fields with guesses
- do not ask the user a live clarifying question during automated execution
- do not treat a half-finished local state as implementation complete
- do not skip mandatory failing gates
- do not treat UI validation as screenshot-only checking
