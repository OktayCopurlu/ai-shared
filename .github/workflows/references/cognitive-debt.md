# Cognitive Debt — Paydown Workflow

Cognitive debt is the gap between code that exists in your repo and code you can confidently reason about. Agent-assisted development accumulates it faster than typing ever did. Pay it down before the next feature, not after something breaks.

## When to Pay It Down (Triggers)

Act on any of these — do not wait until you are stuck:

- You merged a feature you did not read line-by-line.
- You cannot answer "how does X work?" about a file you shipped in the last week.
- The agent's plan mentions an algorithm or library you have never used (e.g. "Archimedean spiral placement").
- A reviewer asks "why this approach?" and your honest answer is "the agent chose it."
- You are about to extend or refactor a module that was originally vibe-coded.
- Daily LLM code output exceeds what you could realistically review — set a per-day cap and stop generating when you hit it.

## Workflow 1 — Linear Walkthrough (default)

Ask the agent to produce a `walkthrough.md` that walks through the code **with real extracts, not paraphrase**. The anti-hallucination rule is non-negotiable: the agent must pull code via shell tools, never retype.

Prompt template:

```
Read the source and then plan a linear walkthrough of the code that explains
how it all works in detail. Build the walkthrough in walkthrough.md.

Use commentary for narration. Use grep, sed, cat, or awk to include snippets
of code you are talking about — do NOT paste snippets manually, since that
risks hallucinated or drifted code.
```

- Run in a fresh agent session pointed at the repo, not the session that wrote the code (avoids confirmation of its own choices).
- Read the walkthrough yourself. If a section makes you skim, that file is a cognitive-debt hotspot — stop and dig in.
- Commit the walkthrough alongside the code so future-you (and reviewers) share the same mental model.

## Workflow 2 — Interactive Explanation (escalate for algorithms)

Use when a linear walkthrough left you with structure but no intuition (e.g. physics sims, layout algorithms, graph traversal, ML inner loops).

Ask the agent to build a small self-contained HTML page that animates the algorithm step-by-step with play / pause / step-frame controls. Paste the existing `walkthrough.md` as context.

Sign you need this: the agent's explanation uses a phrase you cannot picture ("spiral placement", "belief propagation", "constraint relaxation") and the code alone does not make it click.

## Workflow 3 — Two-Version Plan (prevent debt before coding)

Before letting an agent implement a non-trivial plan, require two outputs:

1. The technical plan for the agent (detailed, precise).
2. The intuition build for you (short essay, plain language, no code).

You approve the intuition version. If you cannot explain the intuition version back in your own words, the plan is too ambitious for one pass — split it.

## Anti-Patterns

- Letting the agent paraphrase code into the walkthrough (hallucination risk — enforce grep/sed/cat extraction).
- Reviewing the walkthrough in the same session that generated the code (agent will confirm its own choices).
- Generating features faster than you can absorb walkthroughs — the gap compounds.
- Treating cognitive debt as a documentation problem. It is a comprehension problem; docs are a symptom, not the fix.
- "I'll re-read it when I need to change it" — by then the original context is gone and the agent that wrote it is a different model version.

## Red Flags

- Weekly diff size grows while your ability to answer architectural questions about the module shrinks.
- Every new feature requires the agent to "re-discover" how an earlier feature works.
- Bug reports on code you shipped but cannot recall writing.
- The phrase "the agent wrote that" appears in a code review response.

## Sources

- Simon Willison, *Linear walkthroughs* (Agentic Engineering Patterns, 2026-02-25) — `grep/sed/cat` extraction rule.
- Simon Willison, *Interactive explanations* (Agentic Engineering Patterns, 2026-02-28) — animated explainer pattern, cognitive-debt framing.
- Margaret-Anne Storey, *How Generative and Agentic AI Shift Concern from Technical Debt to Cognitive Debt* (2026-02-09) — definition and team anecdote.
- Max Woolf, *An AI agent coding skeptic tries AI agent coding* (2026-02-27) — `AGENTS.md` discipline and the "approximate knowledge of many things" framing.
- Mario Zechner, *Thoughts on slowing the fuck down* (via Hacker News, 2026-03) — daily code-output cap.
- Nathan Baschez, Twitter (2026-02-17) — two-version plan (technical + intuitive).
