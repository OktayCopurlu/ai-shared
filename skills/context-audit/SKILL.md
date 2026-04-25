---
name: context-audit
description: "Audit ai-shared skills, references, prompts, and agents for bloat, contradictions, redundancy, and drift. USE FOR: periodic hygiene checks, before merging a sibling skill, when files feel repetitive or contradictory, when the agent ignores a rule that should be obvious. Use when user says 'audit my skills', 'check for bloat', 'are my instructions still consistent'. NOT FOR: writing new skills (skill-evolution), reviewing application code (reviewing-code), or runtime context window hygiene (cognitive-debt)."
---

# Context Audit — Hygiene for ai-shared Itself

Skills, references, prompts, and agents accumulate drift the same way code does — duplicated rules, dead pointers, vague advice nobody acts on, bandaid lines added for one bad output. This skill catches that bloat before it silently degrades agent behaviour.

## When to Use

- User asks to audit skills, references, or prompts
- A new skill is about to land that overlaps an existing one (run before merge)
- Something feels repetitive or contradictory across files
- An agent ignored a rule that should have been obvious — suspect signal got drowned out
- After a batch of recent additions (e.g. 3+ research PRs merged in a week)

**NOT for**: brand-new skills with no prior content (use `skill-evolution`), runtime context window failures during a task (`references/cognitive-debt.md`), or generic code review.

## Audit Scope

Inspect only files that actually steer agents:

- `instructions.md` (read-only — flag drift but never modify)
- `skills/*/SKILL.md`
- `references/*.md`
- `prompts/*.prompt.md`
- `agents/*.agent.md`
- `docs/skill-anatomy.md` (the format contract)

Skip `self-evolution/`, `.git/`, and tooling scripts (`setup.sh`, `validate.sh`).

## The Five Filters

Run every candidate line or section through these. Flag, do not auto-delete.

| Filter | Flag when… | Example |
|--------|-----------|---------|
| **Default** | Any modern coding agent already does this without being told | "write clean code", "handle errors properly", "use meaningful names" |
| **Contradiction** | Conflicts with another rule in the same or sibling file | Skill A says "always TDD", Skill B says "skip tests for spikes" with no reconciliation |
| **Redundancy** | Repeats something already covered, sometimes with different wording | "be concise" + "keep it short" + "don't be verbose" in the same skill |
| **Bandaid** | Added to fix one bad output, not a durable rule | "Never use the phrase 'Let me' in PR titles" |
| **Vague** | Two readers would interpret it differently | "be natural", "use good judgement", "keep it tasteful" |

## Structural Checks

- **Misplacement** — file-type rules (e.g. SCSS naming) sitting in `instructions.md` belong in a skill; broad policy sitting deep in one skill belongs in `instructions.md` or a reference.
- **Stale references** — every `~/.ai-shared/path/...` pointer must resolve. Skill name in description must match folder name (validator covers this; verify after rename PRs).
- **Dead See Also** — cross-links to deleted or renamed skills.
- **Bloat thresholds** — flag SKILL.md > 200 lines or any section that repeats general coding advice already in `applying-coding-style`.
- **Description trigger phrase** — `description:` must contain "Use when …" so both `validate.sh` and agnix accept it (see `skill-evolution` repo-specific footguns).

## Workflow

1. **Scope** — ask the user (or pick yourself) which slice to audit: one skill, one category, or a full pass.
2. **Read in parallel** — load every targeted file in one batch; do not iterate file-by-file.
3. **Apply filters** — for each finding, name the file:line, the filter that fired, and the smallest concrete fix.
4. **Cross-file pass** — search for duplicated rules across skills/references using `grep -rn` on the candidate phrase.
5. **Report first, change second** — present findings as a list before editing. Only proceed to edits the user approves.
6. **One change per PR** — never bundle filter hits across unrelated skills. Match the existing research/skill PR style.

## Anti-Patterns

- Auto-rewriting files without showing findings first — owner loses the chance to keep a "vague" rule that was actually intentional.
- Treating bloat as a length problem alone — a 50-line skill full of `Default`/`Vague` lines is worse than a 250-line skill of concrete rules.
- Removing a contradiction by deleting one side — usually both rules exist for a reason; reconcile in `instructions.md` or split into two skills with clearer triggers.
- Running the audit and the addition in the same PR — separate "remove bloat" from "add new content" so each is independently reviewable.
- Editing `instructions.md` from this skill — flag drift, open a separate manual review, never auto-modify.

## See Also

- `skill-evolution` — adding/updating a single skill with intent (this skill is the cross-cutting hygiene pass)
- `reviewing-code` — the same Layer-1/2/3/4 mindset, applied to instruction content instead of source code
- `docs/skill-anatomy.md` — format contract every flagged file must still satisfy after fixes
- `references/cognitive-debt.md` — runtime context-window hygiene, complementary but different concern
