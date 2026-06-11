---
name: github
description: 'Interact with GitHub via the `gh` CLI. USE FOR: reading/creating/updating pull requests, issues, branches, commits, reviews, code search, repository operations. ALWAYS use when user references a PR number, issue, or asks to perform GitHub API operations. NOT FOR: local git operations like committing, rebasing, or branch management (git-workflow).'
---

# GitHub — `gh` CLI

## Routing

- **`git` CLI** for local operations (branch, commit, push, pull, diff, rebase) — see `git-workflow`
- **`gh` CLI** for remote operations (PRs, reviews, issues, code search, releases)

## Auth

- Authenticated via `gh auth login` (token stored in the macOS keyring).
- Verify with `gh auth status`. If it reports an invalid/expired token, re-run `gh auth login` before relying on `gh`.

## Common commands

```bash
# Pull requests
gh pr view 1234 --json title,body,state,reviews,files
gh pr list --state open --limit 20
gh pr diff 1234
gh pr checkout 1234
gh pr create --fill                       # uses commits for title/body
gh pr review 1234 --approve|--comment|--request-changes -b "message"
gh pr comment 1234 -b "message"

# Issues
gh issue view 567 --json title,body,state,labels,comments
gh issue list --state open --label bug
gh issue create --title "..." --body "..."
gh issue comment 567 -b "message"

# Code & repo search
gh search code "queryString" --repo owner/repo
gh search prs "is:open author:@me"
gh api repos/{owner}/{repo}/commits --jq '.[].commit.message'

# Releases / tags
gh release view --json tagName,name,body
gh release list --limit 10

# Anything not covered: raw API
gh api graphql -f query='...'             # GraphQL for review threads, etc.
gh api /repos/{owner}/{repo}/pulls/{n}/comments
```

## Gotchas

- **Output as JSON**: prefer `--json <fields>` + `--jq` for structured, parseable results instead of scraping human-readable text.
- **Review threads**: `gh` has no first-class resolve command. Use the GraphQL API via `gh api graphql` (`resolveReviewThread` / `addPullRequestReviewThreadReply` mutations) for inline thread replies and resolution. Do not substitute a top-level issue/PR comment for an inline thread reply.
- **Invalid keyring token**: if `gh auth status` shows an invalid token, do not rely on `gh` for cleanup or review-thread replies in that session — re-auth first.
- **Pagination**: `gh api` truncates by default. Use `--paginate` for full result sets.
- **Repo context**: `gh` infers the repo from the current git remote. Outside a repo, pass `--repo owner/name` explicitly.

## Procedure

1. Run `gh auth status` if you suspect auth issues; otherwise proceed directly.
2. Use `--json`/`--jq` for any output you need to parse.
3. For review-thread resolution or inline replies, use `gh api graphql`.
