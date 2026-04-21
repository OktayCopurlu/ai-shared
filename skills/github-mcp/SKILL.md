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

- **Granular toolsets**: The server v1.0.0+ organizes tools into toolsets (`repos`, `issues`, `pull_requests`, `actions`, `code_security`, etc.). If you're missing expected tools, the server config may restrict to specific toolsets.
- **Scope filtering**: With classic PATs (`ghp_`), tools are auto-hidden when the token lacks required scopes. Fine-grained PATs show all tools but enforce permissions at API level. If a tool is missing, check token scopes.
- **Resolve review threads**: Use `resolve_review_thread` / `unresolve_review_thread` to manage PR review thread state — available since v0.33.0.
- **Set issue fields**: Use `set_issue_fields` (v1.0.0+) to set/update/delete organization-level custom field values on issues.
- **`list_commits` filtering**: Supports `path`, `since`, and `until` parameters (v0.33.0+) — use these to narrow commit history instead of fetching everything.
- **Read-only mode**: Append `/readonly` to the remote server URL or set `X-MCP-Readonly` header to restrict to read-only operations. Useful for review-only workflows.

## Procedure

1. Prefer MCP tools over `gh` CLI — they integrate with OAuth and don't require separate CLI authentication.
2. When reviewing PRs, use `resolve_review_thread` after addressing feedback to keep thread state clean.
3. For code search across repos, prefer MCP `search_code` over `gh search code` — it returns richer context.
