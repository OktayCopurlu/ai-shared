---
description: "Create and execute manual QA from a ticket, PR, local diff, preview URL, or regression risk. Use for QA plans, manual test instructions, and functional validation."
---

# Manual QA

Run the `manual-qa` skill.

Invocation examples:

- `/manual-qa "https://github.com/org/repo/pull/123"` - execute manual QA for one PR
- `/manual-qa "DSC-1234"` - execute manual QA from a ticket and current local diff
- `/manual-qa` - execute manual QA from the current task context and local diff

Use the context provided by the user, then gather any missing local evidence needed to execute QA:

- Jira ticket details and linked specs/designs when a ticket is provided
- PR description, diff, comments, CI status, linked ticket, and preview URL when a PR URL or PR number is provided
- local `git diff` and changed files when working from the current checkout
- feature flags, variants, URLs, and test data needed to exercise the change

Single PR mode: when the user provides only a PR URL or PR number, treat that PR as the full QA source. Use the `github-mcp` skill to read the PR, derive linked Jira context when present, find the preview environment, create a temporary QA plan from the ticket plus PR diff, and execute it against the preview or another runnable environment. Do not require a local checkout unless the PR data is unavailable or local execution is the only runnable path.

Create a temporary QA plan, execute it yourself, update the plan with results, and end with the `manual-qa` verdict format.

Do not stop after writing a plan unless execution is blocked. If blocked, report the blocker and list exactly what was not verified.
