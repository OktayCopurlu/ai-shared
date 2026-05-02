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

### Lifecycle Frontmatter (Optional)

Use lifecycle fields when a skill, prompt, or agent is being retired but should remain available during migration.

```yaml
---
name: old-skill
description: "DEPRECATED. Superseded by `new-skill`; kept only for migration. Do not activate for new work."
deprecated: true
superseded_by: new-skill
deprecated_at: 2026-05-02
remove_after: 2026-08-02
---
```

Rules:
- `deprecated: true` means the file is kept only for migration and must not be activated for new work.
- `description` must start with `DEPRECATED` and must not contain active trigger phrases such as `USE FOR:` or `ALWAYS use`.
- `superseded_by` should name the replacement when one exists. Use `deprecation_reason` only when there is no direct replacement.
- `deprecated_at` records when the migration window starts.
- `remove_after` records when the file should be deleted or moved out of the active surface; use a date, not an open-ended promise.

Do not delete a skill, prompt, or agent in the same PR that introduces the replacement unless the old file is clearly unused. Deprecate first, remove after the migration window, and keep each step independently reviewable.

## Minimum Required Structure

Every skill must include:

- YAML frontmatter with `name` and `description`
- An H1 title
- At least one substantive H2 section
- Clear activation guidance in the description and/or body

The validator enforces this minimum. It does not require every skill to use the same section set.

## Deprecation Lifecycle

Deprecation is for reducing discovery noise without surprising downstream users. Use it when a skill, prompt, or agent is superseded, too narrow to keep, stale relative to current tools, or merged into a better workflow.

Lifecycle sequence:

1. **Replace** — add or update the better file first.
2. **Deprecate** — mark the old file with lifecycle frontmatter and remove active trigger language from `description`.
3. **Route** — update related `See Also`, README graph entries, and global Skill Awareness so new work points to the replacement.
4. **Validate** — run `zsh validate.sh` and `npx -y agnix .`.
5. **Remove** — after `remove_after`, delete the deprecated file in a separate PR if no references remain.

Keep deprecated files out of `instructions.md` Skill Awareness. Descriptions are part of the every-session discovery surface, so a deprecated file must be obvious and quiet there.

## Behavioral Evals

Structural validation is not enough. When a skill's activation language or required workflow steps change, add or update deterministic eval rows under `~/.ai-shared/evals/` and run `zsh validate.sh`.

- `skill-routing.tsv`: user-request examples that must remain discoverable from a skill's frontmatter description.
- `step-adherence.tsv`: required instructions that prevent agents from skipping important workflow steps.
- `mcp-tool-drift.tsv`: current-surface bad references that previously broke tool routing, not permanent tool-name bans; remove or narrow rows when the exposed tool surface changes.
- `mcp-drift-guardrails.tsv`: tool-adapter skills that must explicitly say how to handle current-session tool-name drift.

Keep each row narrow: one request or one required step per row. These evals do not simulate a full model, but they catch regressions in the text surfaces agents actually use for routing and self-monitoring.

For tool-adapter skills, prefer current-session tool selection guidance over exhaustive MCP tool inventories. If a concrete tool name is useful as an example, make it clear that the name is representative and must be mapped to the tool surface exposed in the current session.

### MCP Drift Pattern

Keep MCP drift guidance centralized here and lightweight in each tool-adapter skill:

- Add a short local guardrail in the affected skill that tells agents to use the current session's exposed tools and map by intent.
- Add or update `mcp-drift-guardrails.tsv` so the skill keeps that current-session guardrail.
- Add stale exact strings to `mcp-tool-drift.tsv` only when they are known-bad for the current exposed surface.
- Prefer updating this pattern over copying long tool-surface explanations into every skill.

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

## Admission Test

Before codifying new guidance in ai-shared, check whether it is ready to become a durable rule.

Ask:
- Is this ai-shared-specific, workflow-specific, or tool-specific enough to belong here?
- If it is specific to one product repo, should it live in that repo's local instructions instead?
- Would a capable agent already know this without ai-shared? If yes, codify only the workflow/tool/local-convention part that changes behavior.
- Does it prevent a repeated miss, a known drift issue, or a failure mode that already showed up in real work?
- Can an agent follow it with observable evidence, not just good intentions?
- Is this already enforced by lint, tests, type checks, `validate.sh`, or another existing rule?
- Does it belong in a skill, prompt, reference, or validator instead of always-on instructions?

If the answers are weak, stage the idea first: log it in the relevant run log, keep it as review feedback, or wait for another occurrence. Codify it when the evidence is stronger or the guidance clearly changes future agent behavior.

Product-repo rules should live closest to that repo by default. Put them in ai-shared only when they are needed by shared prompts, tools, or recurring cross-repo workflows, and keep them scoped to the smallest skill, prompt, reference, or validator that needs them.

## Writing Principles

1. **Process over knowledge.** Skills are operating guides, not reference dumps. Do not turn general agent competence into a skill; capture only the workflow, tool, or local convention the agent would otherwise miss.
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
- [ ] If this replaces an existing skill, prompt, or agent, the old file is either updated in the same PR with lifecycle frontmatter or intentionally left active with a stated reason
- [ ] Routing or required-step changes have matching rows in `~/.ai-shared/evals/skill-routing.tsv` or `~/.ai-shared/evals/step-adherence.tsv`
- [ ] MCP/tool-adapter changes follow the MCP Drift Pattern above when exact tool names can vary
- [ ] Under 500 lines (long reference material extracted to supporting files)
- [ ] No content duplicated from other skills
