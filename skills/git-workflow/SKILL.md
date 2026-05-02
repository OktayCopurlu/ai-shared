---
name: git-workflow
description: "End-to-end local git and PR workflow: branching, committing, rebasing, conflict resolution, pushing, creating PRs, and processing review feedback. Use when creating a branch, writing commits, rebasing, resolving conflicts, opening a PR, or submitting changes for review. NOT FOR: GitHub API operations like listing issues, searching code, or reading PR reviews (github-mcp)."
---

# Git Workflow

Automates the full flow from local changes to a reviewed pull request.

## Procedure

### 1. Create Branch

- Branch name format: `<TICKET>-<description>` (e.g., `DSC-1986-fix-rails-sticky`)
- The ticket ID must correspond to the Jira ticket
- Ensure main is up to date before branching:
  ```
  git checkout main && git pull origin main && git checkout -b <branch-name>
  ```
- If branching from a different base, verify the correct base branch first

### 2. Pre-commit Checks

- Read the `applying-coding-style` skill and review all changed files against it — fix any violations (naming, comments, dead code, test structure) before proceeding
- Read the `reviewing-code` skill and run all 4 layers against the changed files — fix Layer 1 issues inline, report Layer 2–4 findings to the user before proceeding
- If the workspace or package exposes a fix command (for example `yarn lint:fix` or `yarn nx run <package>:lint:fix`), prefer that first
- If no suitable repo/package fix command exists, run the formatter directly on changed files (for example `prettier --write`)
- When CI/local lint reports `prettier/prettier` errors, use the repo fix command or formatter instead of hand-editing whitespace-only fixes
- Run lint on the relevant package before committing (e.g., `yarn nx run <package>:lint`)
- If `yarn lint` fails on unrelated packages due to pre-existing config issues, verify our files are lint-clean by checking the output for the changed files
- Run type checks for the relevant package (e.g., `yarn nx run <package>:check-types`)
- Run related tests to verify nothing is broken
- If checks fail on our changes, fix the issues before proceeding — do not skip or suppress errors
- Only proceed to commit after lint, types, and tests all pass for our changes

### 3. Commit Changes

- Stage only files relevant to the ticket — verify staged files are in scope before committing
- Do not include unrelated formatting churn or generated noise unless intentional
- Write brief, imperative commit messages — NO ticket numbers in commit messages
- If the pre-commit hook rejects the branch name, check the project's allowed-prefix configuration
- Prefer fixing the allowed prefix config over bypassing validation
- Use `--no-verify` only as a last resort, and only when the user explicitly accepts bypassing validation

### 4. Create PR

- Use available GitHub MCP tools to create the pull request
- Title format: `Brief description` (e.g., `Add product franchise chips to PDP purchase pod`) — the ticket ID is prepended automatically from the branch name
- Assign the PR to `OktayCopurlu` using the appropriate GitHub MCP issue or pull request management tool
- Before drafting or updating the PR body, read the Jira ticket when available and read the current PR body when it already exists; use those sources plus current repo evidence to keep real links and preserve valid generated or user-added instructions
- Keep the Preview and Jira ticket links in the format described in step 5
- For preview or Storybook links, use the current repo's real host and path format from one of these sources: the existing PR body, a recent PR in the same repo, repo docs/workflows, or a repo-specific URL reference. Do not hardcode one repo's URL pattern into this shared skill
- Body structure (top to bottom):
  1. **Description** — One or two sentences: what changed and why
  2. **Test Instructions** — Bullet list: preview links, design links, and brief notes on what to verify
  3. **Note** (optional) — Temporary caveats, mock data flags, follow-up ticket links
- Do NOT include a "Key Changes" section unless the PR is large or spans multiple areas
- Do NOT include file-by-file changelogs or implementation inventories in small PRs — reviewers need intent and verification, not a duplicate of the diff
- Do NOT include test commands in review instructions — CI runs tests automatically, reviewers do not need to run them locally
- For component library changes, include a Storybook preview URL when available
- For UI changes on an existing route, include at least one concrete baseline-vs-preview comparison link and say what reviewers should compare
- In Test Instructions, prefer concrete links and page paths over generic directions like "open Storybook" or "navigate to a PDP"
- Keep the PR body concise and reviewer-friendly — should fit on one screen

### 5. Preview & Jira Links

