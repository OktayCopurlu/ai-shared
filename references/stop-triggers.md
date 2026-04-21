# Stop-and-Ask Triggers

A short list of concrete conditions that should halt the agent and surface a question to the user, instead of pushing on. Use this when you catch yourself about to keep going through ambiguity, risk, or scope expansion.

These are triggers, not suggestions. If any one fires, stop, summarize what you found, and ask.

## Ambiguity Triggers

- [ ] You cannot tell whether a failing test is wrong or the code is wrong.
- [ ] The requested change has more than one plausible interpretation and the choice materially changes the outcome.
- [ ] Required input (file, credential, endpoint, spec) is missing and you would otherwise guess.
- [ ] You would need to invent an API, endpoint, schema, or identifier to proceed.

## Scope Triggers

- [ ] The fix requires changing algorithm or control flow beyond the reported symptom.
- [ ] The change would touch a public API, exported signature, or a consumer-visible contract.
- [ ] You are about to add, remove, or upgrade a dependency.
- [ ] You are about to edit CI configuration, build tooling, or release pipelines.
- [ ] You are about to rename or move files that others import.
- [ ] You notice an unrelated problem and feel the urge to "also fix" it — note it, do not bundle it.

## Loop Triggers

- [ ] Your last two attempts at the same problem failed in the same way. Stop; do not try a third blind attempt.
- [ ] You are about to revert your own fix to try the opposite approach without new evidence.
- [ ] You cannot reproduce the reported problem and are about to "fix" it anyway.

## Destructive Triggers

- [ ] Any `git` operation that rewrites or discards history: `reset --hard`, `push --force`, `checkout`/`restore` to an older commit, branch deletion, stash drop.
- [ ] Any command that deletes files, drops tables, or truncates data.
- [ ] A migration, seed, or schema change against a shared environment.
- [ ] Overwriting a file you did not read first.

## What To Send When You Stop

Keep it short. Four lines:

1. **Trigger** — which condition above fired, in one sentence.
2. **Context** — the file/line/command that triggered it.
3. **Options** — 2–3 concrete paths forward, each one sentence.
4. **Recommendation** — which option you would take and why, so the user can confirm or redirect with a single reply.

Do not dump logs, do not re-summarize the whole task, do not apologize. Ask the question and wait.
