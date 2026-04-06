---
name: ui-validation
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
