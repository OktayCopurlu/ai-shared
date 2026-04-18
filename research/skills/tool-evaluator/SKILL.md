---
name: tool-evaluator
description: "Evaluate whether a new tool, platform, MCP server, SDK, workflow, or skill is worth adopting. USE FOR: 'is X worth trying?', 'should I use X or Y?', 'is this production-ready?', 'evaluate this tool for me', 'is this hype or practical?', 'should we adopt this?', 'is this MCP server mature enough?'. ALWAYS use when asked to assess or compare a new technology, library, or workflow."
disable-model-invocation: true
---

# Tool Evaluator Skill

Use this skill when the user asks:
- Is this tool worth trying?
- Is this production-ready or still hype?
- Should I adopt X or Y?
- What is the risk of using this?
- Is this MCP server mature enough?

---

## Workflow

1. Identify the tool(s) and the concrete use case being evaluated.
2. Check official documentation, repository, changelog, and issue tracker.
3. Score the tool using the evaluation matrix below.
4. Define a minimal proof-of-value trial.
5. If comparing two tools, run the matrix for each and add a comparison table.
6. Render the output.

---

## Evaluation matrix

Score each dimension 0-2:

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Use case fit | Not relevant to our problems | Possibly useful for a future need | Directly solves a real problem we have today |
| Setup complexity | Requires major refactor or new paradigm | Moderate effort, some ramp-up | Drop-in or minimal configuration |
| Maturity | Alpha / experimental / abandoned | Beta / actively developed | Stable / GA / widely adopted in production |
| Documentation quality | Sparse, outdated, or missing examples | Adequate but incomplete | Comprehensive with real-world examples |
| Maintenance health | Abandoned or single maintainer | Active but small team | Well-funded or widely supported open source |
| Lock-in risk | High — proprietary API, no migration path | Moderate — some friction to replace | Low — open standard or easy to eject |
| Team adoption friction | High — new paradigm, steep learning curve | Moderate — familiar concepts, docs needed | Low — fits existing patterns, easy to pick up |
| Measurable benefit | No clear upside or too speculative | Probable improvement, hard to quantify | Concrete measurable benefit with a clear metric |

**Score thresholds:**
- >= 13: Strong yes
- 9-12: Maybe later
- < 9: Not worth it now

---

## Proof-of-value trial

Define the smallest trial that would confirm or refute the tool:

- **Time box**: how many days?
- **Success criteria**: what would confirm it is worth adopting?
- **Failure criteria**: what would confirm it is not worth it?
- **Risk**: what could go wrong during the trial?

---

## Comparison mode

If comparing two tools, run the full matrix for each, then add:

| Dimension | {Tool A} | {Tool B} |
|---|---|---|
| Use case fit | | |
| Setup complexity | | |
| Maturity | | |
| Documentation quality | | |
| Maintenance health | | |
| Lock-in risk | | |
| Team adoption friction | | |
| Measurable benefit | | |
| **Total** | | |

Then write one paragraph: which tool wins on the dimensions that matter most for this specific use case, and why.

---

## Output format

# Tool Evaluation

Tool: {name}
Use case: {what problem are we solving}
Date: {YYYY-MM-DD}

## Verdict
Strong yes | Maybe later | Not worth it now

## Score: <total>/16

## Summary
2-4 sentences.

## Pros
- ...

## Cons
- ...

## Risks
- ...

## Best use cases
- ...

## Not a fit for
- ...

## Proof of value
- Time box: {N days}
- Success criteria: {what confirms this is worth it}
- Failure criteria: {what confirms it is not worth it}
- Risk: {what could go wrong}

## Recommendation
Try now | Monitor | Ignore

## Confidence
High | Medium | Low
