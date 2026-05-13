---
description: "Step back from the current code and explain it in system context — what depends on it, what it depends on, what surface it exposes, and what could break if it changes. Use when you've been deep in a function or file and need broader perspective before changing it, when joining unfamiliar code, or when asked to summarize an area at a higher level."
---

# Zoom Out

A fast orchestration prompt. Pull the agent out of line-level reading and force a system-context explanation before changing anything.

Use this when you (or the agent) has been deep in one file and is about to make a structural change, when entering unfamiliar code, or when a review feels like it's missing the forest for the trees.

For full architecture-attention review during code review, use `reviewing-code` Layer 4 instead — `/zoom-out` is the lighter, ad-hoc version.

## Process

1. **Anchor**: Restate what file, function, or area is in focus, in one sentence.
2. **Map the surface**: List the public entry points of this area — exported functions, components, routes, hooks, events, or types that other code consumes.
3. **Map inbound edges**: Where is this area called from? Group by feature/domain, not file. Use the codebase search before guessing.
4. **Map outbound edges**: What does it depend on? External services, shared state, other modules, side effects (network, storage, analytics).
5. **State the contract**: What invariants does this area promise to callers? What does it assume from its dependencies?
6. **Name the blast radius**: If the proposed change lands, what breaks? What needs re-testing? What is silently affected?
7. **Flag attention signals**: One short list — cross-domain coupling, single-consumer abstractions, hidden global state, duplicated logic, client-side computation of server data, prop drilling, oversized interfaces. Same signals as `reviewing-code` Layer 4 but framed as questions to direct review attention, not directives.

## Output

A short structured note, not an essay:

- **Focus**: one sentence
- **Public surface**: bullet list
- **Inbound / Outbound**: bullet list each
- **Contract**: 1–3 invariants and 1–3 assumptions
- **Blast radius**: what changes downstream if this changes
- **Attention signals**: questions only, no prescriptions

Stop when the next implementation step is clear. Do not write the change itself in this prompt.

## Guardrails

- Do not write code in this prompt — the output is context, not implementation.
- Do not refactor untouched code based on what you find here. If something looks wrong, flag it as an attention signal and continue.
- Do not invent edges. If a call site or dependency is not actually grep-able in the repo, do not list it.
- Do not stretch the map. If the area is small and self-contained, say so and stop.
- Prefer the codebase as the source of truth over what the docs or types claim.

## See Also

- `reviewing-code` — Layer 4 architecture attention during full review
- `references/cognitive-debt.md` — when zoomed-out context reveals agent-generated code that no one understands
- `references/refactoring-patterns.md` — when the zoom-out reveals a bounded refactor opportunity
