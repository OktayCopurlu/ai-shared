---
description: "Run the full FE delivery workflow: Jira intake, routing, implementation, quality gates, UI validation, and OpenCode CLI handoff."
---

# FE Delivery Workflow

Run the full delivery flow from ticket selection to OpenCode CLI handoff.

Steps 1-3 (intake and routing) run inside this prompt.
After routing, continue into the implementation prompt automatically.

## Step 1-2: Intake

The goal is to answer:

`Which ticket should we work on now, and is it safe to continue?`

### Required Order

1. Use Atlassian MCP to get active-sprint tickets assigned to the current developer.
2. Ignore tickets that are already `in-review`, `done`, or `testing`.
3. For remaining candidates, read only enough to determine the target repository.
4. In the correct repository, check branch and PR state.
5. Classify the candidate tickets.
6. Select the highest-priority actionable ticket using the selection rules below.
7. Only then read full Jira detail for the selected ticket.
8. Produce the step-2 analysis: target area, workflow, continue yes/no.

Use the order returned by Atlassian MCP as the authoritative sprint priority. Do not re-sort or apply custom ranking.

### Repository Detection

Determine the repository before any branch or PR check.

Use signals in this order:

1. explicit structured Jira field such as `Target repository`
2. clear repository mention in ticket description or acceptance criteria
3. linked notes that explicitly name the repository

Do not rely on title prefixes alone.

If the repository is still unclear, classify the ticket as `unknown` and do not auto-start work for it.

### Branch and PR Matching

A branch belongs to a ticket if its name contains the Jira ticket key (e.g. `DSC-1948`).

A PR belongs to a ticket if its head branch name contains the Jira ticket key.

Do not match by title similarity or description keywords alone.

### Classification Rules

Once the repository is known:

- `branch missing + PR missing` -> `todo`
- `branch present + PR missing` -> `in-progress`
- `open PR present` -> `in-review`
- `merged PR present` -> `done`
- `repository unknown` -> `unknown`

If local state and GitHub state disagree, prefer the safest explanation and say why.

### Selection Rules

After classification, apply selection in sprint priority order:

1. select the highest-priority `in-progress` ticket (finish half-done work first)
2. if no `in-progress` ticket exists, select the highest-priority `todo` ticket
3. otherwise stop and report that no actionable ticket exists

### Step-2 Analysis

For the selected ticket, determine:

- `target area`
- `target system`
- `target repository`
- `work type` (`code` or `investigation` — use `investigation` for Spikes or tickets focused on research/analysis with no deliverable code change)
- `needs UI validation`
- `continue automatically: yes/no`
- `reason`

If required routing fields are missing, pause safely and explain why.

## Step 3: Routing

Map the ticket to exactly one workflow using the routing matrix.

### Routing Rules

Derive the route from the step-2 analysis fields. Do not use a static lookup table.

- if any required field is `unknown`, route to `pause-for-human`
- if `work type` is `investigation`, route to `analysis-only`
- if the ticket spans multiple systems, route to `mixed`
- otherwise combine `target area` and `work type` into the route name (e.g. `on-frontend` + `code` -> `on-frontend-code`)

### Routing Guardrails

- if `continue automatically` is `no`, route to `pause-for-human`
- if the repository is known but not configured locally, route to `pause-for-human`

Do not start implementation before the route is decided.

## Continue

After routing is decided, automatically continue into the `implementation` prompt (`implementation.prompt.md`). Do not wait for user input between routing and implementation.

Pass the step-2 analysis and route as context when continuing.
