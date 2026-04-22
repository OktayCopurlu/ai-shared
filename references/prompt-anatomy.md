# Prompt Anatomy — Writing Effective `.prompt.md` Files

Reference for authoring and reviewing prompt files in `prompts/`.

## Required Structure

Every `.prompt.md` file must have:

1. **YAML frontmatter** with a `description` field — one sentence explaining what the prompt does and when to use it
2. **H1 title** — the prompt's name
3. **Body** — the instructions the agent follows when the prompt is invoked

## Recommended Sections

Order matters. Place high-priority instructions early — models attend to the beginning and end of prompts more reliably than the middle.

| Section | Purpose | Required? |
|---------|---------|-----------|
| **Context gathering** | What to read/fetch before acting (tickets, PRs, linked pages) | When the prompt needs external input |
| **Steps / Procedure** | Numbered workflow the agent follows | Yes — the core of every prompt |
| **Output format** | Exact structure of what the agent produces | When output must be machine-readable or reviewable |
| **Guardrails** | Hard constraints — what the agent must never do | Yes — prevents common failure modes |
| **Failure policy** | What to do when a step fails or blocks | When the prompt runs unattended |

## Writing Rules

### Be specific, not vague

| Weak | Strong |
|------|--------|
| "Review the code carefully" | "Run all 4 layers of the reviewing-code skill on the PR diff" |
| "Make sure tests pass" | "Run `yarn test --coverage` and fail if coverage drops below the threshold in `jest.config`" |
| "Follow best practices" | "Load the `applying-coding-style` skill and fix violations before continuing" |

### Use skills and references — do not inline their content

Prompts orchestrate. Skills contain the expertise. Reference a skill by name rather than copying its rules into the prompt.

```markdown
<!-- Good -->
Load the `reviewing-code` skill and run it on the PR diff.

<!-- Bad — duplicates skill content, drifts over time -->
Check for unused variables, verify naming conventions, look for...
```

### State completion criteria

Every major phase should define what "done" means so the agent knows when to advance.

```markdown
Quality gates are complete when all mandatory checks pass
and no known validation failure remains.
```

### Include guardrails as "do not" rules

Guardrails prevent the most damaging failure modes. Write them as direct prohibitions.

```markdown
## Guardrails
- do not start implementation before the target repository is confirmed
- do not replace missing required fields with guesses
- do not skip mandatory failing gates
```

### Explain the "why" for non-obvious rules

When a rule exists because of a past failure or a subtle trade-off, include one sentence of reasoning. The agent makes better edge-case decisions when it understands intent.

```markdown
- reuse an existing ticket branch for in-progress work when possible
  <!-- avoids orphaned branches and duplicated effort -->
```

### Keep the prompt self-contained for its trigger

A prompt should contain everything needed to execute after the user provides its expected input (e.g., a ticket key, a PR URL). Do not assume the agent remembers prior conversation context.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| **Wall of rules** | Too many constraints crowd out the task itself; the agent may ignore some | Move detailed rules into a skill or reference; keep the prompt orchestration-focused |
| **Ambiguous completion** | No exit criteria; the agent keeps going or stops too early | Add explicit "X is complete when…" after each phase |
| **Silent skip** | A step says "if applicable" without saying how to decide | Replace with a concrete condition: "If the ticket contains a Figma link…" |
| **Inline expertise** | Prompt duplicates content from a skill or reference | Replace with "Load skill X" or "See `references/Y.md`" |
| **Missing failure path** | Only the happy path is described | Add a failure policy section or per-step fallback |

## Frontmatter Reference

```yaml
---
description: "One sentence: what this does and when to use it."
---
```

The `description` field is shown in command palettes and help menus. Make it scannable — start with a verb, include the trigger context.

Good: `"Implement a Jira ticket: code changes, quality gates, and UI validation. Use with a ticket key or link."`
Bad: `"This prompt helps with implementation."` — too vague, no trigger context.

## Validation Checklist

Before shipping a new or updated prompt:

- [ ] Frontmatter has a clear `description`
- [ ] Steps are numbered and ordered by execution sequence
- [ ] Each phase has explicit completion criteria
- [ ] Skills are referenced by name, not inlined
- [ ] Guardrails cover the top 3-5 failure modes for this workflow
- [ ] Prompt is self-contained given its expected input
- [ ] No placeholder or TODO content remains
