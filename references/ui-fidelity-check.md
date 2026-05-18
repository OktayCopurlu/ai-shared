# UI Fidelity Check

Three-way check used to claim a UI implementation matches a Figma design. Screenshots alone are not validation.

Referenced by `validating-ui`, `figma-mcp`, `manual-qa`, `a11y-audit`, and the implementation / review prompts. Load this **before** stating that a UI change matches Figma.

## The Three Sources (all required)

1. **Figma specs** — pull exact values via `figma-mcp` for the correct platform variant (web / mobile / desktop node — not a different platform's frame).
2. **Codebase** — read the actual SCSS/CSS for every changed component. Check every side explicitly: `padding-top`, `padding-right`, `padding-bottom`, `padding-left`, and the same for `margin`. Resolve design-system tokens to their final values.
3. **Browser** — measure the rendered DOM via `browser_evaluate` + `getComputedStyle` for the same properties. Report Figma → computed deltas, never "looks right".

A check that skips any of the three is incomplete.

## Properties To Compare

For each changed or new component, at minimum:

- spacing: `padding`, `margin`, `gap` (per side, not shorthand summaries)
- sizing: `width`, `height`, `min-*`, `max-*` where the design specifies them
- typography: `font-size`, `line-height`, `font-weight`, `letter-spacing`, `font-family`
- color: `color`, `background-color`, `border-color` (compare hex/rgba, not visual similarity)
- borders/corners: `border-width`, `border-radius`

Report each deviation as `Figma value → computed value` with the property name. Tolerate ≤1px rounding on dimensions; treat any color/typography mismatch as a finding.

## Token Discipline

If the codebase has design tokens (CSS variables, theme keys), verify the implementation uses them rather than hardcoded numbers. A value that matches Figma but bypasses the token system is still a finding.

## Viewport Matrix

Run the check at both desktop (≥1280px) and mobile (375px) viewports unless the change is explicitly scoped to a single layout. State the scope explicitly when skipping a viewport.

## Consumer Coverage

A shared component with multiple consumers must be measured on at least one real consumer per layout. Do not assume "same component = same render" without checking at least one instance. State explicitly when variants are skipped.

## Common Gotchas

- UA defaults leaking through: e.g. `<dialog>` default `padding: 1em` if `padding-top` is not reset. Always check computed style on the rendered element, not just the rule you wrote.
- Reading only one side of `padding` / `margin` and missing asymmetric mismatches.
- Comparing against the wrong Figma variant (mobile design vs. desktop render, or a different platform's frame).
- Approving on screenshot resemblance without computed-style numbers.

## Verdict Rule

Do not claim a UI change matches Figma until all three sources have been compared for every property in the list above on at least one real consumer per required viewport. If any check is skipped, label it explicitly in the report and surface what still needs human review.
