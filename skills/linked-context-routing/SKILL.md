---
name: linked-context-routing
description: "Use when the user provides any URL, needs project-specific URL/environment mapping, or asks to inspect, read, summarize, or route links, especially private/internal pages or pages that may require auth. Route to first-party integrations before browser fallback."
---

# Linked Context Routing

Use this workflow when a single ticket, doc, or project page contains multiple outbound links and the agent needs to open the linked context efficiently.

## Default Route

1. Read the source page with its first-party integration first.
   Example: use `atlassian-mcp` for Confluence or Jira before opening the source page in a browser.
2. Extract the real target URLs and group them by domain.
   De-duplicate obvious repeats before opening anything.
3. Before opening project-specific frontend, local, staging, preview, or production URLs, load the matching environment reference when the current repo, ticket, or page identifies one.
   Example: for `on-frontend`, use `~/.ai-shared/references/on-frontend-urls.md` before choosing the access path.
   Environment URL references are routing input for every access method, including fetch/read tools, first-party integrations, generic browser tools, and `playwright-mcp`.
4. Route each URL to the narrowest capable path.
   - Atlassian URLs → `atlassian-mcp`
   - Figma URLs → `figma-mcp`
   - Google Docs and Sheets URLs → `google-drive`
   - GitHub URLs → `github-mcp`
   - Contentful URLs or CMS content asks → `contentful`
5. For domains without a dedicated integration, decide whether browser state is required.
   - Public, static pages → direct fetch/read tools
   - If the current session exposes a dedicated connector or authenticated integration for the domain, use that before generic browser automation
   - If no connector exists and browser state is required, use an explicit authenticated `playwright-mcp` browser path
   - If browser access still fails or a first-party integration needs user-side prep, ask the user how to recover before marking the link blocked
6. Track status per link.
   Mark each one as opened, partially read, awaiting user-assisted auth, awaiting user-side prep, blocked by missing tools, or unsupported.

## Non-Obvious Rules

- Prefer first-party integrations over browser automation even if the browser path looks faster.
- Project-specific environment URL references belong to routing, not to any one browser implementation. Load them before deciding whether the final path is fetch, generic browser, or Playwright.
- A failed fetch for Slack, Asana, or Figma does not prove the content is unreadable. It may only mean auth or a missing integration is in the way.
- For private SaaS, auth is usually the first problem to solve. Do not treat it like an ordinary public-page fetch.
- "Blocked" is the last status, not the first one. If a user-assisted recovery path still exists, surface that path first.
- If the target page is a smart-link wrapper, resolve the actual underlying URL before routing it.
- Stop after the first precise blocker. Do not keep retrying weaker paths once the cause is clear.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I already have the URL, I'll just open it in the browser." | That skips structured integrations and often lands on login walls unnecessarily. |
| "A fetch failed, so the link is unreadable." | Failed fetch often means the wrong access path was chosen, not that the content is unavailable. |
| "This page has ten links, I should summarize from the first two." | Linked-context tasks need per-link routing and explicit status, not silent sampling. |

## Rules

- Start from the source page, not from guessed downstream pages.
- Route by domain and platform before considering browser fallback.
- Use `playwright-mcp` as the browser fallback when a link requires browser state, interaction, or inspection.
- When auth or user-side prep is still recoverable, use an "awaiting user" status instead of calling the link blocked.
- Report blockers precisely: missing integration, auth gate, unsupported URL shape, or tool/policy limitation.
- When the user asks to read all links, say which ones were actually opened and which ones were blocked.

## Verification

- [ ] I extracted the outbound URLs from the source page before routing them.
- [ ] I routed known domains to first-party integrations before using the browser.
- [ ] I only used auth-aware browser fallback for links that actually required browser state.
- [ ] I distinguished between "awaiting user action" and a true blocker.
- [ ] I reported per-link success or blocker status instead of giving a blended summary.

## See Also

- `atlassian-mcp` — read Jira and Confluence source pages directly
- `figma-mcp` — open Figma URLs through a Figma integration before browser fallback
- `google-drive` — read Google Docs and Sheets via OAuth-backed export
- `playwright-mcp` — stateful browser fallback when the task needs it
- `~/.ai-shared/references/on-frontend-urls.md` — On frontend local, preview, production, and preview-auth URL conventions