- The PR workflow often adds Preview and Jira links at the very top of the body in this format:
  ```
  **[Preview](<preview-url>)**
  **[Jira ticket](<jira-url>)**
  ```
- Treat these lines as part of the body, not separate comments
- If the workflow hasn't run yet (e.g., you just created the PR), include the links yourself using the format above
- Storybook PR links are repo-specific — derive the exact host and path format from the repo's current conventions before writing them into the PR body

### 6. Request Review

- Use available GitHub MCP tools to request Copilot review and fetch review comments
- To address review feedback, use the `/address-review` prompt

## Guardrails

- Do not create a PR if the diff is empty
- Do not stage unrelated files
- Confirm branch name matches the ticket key before creating the PR
- Do not invent testing steps not supported by the actual changes
- Do not ask reviewers to run tests locally — CI handles test execution
- Do not mark review comments as resolved without a corresponding fix
- Do not include secrets, tokens, or internal debug artifacts in the PR body
- Always run lint before committing — never skip this step
- Do not hand-fix whitespace-only formatting if the repo already exposes a fix command or formatter that can do it deterministically
- Do not skip formatter or typecheck runs when the package provides them
- Do not force-push without checking if anyone else has the branch
- Do not blindly accept one side of a merge conflict without reading both
- Do not add AI-assistant attribution anywhere — no `Co-Authored-By: Claude`/`Copilot`/etc. trailers, no "🤖 Generated with…" lines in commit messages, no "written by Claude/GPT/Copilot" notes in PR bodies or code comments. The human submitter owns the change.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll run lint after the PR is up" | Lint failures in CI waste reviewer time. Run lint before committing — always. |
| "This file is tangentially related, I'll include it" | Unrelated changes make PRs harder to review and riskier to revert. One PR = one concern. |
| "The commit message doesn't matter, the PR title matters" | Commit messages are permanent history. Imperative, descriptive messages make `git log` useful. |
| "I'll skip the `reviewing-code` skill, Copilot review will catch it" | Copilot review is a second opinion, not a replacement. Self-review catches 80% of issues before anyone else sees the code. |
| "The pre-commit hook is annoying, I'll bypass it" | Hooks exist for a reason. `--no-verify` erodes team guardrails — fix the root cause instead. |
| "I'll address review comments in a follow-up PR" | Unresolved comments become tech debt. Address valid feedback before merge. |
| "Adding `Co-Authored-By: Claude` credits the tool honestly" | Multiple OSS projects (pydantic-ai, dd-sdk-ios, vllm) explicitly ban AI co-author trailers and attribution lines. The submitter is the author and must defend every line. Strip these before committing. |

## Red Flags

- PR body is empty or says only "fixes bug"
- Staged files include unrelated formatting or generated noise
- Branch name doesn't match the ticket key
- Pre-commit checks skipped with `--no-verify`
- PR includes secrets, debug logs, or `console.log` statements
- Review comments resolved without corresponding commits
- PR description promises behavior the code doesn't deliver

## Verification

Before marking the PR workflow complete:

- [ ] Branch name includes the Jira ticket key
- [ ] `applying-coding-style` and `reviewing-code` skills were run against changed files
- [ ] Repo/package fix command or formatter was run on changed files when needed
- [ ] Lint, type checks, and tests pass for changed files
- [ ] Only ticket-relevant files are staged
- [ ] Commit messages are imperative and descriptive
- [ ] Test instructions use concrete repo-valid links and comparisons where applicable
- [ ] PR body has Description, Test Instructions, and (optional) Note
- [ ] PR is assigned and review is requested

## See Also

- `reviewing-code` — run all 4 layers before creating the PR
- `applying-coding-style` — naming and comment rules applied during pre-commit checks
- `debugging` — when quality gates fail and need structured triage

## PR Description Template

```markdown
**[Preview](<preview-url>)**
**[Jira ticket](<jira-url>)**

### Description

One or two sentences: what changed and why.

### Test Instructions

- Storybook preview: [Story name](<storybook-preview-url>)
- Regression compare: [baseline page](<baseline-url>) vs [preview page](<preview-page-url>)
- Verify the change matches [mobile design](real-mobile-figma-link) and [desktop design](real-desktop-figma-link)
- Confirm unaffected behavior stays the same

### Note

Temporary caveats, mock data, or follow-up ticket links (if any).
```
