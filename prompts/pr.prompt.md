---
description: "Commit, push, and create a PR with description and test instructions."
---

Use the git-workflow skill to:

1. Commit all staged changes with a clear commit message
2. Push the branch
3. Create a PR with:
   - a descriptive title using the Jira ticket format `[TICKET] Brief description`
   - a reviewer-friendly body including description, key changes, review/test instructions, and risks
4. Request Copilot review
5. Run the `skill-evolution` skill to capture any reusable insight from this PR (a new pattern, a missed step in an existing skill, a recurring footgun). Skip only when nothing non-obvious was learned.
