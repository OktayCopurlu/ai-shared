---
description: "Commit, push, and create a PR with description and test instructions."
---

Load and follow the `git-workflow` skill to:

1. Commit all staged changes with a clear commit message
2. Push the branch
3. Create a PR with:
   - a descriptive title following the repository convention from `git-workflow`; do not duplicate the Jira key when repo automation derives or prepends it
   - a reviewer-friendly body including description, reviewer-visible verification evidence when applicable, concrete review/test instructions, and risks
   - full preview URLs for changed routes and baseline/control comparison links when the change affects existing UI
   - no CI transcript: do not list passing lint, typecheck, build, unit-test, or spec command results in the PR body
4. Request Copilot review
