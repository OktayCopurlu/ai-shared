# Context Hygiene — Managing LLM Context Windows

Context hygiene is the discipline of keeping an LLM agent's context window clean, focused, and free of noise. Poor context hygiene degrades output quality silently — the model does not warn you when its window is polluted.

## Failure Modes

Four ways context goes wrong. Recognize these early:

### Context Poisoning

Stale, incorrect, or hallucinated content enters the window and the model treats it as ground truth. Common causes:

- Pasting outdated documentation or specs that no longer match the codebase.
- Prior tool output that returned errors or partial results, still sitting in the conversation.
- The model's own earlier hallucination referenced later as if it were verified.

**Mitigation:** Verify tool outputs before relying on them. Start fresh sessions for new tasks rather than reusing long conversations. When referencing prior output, re-verify against source.

### Context Distraction

Irrelevant content dilutes the model's attention. The window has capacity, but the signal-to-noise ratio drops.

- Dumping entire files when only a few lines matter.
- Verbose tool output (full stack traces, large JSON blobs) left unfiltered.
- Conversational tangents that were never pruned.

**Mitigation:** Use targeted reads (offset + limit) instead of full file dumps. Summarize large outputs before continuing. Keep instructions concise — every token competes for attention.

### Context Confusion

Contradictory information in the window causes the model to oscillate or blend incompatible approaches.

- Two different coding styles described in the same prompt.
- Instructions that say "always use X" alongside examples that use Y.
- Multiple conflicting requirements pasted without prioritization.

**Mitigation:** Resolve contradictions before they enter the prompt. When loading multiple references, note which takes precedence. Single-purpose sessions reduce confusion.

### Context Clash

The model's trained knowledge conflicts with project-specific conventions in the window. The model defaults to its training when the window signal is weak.

- Project uses an unconventional pattern that the model keeps "correcting."
- Custom DSLs or internal APIs that resemble but differ from popular libraries.

**Mitigation:** Make project conventions explicit and prominent in the prompt. Provide concrete examples, not just rules. Repeat critical conventions near the end of the context where recency bias helps.

## The Principle of Least Context

Treat the main agent session as an orchestrator, not a knowledge store:

- **Delegate to sub-agents.** Each sub-agent gets only the context it needs for its specific task. Results flow back as concise summaries, not full transcripts.
- **Use side-channel persistence.** Sub-agents write findings to files (plans, summaries, intermediate results), not back into the main conversation context. The orchestrator reads files on demand.
- **Prune aggressively.** If a piece of context has served its purpose (e.g., a search that found the right file), do not carry the raw search results forward.

### Context Rot

Beyond approximately 40% of the context window, output quality degrades measurably. Signs:

- The model forgets instructions given early in the conversation.
- Responses become repetitive or circular.
- The model stops following conventions it was following earlier.

**Response:** Start a new session. Transfer only the essential state (current task, key decisions, file paths) — not the full history.

## Practical Rules

1. **One task per session** when possible. Multi-task sessions accumulate noise.
2. **Verify, do not trust.** Treat all model output as unverified until confirmed by a tool or source read.
3. **Front-load and back-load critical instructions.** Models attend most to the beginning and end of context (primacy and recency effects).
4. **Summarize before continuing.** After a long exploration phase, summarize findings before starting implementation.
5. **Prefer targeted reads.** `Read file X lines 50-80` over `Read file X` when you know what you need.
6. **Watch for the 40% threshold.** If the conversation is long and quality drops, start fresh with a state transfer.

## When to Load This Reference

- Before starting a long or complex agent session.
- When output quality degrades mid-session (context rot signal).
- When debugging why an agent "forgot" something or produced contradictory output.
- During code review of agent-assisted workflows that manage context.

## Sources

- Weaviate Engineering Blog, *Context Engineering* (2026-04) — failure mode taxonomy: poisoning, distraction, confusion, clash; six pillars of context engineering.
- Basti Ortiz (dev.to), *The Mental Framework for Unlocking Agentic Workflows* (2026-04) — Principle of Least Context, side-channel persistence, context rot beyond 40% window, sub-agent delegation pattern.
- Simon Willison, *Agentic Engineering Patterns* (2026-02) — session isolation, targeted reads, verification-first patterns.
