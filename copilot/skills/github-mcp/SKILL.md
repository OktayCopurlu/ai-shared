---
name: github-mcp
description: 'Interact with GitHub via the GitHub MCP server. USE FOR: reading/creating/updating pull requests, issues, branches, commits, reviews, code search, repository operations. ALWAYS use when user references a PR number, issue, or asks to perform GitHub operations. Prefer over gh CLI.'
---

# GitHub MCP Server Usage

When interacting with GitHub (pull requests, issues, repositories, branches, etc.), **always prefer using the GitHub MCP server tools** over other methods (e.g., `gh` CLI, fetching web pages).

## Pull Requests

- **Reading PRs**: Use `pull_request_read` to get PR details, diffs, and review comments
- **Creating PRs**: Use `create_pull_request` to create new pull requests
- **Updating PRs**: Use `update_pull_request` to modify title, body, or status
- **Reviews**: Use `pull_request_review_write` to submit reviews
- **Copilot review**: Use `request_copilot_review` to request automated review
- **Searching PRs**: Use `search_pull_requests` or `list_pull_requests` to find PRs
- **Status checks**: Use `pullRequestStatusChecks` to check CI status
- **Merging**: Use `merge_pull_request` to merge PRs

## Issues

- **Reading issues**: Use `issue_read` to fetch issue details
- **Creating/updating issues**: Use `issue_write` to create or update issues
- **Searching issues**: Use `search_issues` or `list_issues` to find relevant issues
- **Comments**: Use `add_issue_comment` to add comments

## Repository Operations

- **File contents**: Use `get_file_contents` to read files from remote branches
- **Branches**: Use `create_branch`, `list_branches` for branch management
- **Commits**: Use `list_commits`, `get_commit` for commit history
- **Code search**: Use `search_code` for searching across repositories
- **Push files**: Use `push_files` or `create_or_update_file` for direct file changes on remote

## Procedure

1. Load GitHub MCP tools via `tool_search_tool_regex` with pattern `mcp_io_github`
2. Use `owner: "onrunning"` and `repo: "on-frontend"` for this repository
3. Call the appropriate tool for the operation
4. Prefer MCP tools over `gh` CLI — they don't require separate CLI authentication
