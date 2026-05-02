---
description: "Mine recent delivery PR feedback and turn recurring agent friction into one durable ai-shared improvement."
---

# Self-Evolution From PR Feedback

Run a focused self-evolution pass for ai-shared. The goal is not to polish everything; it is to convert one recurring failure mode from PR feedback into a durable guardrail.

## Inputs

Use any context the user provides, plus the smallest useful set of local evidence.

Default feedback source when the user does not specify another source:

- GitHub repo: `onrunning/on-frontend`
- PR author: `OktayCopurlu`
- Time window: previous Monday 10:00 local time through the most recent Monday 10:00 local time; if run manually before a Monday 10:00 boundary, use the last completed Monday-to-Monday window
- Read human-authored PR review comments, issue comments, review summaries, and requested changes
- Prefer the `github-mcp` skill and GitHub API data over browser scraping

Human-only feedback rule:

- Keep only feedback whose author is a human GitHub user.
- Exclude GitHub Copilot feedback and any bot/app-authored feedback, including author logins such as `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, logins ending in `[bot]`, GitHub Apps, and API author types like `Bot` or `App`.
- If author metadata is unavailable or ambiguous, do not use that feedback as evidence for a durable ai-shared change.
- Do not count excluded automated feedback toward recurrence, scoring, PR evidence, or run-log findings.

Supplementary sources:

- recent human PR review comments or user feedback
- repeated agent mistakes from the current session
- stale skill/tool behavior discovered during work
- relevant entries from `self-evolution/jobs/research/run-log.jsonl`

## Workflow

1. Collect human feedback evidence from the default source unless the user supplied a narrower source.
2. Identify friction points and group them by failure mode:
   - stale tool or MCP guidance
   - missing validator guardrail
   - unclear prompt workflow
   - duplicated or bloated skill guidance
   - missing reference checklist
   - PR/review/QA evidence gap
3. Keep only feedback that points to a reusable ai-shared improvement. Ignore one-off product/design disagreements, ticket ambiguity, and local implementation bugs that do not imply a missing harness rule.
4. Use run logs as staging: log one-off patterns, but update ai-shared only when the same failure mode appears in 2+ PRs in the current window or appears again after a previous run-log entry.
5. Pick exactly one failure mode to address now. Prefer the one that is repeated, verifiable, and small enough for one PR.
6. Decide the durable home:
   - `validate.sh` for mechanical repo checks
   - an existing skill for reusable operating guidance
   - an existing prompt for workflow sequencing
   - a reference file for checklist-style detail
   - `self-evolution/policy.md` for research selection rules
7. Before creating or updating any skill, read `skills/skill-evolution/SKILL.md` and `docs/skill-anatomy.md`, then follow their rules for whether to update an existing skill or create a new one.
8. Make the smallest coherent change. Update README only when a top-level skill, prompt, agent, or reference is added.
9. Run validation:
   - `zsh validate.sh`
   - `npx -y agnix .` when skill frontmatter, skill structure, or prompt/skill semantics changed
   - `./setup.sh` when a skill folder or prompt file was added, renamed, or removed

## Guardrails

- Do not create a new skill when an existing skill can absorb the guidance cleanly.
- Do not add broad always-on instructions for a narrow failure mode.
- Do not encode a one-off preference as a durable rule unless the user explicitly asks.
- Do not add guidance a competent agent would already know; only add repo-specific, workflow-specific, tool-specific, or repeatedly missed guidance.
- Do not keep a stale tool inventory just because it is convenient; prefer selection rules and representative examples.
- Do not open more than one improvement thread in a single self-evolution-from-pr-feedback pass.
- Do not write comments, replies, labels, or status changes on delivery PRs while collecting feedback. Treat PRs as read-only evidence.
- Do not use GitHub Copilot comments, bot comments, or app-authored review feedback as source evidence.

## Output

End with:

- the failure mode addressed
- feedback source and time window used
- files changed
- validation results
- any follow-up candidates intentionally left for later
