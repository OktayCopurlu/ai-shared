# Zoom Out — System Context Before Changing Code

Load this reference when stepping back from line-level reading to map an area's place in the system before changing it. Use it when joining unfamiliar code, before structural changes inside a familiar file, or when a review feels like it's missing the forest for the trees.

For full architecture-attention review during a code review pass, use `reviewing-code` Layer 4 directly. This reference is the lighter, ad-hoc version — pull it in when you need the map without the full review ceremony.

## Process

1. **Anchor**: Restate what file, function, or area is in focus, in one sentence.
2. **Map the surface**: List the public entry points of this area — exported functions, components, routes, hooks, events, or types that other code consumes.
3. **Map inbound edges**: Where is this area called from? Group by feature/domain, not file. Use codebase search before guessing.
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

Stop when the next implementation step is clear. The map is context, not the change.

## Guardrails

- Do not write code while producing this map — the output is context.
- Do not refactor untouched code based on what you find here. Flag it as an attention signal and continue.
- Do not invent edges. If a call site or dependency is not actually grep-able in the repo, do not list it.
- Do not stretch the map. If the area is small and self-contained, say so and stop.
- Prefer the codebase as the source of truth over what the docs or types claim.

## See Also

- `~/.ai-shared/skills/reviewing-code/SKILL.md` — Layer 4 architecture attention during full review
- `~/.ai-shared/references/cognitive-debt.md` — when zoomed-out context reveals agent-generated code that no one understands
- `~/.ai-shared/references/refactoring-patterns.md` — when the zoom-out reveals a bounded refactor opportunity
- `~/.ai-shared/references/subagent-driven-development.md` — system context map can sharpen a slice brief before dispatch
