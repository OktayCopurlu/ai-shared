---
name: a11y-audit
description: 'Build and review frontend UI with accessibility in mind. USE FOR: implementing components, forms, dialogs, menus, and flows that need good semantics, labels, keyboard support, focus management, error handling, and reduced-motion behavior. ALSO use for accessibility reviews, a11y audits, keyboard/focus checks, and prioritizing accessibility issues.'
---

# Accessibility Build And Audit

Use this skill both when writing code and when reviewing UI.

Prefer preventing accessibility problems during implementation over finding them later in audit.

## Use This Skill For

- building new UI
- refactoring interactive components
- reviewing PRs for accessibility risk
- auditing pages or flows in the browser
- debugging keyboard, focus, label, or screen-reader issues

## Core Checks

Always think through these first:

- use semantic HTML before ARIA
- ensure every interactive element has a clear accessible name
- make all core actions reachable by keyboard
- keep focus visible, logical, and intentionally managed
- make forms understandable, including labels and errors
- make dynamic UI communicate state changes
- respect reduced-motion preferences

## Build Guidance

When implementing UI, prefer these defaults:

- use `button`, `a`, `input`, `select`, `textarea`, `dialog`, and headings correctly
- avoid clickable `div` or `span` unless full semantics and keyboard behavior are intentionally recreated
- give icon-only controls an accessible name
- ensure custom controls support expected keyboard interaction
- move focus into modals and return focus when they close
- connect field errors and helper text to the relevant input
- do not remove focus outlines without an accessible replacement
- do not rely on hover-only behavior for important actions
- do not rely only on color or animation to convey meaning

## Review Guidance

When reviewing existing UI or code, check:

- semantics and heading structure
- accessible names and labels
- keyboard reachability and tab order
- focus entry, trapping, return, and visibility
- dialog, menu, drawer, popover, and accordion behavior
- form validation, instructions, and error messaging
- loading, success, and error states
- reduced-motion handling for non-essential animation

## Tooling

- Use Playwright browser tools when a real page or flow can be exercised.
- Use Chrome DevTools MCP when DOM, ARIA, or runtime behavior needs inspection.
- Use code review when the UI cannot be run, but say clearly that the review is partial.
- Do not claim exact color-contrast compliance unless it was actually measured.

## Lightweight Workflow

### If writing code

1. Identify the user interaction.
2. Choose semantic elements first.
3. Add keyboard, focus, labels, and error behavior as part of the implementation.
4. Call out any remaining a11y risks or follow-up verification needs.

### If reviewing or auditing

1. Identify the main user flow.
2. Test keyboard-only interaction when possible.
3. Check focus behavior and interactive states.
4. Inspect suspicious markup or ARIA usage.
5. Report only meaningful findings with concrete fixes.

## Severity

- `critical`: blocks a core task for keyboard or assistive-technology users
- `high`: major friction in an important flow
- `medium`: meaningful issue, but the flow still works
- `low`: polish or consistency issue

## Response Format

### For implementation help

```md
## Accessibility Notes
- what to build or change
- key risks to avoid
- anything still needing manual verification
```

### For audits or reviews

```md
## Verdict
Accessible enough / Needs fixes / High-risk accessibility issues

## Findings
- [severity] Surface: short issue summary
  Why it matters: user impact
  Suggested fix: practical change
  Verify: how to confirm the fix

## Gaps
- what was not verified
```

## Rules

- Prefer semantic HTML before ARIA workarounds.
- Do not treat mouse-only success as accessible behavior.
- Do not overstate certainty when only code was reviewed.
- If no issues are found, say so explicitly and mention any testing gaps.
