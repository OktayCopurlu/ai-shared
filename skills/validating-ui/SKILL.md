---
name: validating-ui
description: "Frontend UI validation methodology after implementation. USE FOR: verifying visual correctness, runtime health, design comparison, regression checks, and deciding pass/fail after code changes. ALWAYS use when a ticket has UI impact and needs browser-level validation before PR."
---

# UI Validation

Defines what to validate in the browser after frontend implementation and how to decide pass or fail.

This skill does not explain how to use browser tools — load `playwright-mcp` for that. It does not cover accessibility — load `a11y-audit` for that.

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
- **Token-level fidelity check (required, not optional).** Visual similarity is not enough — "the button is visible" does not pass this check. For each changed or new component, extract the Figma values via `figma-mcp` and compare against the rendered DOM's computed styles using `browser_evaluate` with `getComputedStyle`. Verify at minimum:
  - spacing: `padding`, `margin`, `gap`
  - sizing: `width`, `height`, `min-*`, `max-*` where the design specifies them
  - typography: `font-size`, `line-height`, `font-weight`, `letter-spacing`, `font-family`
  - color: `color`, `background-color`, `border-color` (compare hex/rgba, not just "looks similar")
  - borders/corners: `border-width`, `border-radius`
- Report each deviation as Figma value → computed value with the property name. Tolerate ≤1px rounding on dimensions; treat any color/typography mismatch as a finding.
- If the codebase has design-system tokens (e.g. CSS variables, theme keys), verify the implementation uses them rather than hardcoded numbers — a value that matches Figma but bypasses the token system is still a finding.
- If the design shows multiple states (empty, loading, populated, error), verify each one that is reachable at both viewports.
- If the ticket or Figma has multiple platform variants, select the web-specific design node before judging spacing or typography.
- Screenshots are supporting evidence, not the primary check. Do not approve design fidelity on screenshots alone.
- If visual polish, copy, or design intent remains subjective after token comparison, prepare a designer handoff with the exact preview URL or Storybook story, viewport, Figma node, and screenshots instead of claiming full design approval.

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
3. For deeper inspection, use `browser_console_messages`, `browser_network_requests`, `browser_snapshot`, and `browser_evaluate`.
4. If a11y is relevant, load `a11y-audit` separately — do not mix a11y findings into this validation.
5. If the change is behind a feature flag, experiment, or A/B test, follow the experiment override protocol below. Test both enabled/disabled or control/treatment states when they are controllable.

### Experiment Override Protocol

Use this when a UI change is gated by a feature flag, experiment, or A/B test.

1. Identify the exact flag or experiment key, expected group names, assignment SDK/helper, and whether assignment is server-side or client-side. Use the ticket, PR description, diff, linked docs, and nearby source code.
2. Look for supported QA override mechanisms before changing browser state: URL parameters, cookies, localStorage, sessionStorage, SDK debug APIs, preview flag endpoints, or documented browser extensions.
3. Apply only a confirmed override. Do not guess cookie or storage keys from the experiment name.
4. For cookie or storage overrides, use `playwright-mcp` to set the value directly on the current origin, then reload. If storage helper tools are unavailable, use browser evaluation with the confirmed cookie or storage key/value.
5. Reload after applying the override and verify the active variant through rendered UI, exposure/tracking payload, network response, or runtime state. A stored value alone is not enough evidence.
6. For localhost-only validation, if the confirmed runtime override cannot be applied because assignment is server-side, extension-only, or unavailable in automation, temporarily hard-code or stub the confirmed flag/experiment return value in the local working tree. Remove the temporary change before finishing and label the evidence as local hard-code validation.
7. If the only available switch is an extension or admin UI that automation cannot operate, and local hard-code validation is not suitable, mark that variant as awaiting user-assisted override and include the exact key/group the user should select.

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
- Token-level fidelity check: pass / pass with deviations / fail / not applicable
- Tracking verified: yes / no / not applicable

