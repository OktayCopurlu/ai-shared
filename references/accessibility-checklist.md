# Accessibility Checklist

Quick-reference for accessibility review passes. Referenced by `a11y-audit` and `code-review`.

## Keyboard Navigation

- [ ] All interactive elements reachable via Tab
- [ ] Tab order follows visual layout (no unexpected jumps)
- [ ] Custom controls support expected keys (Enter/Space for buttons, Arrow keys for menus)
- [ ] No keyboard traps — user can always Tab out (except modals, which trap intentionally)
- [ ] Skip-to-content link available on pages with repeated navigation
- [ ] Focus ring visible on all focusable elements — never removed without replacement

## Focus Management

- [ ] Focus moves into modals/dialogs when opened
- [ ] Focus returns to trigger element when modal/dialog closes
- [ ] Focus moves to new content when dynamically inserted (toasts, drawers, inline edits)
- [ ] Autofocus used sparingly — only on the primary action in a focused flow (e.g. search input)
- [ ] No focus loss — after deletion, navigation, or state change, focus is on a sensible element

## Semantic HTML

- [ ] Buttons use `<button>`, links use `<a href>` — no clickable `<div>` or `<span>`
- [ ] Headings follow a logical hierarchy (h1 → h2 → h3, no skipping)
- [ ] Lists use `<ul>`/`<ol>` — not styled `<div>` sequences
- [ ] Tables use `<table>`, `<th>`, `<td>` — not grid layouts pretending to be tables
- [ ] Landmark roles present: `<main>`, `<nav>`, `<header>`, `<footer>`
- [ ] Form inputs wrapped in `<form>` with proper `<label>` elements

## Labels & Names

- [ ] Every form input has a visible `<label>` or `aria-label`/`aria-labelledby`
- [ ] Icon-only buttons have accessible names (`aria-label` or visually hidden text)
- [ ] Images have meaningful `alt` text — or `alt=""` for decorative images
- [ ] Links describe their destination — no "click here" or "read more" without context
- [ ] Group labels exist for related form fields (`<fieldset>` + `<legend>`)

## Dynamic Content

- [ ] Live regions (`aria-live`) announce status messages, errors, loading states
- [ ] Alerts use `role="alert"` or `aria-live="assertive"` for urgent messages
- [ ] Status updates use `aria-live="polite"` for non-urgent changes
- [ ] Loading states communicated (spinner + `aria-busy`, or status text)
- [ ] Error messages programmatically connected to inputs (`aria-describedby`)

## Visual Design

- [ ] Text meets 4.5:1 contrast ratio (3:1 for large text)
- [ ] Interactive elements meet 3:1 contrast against background
- [ ] Information not conveyed by color alone — use text, icons, or patterns too
- [ ] Text resizable to 200% without loss of content (no fixed-height containers clipping text)
- [ ] Touch targets at least 44×44px on mobile

## Motion & Animation

- [ ] Non-essential animations respect `prefers-reduced-motion`
- [ ] No auto-playing video or audio without user control
- [ ] No flashing content > 3 flashes per second
- [ ] Carousels/sliders have pause controls

## Testing Tools

```bash
# axe-core CLI
npx @axe-core/cli <url>

# Lighthouse accessibility audit
npx lighthouse <url> --only-categories=accessibility

# pa11y
npx pa11y <url>
```

Browser DevTools: Chrome Accessibility tab, Firefox Accessibility Inspector.
Screen readers: VoiceOver (macOS), NVDA (Windows).
