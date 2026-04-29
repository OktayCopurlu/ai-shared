# Work Shaping for Agentic Coding

Use this when a task is fuzzy, large, cross-layer, or likely to outgrow one clean implementation pass. The goal is to shape the work before asking an agent to build it.

This is not a default checklist. Use only the sections that reduce real ambiguity or review risk.

## When Not to Use

Skip this reference when:

- the task is a small bugfix, copy tweak, config change, or single-file change
- acceptance criteria and the implementation path are already clear
- the work can be implemented, tested, and reviewed in one straightforward pass
- a short inline note would give the same clarity as a separate artifact

## Core Idea

AI coding works best when the context is small, the target is clear, and feedback arrives early. Big vague requests degrade quickly: the agent explores too much, plans too broadly, and starts coding before the human and agent share the same design concept.

Shape the work in this order:

1. **Alignment**: interview the human until the goal, non-goals, edge cases, and trade-offs are clear.
2. **Destination**: write a spec, PRD, README, or design doc that captures the desired end state.
3. **Journey**: split the destination into independently reviewable vertical slices with explicit blockers.
4. **Implementation**: let the agent work one slice at a time with fast feedback loops.
5. **QA and review**: use human taste, code review, and validation results to create follow-up slices.

## Context Rules

- Keep always-loaded instructions small. Prefer scoped prompts, skills, and references for task-specific guidance.
- Start large phases from fresh context when possible; summarize durable decisions into an artifact instead of relying on chat history.
- Use read-only subagents for broad exploration. Pull back a concise summary instead of filling the parent context with every file read.
- Treat compacted history as lossy. When exact details matter, verify from source files, tickets, specs, or tests.
- If the context is getting crowded, stop and create the next durable artifact instead of pushing through.

## Human-In-Loop vs AFK

Keep the human in the loop for:

- ambiguous requirements, product trade-offs, and scope boundaries
- architecture shape, module boundaries, and public interfaces
- vertical-slice planning and blocker relationships
- manual QA, visual/product taste, and final review

AFK work does not mean accepted work. After any AFK implementation, a human still owns QA, code review, and the decision to merge.

AFK work is reasonable only after the destination and current slice are clear:

- implementing one scoped slice
- running lint, type checks, tests, and automated review
- fixing validation failures caused by the current slice
- preparing a summary of what changed and what still needs human judgement

## Alignment Interview

Use an alignment interview before writing the spec when the request is rough or the design space is still open.

Skip the interview when the ticket is already clear and the next implementation slice is obvious.

- Ask one question at a time.
- Walk dependencies in order: goal, users, scope, data, UI, failure states, rollout, analytics, testing.
- For every question, provide a recommended answer and the trade-off behind it.
- If the answer needs a domain expert, flag that instead of inventing it.
- Stop when remaining questions would not materially change the first implementation slice.

## Vertical Slices

Avoid horizontal plans like `database -> API -> UI`. They delay integrated feedback until late in the work.

Do not create a slice plan for a small, single-path change with an immediate feedback loop.

A good slice:

- crosses the layers needed for one user-observable behavior
- has a testable or visible outcome at the end
- is small enough to implement, test, and review in one focused pass
- names its blockers explicitly so unrelated slices can run in parallel
- can generate follow-up work during QA without invalidating the whole plan

For the first slice, prefer the thinnest path that proves the end-to-end flow. It can be ugly internally if the interface and feedback loop are right.

## Module Shape

During spec and design, keep a module map in view:

Skip module mapping for tiny local edits that do not introduce or change a behavior boundary.

- identify new and modified modules before implementation starts
- design small public interfaces with meaningful behavior behind them
- prefer tests around behavior-rich modules instead of one test boundary per helper function
- delegate internals only after the module contract and feedback loop are clear

This keeps the human aware of the codebase shape while still letting the agent handle implementation detail.

## Red Flags

- The plan is a sequence of layers rather than user-observable slices.
- The agent wants to implement before the human has answered product or architecture questions.
- A task requires reading half the repo before any testable behavior appears.
- QA only checks whether automation passed, not whether the behavior feels right.
- Old planning docs are treated as authoritative after the code or requirements have moved on.
