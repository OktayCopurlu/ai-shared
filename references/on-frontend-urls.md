# on-frontend URLs

Repository-specific URL and preview authentication conventions for on-frontend work only.

Last updated: 2026-04-24

Scope: Use this reference only when working in the `on-frontend` repo or another repo whose current PRs/workflows confirm the same host patterns. Do not treat it as a cross-repo default.

## Environments

- **Local dev**: `http://localhost:5050`
- **Production**: `https://www.on.com`
- **Shop preview**: `https://on-shop-<PR_NUMBER>.on.com`
- **Storybook preview**: `https://on-ui-<PR_NUMBER>.on.com/?path=/story/<story-id>`
- **Staging / Preview auth**: Use HTTP basic auth credentials from `~/.ai-shared/.secrets` when a browser or script prompts for them

## Preview Authentication

For staging or preview URLs that require auth:

- read `STAGING_USER` and `STAGING_PASS` from `~/.ai-shared/.secrets`
- do not look for credentials in the target project repo
- prefer the clean `https://on-shop-<PR_NUMBER>.on.com/...` and `https://on-ui-<PR_NUMBER>.on.com/...` forms in PR descriptions and docs
- if automation or a browser session needs embedded credentials, prepend them directly in the URL

Format:

```text
https://<STAGING_USER>:<STAGING_PASS>@on-shop-<PR_NUMBER>.on.com/...
https://<STAGING_USER>:<STAGING_PASS>@on-ui-<PR_NUMBER>.on.com/?path=/story/<story-id>
```

## Examples

- `https://www.on.com/en-ch/shop/mens/low` → `http://localhost:5050/en-ch/shop/mens/low`
- `https://www.on.com/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851` → `http://localhost:5050/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851`
- Preview root: `https://on-shop-9096.on.com/`
- Preview page: `https://on-shop-9096.on.com/en-ch/products/cloudspike-citius-2-m-3mf1030/mens/bloom-lime-shoes-3MF10304849`
- Storybook root: `https://on-ui-9096.on.com/`
- Storybook story: `https://on-ui-9096.on.com/?path=/story/components-atoms-boxchip--withmedia`
- Authenticated preview page for automation: `https://<STAGING_USER>:<STAGING_PASS>@on-shop-9096.on.com/en-ch/products/...`

## Rules

- Treat `~/.ai-shared/.secrets` as the source of truth even when the current workspace is another repo
- Never hardcode credentials in skills, prompts, or checked-in project files
- Prefer `on.com` preview hosts; treat older `on-running.com` examples as stale unless the current PR or workflow proves otherwise
- If the current repo or PR shows a different host pattern, trust the current repo evidence over this reference
