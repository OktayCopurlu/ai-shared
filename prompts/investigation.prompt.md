---
description: "Run a time-boxed investigation (spike) from a Jira ticket or freeform question. Research, validate with evidence, and produce a clear recommendation. Use when start-working routes to analysis-only or for tickets labeled as Spikes."
---

# Investigation

Run a time-boxed investigation for a spike or research ticket. The goal is a concrete recommendation backed by evidence — not a report for its own sake.

## Process

### 1. Frame the Investigation

If a Jira ticket key or link is provided:
1. Read the full Jira detail via Atlassian MCP
2. Open and read every link — wiki pages, linked tickets, external docs
3. Extract the primary question the spike must answer

If only a freeform research question is provided:
1. Ask the user for the decision it unblocks and who needs the answer

Produce a short investigation frame:

- **Primary question**: the single question this spike must answer
- **Secondary questions**: related questions worth answering if time allows
- **Timebox**: how long to spend (default: 2 hours unless the ticket specifies otherwise)
- **Decision deadline**: when this must be resolved to avoid blocking downstream work
- **Success criteria**: what counts as "answered" — e.g., a recommendation with evidence, a working prototype, a comparison table

### 2. Research

Follow this order:

1. **Codebase first** — search the existing codebase for prior art, related patterns, constraints, and integration points. Use the `search-first` reference.
2. **Documentation** — read official docs, API references, and changelogs for relevant tools or services.
3. **External sources** — fetch engineering posts, release notes, or community discussions only when codebase + docs are insufficient.

For each source, record:
- What was found
- Whether it supports or contradicts a candidate approach

Do not research beyond the timebox. If the question is not answerable within the timebox, say so and explain what additional information is needed.

### 3. Validate (when applicable)

If the question can be answered by running code:

1. Write a minimal proof-of-concept or experiment
2. Run it and record the result
3. Clean up — do not leave prototype code in the working tree unless the ticket asks for it

If the question is purely analytical (e.g., comparing vendor options, evaluating migration paths), skip this step.

### 4. Recommend

Produce a recommendation structured as:

**Recommendation**: one clear sentence stating the recommended approach.

**Rationale**: why this approach over alternatives. Include:
- Evidence from the research (specific findings, measurements, or references)
- Trade-offs of the recommended approach
- What was explicitly ruled out and why

**Follow-up actions**: what should happen next — e.g., create implementation tickets, update a wiki page, schedule a team discussion.

**Open questions**: anything that could not be resolved within the timebox.

### 5. Deliver

Output options (ask the user if not obvious):

1. **Inline in chat** — for quick review
2. **Jira comment** — add the recommendation as a comment on the spike ticket via Atlassian MCP
3. **Confluence page** — create or update a wiki page with the findings via Atlassian MCP

Default to inline. If a ticket exists, also add a short summary comment on the ticket regardless of the chosen output.

## Guardrails

- Do not implement a full solution — this is research, not implementation
- Do not exceed the timebox without telling the user
- Do not recommend without evidence — "I think X is better" is not a recommendation
- Do not leave the primary question unanswered — if you cannot answer it, explain why and what is needed
- Do not pad the output — a spike that confirms "yes, approach A works" in three sentences is a good spike
- Keep prototype code minimal and disposable — do not gold-plate experiments
