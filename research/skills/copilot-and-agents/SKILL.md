---
name: copilot-and-agents
description: "Track GitHub Copilot, VS Code agent mode, MCP servers, skills, prompts, and AI developer workflow updates. USE FOR: 'what's new in Copilot?', 'any new MCP servers?', 'what changed in VS Code agent mode?', 'any useful new skills or prompts?', 'is there a new agent workflow worth adopting?'. ALWAYS use when the focus is AI coding tools, agent workflows, or developer automation."
disable-model-invocation: true
---

# Copilot & Agents Skill

Use this skill when the user asks about:
- GitHub Copilot (chat, agent mode, coding agent, workspace, review agent)
- VS Code agent mode: `.instructions.md`, `.prompt.md`, `.agent.md`, SKILL.md, toolsets
- MCP servers (new releases, maturity, breaking changes, new integrations)
- AI-assisted developer workflows (automation, code generation, multi-agent patterns)
- Agent patterns, prompt packaging, skill design, toolset definitions

---

## Research scope

### Primary coverage
- GitHub Copilot agent mode, coding agent, review agent, workspace features
- VS Code agent customization: `.instructions.md` behavior, `applyTo`, toolset format changes, SKILL.md conventions
- MCP protocol and official server releases (github.com/modelcontextprotocol)
- New MCP servers relevant to our stack: GitHub, Nx, Amplitude, Atlassian, Contentful, Playwright, Chrome DevTools
- Tool restriction models, security controls added to agents
- Multi-agent composition and invocation patterns

### Secondary coverage
- OpenAI Agents SDK and tool-calling patterns
- Anthropic Claude in agentic / tools context
- New VS Code extensions with agent integration
- Prompt engineering advances specific to coding agents

---

## Source priority

### GitHub Copilot & VS Code
1. `code.visualstudio.com/updates` — "Agent", "Chat", "Language Models" sections
2. `github.blog/changelog` — filter tag: Copilot
3. `docs.github.com/copilot` — new feature docs, what's new page
4. `github.com/microsoft/vscode/releases` — raw release notes
5. `github.com/microsoft/vscode/blob/main/CHANGELOG.md`

### MCP protocol & servers
6. `modelcontextprotocol.io` — spec updates, new transports
7. `github.com/modelcontextprotocol/servers/releases` — official server releases
8. `github.com/modelcontextprotocol/modelcontextprotocol/discussions` — protocol proposals
9. `github.com/punkpeye/awesome-mcp-servers` — community discovery (Tier 2, verify maturity)
10. `mcp.so` — MCP server registry (Tier 2)
11. `glama.ai/mcp/servers` — server directory with usage stats (Tier 2)

### AI agent frameworks & coding agents
12. `openai.com/news` — Agents SDK, tool-calling updates
13. `anthropic.com/news` — Claude tool use, computer use, context window
14. `docs.anthropic.com/en/release-notes` — API changelog
15. `platform.openai.com/docs/changelog` — API changes affecting agents

### VS Code extension ecosystem
16. `marketplace.visualstudio.com/search?term=mcp&target=VSCode` — new MCP extensions
17. `marketplace.visualstudio.com/search?term=agent&target=VSCode` — agent-related extensions

---

## Evaluation questions for each candidate

1. Does this change how skills, instructions, or prompts are written or invoked?
2. Does this add or remove capabilities for an MCP server we already use?
3. Does this affect tool restriction, scope, or security behavior of agents?
4. Is there a new workflow pattern with a concrete implementation example we can act on?
5. Does this change who can do what in agent mode (permissions, trust model, guardrails)?

---

## Output format

# Copilot & Agents Digest

Date: {YYYY-MM-DD}
Time window: {N days}

## Top findings

### 1. {title}
- Source: {canonical URL}
- Vendor: {vendor}
- Published: {date if available}
- Status: Released | Preview | Beta | Announced | Deprecated
- Summary: {2-3 sentences}
- Why it matters: {engineering impact}
- Affects: {skills / instructions / MCP / toolsets / workflow / permissions}
- Recommendation: Try this week | Add to watchlist | Ignore for now | Create spike ticket
- Priority: P0 | P1 | P2
- Confidence: High | Medium | Low

### 2. ...

## Watchlist
Items in Preview or Beta worth revisiting. Include a re-evaluate date.

## Ignore
Items checked but excluded — one-line reason each.

## Recommended next steps
- Try now: {1 item}
- Investigate: {1 item}
- Ignore: {1 item}

---

## Selection rubric

Prefer 3–5 strong findings over a longer weak list.

Prioritize items that:
- Change how agent instructions, skills, or prompts behave
- Add or deprecate MCP capabilities we depend on
- Introduce new tool types or security controls
- Have a concrete implementation example you can copy today

Deprioritize items that:
- Are pure marketing announcements with no technical detail
- Repeat existing capabilities with minor rewording
- Affect platforms or stacks outside our setup
