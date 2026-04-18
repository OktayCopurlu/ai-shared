---
description: "Define what to build before writing code. Produces a lightweight spec with scope, acceptance criteria, and open questions. Use before implementation when requirements are vague or a ticket needs clarification."
---

# Spec — Define Before You Build

Clarify what to build before writing any code. This prompt produces a lightweight spec that prevents wasted implementation effort.

## When to Use

- A ticket is vague or missing acceptance criteria
- A feature idea needs structure before it becomes a ticket
- You're about to implement something but aren't sure of the exact scope
- A discussion surfaced multiple approaches and no decision was captured

## Inputs

The user provides one of:

- A Jira ticket key or link
- A rough feature description
- A Slack/meeting discussion summary
- A Figma/design link with no accompanying ticket

## Process

### 1. Gather Context

If a ticket exists:
1. Read the full Jira detail via Atlassian MCP
2. Open and read every link — Figma, Contentful, wiki pages, linked tickets
3. Identify what's clear vs. what's ambiguous

If no ticket exists:
1. Ask the user to describe what they want to achieve (the problem, not the solution)
2. Identify the affected area (which repo, which page/flow, which users)

### 2. Produce the Spec

Output a structured spec covering:

**Problem Statement**
- What is happening today?
- Why is it a problem?
- Who is affected?

**Proposed Scope**
- What changes are needed?
- What is explicitly out of scope?
- What are the acceptance criteria? (observable outcomes only — no implementation details)

**Open Questions**
- Unstated assumptions that need confirmation
- Edge cases without a clear answer
- Decisions that need PM/design/team input
- Dependencies on other tickets, teams, or services

**Risks**
- What could go wrong?
- What are the unknowns?

### 3. Calibrate Depth

Match the spec depth to the scope:

- **Small task** (1–2 AC items): Problem + Scope + Open Questions. One paragraph each.
- **Medium feature** (3–6 AC items): Full spec with all sections. Fits on one screen.
- **Large initiative** (cross-team, new architecture): Full spec + link to solution design. Consider using `solution-design` prompt.

## Variant: README-Driven for New Tools/Libraries/CLIs

When the deliverable is a **net-new standalone tool, library, or CLI** (no Jira ticket, no existing app to extend), use README-driven development (RDD) as the spec format.

**When to use this variant (decision rule):**

- Net-new standalone tool, library, package, or CLI — yes, use RDD
- New feature inside an existing app, or change to existing code — no, use the standard spec above

**Workflow:**

1. Write the README first, as if the tool already existed — installation, usage examples, CLI flags, API signatures, expected output
2. Include concrete input/output examples (these become the acceptance criteria)
3. List non-goals explicitly — what the tool will not do
4. Feed the README to the coding agent as the spec, then implement with red/green TDD (see `tdd` skill): write a failing test derived from a README example, make it pass, move to the next example

**Why this works:** AI agents are strong at implementation but weak at architecture and API design. A human-authored README forces the design decisions up front — naming, interface shape, scope boundaries — before the agent starts generating code. The README doubles as the spec, the acceptance criteria, and the shipped documentation.

**Sources:** Tom Preston-Werner, "Readme Driven Development" (2010); Simon Willison, `scan-for-secrets` and `datasette-ports` build logs (Apr 2026); Lalit Maganti, "Building syntaqlite with AI" (2026).

## Output Options

1. **Inline in chat** — for quick review and iteration
2. **Update the Jira ticket** — add/rewrite the description and AC via Atlassian MCP
3. **Create a new Jira ticket** — if no ticket exists, create one with the spec as the description

Default to inline if the user doesn't specify.

## Guardrails

- Do not invent requirements — spec what the user described, flag what's missing
- Do not include implementation details in acceptance criteria
- Do not write a spec for something that's already clearly defined — say "this looks ready" and stop
- Do not over-spec small tasks — a 2-line fix doesn't need a full spec
- Keep open questions specific and answerable — not vague concerns
- If the user provides a solution, reframe it as a problem first, then evaluate the solution

## See Also

- `jira-ticket` — for ticket structure, AC rules, and review mode
- `solution-design` — for deeper technical design after the spec is clear
- `refine-ticket` — for reviewing an existing ticket before refinement
