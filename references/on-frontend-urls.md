# on-frontend URLs

Repository-specific URL and preview authentication conventions for on-frontend work only.

Last updated: 2026-04-24

Scope: Use this reference only when working in the `on-frontend` repo or another repo whose current PRs/workflows confirm the same host patterns. Do not treat it as a cross-repo default.

## Environments

- **Local dev**: `http://localhost:5050`
- **Production**: `https://www.on.com`
- **Shop preview for PRs/docs**: `https://on-shop-<PR_NUMBER>.on.com`
- **Storybook preview for PRs/docs**: `https://on-ui-<PR_NUMBER>.on.com/?path=/story/<story-id>`
- **Shop preview for agent/browser automation**: `https://on:trend@on-shop-<PR_NUMBER>.on.com`
- **Storybook preview for agent/browser automation**: `https://on:trend@on-ui-<PR_NUMBER>.on.com/?path=/story/<story-id>`

## Preview Authentication

For staging or preview URLs that require auth:

- do not look for credentials in the target project repo
- use clean preview URLs in PR descriptions, project docs, review notes, and final user-facing summaries
- use the `on:trend@...` URL form only when navigating a browser or script to a preview URL

## Examples

- `https://www.on.com/en-ch/shop/mens/low` → `http://localhost:5050/en-ch/shop/mens/low`
- `https://www.on.com/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851` → `http://localhost:5050/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851`
- Preview root: `https://on-shop-9096.on.com/`
- Preview page: `https://on-shop-9096.on.com/en-ch/products/cloudspike-citius-2-m-3mf1030/mens/bloom-lime-shoes-3MF10304849`
- Storybook root: `https://on-ui-9096.on.com/`
- Storybook story: `https://on-ui-9096.on.com/?path=/story/components-atoms-boxchip--withmedia`
- Authenticated preview page for agent/browser automation: `https://on:trend@on-shop-9096.on.com/en-ch/products/...`
- Authenticated Storybook story for agent/browser automation: `https://on:trend@on-ui-9096.on.com/?path=/story/components-atoms-boxchip--withmedia`

## Rules

- Never put credential-embedded URLs in PR descriptions, project docs, review comments, screenshots, or final summaries
- Do not generalize the `on:trend` preview auth pattern to other repos, hosts, or credentials
- Prefer `on.com` preview hosts; treat older `on-running.com` examples as stale unless the current PR or workflow proves otherwise
- If the current repo or PR shows a different host pattern, trust the current repo evidence over this reference
