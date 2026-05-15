---
name: figma-mcp
description: "Read Figma designs and node context using Figma integrations before browser fallbacks. USE FOR: opening Figma design URLs, reading node context, extracting specs or copy from Figma, and checking whether a Figma link is readable. Use when the user shares a Figma URL, node-id, or asks to read a design."
---

# Figma MCP

The official Figma MCP system instruction already covers tool inventory, URL parsing (fileKey / branchKey / makeFileKey, `-` → `:`, board → `get_figjam`), and the design-to-code workflow. This skill only records the local environment rules and routing decisions that are **not** in that instruction.

Use the Figma MCP tool names actually exposed in the session; do not assume one exact function name.

## Local Environment

- **Remote-only.** No desktop or local Figma MCP server is configured. There is no desktop selection to read — always ask the user for a link if one is missing.
- **Authenticated browser fallback = extension-backed Playwright MCP** (Chrome attached through the Playwright MCP Bridge extension). Do **not** use the VS Code simple browser, `open_browser_page`, or `read_page` as a Figma auth fallback. A login wall in those tools is evidence of the wrong surface, not a real block.

## Blocker Taxonomy

When the Figma MCP route fails, name the blocker precisely instead of retrying weaker fallbacks:

- **tool unavailable** — no Figma MCP tool surface in the session
- **URL unsupported** — shape doesn't match the known fileKey/branchKey/makeFileKey forms
- **missing input** — no `node-id` and no `get_metadata` discovery requested by the user
- **auth/access** — remote server can't read the file (unshared, wrong workspace, expired session)

If the browser fallback also fails, report the exact blocker and stop.

## See Also

- `linked-context-routing` — route mixed project-page links to the right integration before browser fallback
- `validating-ui` — compare implementation against a Figma design once the design is readable
