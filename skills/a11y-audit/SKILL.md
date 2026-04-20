---
name: a11y-audit
description: 'Build and review frontend UI with accessibility in mind. USE FOR: implementing components, forms, dialogs, menus, and flows that need good semantics, labels, keyboard support, focus management, error handling, and reduced-motion behavior. Use when implementing UI, running an a11y audit, checking keyboard/focus, or prioritizing accessibility issues.'
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
| "We'll add accessibility later" | Retrofitting a11y is 5-10x harder than building it in. Semantic HTML costs nothing upfront. |
| "ARIA will fix it" | ARIA is a last resort. Wrong ARIA is worse than no ARIA. Semantic HTML first. |
| "The automated scan shows no issues" | Automated tools catch ~30% of a11y issues. Manual keyboard and focus testing is essential. |

## See Also

- `~/.ai-shared/references/accessibility-checklist.md` — full checklist for keyboard, focus, semantics, labels, and visual design
- `reviewing-code` — a11y issues may surface during Layer 1 or Layer 4 review
- `validating-ui` — browser-level validation that may include accessibility checks
