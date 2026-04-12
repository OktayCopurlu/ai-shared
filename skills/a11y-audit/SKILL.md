---
name: a11y-audit
description: 'Build and review frontend UI with accessibility in mind. USE FOR: implementing components, forms, dialogs, menus, and flows that need good semantics, labels, keyboard support, focus management, error handling, and reduced-motion behavior. ALSO use for accessibility reviews, a11y audits, keyboard/focus checks, and prioritizing accessibility issues.'
---

# Accessibility Build And Audit

Prefer preventing accessibility problems during implementation over finding them later in audit.

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

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Screen reader users are a tiny percentage" | Legal risk aside, accessibility fixes improve UX for everyone — keyboard users, motor impairments, temporary injuries. |
| "We'll add accessibility later" | Retrofitting a11y is 5-10x harder than building it in. Semantic HTML costs nothing upfront. |
| "It works with a mouse, so it's fine" | Mouse-only is not accessible. Keyboard and assistive tech must work independently. |
| "ARIA will fix it" | ARIA is a last resort. Wrong ARIA is worse than no ARIA. Semantic HTML first. |
| "The automated scan shows no issues" | Automated tools catch ~30% of a11y issues. Manual keyboard and focus testing is essential. |
| "It's just a visual change, no a11y impact" | Color contrast, focus indicators, hover states, and motion all have direct a11y implications. |

## Red Flags

- Interactive elements built from `div` or `span` without keyboard support
- `aria-label` used where a visible label should exist
- Focus outline removed with no replacement
- Modal or drawer opens without receiving focus
- Form errors only indicated by color
- `tabindex` values greater than 0
- Animations without `prefers-reduced-motion` checks
- "Accessible" verdict with no keyboard testing performed

## Verification

After accessibility work:

- [ ] All interactive elements reachable by keyboard (Tab, Enter, Escape, Arrow keys)
- [ ] Focus visible on every interactive element
- [ ] Focus moves into modals/drawers and returns on close
- [ ] Form inputs have associated labels and error descriptions
- [ ] Semantic HTML used before ARIA
- [ ] No new `tabindex > 0` values introduced
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Verdict includes what was NOT tested

## See Also

- `references/accessibility-checklist.md` — full checklist for keyboard, focus, semantics, labels, and visual design
- `code-review` — a11y issues may surface during Layer 1 or Layer 4 review
- `ui-validation` — browser-level validation that may include accessibility checks
