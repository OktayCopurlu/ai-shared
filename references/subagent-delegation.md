# Subagent Delegation — When to Fork Work

A subagent is a fresh agent session spawned from the main (root) agent, with its own context window, that returns a single message when done. Use it to preserve root context and parallelize token-heavy work — not as a default.

## When to Delegate (Triggers)

Delegate when at least one is true:

- **Unfamiliar-repo exploration** — needle questions ("where is X handled?", "how does Y work?") that would otherwise fill the root context with file reads and grep output.
- **Token-heavy tool output** — log scraping, dependency audits, large test runs, web fetches of long pages. Subagent digests; root only sees the summary.
- **Independent parallel work** — 2+ subtasks with no shared state (e.g. "migrate 5 independent files", "review frontend and backend separately"). Dispatch in a single message with multiple tool calls.
- **Multi-perspective review** — spawn reviewers that do not see each other's output. Independence is the feature; it produces unbiased findings (e.g. security review + a11y review + perf review on the same PR).
- **Specialist prompt needed** — the work wants a different system prompt / persona than the root (e.g. devils-advocate on a plan the root just wrote). Avoids priming bias.

## When NOT to Delegate

- The task is small or local to one file — the round-trip cost (extra tokens to spin up + summary back) exceeds the work.
- Subtasks depend on each other — sequential logic belongs in the root; subagents cannot see each other.
- You need the full reasoning in the main transcript (debugging a hard bug, teaching moment, audit trail).
- The detail you need is exactly what the subagent would compress away. Subagents return summaries, not raw traces.

## Three Modes

1. **Explore (read-only, fast)** — OpenCode `explore`, Codex `explorer`. Cannot write. Cheapest. Use for codebase questions and research reads. Ask for file paths + line numbers in the reply so root can read directly.
2. **Parallel workers (independent write)** — OpenCode `general`, Codex `worker`. Dispatch N in one message. Each gets its own slice; none see the others.
3. **Specialist (custom prompt)** — a subagent whose system prompt is a skill or persona (devils-advocate, security-review). Pass the artifact to review in the prompt; require a structured output (findings list, severity).

## Gotchas

- **Cost compounds.** Each subagent is a full model call with its own prompt. A run with 5 parallel workers ≈ 5× the tokens, not 1×. Budget explicitly.
- **Recursion explodes.** Subagents spawning subagents is a cost bomb. Codex caps this with `max_depth` (default 1); OpenCode does not enforce — keep it to depth 1 yourself.
- **Context is the prompt, full stop.** A subagent sees only what you put in its prompt — no access to the root's prior messages, open files, or scratchpad. If it needs three files, paste the paths; do not assume.
- **Over-specialization is a trap.** The root agent is capable. Do not spawn a "file-renamer subagent" for a task the root could do in two tool calls. Reach for a subagent when the context-preservation or parallelism payoff is obvious.
- **Summaries drop detail.** If the subagent finds a subtle bug, the one-message return may bury it. For high-stakes findings, ask the subagent to write a file (e.g. `review-findings.md`) and have the root read it.
- **Invocation syntax differs.** OpenCode: `@explore` / `@general` mention, or Task tool with `subagent_type`. Codex: Task tool with agent name. VS Code Copilot: agent mode → delegate. Keep the skill abstraction; pick invocation per tool.

## Red Flags

- Root context is still filling with raw grep/find output → should have been an explore subagent.
- Subagent returns "I couldn't find the file" → its prompt was too thin; add paths.
- Parallel workers produced contradictory edits to the same file → tasks were not actually independent.
- Depth >1 without a clear reason → stop and flatten.

## Sources

- Simon Willison, *Subagents* (Agentic Engineering Patterns, 2026-03) — context preservation as the primary value; "the root agent is capable" warning against over-specialization.
- OpenCode, *Agents* docs (opencode.ai/docs/agents/) — built-in `explore` (read-only) vs `general`; `@mention` and Task tool invocation.
- OpenAI, *Codex Subagents* (developers.openai.com/codex/subagents/) — `default` / `worker` / `explorer`; `max_depth` default 1.
- VS Code Copilot, *Subagents* (code.visualstudio.com/docs/copilot/agents/subagents) — specialist orchestration and independent-review pattern.
- `ersinkoc/claude-code-subagents` (GitHub) — community catalog showing specialist-per-domain patterns; useful as counter-example for over-specialization.
