# Context Audit

Use this guide only inside the `OktayCopurlu/ai-shared` repository. It is for auditing ai-shared skills, references, prompts, agents, and repo instructions for bloat, contradictions, redundancy, and drift.

This is intentionally documentation, not a global skill. Product/application repos should not see this in skill discovery.

## When To Use

- Before adding or substantially updating an ai-shared skill, prompt, reference, or agent
- When a new ai-shared content PR overlaps existing guidance
- When files feel repetitive, vague, contradictory, or too broad
- After several research PRs have added new ai-shared content in a short period
- When an agent ignored a rule that should have been obvious and the signal may be buried

Do not use this for normal product-code review, runtime context-window issues, or brand-new content with no surrounding overlap to audit.

## Audit Scope

Inspect only files that steer agents or explain ai-shared maintenance:

- `instructions.md` (read-only: flag drift, do not auto-modify)
- `skills/*/SKILL.md`
- `references/*.md`
- `prompts/*.prompt.md`
- `agents/*.agent.md`
- `docs/*.md`
- `self-evolution/jobs/*/command.md` when the PR changes automation behavior

Skip `.git/`, generated logs, `setup.sh`, `validate.sh`, `self-evolution/runner.sh`, and job config JSON unless the user explicitly asks for tooling review.

## The Five Filters

Run each candidate line or section through these filters. Flag findings before editing.

| Filter | Flag when | Example |
| --- | --- | --- |
| Default | Any modern coding agent already does this without being told | "write clean code", "handle errors properly", "use meaningful names" |
| Contradiction | It conflicts with another rule in the same or sibling file | One workflow says always TDD, another says skip tests for spikes with no reconciliation |
| Redundancy | It repeats guidance already covered with equivalent effect | "be concise" plus "keep it short" plus "do not be verbose" in the same area |
| Bandaid | It fixes one bad output but is not a durable rule | "Never use the phrase 'Let me' in PR titles" |
| Vague | Two maintainers would interpret it differently | "be natural", "use good judgement", "keep it tasteful" |

## Structural Checks

- **Misplacement**: broad policy buried in one skill may belong in `instructions.md`, a reference, or docs; narrow file-type rules should not live in always-loaded instructions.
- **Stale references**: every ai-shared path reference must resolve after the change.
- **Dead See Also links**: cross-links to renamed or deleted skills, prompts, docs, or references should be removed or updated.
- **Global discovery cost**: repo-only guidance should be a doc, prompt, or automation note rather than a top-level skill.
- **Bloat**: flag long sections that repeat general coding advice already covered by `applying-coding-style` or existing references.

## Workflow

1. Pick the slice to audit: one file, one PR, one content family, or a full ai-shared pass.
2. Read the targeted files together so contradictions and duplicates are visible.
3. Apply the five filters and structural checks.
4. For each finding, record the file, the filter/check that fired, and the smallest concrete fix.
5. Report findings before editing unless the change is an obvious mechanical cleanup.
6. Keep audit fixes separate from unrelated content additions when possible.

## Anti-Patterns

- Turning repo-only maintenance guidance into a global skill that appears in every workspace.
- Treating bloat as a line-count problem only; short vague guidance can be worse than long concrete guidance.
- Removing one side of a contradiction without understanding why both rules existed.
- Combining a large cleanup with a new feature or research finding in the same PR.
- Editing `instructions.md` automatically; flag drift and leave that change for explicit review.

## Where This Guide Is Used

- `skills/skill-evolution/SKILL.md` before codifying or reshaping ai-shared content
- `self-evolution/jobs/research/command.md` before research automation opens an ai-shared content PR
- `self-evolution/jobs/research-pr-triage/command.md` when deciding whether an open research PR should stay open for human review