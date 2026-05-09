---
name: figma-mcp
description: "Read Figma designs and node context using Figma integrations before browser fallbacks. USE FOR: opening Figma design URLs, reading node context, extracting specs or copy from Figma, and checking whether a Figma link is readable. Use when the user shares a Figma URL, node-id, or asks to read a design."
---

# Figma MCP

Prefer a Figma integration over generic browser automation when the user gives a Figma link or asks to inspect a design.

## Tool Selection

1. Prefer the remote Figma MCP tool surface first when it is available.
   The remote server has the broadest feature set, uses link-based context, and may expose tools such as `get_design_context`, `get_screenshot`, `get_variable_defs`, `get_metadata`, `get_code_connect_map`, `add_code_connect_map`, `get_code_connect_suggestions`, `send_code_connect_mappings`, `generate_figma_design`, `use_figma`, `search_design_system`, `create_design_system_rules`, `get_figjam`, `generate_diagram`, `whoami`, and `create_new_file`.
2. Use a desktop or local Figma MCP server when the remote integration is unavailable, when the user explicitly wants to use the current desktop selection, or when the available remote tool cannot access the target.
   Desktop selection-based prompting works only with a desktop-backed MCP server; the remote server needs a link to a frame, layer, file, or Make project.
3. If a tool surface uses different names in the current session, use the tool names actually exposed in the session instead of assuming exact function names.
4. If neither Figma integration is available, or the integration cannot resolve the target URL or node, fall back to browser inspection.
5. If browser fallback lands on login, workspace, or membership gates, use the extension-backed browser tools directly and let the extension manage session state.

## Tool Map

| User intent | Prefer |
| --- | --- |
| Read or implement a Figma Design or Make node | `get_design_context`, plus `get_screenshot` for visual reference |
| Extract colors, spacing, typography, variables, or styles | `get_variable_defs` |
| Large, slow, or truncated selections | `get_metadata` first, then fetch only needed child nodes with `get_design_context` |
| Compare against the visual source of truth | `get_screenshot` |
| Read FigJam diagrams | `get_figjam` |
| Generate FigJam diagrams | `generate_diagram` |
| Use or manage Code Connect mappings | `get_code_connect_map`, `add_code_connect_map`, `get_code_connect_suggestions`, `send_code_connect_mappings` |
| Search reusable Figma library components, variables, or styles | `search_design_system` |
| Create design-system rule guidance for agents | `create_design_system_rules` |
| Write to Figma Design or FigJam canvas | `use_figma` only after explicit user intent to modify Figma |
| Capture live web UI into Figma | `generate_figma_design` when available, not `get_design_context` |
| Create a blank Figma Design or FigJam file | `create_new_file` |
| Check authenticated account, plans, or seat context | `whoami` |
| Read Figma Make project resources | Use MCP resources capability when exposed, then download only requested files |

## Default Route

1. Normalize the Figma URL first.
   Extract the file key when possible and keep `node-id`, branch keys, `m=dev`, and other context that may matter for the target.
2. For read-only design inspection or code implementation from a design, fetch structured context and a screenshot first.
   Use `get_design_context` for the selected node and `get_screenshot` as the visual source of truth. If the response is too large or incomplete, switch to `get_metadata` to identify child nodes, then fetch only the needed slices.
3. Ask for variables explicitly when token details matter.
   If the task is about colors, spacing, typography, or token values, call `get_variable_defs`; do not rely on the default design-context output to include the right level of token detail.
4. Use Code Connect tools only when the user asks about node-to-code mappings or component reuse through Code Connect.
   Do not route simple design-reading tasks through code-connect flows.
5. Use write or capture tools only for matching intents.
   `use_figma` is for creating, editing, deleting, or inspecting Figma canvas objects. `generate_figma_design` is for capturing live web UI into Figma. Neither is the default route for reading a design or implementing a Figma node in code.
6. For Figma Make links, use MCP resources if exposed.
   Fetch the available resource list, then download only the files needed for the user's implementation or review task.
7. If the Figma integration cannot open the target directly, say why.
   Typical reasons: no Figma tool surface in the session, no Figma window or target file open for a desktop-backed integration, unsupported URL shape, missing node selection, or auth/access issues.
   If the issue is user-side prep such as "No Figma window open", ask whether the user wants to open or focus the target file in Figma and then retry before falling back to the browser.
8. Only then fall back to browser-based access.
   If browser access is needed, verify whether the page is truly readable or only a login wall.

## Rules

- Do not jump straight to Playwright for a Figma URL if any Figma integration exists in the session.
- Do not use code-connect tools for simple read-only design inspection unless the user asked for implementation mappings.
- Do not use `use_figma`, `generate_figma_design`, `generate_diagram`, or `create_new_file` unless the user explicitly asked to create, modify, capture, or generate Figma/FigJam content.
- Do not treat a Figma URL as browser-navigable context for the agent. Use the URL to extract the file key and node ID for MCP tools.
- Do not assume remote Figma MCP can use a desktop selection; ask for a link when only the remote server is available.
- Do not assume the default `get_design_context` output is final code style. Treat it as design context to translate into the target project's conventions.
- When output is missing token values or looks like raw code instead of variables, explicitly call `get_variable_defs`.
- When a selection is large, slow, or truncated, reduce scope through `get_metadata` before retrying broad context fetches.
- If the integration is present but needs a Figma desktop window or focused file, ask the user to provide that prep before switching to browser fallback.
- Distinguish between "tool unavailable", "URL unsupported", and "auth required". These are different blockers.
- If the MCP route succeeds, prefer its structured output over scraping the rendered Figma web app.
- If the browser fallback also fails, report the exact blocker and stop. Do not keep retrying weaker fallbacks.

## Verification

- [ ] I checked for a Figma integration before opening the URL in a browser.
- [ ] I chose the Figma tool group by intent: design context, variables, metadata, screenshot, Code Connect, write-to-canvas, code-to-canvas, FigJam, Make resources, or file creation.
- [ ] For read-only inspection or implementation, I fetched structured context and a screenshot before relying on visual/browser inspection.
- [ ] If the context was too large or incomplete, I used metadata to narrow the node scope before retrying.
- [ ] I used Code Connect tools only when mapping code was requested.
- [ ] I avoided write/capture/create tools unless the user explicitly asked to modify Figma, capture live UI into Figma, generate a diagram, or create a file.
- [ ] If the integration was present but needed user-side prep, I asked for that before browser fallback.
- [ ] If I fell back to the browser, I verified whether the page was actually readable or only an access gate.
- [ ] If I could not read the design, I named the blocker precisely: missing Figma tool surface, unsupported URL, or auth/access gate.

## See Also

- `linked-context-routing` — route mixed project-page links to the right integration before browser fallback
- `validating-ui` — compare implementation against a Figma design once the design is readable
