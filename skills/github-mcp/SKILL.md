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

- **Granular toolsets**: The server v1.0.0+ organizes tools into toolsets (`repos`, `issues`, `pull_requests`, `actions`, `code_security`, etc.). If you're missing expected tools, the server config may restrict to specific toolsets.
- **Prefer toolsets over hand-listed tool names**: Tool names can be renamed across releases; toolset IDs are the stable API. If a host pins individual tools via `X-MCP-Tools` / `--tools`, expect breakage on server upgrades.
- **Canonical (renamed) tool names**: Several tools have been consolidated and the old names are kept only as silent aliases. Use the canonical names in instructions and docs:
  - Workflow reads → `actions_get` (was `get_workflow`, `get_workflow_run`, `get_workflow_run_logs`, `get_workflow_job_logs`, `get_workflow_run_usage`, `download_workflow_run_artifact`)
  - Workflow lists → `actions_list` (was `list_workflows`, `list_workflow_runs`, `list_workflow_jobs`, `list_workflow_run_artifacts`)
  - Workflow triggers/cancels/reruns → `actions_run_trigger` (was `run_workflow`, `rerun_workflow_run`, `rerun_failed_jobs`, `cancel_workflow_run`, `delete_workflow_run_logs`)
  - Projects reads → `projects_get` (was `get_project`, `get_project_field`, `get_project_item`)
  - Projects lists → `projects_list` (was `list_projects`, `list_project_fields`, `list_project_items`)
  - Projects writes → `projects_write` (was `add_project_item`, `update_project_item`, `delete_project_item`)
- **Scope filtering**: With classic PATs (`ghp_`), tools are auto-hidden when the token lacks required scopes. Fine-grained PATs, GitHub Apps (`ghs_`), and server-to-server tokens show all tools and let the API enforce permissions. If a tool is missing, check token scopes (`curl -sI -H "Authorization: Bearer $TOKEN" https://api.github.com/user | grep -i x-oauth-scopes`).
- **Resolve review threads**: Use `resolve_review_thread` / `unresolve_review_thread` to manage PR review thread state — available since v0.33.0.
- **Set issue fields**: Use `set_issue_fields` (v1.0.0+) to set/update/delete organization-level custom field values on issues.
- **`list_commits` filtering**: Supports `path`, `since`, and `until` parameters (v0.33.0+) — use these to narrow commit history instead of fetching everything.
- **Read-only mode**: Append `/readonly` to the remote server URL or set `X-MCP-Readonly: true`. Read-only is a strict filter that takes precedence over toolsets and explicit `X-MCP-Tools` — write tools are dropped even when explicitly requested. Use for review-only workflows.
- **Per-toolset URL paths**: The remote server exposes one URL per toolset (e.g. `https://api.githubcopilot.com/mcp/x/repos`, `/x/issues`, `/x/pull_requests`). Mount only the slice you need to keep the tool list small.
- **Lockdown mode (prompt-injection defense)**: On public repos, set `X-MCP-Lockdown: true` (or `GITHUB_LOCKDOWN_MODE=true`). The server then only surfaces issue/PR/comment content from users with push access, hiding bodies authored by drive-by accounts. Private repos are unaffected and collaborators keep full access. Treat this as the default for any agent that reads public issues unattended.
- **Insiders mode**: Append `/insiders` to the URL or set `X-MCP-Insiders: true` to opt into preview tools (e.g. `create_pull_request_with_copilot`). Combine with `/readonly` if needed.

## Procedure

1. Prefer MCP tools over `gh` CLI — they integrate with OAuth and don't require separate CLI authentication.
2. When reviewing PRs, use the review-thread resolution tool after addressing feedback when that tool is exposed.
3. For code search across repos, prefer the MCP code-search tool over `gh search code` when available — it returns richer context.
