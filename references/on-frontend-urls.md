# on-frontend URLs

Repository-specific URL and preview authentication conventions for on-frontend work only.

Last updated: 2026-07-24

Scope: Use this reference only when working in the `on-frontend` repo or another repo whose current PRs/workflows confirm the same host patterns. Do not treat it as a cross-repo default.

## Environments

- **Local dev**: `http://localhost:5050`
- **Production**: `https://www.on.com`
- **Shop preview**: `https://on-shop-<PR_NUMBER>.stg.int.on.com`
- **Storybook preview**: `https://on-ui-<PR_NUMBER>.stg.int.on.com/?path=/story/<story-id>`
- **Preview auth**: Use the Cloudflare Access flow below

## Cloudflare Zero Trust Staging (`*.stg.int.on.com`)

Shop and Storybook previews sit behind Cloudflare Access (Zero Trust), not HTTP basic auth:

- **Shop host pattern**: `https://on-shop-<PR_NUMBER>.stg.int.on.com/...`
- **Storybook host pattern**: `https://on-ui-<PR_NUMBER>.stg.int.on.com/...`
- All PR previews share ONE wildcard CF Access app (`*.stg.int.on.com`), so a single
  `CF_Authorization` cookie scoped to the parent domain works for every PR.

Authenticate with the service token (never the basic-auth creds):

- read `CLOUDFLARE_ACCESS_CLIENT_ID` and `CLOUDFLARE_ACCESS_CLIENT_SECRET` from `~/.ai-shared/.secrets`
- the matching request headers are `CF-Access-Client-Id` and `CF-Access-Client-Secret`
- **never** send the token as a browser request header (`extraHTTPHeaders`) — it would be
  sent to every origin the page loads. Use a domain-scoped cookie instead.

Recommended flow for browser automation (Playwright MCP / integrated browser):

1. Mint a fresh cookie from the permanent token:
   ```sh
   ~/.ai-shared/skills/playwright-mcp/scripts/refresh-cf-cookie.sh "https://on-shop-<PR>.stg.int.on.com/"
   ```
   This writes a Playwright storage-state file (default
   `~/Library/Application Support/Code/User/cf-stg-storage-state.json`) holding only the
   `CF_Authorization` cookie, domain `.stg.int.on.com`.
2. Point Playwright MCP at it with `--storage-state=<file>` in `mcp.json`, then restart the
   server; or inject the cookie into a live context with `page.context().addCookies(...)`.
3. Navigate to the Zero Trust URL. A real page title (not a Cloudflare login screen) confirms access.

The cookie expires ~24h — re-run the helper and restart/refresh when navigation starts hitting
the CF login page. The service token itself is permanent, so no manual JSON edits are ever needed.

## A/B And Feature Flag Overrides

For on-frontend preview validation, do not guess cookies from an experiment name.

Before forcing a variant:

1. find the exact experiment or feature flag key in the ticket, PR, diff, linked docs, or nearby source code
2. identify the real override mechanism used by that code path: URL parameter, cookie, localStorage, sessionStorage, SDK debug API, preview endpoint, or AB Flag Override extension
3. apply only confirmed key/value pairs, then reload and verify the variant through UI, exposure/tracking payload, network response, or runtime state

For local dev at `http://localhost:5050`, agents may set confirmed cookie or storage overrides directly through browser page evaluation (the built-in VS Code integrated browser or Playwright MCP). Localhost cookies should omit `Domain`, use `Path=/`, and clear stale assignments with `Max-Age=0` when switching variants.

If the real allocation is server-side or only controllable through an extension/admin UI, agents may temporarily hard-code or stub the confirmed local flag/experiment value in the on-frontend working tree for screenshot and UI validation only. The temporary change must be removed before handoff, and the final report must say the variant was validated through a local hard-code rather than a real allocation path.

The AB Flag Override Chrome extension UI is a user-side control and is not reliably operable through browser automation. If that is the only available switch, ask the user to set the exact key and group manually, then continue validation after confirmation.

## Examples

- `https://www.on.com/en-ch/shop/mens/low` → `http://localhost:5050/en-ch/shop/mens/low`
- `https://www.on.com/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851` → `http://localhost:5050/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851`
- Preview root: `https://on-shop-9727.stg.int.on.com/`
- Preview page: `https://on-shop-9727.stg.int.on.com/en-ch/products/cloudspike-citius-2-m-3mf1030/mens/bloom-lime-shoes-3MF10304849`
- Storybook root: `https://on-ui-9727.stg.int.on.com/`
- Storybook story: `https://on-ui-9727.stg.int.on.com/?path=/story/components-atoms-boxchip--withmedia`

## Rules

- Treat `~/.ai-shared/.secrets` as the source of truth even when the current workspace is another repo
- Never hardcode credentials in skills, prompts, or checked-in project files
- Prefer `stg.int.on.com` for shop and Storybook preview hosts; treat older preview patterns as stale unless the current PR or workflow proves otherwise
- If the current repo or PR shows a different host pattern, trust the current repo evidence over this reference
