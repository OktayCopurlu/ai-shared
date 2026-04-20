---
name: clarifying-questions
description: "Ask structured clarifying questions when a task is underspecified. USE FOR: ambiguous requests, multiple viable interpretations, missing inputs, unclear scope before a non-trivial change. Use when the user says 'build X', 'add Y', 'refactor Z' and key decisions (scope, target, format, constraints) are undefined."
---

# Clarifying Questions — Ask Before You Act

When a request is underspecified, guessing is worse than asking. One well-structured round of questions saves time compared to rework after the wrong thing ships.

## When to Use

Ask before acting when any of these are true:

- Multiple viable interpretations exist and the choice materially changes the output
- A required input is missing (file path, ticket ID, target env, credentials)
- Scope is unbounded ("clean up the code", "improve perf")
- The task would create or delete more than a handful of files and direction is unclear

Do NOT use when:

- The answer is verifiable from the codebase, config, or tool output — search first (see `~/.ai-shared/references/search-first.md`)
- The request is trivial, reversible, and cheap to redo
- A default is obvious and the user can course-correct mid-flight

## Procedure

### Step 1 — Verify first, ask second

Exhaust verification before asking. Check source files, configs, open PRs, recent commits, and tool state. Only escalate to a question if verification fails or external context is required.

### Step 2 — Separate "Need to know" from "Nice to know"

- **Need to know** — blocks correct execution. Ask now.
- **Nice to know** — would refine output but a sensible default exists. Note the default, proceed, let user course-correct.

If everything is "nice to know", do not ask — state your assumptions and proceed.

### Step 3 — Write multiple-choice questions with defaults

Prefer MCQ over open-ended. Each question should have:

- A short stem (one line)
- 2–4 concrete options
- A **default** marked so the user can reply "defaults" and move on
- An "Other" escape hatch for open input

Example:

```
1. Scope of the refactor?
   a) Just the function I pointed at
   b) The whole file  ← default
   c) The whole module
   d) Other: ___

2. Keep the existing public API?
   a) Yes, no breaking changes  ← default
   b) Breaking changes OK
```

### Step 4 — Cap the round

- Max 3–5 questions per round. If you need more, the task is not ready — push back on scope first.
- One round only. Do not drip-feed questions across multiple turns.
- If the user replies "defaults" or "you pick", proceed with the marked defaults and state them back in one sentence.

### Step 5 — Pause and wait

After asking, stop. Do not start editing files, running commands, or making tool calls that mutate state. Read-only verification (search, read) is allowed while waiting.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just pick something reasonable" | If "reasonable" isn't obvious to you, it isn't obvious to the user either — ask. |
| "Asking slows us down" | A 30-second question beats 20 minutes of rework. |
| "They said be autonomous" | Autonomy means handling the known; ask when the unknown materially shifts the outcome. |
| "I'll ask as I go" | Drip-feeding questions fragments context. Batch them. |

## Red Flags

- Writing code before the target file, scope, or acceptance criteria is known
- More than 5 questions in one round — scope is too large, push back instead
- Open-ended questions where an MCQ would do
- Asking things that can be answered by reading the codebase
- Continuing to execute while waiting for an answer

## Verification

Before sending the question block:

- [ ] Each question blocks progress (no "nice to know" in the list)
- [ ] Each has a marked default or "Other" option
- [ ] Nothing in the list is answerable by searching the codebase
- [ ] Total count ≤ 5

## See Also

- `~/.ai-shared/references/search-first.md` — verify before asking
- `jira-ticket` — ticket-writing flow uses a similar "up to 3 questions" rule for acceptance criteria gaps
- `~/.ai-shared/prompts/spec.prompt.md` — "Open Questions" section captures clarifications during spec writing

## Source

Pattern adapted from Trail of Bits' `ask-questions-if-underspecified` skill (https://github.com/trailofbits/skills) and the `first-ask` skill in github/awesome-copilot (https://github.com/github/awesome-copilot).
