---
name: validating-ui
description: "Frontend UI validation methodology after implementation. USE FOR: verifying visual correctness, runtime health, design comparison, regression checks, and deciding pass/fail after code changes. ALWAYS use when a ticket has UI impact and needs browser-level validation before PR."
---

# UI Validation

Defines what to validate in the browser after frontend implementation and how to decide pass or fail.

This skill does not explain how to use browser tools — load `playwright-mcp` or `chrome-devtools-mcp` for that. It does not cover accessibility — load `a11y-audit` for that.

## When To Use

- The change visibly affects rendered UI (component changes, layout, styling, new elements).
- After implementation is complete and quality gates (lint, types, tests) have passed.
- Before committing the final state or creating a PR.

## Validation Checklist

Run these checks in order. Stop early if a critical failure is found.

### 1. Page Load

- Page loads without a blank screen or crash.
- No unhandled errors in the console.
- No failed network requests that block rendering (4xx/5xx on critical resources).
- Hydration completes without mismatch warnings (check console for hydration errors).

### 2. Visual Correctness

- Test at both desktop (≥1280px) and mobile (375px) viewports. Both are mandatory unless the change is explicitly scoped to a single layout.
- The changed UI renders as expected at each viewport.
- Text content, images, and layout match what the ticket describes.
- Interactive states work: hover, focus, active, disabled, loading, empty, error.
- No layout shifts, overlapping elements, or clipped content in the affected area.
- Layout transitions between breakpoints do not break (no overlapping, collapsing, or hidden content).

### 3. Design Comparison

Only when a Figma reference exists in the ticket:

- Compare the rendered UI to the Figma design at both desktop and mobile breakpoints.
- If Figma provides designs for both viewports, compare both. If only one viewport is designed, compare that one and still verify the other viewport renders correctly.
- Check spacing, sizing, typography, and color against the design.
- Note meaningful deviations — do not chase pixel-perfect alignment on dynamic content.
- If the design shows multiple states (empty, loading, populated, error), verify each one that is reachable at both viewports.

### 4. Runtime Health

- No new console errors or warnings introduced by the change.
- Network requests relevant to the feature return expected data (check response payloads if needed).
- GraphQL queries return the expected shape when the feature uses GraphQL.
- No infinite loops, repeated requests, or excessive re-renders visible in console or network tab.

### 5. Regression

- Navigate to the page or flow that existed before the change.
- Verify that existing behavior still works — especially adjacent UI that shares the same container or data source.
- If the change affects a shared component, check at least one other consumer.

### 6. Tracking

Only when the ticket mentions analytics or tracking:

- Verify that expected tracking events fire with correct payloads.
- Use `amplitude-analytics` skill or network tab to confirm event names and properties.

## How To Run

1. Ensure local dev server is running.
2. Use `playwright-mcp` tools to navigate, interact, and snapshot.
3. Use `chrome-devtools-mcp` tools when deeper inspection is needed (console, network, DOM state).
4. If a11y is relevant, load `a11y-audit` separately — do not mix a11y findings into this validation.

## Verdict

After running the checklist, state one of:

- **Pass**: All checks passed. No issues found.
- **Pass with notes**: Minor issues exist but do not block the ticket. List them.
- **Fail**: One or more checks failed. List the failures with evidence (console output, screenshot description, or observed behavior).

## Verdict Format

```md
## UI Validation

- Viewport(s) tested: <list>
- Design reference compared: yes / no / not available
- Tracking verified: yes / no / not applicable

### Verdict: Pass | Pass with notes | Fail

### Findings

- [check name] result — evidence or note

### Not Verified

- what was skipped and why
```

## Rules

- Do not validate UI before quality gates pass — fix lint/type/test errors first.
- Always test both desktop and mobile viewports. If skipping one, state the reason explicitly in the verdict.
- Do not claim design match without actually comparing to Figma.
- Do not mix accessibility findings into this validation — use `a11y-audit` for that.
- If the page cannot be loaded locally, say so and list what was not verified.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It looks fine on desktop, mobile is probably fine too" | Most layout bugs are viewport-specific. Both viewports are mandatory unless explicitly scoped. |
| "I compared it to the design mentally" | Comparing from memory is unreliable. Open Figma and the browser side by side. |
| "The tests pass, so the UI is correct" | Tests verify logic, not pixels. Visual regressions, layout shifts, and styling issues don't show up in unit tests. |
| "Console warnings are not errors" | Hydration warnings, deprecation notices, and React/Vue warnings often indicate real bugs. Investigate each one. |
| "I'll check regression later" | Adjacent UI sharing the same container or data source can break silently. Check it now. |
| "The change is too small to need browser validation" | Even a one-line CSS change can cause layout shifts across viewports. Small changes are quick to validate. |

## Red Flags

- Verdict says "Pass" but only one viewport was tested
- Design comparison claimed without a Figma link in the ticket
- Console errors dismissed as "pre-existing" without verification
- No regression check on adjacent UI
- Validation done before quality gates passed
- Tracking verification skipped when the ticket mentions analytics

## Verification

After completing UI validation:

- [ ] Page loads without errors or blank screen
- [ ] Both desktop (≥1280px) and mobile (375px) viewports tested
- [ ] Design comparison done against Figma (if reference exists)
- [ ] No new console errors or warnings
- [ ] Regression check on adjacent UI completed
- [ ] Tracking verified (if applicable)
- [ ] Verdict stated with evidence

## See Also

- `a11y-audit` — accessibility validation (separate from UI validation)
- `playwright-mcp` — browser automation for navigation and interaction
- `chrome-devtools-mcp` — console, network, DOM inspection
- `~/.ai-shared/references/performance-checklist.md` — Core Web Vitals and frontend performance checks
