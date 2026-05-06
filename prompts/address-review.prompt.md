---
description: "Triage Copilot review comments on a PR: address valid ones, dismiss the rest, assign human reviewers."
---

# Review Triage

Triage Copilot review comments on a PR.

The goal is to answer:

`Which review comments make sense, and what should be done about them?`

## Inputs

The user provides:

- PR URL or PR number
- repository name

If the ticket branch name is needed, derive it from the PR's head branch using `gh pr view <number> --json headRefName`.

## Required Order

1. Fetch the Copilot review comments from the PR.
2. Fetch review threads from both Files and Conversation views when the API/tool surface exposes them; GitHub can hide or bury threads after file changes.
3. Read each comment and the code it refers to.
4. Evaluate whether the comment makes sense in context.
5. Address comments that make sense.
6. Dismiss or note comments that do not make sense.
7. Run the `reviewing-code` skill (all 4 layers) on the full PR diff as an additional pass — report any findings not already covered by Copilot comments.
8. If review changes alter behavior, scope, setup, or reachable edge cases, update the PR test instructions before asking for another review.
9. Run quality gates if any code was changed.
10. Push the updates.
11. Update the PR to a review-ready state.
12. Assign human reviewers.

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

Reply to addressed comments with a short note confirming the fix was made. Include the why only when the comment required a trade-off or architectural decision. Do not write lengthy justifications.

## Dismissing Comments

For comments that do not make sense:

1. Reply with a brief, respectful explanation of why the suggestion does not apply.
2. Reference the specific context that makes the suggestion invalid (e.g. "This follows the existing pattern in X" or "The ticket intent requires Y").
3. Do not ignore comments silently — every comment gets either a fix or a dismissal reply.

For prose follow-up notes, label non-blocking items as `nit:`/`nitpick:`. GitHub review comments should keep the `reviewing-code` `🔵 nit:` severity prefix. Do not treat personal preference as required work.

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

1. Confirm the PR is review-ready: not draft-quality, all known valid comments handled, PR description/testing instructions still match the final scope, and no known implementation-blocking CI failures remain.
2. Identify the appropriate human reviewers for the PR.
3. Use the repository's default reviewer assignment if configured.
4. If no default exists, assign based on code ownership or team conventions.
5. Request review from the assigned reviewers.

Do not assign reviewers before triage is complete — the PR should be clean when they see it.

If the PR is not ready but review was already requested, communicate that directly in the PR and avoid adding more reviewers until it is ready.

## Compound

After the PR is review-ready, run the `skill-evolution` skill to capture any reusable insight from this triage:

- Did a recurring class of Copilot comment surface? Note the pattern.
- Did a fix expose a missing step in an existing skill? Update that skill.
- Did the review reveal a project convention worth recording? Stage it in memory or repo-scoped notes per `skill-evolution`.

Skip this step only when nothing non-obvious was learned.

## Guardrails

- do not ask the user live questions during execution
- do not start new feature work during triage
- do not ignore or lose review threads just because they disappeared from the Files tab
- do not assign human reviewers before valid feedback is handled and PR instructions are current
