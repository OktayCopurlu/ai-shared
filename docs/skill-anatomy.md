# Skill Anatomy

This document defines the structure and format for all skills in `~/.ai-shared/skills/`. Use it when creating or reviewing skills.

## File Location

Every skill lives in its own directory:

```
skills/
  skill-name/
    SKILL.md              # Required: the skill definition
    supporting-file.md    # Optional: reference material loaded on demand
```

## Skill Types

This repo intentionally supports two shapes of skills:

- **Workflow skills**: structured processes the agent should follow step by step. Examples: `debugging`, `reviewing-code`, `test-driven-development`, `git-workflow`.
- **Tool skills**: focused adapters for a specific MCP server, CLI, or browser tool. Examples: `contentful`, `playwright-mcp`, `atlassian-mcp`.

Workflow skills benefit from richer self-check sections. Tool skills can stay lean if extra ceremony would not improve decisions.

## SKILL.md Format

### Frontmatter (Required)

```yaml
---
name: skill-name-with-hyphens
description: "Brief statement of what the skill does. USE FOR: specific triggers. Use when [conditions]."
---
```

**Rules:**
- `name`: Lowercase, hyphen-separated. Must match the directory name.
- `description`: Starts with what the skill does, followed by trigger conditions. Include both **what** and **when**. Maximum 1024 characters.

**Why this matters:** Agents discover skills by reading descriptions. The description is injected into the system prompt, so it must tell the agent both what the skill provides and when to activate it. Do not summarize the workflow in the description — the agent will follow the summary instead of reading the full skill.

## Minimum Required Structure

Every skill must include:

- YAML frontmatter with `name` and `description`
- An H1 title
- At least one substantive H2 section
- Clear activation guidance in the description and/or body

The validator enforces this minimum. It does not require every skill to use the same section set.

### Workflow Skill Template

```markdown
# Skill Title

## When to Use
- Triggering conditions (positive)
- When NOT to use (exclusions)

## [Core Process / Workflow / Steps]
The main workflow — numbered steps, phases, or heuristic layers.
Include code examples where they help.

## [Specific Techniques / Patterns]
Detailed guidance for specific scenarios.
Only when needed.

## Common Rationalizations
| Rationalization | Reality |
|---|---|
| Excuse agents use to skip steps | Why the excuse is wrong |

## Red Flags
- Behavioral patterns indicating the skill is being violated
- Things to watch for during self-monitoring

## Verification
After completing the skill's process:
- [ ] Checklist of exit criteria
- [ ] Evidence requirements

## Output Contract (optional)
Mandatory sections, in order, that the produced artifact must contain.
Add only if the skill hands off a structured deliverable.

## See Also
- `other-skill` — when to cross-reference
- `~/.ai-shared/references/checklist.md` — supporting material
```

Use this fuller template for process-heavy skills where self-monitoring matters.

### Tool Skill Template

```markdown
# Skill Title

Short description of what tool or integration this skill governs.

## Tool Selection
How to choose between MCP, CLI, browser tools, or fallbacks.

## Procedure
Ordered steps for reading, querying, or operating the tool safely.

## Rules
Mutation guardrails, safety boundaries, or things the skill must never do.

## Optional Sections
- `When to Use`
- `Guardrails`
- `Verification`
- `Output Contract` — when the skill produces a structured artifact (report, plan, query)
- `See Also`
```

Use this leaner template for tool-adapter skills when it communicates the operational rules more clearly than the full workflow format.

## Section Purposes

### When to Use
Helps agents decide if this skill applies. Include both positive triggers ("Use when X") and negative exclusions ("NOT for Y").

### Core Process
The heart of the skill. Step-by-step workflow the agent follows. Must be **specific and actionable** — not vague advice.

- **Good:** "Run `npm test` and verify all tests pass"
- **Bad:** "Make sure the tests work"

### Common Rationalizations
The most distinctive feature of well-crafted skills. These are excuses agents use to skip important steps, paired with rebuttals.

Think of every time an agent said "I'll add tests later" or "This is simple enough to skip the spec" — those go here with a factual counter-argument.

### Red Flags
Observable signs the skill is being violated. Useful during self-monitoring and code review.

### Verification
Exit criteria. A checklist the agent uses to confirm the process is complete. Every checkbox should be verifiable with evidence (test output, build result, screenshot, etc.).

### Output Contract (optional)
Specifies the **structure of the artifact** the skill produces — distinct from `Verification`, which checks whether the process ran. Add this section when the skill must hand off a structured deliverable (PR body, ADR, ticket, audit report, code-review summary). Without it, agents tend to inline prose where downstream readers expect named sections.

