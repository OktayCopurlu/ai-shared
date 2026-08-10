---
name: manual-qa
description: "Plan and execute evidence-based functional and regression QA from requirements plus the actual diff. Use when asked for manual QA, QA plans or instructions, PR/ticket validation, or runtime checks beyond automated tests. For visible frontend changes, orchestrate the separate validating-ui skill."
---

# Manual QA

Turn requirements and changed files into executable checks, run them, and report evidence. A plan alone is not completed QA.

## Workflow

1. Gather the ticket or request, acceptance criteria, linked designs/specs, PR or local diff, runtime target, flags/variants, test data, and known blockers.
2. Select `smoke`, `focused`, or `full` depth using the rules below.
3. Create a temporary plan from `~/.ai-shared/references/manual-qa-checklist.md`. Default to `$TMPDIR/manual-qa/<ticket-or-branch>-<timestamp>.md`; keep it outside the repository and do not commit it.
4. Build checks from both requirements and the actual diff. Include a targeted regression check for changed areas not explained by the ticket.
5. Execute the plan through the lightest observable runtime:
   - visible frontend change: load `validating-ui`; use its browser, recovery, experiment, design-fidelity, and verdict rules without duplicating them here
   - form, dialog, menu, keyboard, focus, or error interaction: load `a11y-audit`
   - browser interaction: load `playwright-mcp` for tool routing
   - analytics requirement: use network/console evidence or `amplitude-analytics`
   - non-UI behavior: use the relevant CLI, API, dev server, focused script, or existing harness
6. Mark every planned check `Pass`, `Fail`, `Blocked`, or `Not verified` and attach concrete evidence. If the implementation caused a failure and the task authorizes changes, fix it and rerun the affected checks.
7. Report the verdict, regression coverage, blockers, and anything not verified. Include the temporary plan path.

## Depth

- **Smoke:** Runtime access is limited or only the lightest relevant surface can be exercised.
- **Focused:** Default. Cover the primary scenarios plus diff-driven regression risk.
- **Full:** Use for auth, checkout, pricing, routing, tracking, experiments, shared components, or broad data/contract changes. Cover important states, variants, and adjacent consumers.

If uncertain, choose `focused` and state what remains unverified.

## Result Format

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

## Rules

- Do not substitute manual QA for lint, types, or automated tests.
- Do not report `Pass` without executed checks and evidence.
- Separate implementation failures from environment/access blockers and intentionally unverified items.
- Let `validating-ui` own browser recovery and design-fidelity detail; include its outcome in the overall QA verdict.

## See Also

- `validating-ui` — browser-level visual and runtime validation
- `a11y-audit` — accessibility checks for interactive UI
- `playwright-mcp` — browser automation
- `~/.ai-shared/references/manual-qa-checklist.md` — QA plan template and risk cues
