---
description: "Triage Copilot review comments on a PR: address valid ones, dismiss the rest, assign human reviewers."
---

# Review Triage

This prompt runs after Copilot review arrives on a PR.

The goal is to answer:

`Which review comments make sense, and what should be done about them?`

## Trigger

This prompt is triggered by the background script:

```
pnpm --prefix ~/Desktop/fe-workflow-automation wait-for-review <repo> <pr-number> --workspace <path>
```

The script waits for Copilot review, then launches the agent with the triage prompt. The agent does not need to manage timing or polling — it runs only after the script confirms a review exists.

## Inputs

The agent receives:

- PR URL or PR number
- repository name

If the ticket branch name is needed, derive it from the PR's head branch using `gh pr view <number> --json headRefName`.

## Required Order

1. Fetch the Copilot review comments from the PR.
2. Read each comment and the code it refers to.
3. Evaluate whether the comment makes sense in context.
4. Address comments that make sense.
5. Dismiss or note comments that do not make sense.
6. Run quality gates if any code was changed.
7. Push the updates.
8. Assign human reviewers.
9. Update the PR to a review-ready state.

## Comment Evaluation

For each Copilot review comment:

1. Read the comment text.
2. Read the code context it refers to (the diff hunk or file).
3. Decide: does this comment make sense?

A comment makes sense when:

- it identifies a real bug or incorrect behavior
- it points out a missing edge case that matters
- it suggests a genuinely better approach for the specific context
- it catches a security or performance concern

A comment does not make sense when:

- it misunderstands the intent of the code
- it suggests a change that would break the intended behavior
- it is a style preference already contradicted by repository conventions
- it is a generic suggestion that does not apply to this specific case
- it repeats something already handled elsewhere in the diff

If a comment is partially valid, address the valid part and explain why the rest does not apply.

Do not blindly apply every suggestion. Evaluate each one against the actual code and ticket intent.

## Addressing Comments

For comments that make sense:

1. Make the fix in the correct location.
2. Keep the fix scoped to what the comment actually identified.
3. Do not bundle unrelated improvements into a review-triage fix.
4. If a comment reveals a deeper issue beyond its scope, note it but do not fix it here.

Reply to addressed comments with a short note confirming the fix was made. Do not write lengthy justifications.

## Dismissing Comments

For comments that do not make sense:

1. Reply with a brief, respectful explanation of why the suggestion does not apply.
2. Reference the specific context that makes the suggestion invalid (e.g. "This follows the existing pattern in X" or "The ticket intent requires Y").
3. Do not ignore comments silently — every comment gets either a fix or a dismissal reply.

## Quality Gates After Fixes

If any code was changed during triage:

1. Run lint.
2. Run type checks.
3. Run relevant unit tests.

Use repository-defined commands. Do not invent custom validation.

If a gate fails because of a triage fix: fix it, rerun.

If no code was changed, skip quality gates.

## Push And Update PR

After quality gates pass (or if no code was changed):

1. Stage only the files changed during triage.
2. Commit with a short message like `address copilot review feedback`.
3. Push to the existing ticket branch.

Do not amend the original commit. Add a new commit so the review diff is visible.

Do not force-push.

## Assign Human Reviewers

After all comments are addressed or dismissed:

1. Identify the appropriate human reviewers for the PR.
2. Use the repository's default reviewer assignment if configured.
3. If no default exists, assign based on code ownership or team conventions.
4. Request review from the assigned reviewers.

Do not assign reviewers before triage is complete — the PR should be clean when they see it.

## Guardrails

- do not ask the user live questions during execution
- do not start new feature work during triage
