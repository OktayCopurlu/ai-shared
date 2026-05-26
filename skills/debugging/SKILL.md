---
name: debugging
description: 'Structured debugging workflow: reproduce, localize, reduce, fix, guard. USE FOR: test failures, build breaks, unexpected behavior, runtime errors. Use when quality gates fail, a bug is reported, or behavior does not match expectations. NOT FOR: writing new features test-first (test-driven-development), or reviewing code that already works (reviewing-code).'
---

# Debugging — 5-Step Triage

Resist the urge to guess — follow the steps in order.

## The 5 Steps

### Step 1 — Reproduce
Reproduce the failure reliably before doing anything else. If you cannot reproduce, check environment differences, leftover state, or timing dependencies.
- **Exit:** You can trigger the failure on demand.

### Step 2 — Localize
Narrow where the failure originates. Bisect — do not read the entire codebase.

Pick the isolation technique that fits the situation:

| Technique | How | When to use |
|---|---|---|
| Binary search | Comment out or bypass half the code path, check if failure persists, repeat | Large codebase, unclear location |
| Input reduction | Simplify the input until the bug disappears, then add back the trigger | Complex inputs, data-dependent bugs |
| Dependency elimination | Mock or remove external deps one at a time | Could be in a dependency or integration |
| Version bisect | `git bisect` to find the commit that introduced the regression | Known-good prior state exists |
| Targeted logging | Add log statements at function entry/exit boundaries (not everywhere) | Need to trace runtime execution flow |

For unfamiliar code, use the `Explore` subagent to map module boundaries before diving in.
- **Exit:** You know which file, function, and roughly which lines cause the failure.

### MCP integration failures
When the failure involves an MCP server, client configuration, missing tool, or JSON-RPC error, keep the same reproduce/localize order but use MCP-specific probes:

1. Reproduce outside the host with MCP Inspector; verify capability negotiation, list tools/resources/prompts, call one happy path, and call one invalid-input path.
2. For local stdio servers, run the configured command directly, use absolute paths, pass required env vars explicitly, and verify startup/log text goes to stderr or files rather than stdout.
3. Read the client MCP logs before editing server logic; config syntax, missing executables, inherited working directories, and missing env vars often fail before tool code runs.
4. For Streamable HTTP servers, inspect the initialize exchange plus `MCP-Protocol-Version`, `Mcp-Session-Id`, auth, `Origin`, and `Accept` headers before changing application behavior.
5. If sampling, elicitation, resources, prompts, or list-change notifications fail, confirm both client and server negotiated that capability before treating it as a tool bug.

### Step 3 — Reduce
Create the simplest possible reproduction. Skip if the reproduction is already trivial.
- **Exit:** A minimal test case or snippet that demonstrates the bug clearly.

### Step 4 — Fix
Fix the root cause, not the symptom.
- Fix at the source — no workarounds downstream.
- Smallest correct change — do not bundle refactors with bug fixes.
- **Exit:** Reproduction passes. Full test suite passes. Root cause addressed.

### Step 5 — Guard
Prevent recurrence.
- Write a regression test that fails without the fix and passes with it.
- Commit the fix and guard together.
- **Exit:** A test guards against recurrence.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know what the bug is, let me just fix it" | Skipping reproduction means you might fix the wrong thing. |
| "It works on my machine" | Environment differences are bugs too. |
| "I'll just restart and try again" | Intermittent failures are real bugs — harder to find, not less important. |
| "The MCP tool is broken, so I'll rewrite the handler" | Many MCP failures happen before the handler runs: launch config, stdout corruption, env inheritance, transport headers, or capability negotiation. |

## Red Flags

- Fixing without reproducing first
- Multiple "fix" attempts without localizing the root cause
- Bug fix committed without a regression test
- Editing MCP server code before checking Inspector output and client logs

## See Also

- `reviewing-code` — when debugging uncovers code quality issues for review
- `~/.ai-shared/references/testing-patterns.md` — for writing effective regression tests
- `~/.ai-shared/references/cognitive-debt.md` — when the bug is in agent-generated code you never read; run the walkthrough workflow before trying to localize
