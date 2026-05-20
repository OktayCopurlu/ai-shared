---
description: "Run the canonical delivery pipeline for a single ticket, from clarification through implementation, PR, review, and feedback."
---

# Delivery Pipeline — Phase Contract

Canonical phase order for taking **a single ticket** from raw input to merged code. Each phase has a single owning prompt, a skip rule, and a default next phase.

This is a **contract**, not a script. Phases can be skipped per the skip rule, but the order is fixed: never advance to a later phase without the earlier phase's required output existing (in the ticket, a doc, or chat history).

> Project- or epic-shaped work (greenfield, architectural, cross-team) uses [project-design.prompt.md](project-design.prompt.md) **before** this pipeline starts producing tickets. It is intentionally outside this pipeline.

## Phase Map

| # | Phase            | Owning prompt                                                                                    | Required output                                                  | Skip when                                                       |
| - | ---------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- | --------------------------------------------------------------- |
| 0 | Constitute       | `instructions.md` + `AGENTS.md` / `.github/copilot-instructions.md` in local repo | Governing rules loaded for the session                           | Never — always implicit                                         |
| 1 | Clarify          | [grill-me.prompt.md](grill-me.prompt.md)   | Decisions made / open questions / non-goals                      | Small ticket with crisp AC, single-file bugfix, or obvious next step |
| 2 | Specify          | [spec.prompt.md](spec.prompt.md)                                                                 | Spec: scope, acceptance criteria, open questions                 | Ticket already has spec-quality AC and no hidden decisions      |
| 3 | Implement        | [implementation.prompt.md](implementation.prompt.md)                                             | Tasks shaped · AC ↔ diff cross-check · code · tests · quality gates · manual QA · UI validation | Never — execution lives here    |
| 4 | Open PR          | [pr.prompt.md](pr.prompt.md)                                                                     | PR with title + body per `git-workflow`, Copilot review requested | Never for shipped work                                          |
| 5 | Self-review PR   | [review-pr.prompt.md](review-pr.prompt.md) _(run against own PR)_                                | 4-layer review (`reviewing-code` skill) · AC coverage table · preview validation | Trivial PRs (typo, dependency bump) — judgement call |
| 6 | Address feedback | [address-review.prompt.md](address-review.prompt.md)                                             | Each review comment triaged · valid ones fixed · rerun quality gates · PR set review-ready | No review comments to address                       |

## What lives inside Phase 3 (Implement)

`implementation.prompt.md` is intentionally one prompt that walks through several sub-steps. Don't promote these into separate phases — that adds ceremony without value.

The pipeline should name the skills involved, but the detailed trigger rules stay in `implementation.prompt.md` so there is one source of truth during execution:

| Sub-step inside Implement       | Section in implementation.prompt.md  | Skills / refs used |
| ------------------------------- | ------------------------------------ | ------------------ |
| **Tasks** — shape work into vertical slices | §"Task Shape and Context"  | [references/work-shaping.md](../references/work-shaping.md) |
| **Implement** — write code                  | §"Code Changes"            | `applying-coding-style`; `linked-context-routing`; `figma-mcp` / `playwright-mcp` when linked context requires them; `a11y-audit` for interactive UI; `security-hardening` for auth, user input, secrets, or data-boundary changes |
| **Analyze** — AC ↔ diff coverage map        | §"Cross-Check"             | Ticket/spec contract |
| **Self-review** — coding-style pass         | §"Quality Gates" (step 4)  | `applying-coding-style` |
| **Quality gates** — lint, types, tests      | §"Quality Gates"           | Repo-defined commands; `test-driven-development` when adding behavior with regression coverage |
| **Manual QA / UI validation**               | §"Manual QA"               | `manual-qa`; `validating-ui` for visible UI impact, including recovery before marking checks blocked/not verified |

If `implementation.prompt.md` ever grows too large, this is where to split it — but only when the prompt becomes hard to maintain, not for spec-kit symmetry.

## Skip Rules — Quick Reference

| Ticket shape                              | Phases to run         |
| ----------------------------------------- | --------------------- |
| Single-file bugfix with reproduction      | 3 → 4 → 5 → 6         |
| Small ticket, clear AC                    | 2 → 3 → 4 → 5 → 6     |
| Medium ticket, multiple files             | 1 (if fuzzy) → 2 → 3 → 4 → 5 → 6 |
| Large or under-specified ticket           | 1 → 2 → 3 → 4 → 5 → 6 |
| Project / epic / new architecture         | [project-design.prompt.md](project-design.prompt.md) **first**, then split into tickets that re-enter this pipeline |

## Entry Points

This pipeline is independently callable for a single ticket. A user can provide a Jira key, ticket link, PR link, or clearly scoped ticket description and enter the phase that matches the current state of the work.

## Related

- Phase 0 governing rules: `~/.github/copilot-instructions.md` for VS Code Copilot, `~/.codex/instructions.md` for Codex, `~/.config/opencode/AGENTS.md` for OpenCode, `~/.claude/CLAUDE.md` for Claude Code)
- Work-shaping rules used in Clarify and Implement §Task Shape: [references/work-shaping.md](../references/work-shaping.md)
- Post-ship learning loop: [skills/skill-evolution/SKILL.md](../skills/skill-evolution/SKILL.md)