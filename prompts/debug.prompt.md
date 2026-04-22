---
description: "Investigate a bug, test failure, or unexpected behavior. Structured hypothesis-driven debugging with root cause confirmation before any fix."
---

# Debug

Investigate and fix a bug, test failure, or unexpected behavior.

## Gather Context

Before forming hypotheses, collect what exists:

1. **Symptom** — exact error message, stack trace, or observed behavior
2. **Expected behavior** — what should have happened instead
3. **Reproduction** — steps or command to trigger the failure
4. **Scope** — when it started, what changed recently (`git log --oneline -10`), affected environments

If any of these are missing, ask the user before proceeding.

## Investigate

Load the `debugging` skill and follow its 5-step triage.

1. **Reproduce** — confirm you can trigger the failure on demand
2. **Hypothesize** — form 2-3 ranked candidate causes with reasoning
3. **Test** — validate one hypothesis at a time with evidence (log output, test result, code trace)
4. **Confirm** — eliminate until one cause remains, citing the confirming evidence (file:line or log output)
5. **Fix** — apply the smallest change that addresses the root cause

Do not propose a fix until the root cause is confirmed by evidence.

## Constraints

- No speculative fixes — evidence before action
- No symptom masking — fix the cause, not the crash
- No bundled refactors — fix the bug only
- If the fix needs regression coverage, load the `test-driven-development` skill

## Output

Summarize findings in this format:

```
Root cause: <what broke and why, with file:line>
Fix: <what changed>
Validation: <how it was verified>
Risk: <what else could be affected>
Guard: <regression test added>
```

## See Also

- `test` prompt — when you need to write or run tests after the fix
- `~/.ai-shared/references/error-messages.md` — for writing clear error messages in the fix
