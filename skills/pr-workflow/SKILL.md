---
name: pr-workflow
description: "End-to-end PR workflow: prepare branch, commit relevant changes, push, create a reviewer-friendly PR, request review, and help process feedback. USE FOR: when user asks to create a PR, submit changes, or push code for review. Automates the full git-to-PR pipeline."
---

# Pull Request Workflow

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

- Read the `coding-style` skill and review all changed files against it — fix any violations (naming, comments, dead code, test structure) before proceeding
- Read the `code-review` skill and run all 4 layers against the changed files — fix Layer 1 issues inline, report Layer 2–4 findings to the user before proceeding
- Run lint on the relevant package before committing (e.g., `yarn nx run on-shop:lint` for on-shop changes)
- If `yarn lint` fails on unrelated packages due to pre-existing config issues, verify our files are lint-clean by checking the output for the changed files
- Run type checks: `yarn on-shop check-types` (or the relevant package's type check)
- Run related tests to verify nothing is broken
- If checks fail on our changes, fix the issues before proceeding — do not skip or suppress errors
- Only proceed to commit after lint, types, and tests all pass for our changes

### 3. Commit Changes

- Stage only files relevant to the ticket — verify staged files are in scope before committing
- Do not include unrelated formatting churn or generated noise unless intentional
- Write brief, imperative commit messages — NO ticket numbers in commit messages
- If the pre-commit hook rejects the branch name, check allowed prefixes in `shared/on-cli/src/settings/constants.ts`
- Prefer fixing the allowed prefix config over bypassing validation
- Use `--no-verify` only as a last resort, and only when the user explicitly accepts bypassing validation

### 4. Push Branch

- Push with upstream tracking: `git push -u origin <branch-name>`

### 5. Create PR

- Use available GitHub MCP tools to create the pull request
- Title format: `Brief description` (e.g., `Add product franchise chips to PDP purchase pod`) — the ticket ID is prepended automatically from the branch name
- Assign the PR to `OktayCopurlu` using the appropriate GitHub MCP issue or pull request management tool
- Do NOT add Preview or Jira ticket links manually — the GitHub PR workflow extracts the ticket key from the branch and adds both the Jira link and preview link to the PR description automatically
- Body structure (top to bottom):
  1. **Description** — One or two sentences: what changed and why
  2. **Test Instructions** — Bullet list: link to the preview page, inline design links (Figma), brief notes on what to verify
  3. **Note** (optional) — Temporary caveats, mock data flags, follow-up ticket links
- Do NOT include a "Key Changes" section unless the PR is large or spans multiple areas
- Do NOT include test commands in review instructions — CI runs tests automatically, reviewers do not need to run them locally
- Keep the PR body concise and reviewer-friendly — should fit on one screen

### 6. Preview URLs

- The PR workflow automatically adds the preview link to the description — do not duplicate it at the top
- For `on-shop` test instructions, link to the specific page: `https://on-shop-<PR_NUMBER>.on-running.com/<path>`
- For `on-ui` changes: add required labels to trigger the on-ui build pipeline, then include the Storybook URL in test instructions: `https://on-ui-<PR_NUMBER>.on.com/?path=/story/<story-path>`
- Reviewers do NOT need to run Storybook locally — they can use the preview URL

### 7. Request Review

- Use available GitHub MCP tools to request Copilot review and fetch review comments

### 8. Address Feedback

- Fetch all review comments
- Evaluate each comment: distinguish actionable bugs from style suggestions — do not blindly apply all comments
- Make fixes for valid issues, commit, and push
- Summarize what was addressed vs. what was declined (with reasoning)
- Only resolve comments after the corresponding fix is actually pushed — never resolve without a fix

## Guardrails

- Do not create a PR if the diff is empty
- Do not stage unrelated files
- Confirm branch name matches the ticket before creating the PR
- Do not invent testing steps not supported by the actual changes
- Do not ask reviewers to run tests locally — CI handles test execution
- Do not mark review comments as resolved without a corresponding fix
- Do not include secrets, tokens, or internal debug artifacts in the PR body
- Always run lint before committing — never skip this step

## PR Description Template

```markdown
### Description

One or two sentences: what changed and why.

### Test Instructions

- Navigate to [the page](https://on-shop-<PR_NUMBER>.on-running.com/<path>)
- Verify the change matches [mobile design](figma-link) and [desktop design](figma-link)
- Any additional verification steps

### Note

Temporary caveats, mock data, or follow-up ticket links (if any).
```

> Preview link and Jira ticket link are added automatically by the PR workflow — do not include them manually.
