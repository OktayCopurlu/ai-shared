# MCP Security Checklist

Quick-reference for reviewing MCP server configurations and usage. Referenced by `security-hardening`.

## Config Hygiene

- [ ] No API keys, tokens, or secrets hardcoded in MCP config files — use environment variable references (`${VAR}`)
- [ ] Config files containing secrets are gitignored and not committed to version control
- [ ] No `autoApprove`, `alwaysAllow`, or `auto_approve` lists — especially no wildcard (`["*"]`) entries
- [ ] MCP server commands use pinned versions, not `@latest` or unpinned `npx`
- [ ] Config files have restricted filesystem permissions (not world-readable)

## Tool Poisoning

Tool descriptions are fully visible to the LLM but often hidden from users in the UI. A malicious or compromised server can embed instructions that exfiltrate data or override trusted tool behavior.

- [ ] Do not install MCP servers from untrusted or unvetted sources
- [ ] Review tool descriptions for hidden instructions (look for `<IMPORTANT>`, injected behavioral overrides, or requests to read sensitive files)
- [ ] Be suspicious of tools with unexpected parameters (e.g. a `sidenote` field on a math tool)
- [ ] Confirm tool call arguments are visible and reviewed before approval — do not blindly accept summarized tool calls

## Tool Shadowing

A malicious server can inject instructions in its tool descriptions that change the behavior of tools from other trusted servers in the same session.

- [ ] Minimize the number of MCP servers connected simultaneously
- [ ] Treat each server as an untrusted boundary — a compromised server can influence agent behavior toward all other connected servers
- [ ] If a server does not need to be active, disconnect it

## Rug Pulls

MCP servers can silently change tool descriptions between sessions or even mid-session via `tools/list_changed` notifications.

- [ ] Pin server versions where possible (lock to specific npm version, Docker tag, or git commit)
- [ ] Use configuration pinning tools (e.g. `mcp-context-protector`) to detect description changes after first approval
- [ ] Re-review tool descriptions after any server update

## Supply Chain

- [ ] Verify MCP server packages come from the official maintainer (check npm `_npmUser`, GitHub org, provenance)
- [ ] Audit server startup commands — reject commands containing `sudo`, `curl | sh`, or piped execution chains
- [ ] For local MCP servers: review the source or use sandboxed execution (container, restricted filesystem)
- [ ] Check that server commands do not access sensitive directories beyond what the tool requires

## When To Review

Run this checklist when:
- Adding a new MCP server to any AI tool config
- Updating an existing MCP server version
- Reviewing a PR that changes MCP configuration
- After any security incident involving an AI coding tool