### Verdict: Pass | Pass with notes | Fail

### Findings

- [check name] result — evidence or note (for token deviations: `property`: Figma `X` → computed `Y`)

### Not Verified

- what was skipped and why
```

## Rules

- Do not validate UI before quality gates pass — fix lint/type/test errors first.
- Always test both desktop and mobile viewports. If skipping one, state the reason explicitly in the verdict.
- Do not claim design match without actually comparing to Figma.
- Do not use an app/native/mobile-platform design node as the source of truth for web UI unless the ticket explicitly says to.
- Do not treat agent-side UI validation as designer or UX approval. Report the concrete evidence and any design handoff still needed.
- Do not mix accessibility findings into this validation — use `a11y-audit` for that.
- If the page cannot be loaded locally, say so and list what was not verified.
- Do not call a treatment variant blocked after arbitrary cookie attempts; first prove the supported override path or report that the variant needs user-assisted/server-side allocation.
- Do not leave temporary localhost hard-codes or stubs in the final diff unless the user explicitly asks for that implementation change.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It looks fine on desktop, mobile is probably fine too" | Most layout bugs are viewport-specific. Both viewports are mandatory unless explicitly scoped. |
| "It looks right next to the Figma" | Side-by-side visual comparison misses 4px, color, and font-weight drift. Read the computed style and compare to the Figma value. |
| "The button shows up, design matches" | Visibility is not fidelity. Padding, font-size, color, and radius must match the Figma node values. |
| "I'll skip the token check, it's a small change" | Reviewers and designers catch token drift on small changes too. Run the check or mark it not verified with a reason. |
| "I checked Storybook, so design is approved" | Storybook/browser evidence helps reviewers, but subjective UX approval still needs the designer or UX owner when intent is ambiguous. |
| "The tests pass, so the UI is correct" | Tests verify logic, not pixels. Visual regressions, layout shifts, and styling issues don't show up in unit tests. |
| "Console warnings are not errors" | Hydration warnings, deprecation notices, and React/Vue warnings often indicate real bugs. Investigate each one. |
| "I'll check regression later" | Adjacent UI sharing the same container or data source can break silently. Check it now. |
| "The change is too small to need browser validation" | Even a one-line CSS change can cause layout shifts across viewports. Small changes are quick to validate. |

## Red Flags

- Verdict says "Pass" but only one viewport was tested
- Design comparison claimed without a Figma link in the ticket
- Design comparison claimed without a token-level computed-style check — only screenshots or visual side-by-side
- Hardcoded numbers used when matching design-system tokens exist
- Design feedback comes from a different platform node than the implemented web surface
- Console errors dismissed as "pre-existing" without verification
- No regression check on adjacent UI
- Subjective UX or visual-polish questions are marked fully verified without designer handoff evidence
- Validation done before quality gates passed
- Tracking verification skipped when the ticket mentions analytics

## Verification

After completing UI validation:

- [ ] Page loads without errors or blank screen
- [ ] Both desktop (≥1280px) and mobile (375px) viewports tested
- [ ] Design comparison done against Figma (if reference exists)
- [ ] Token-level computed-style check completed for each changed/new component (spacing, sizing, typography, color, borders) — or marked not applicable with reason
- [ ] Design-system tokens used instead of hardcoded values where available
- [ ] Web-specific design node was used when multiple platform variants exist
- [ ] Designer/UX handoff evidence was prepared when subjective visual approval is still needed
- [ ] No new console errors or warnings
- [ ] Regression check on adjacent UI completed
- [ ] Tracking verified (if applicable)
- [ ] Verdict stated with evidence

## See Also

- `a11y-audit` — accessibility validation (separate from UI validation)
- `playwright-mcp` — browser automation for navigation and interaction
- `~/.ai-shared/references/performance-checklist.md` — Core Web Vitals and frontend performance checks
