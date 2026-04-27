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
4. If browser fallback lands on login, workspace, or membership gates, use the extension-backed browser tools directly and let the extension manage session state.

## Default Route

1. Normalize the Figma URL first.
   Extract the file key when possible and keep `node-id`, `m=dev`, and other context that may matter for the target.
2. Activate the available design-context tool group first when the task is read-only.
   Use them to fetch design context, metadata, screenshots, or reference code for the target node.
3. Use the available code-connect tools only when the user asks about node-to-code mappings.
   Do not route simple design-reading tasks through code-connect flows.
4. If the Figma integration cannot open the target directly, say why.
   Typical reasons: no Figma tool surface in the session, no Figma window or target file open for a desktop-backed integration, unsupported URL shape, missing node selection, or auth/access issues.
   If the issue is user-side prep such as "No Figma window open", ask whether the user wants to open or focus the target file in Figma and then retry before falling back to the browser.
5. Only then fall back to browser-based access.
   If browser access is needed, verify whether the page is truly readable or only a login wall.

## Rules

- Do not jump straight to Playwright for a Figma URL if any Figma integration exists in the session.
- Do not use code-connect tools for simple read-only design inspection unless the user asked for implementation mappings.
- If the integration is present but needs a Figma desktop window or focused file, ask the user to provide that prep before switching to browser fallback.
- Distinguish between "tool unavailable", "URL unsupported", and "auth required". These are different blockers.
- If the MCP route succeeds, prefer its structured output over scraping the rendered Figma web app.
- If the browser fallback also fails, report the exact blocker and stop. Do not keep retrying weaker fallbacks.

## Verification

- [ ] I checked for a Figma integration before opening the URL in a browser.
- [ ] I used design-context tools for read-only inspection and code-connect tools only when mapping code was requested.
- [ ] If the integration was present but needed user-side prep, I asked for that before browser fallback.
- [ ] If I fell back to the browser, I verified whether the page was actually readable or only an access gate.
- [ ] If I could not read the design, I named the blocker precisely: missing Figma tool surface, unsupported URL, or auth/access gate.

## See Also

- `linked-context-routing` — route mixed project-page links to the right integration before browser fallback
- `validating-ui` — compare implementation against a Figma design once the design is readable
