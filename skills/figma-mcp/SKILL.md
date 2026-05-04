---
name: figma-mcp
description: "Read Figma designs and node context using Figma integrations before browser fallbacks. USE FOR: opening Figma design URLs, reading node context, extracting specs or copy from Figma, and checking whether a Figma link is readable. Use when the user shares a Figma URL, node-id, or asks to read a design."
---

# Figma MCP

Prefer a Figma integration over generic browser automation when the user gives a Figma link or asks to inspect a design.

## Tool Selection

1. Prefer a remote Figma MCP tool surface first.
   In current sessions this may appear as activation helpers for Figma design-context and code-connect tool groups. Use the Figma tool names actually exposed in the session instead of assuming one exact function name.
2. If a remote/server-backed Figma integration is not available but a desktop or local Figma MCP server is available in the session, use that next.
3. If neither Figma integration is available, or the integration cannot resolve the target URL or node, fall back to browser inspection.
4. If browser fallback may need login, workspace, or membership state, use an extension-backed browser route directly. Prefer Playwright MCP configured with `--extension` when it is available so the already logged-in Chrome or Edge session can be reused.

## Default Route

1. Normalize the Figma URL first.
   Extract the file key when possible and keep `node-id`, `m=dev`, and other context that may matter for the target.
2. Activate the available design-context tool group first when the task is read-only.
   Use them to fetch design context, metadata, screenshots, or reference code for the target node.
3. Use the available code-connect tools only when the user asks about node-to-code mappings.
   Do not route simple design-reading tasks through code-connect flows.
4. If the Figma integration cannot open the target directly, say why.
   Typical reasons: no Figma tool surface in the session, no Figma window or target file open for a desktop-backed integration, unsupported URL shape, missing node selection, or auth/access issues.
   If the issue is user-side prep such as "No Figma window open", mark that integration route unavailable for now and continue to browser fallback with the original URL.
5. Only then fall back to browser-based access.
   If browser access is needed, verify whether the page is truly readable or only a login wall.

## Rules

- Do not jump straight to Playwright for a Figma URL if any Figma integration exists in the session.
- Do not use code-connect tools for simple read-only design inspection unless the user asked for implementation mappings.
- If the integration is present but needs a Figma desktop window or focused file, do not stop to ask for prep. Treat that route as unavailable for now and continue to browser fallback.
- Distinguish between "tool unavailable", "URL unsupported", and "auth required". These are different blockers.
- If the MCP route succeeds, prefer its structured output over scraping the rendered Figma web app.
- Do not treat a generic VS Code browser page, temporary Playwright profile, or other non-extension browser context as equivalent to `playwright-mcp --extension` when a Figma link may depend on the user's already logged-in browser state. This is common for private files and links from tickets, docs, chats, workspace pages, project pages, or access-controlled tools.
- If the browser fallback also fails, report the exact blocker and stop. Do not keep retrying weaker fallbacks.

## Mandatory Browser Fallback

A Figma MCP failure is not a terminal blocker.

If `get_design_context`, metadata, or another Figma integration fails because the MCP server cannot start, cannot connect, times out, needs user-side desktop prep, or cannot resolve the target URL or node:

1. Immediately try browser fallback with the original Figma URL.
2. Most Figma links that are not clearly public may depend on the user's already logged-in browser state. First use or attempt an extension-backed Playwright MCP route, such as a server/session configured with `--extension` and the Playwright MCP Bridge extension.
3. If the current session does not expose or confirm an extension-backed Playwright MCP route, say that explicitly. Do not substitute `open_browser_page` or a temporary browser profile and call that the logged-in fallback.
4. Verify whether the Figma page is readable, not just whether it opens.
5. Only mark the design unreadable or comparison unverified after the extension-backed fallback also fails, is unavailable, or hits a login, workspace, membership, or access gate. For public Figma links, a generic browser fallback is acceptable after this auth-aware route is not needed.

Final reports must distinguish each route attempted:

- `Figma MCP failed: <reason>`
- `Extension-backed browser fallback succeeded`
- `Extension-backed browser fallback unavailable: <reason>`
- `Browser fallback failed: <reason>`
- `Generic browser fallback attempted: <outcome>` when used only as a public-page fallback or diagnostic

Do not write final wording that makes MCP failure sound sufficient by itself, such as "Figma comparison was not verified because Figma MCP failed." Use wording such as "Figma MCP failed; browser fallback was attempted and <outcome>."

## Verification

- [ ] I checked for a Figma integration before opening the URL in a browser.
- [ ] I used design-context tools for read-only inspection and code-connect tools only when mapping code was requested.
- [ ] If the integration was present but needed user-side prep, I treated that route as unavailable for now and continued to browser fallback.
- [ ] If the MCP route failed for startup, connection, timeout, or node-resolution reasons, I tried browser fallback before calling the design unreadable.
- [ ] If the Figma link may depend on logged-in browser state, I used or attempted extension-backed Playwright MCP (`--extension`) before treating Figma as auth-blocked.
- [ ] If I fell back to the browser, I verified whether the page was actually readable or only an access gate.
- [ ] If I could not read the design, I named the blocker precisely: missing Figma tool surface, unsupported URL, or auth/access gate.

## See Also

- `linked-context-routing` — route mixed project-page links to the right integration before browser fallback
- `validating-ui` — compare implementation against a Figma design once the design is readable