Include:
- An ordered list of mandatory sections, each one or two words.
- Per-section content rules ("≤2 sentences", "checkbox list", "code block").
- An explicit fallback for partial outputs ("If section X cannot be produced, state why and continue").

Skip this section for skills whose artifact is the side effect itself (e.g. `playwright-mcp` runs an action and returns nothing structured).

- **Good:** "Mandatory sections in order: 1) Summary (≤3 sentences) 2) Verification (per-change-type evidence) 3) Risk & Rollback (single line)."
- **Bad:** "Produce a clear summary."

### See Also
Cross-references to related skills and reference checklists. Prevents duplication and creates a connected skill graph.

### Tool Selection
Useful for tool-adapter skills that need to choose between MCP, CLI, browser automation, or a fallback path.

### Rules / Guardrails
Important for tool-adapter skills that can mutate data, trigger side effects, or depend on environment-specific credentials.

## Supporting Files

Create supporting files only when:
- Reference material exceeds 100 lines (keep SKILL.md focused)
- Code examples or scripts are needed
- Checklists are long enough to justify separate files

Keep patterns and principles inline when under 50 lines.

Shared reference material goes in `references/` at the project root, not inside skill directories.

## Writing Principles

1. **Process over knowledge.** Skills are operating guides, not reference dumps. Use the amount of structure the skill type actually needs.
2. **Specific over general.** "Run `npm test`" beats "verify the tests."
3. **Evidence over assumption.** Every verification checkbox requires proof.
4. **Anti-rationalization.** Every skip-worthy step needs a counter-argument.
5. **Progressive disclosure.** SKILL.md is the entry point. Supporting files load only when needed.
6. **Token-conscious.** Every section must justify its inclusion. If removing it wouldn't change agent behavior, remove it.
7. **Explain the why.** State the reasoning behind a rule when it isn't self-evident. Agents follow rules more reliably when they understand the intent.
8. **Show preferred vs. avoided.** For non-trivial conventions, pair a short "do this" example with a short "not this" example. Concrete code beats abstract description.
9. **Skip what tooling enforces.** Don't restate rules the linter, formatter, or type-checker already catches. Spend tokens on non-obvious decisions the agent would otherwise get wrong.
10. **Never add output-length constraints.** Do not include word limits, line limits, or brevity instructions (e.g. "keep responses under 25 words", "be concise between tool calls"). Anthropic's April 2026 postmortem showed that a single verbosity-reducing prompt line ("keep text between tool calls to ≤25 words") degraded Claude's coding intelligence by 3% — undetected by narrow evals. Control skill length by writing fewer instructions, not by constraining model output.

## Naming Conventions

- Skill directories: `lowercase-hyphen-separated`
- Skill files: `SKILL.md` (always uppercase)
- Supporting files: `lowercase-hyphen-separated.md`
- References: stored in `references/` at the project root

## Cross-Skill References

Reference other skills by name:

```markdown
Follow the `debugging` skill if the build breaks.
Apply `applying-coding-style` to all code written during implementation.
```

When linking to references, docs, or other files in this repo, always use the absolute `~/.ai-shared/` path — never a bare relative path like `references/foo.md`. Skills and prompts are consumed via symlinks from other repos, so a relative path resolves inside the wrong workspace.

```markdown
# ✅ Correct
- `~/.ai-shared/references/security-checklist.md`
- `~/.ai-shared/docs/skill-anatomy.md`

# ❌ Wrong — will look inside the current project repo
- `references/security-checklist.md`
- `docs/skill-anatomy.md`
```

Don't duplicate content between skills — reference and link instead.

## Checklist for New Skills

Before merging a new skill:

- [ ] YAML frontmatter has `name` and `description`
- [ ] `name` matches the directory name
- [ ] `description` includes trigger phrases ("USE FOR", "Use when")
- [ ] Has an H1 title
- [ ] Has at least one substantive H2 section
- [ ] Workflow skills: include "When to Use", a concrete process section, and usually "Common Rationalizations", "Red Flags", "Verification", and "See Also"
- [ ] Tool skills: include clear tool-selection/procedure/rules guidance; add richer sections only when they improve decisions
- [ ] If the skill produces a structured artifact (PR body, ADR, ticket, audit report, code-review summary), it includes an `Output Contract` section listing mandatory output sections in order
- [ ] Under 500 lines (long reference material extracted to supporting files)
- [ ] No content duplicated from other skills
