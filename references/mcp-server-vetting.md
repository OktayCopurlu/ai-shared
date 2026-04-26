# MCP Server Vetting Checklist

Quick-reference for evaluating whether to adopt a new MCP server. Run this before adding any server to your AI tool config. Referenced by `security-hardening`.

See also: `references/mcp-security.md` for post-install security review.

## Fitness Check

- [ ] The server solves a concrete, recurring need — not a hypothetical one
- [ ] No existing MCP server or built-in tool already covers this capability
- [ ] The server's tool count is manageable — prefer focused servers (5–15 tools) over sprawling ones (50+)
- [ ] Tool names and descriptions are clear enough for an LLM to select correctly without trial-and-error

## Maintenance Health

- [ ] Repository has commits within the last 90 days
- [ ] Issues and PRs show maintainer responsiveness (not just bot activity)
- [ ] Has at least one tagged release (not just main-branch commits)
- [ ] README documents setup, configuration, and available tools
- [ ] Has a CI pipeline (GitHub Actions, etc.) — not just local testing

## Trust Signals

- [ ] Published by a known org or maintainer with a track record
- [ ] Source code is available and readable — no obfuscated or compiled-only distributions
- [ ] Package registry entry (npm, PyPI) matches the GitHub source (check `repository` field)
- [ ] No `postinstall` scripts that download or execute remote code
- [ ] For npm: check `_npmUser` and provenance; for PyPI: check maintainer history

## Transport and Compatibility

- [ ] Supports a transport your client uses (stdio for local, Streamable HTTP for remote)
- [ ] Config example is provided for your client (Claude Desktop, Cursor, OpenCode, etc.)
- [ ] Environment variables or auth tokens use reference syntax (`${VAR}`), not hardcoded values
- [ ] Server starts cleanly with documented config — no undocumented env vars required

## Overlap and Blast Radius

- [ ] Adding this server does not duplicate tools from already-connected servers (risk: tool shadowing)
- [ ] The server does not request filesystem access beyond what its purpose requires
- [ ] No `autoApprove` or `alwaysAllow` in the suggested config
- [ ] Disconnecting the server does not break other connected servers or workflows

## When To Run This

- Before adding any new MCP server to your config
- Before recommending an MCP server in a skill or reference file
- When evaluating alternatives for an existing server
- During periodic review of connected servers (quarterly)
