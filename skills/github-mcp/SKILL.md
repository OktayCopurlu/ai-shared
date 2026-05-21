---
name: github-mcp
description: 'Interact with GitHub via the GitHub MCP server API. USE FOR: reading/creating/updating pull requests, issues, branches, commits, reviews, code search, repository operations. ALWAYS use when user references a PR number, issue, or asks to perform GitHub API operations. NOT FOR: local git operations like committing, rebasing, or branch management (git-workflow).'
---

# GitHub MCP

## Routing

- **`git` CLI** for local operations (branch, commit, push, pull, diff, rebase)
- **GitHub MCP** for remote operations (PRs, reviews, issues, code search)
- **`gh` CLI** as fallback only when MCP is unavailable

## Gotchas

- **Tool-name drift**: Use the GitHub tool names exposed in the current session. The names below are representative examples from recent GitHub MCP surfaces, not a reason to invent a missing tool name.

- **Granular toolsets**: The server organizes tools into toolsets. The default set is `context`, `repos`, `issues`, `pull_requests`, and `users`; tools for `actions`, `code_security`, `dependabot`, `discussions`, `projects`, `secret_protection`, and other areas require those toolsets or exact tools to be enabled.
- **Config precedence**: Read-only mode removes write tools even if explicitly enabled. Excluded tools override both toolsets and individual tool allowlists.
- **Remote-only toolsets**: The hosted GitHub MCP server can expose toolsets that local Docker/stdio servers do not, including `copilot_spaces` and `github_support_docs_search`. Do not treat their absence on a local server as a broken install.
- **Scope filtering**: With classic PATs (`ghp_`), tools are auto-hidden when the token lacks required scopes. Fine-grained PATs and GitHub App tokens show tools but enforce permissions at API level. Remote OAuth can prompt for additional scopes when a tool is used.
- **Resolve review threads**: Use `resolve_review_thread` / `unresolve_review_thread` to manage PR review thread state — available since v0.33.0.
- **Set issue fields**: Use `set_issue_fields` (v1.0.0+) to set/update/delete organization-level custom field values on issues.
- **`list_commits` filtering**: Supports `path`, `since`, and `until` parameters (v0.33.0+) — use these to narrow commit history instead of fetching everything.
- **Read-only mode**: Append `/readonly` to the remote server URL or set `X-MCP-Readonly` header to restrict to read-only operations. Useful for review-only workflows.
- **Insiders / MCP Apps**: Insiders mode can expose experimental UI-backed MCP Apps for tools such as `get_me`, `issue_write`, and `create_pull_request`; only rely on these when the host supports MCP Apps and the mode is explicitly enabled.

## Missing Tool Diagnostic

When an expected GitHub MCP tool is missing, diagnose configuration before falling back to `gh`:

1. Check whether the current host is using the remote server or the local server; their available toolsets can differ.
2. Check enabled toolsets or exact tools (`X-MCP-Toolsets`, `X-MCP-Tools`, `GITHUB_TOOLSETS`, `GITHUB_TOOLS`, or URL paths such as `/x/actions`).
3. Check whether read-only mode or exclude-tools (`X-MCP-Exclude-Tools`, `GITHUB_EXCLUDE_TOOLS`) removed the tool.
4. Check auth mode and scopes: classic PATs hide tools at startup, while OAuth and fine-grained PATs may show tools but fail at call time.
5. Check organization or enterprise policies if MCP access itself is blocked.

## Procedure

1. Prefer MCP tools over `gh` CLI — they integrate with OAuth and don't require separate CLI authentication.
2. When reviewing PRs, use the review-thread resolution tool after addressing feedback when that tool is exposed.
3. For code search across repos, prefer the MCP code-search tool over `gh search code` when available — it returns richer context.
