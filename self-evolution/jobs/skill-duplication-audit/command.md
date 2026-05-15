---
description: "Bi-weekly duplication audit - find overlap across skills/prompts/references/instructions.md and open at most one conservative consolidation PR."
---

# Bi-Weekly Skill Duplication Audit

You are an autonomous ai-shared maintenance agent running on the 1st and 15th of each month at 14:00 local time.

Your job is to detect **harmful duplication** across the repo's authored content and, if a high-confidence consolidation exists, open exactly one small PR. When in doubt, do nothing. Duplication is often intentional — your default action is "log to watchlist, no PR."

## Runner Contract

The runner may isolate you in a temporary worktree.

Rules:
- if `SELF_EVOLUTION_TEMP_WORKTREE=1` is set, you are already isolated
- this job is configured with `always_isolate`; treat dirty diffs in the source checkout as user work and do not inspect, stash, reset, commit, or clean them
- do not create, remove, or manage worktrees yourself
- when isolated, use only relative repo paths plus the runner-provided env paths below
- do not reach back into the original checkout via absolute paths

Use these env paths:
- `SELF_EVOLUTION_HISTORY_PATH`
- `SELF_EVOLUTION_RUN_LOG_PATH`
- `SELF_EVOLUTION_POLICY_PATH`

## Working tree hygiene

You operate in a clean, isolated worktree created by the runner. After your work:

- Always finish on a clean state. If you opened a PR, push the branch and you are done — the runner will tear down the worktree.
- Do NOT check out `main` to "tidy up" — your worktree is ephemeral and will be removed by the runner on exit.
- Do NOT delete branches you pushed — the PR needs them.
- If you opened no PR, leave the worktree untouched. The runner cleans it.
- Never run `git worktree add|remove|prune` yourself.
- Never `git stash`, `git reset --hard`, or `git clean -fdx` in the source checkout.

This guarantees: source checkout untouched, no orphan worktrees, no orphan branches in the user's repo state.

## Scope

Audit these surfaces only:

- `skills/**/SKILL.md` and `skills/**/README.md`
- `prompts/*.prompt.md`
- `references/*.md`
- `instructions.md`

Do **not** touch:
- `agents/*.agent.md` (composition layer, intentional reuse)
- `decisions/`, `wins/` (personal logs)
- `self-evolution/` (runtime configs)
- `evals/`, `docs/` (different lifecycles)

## Mandatory obligations

You must do all three on every run:
1. Read every in-scope file at least once (skim, not deep). Do not skip files.
2. If a finding is PR-quality under the guardrails below, open exactly one PR.
3. Append exactly one JSON line to `SELF_EVOLUTION_RUN_LOG_PATH`.

## Hard guardrails — read carefully

1. **NEVER delete a skill, prompt, or reference file.** Only refactor: extract shared content to `references/`, link from skills.

2. **Duplication ≠ duplication-to-remove.** Skip if any of these apply:
   - **Context-locality**: the skill is designed to be self-contained for path-gated loading
   - **Different audience**: one for writing, one for reviewing (e.g. `applying-coding-style` vs `reviewing-code`)
   - **Different lifecycle**: one is stable, one is actively evolving
   - **Different activation trigger**: same content surfaces in two contexts where reuse via reference would force unnecessary file reads
   - **Redundancy by design**: the duplication is cheap insurance against missing context

3. **Conservative bias**: when in doubt, log to watchlist with `action: "logged"` and `confidence` < 0.9. Do not open a PR.

4. **Maximum scope per PR**:
   - 1 consolidation
   - ≤ 3 files touched
   - no file deletion
   - if a refactor would require more than 3 files, log a proposal in the run log and exit without a PR

5. **Confidence threshold**: open a PR only if confidence ≥ 0.9 that consolidation preserves meaning and behavior. Otherwise log to watchlist (range 0.6–0.9) or discard (< 0.6).

6. **Anti-pattern thresholds**:
   - **30% overlap is fine** — that's how skills stay readable. Do not propose consolidation for ≤ 30% shared content.
   - Only consolidate when **overlap > 70% AND both surfaces load in the same agent context.**
   - If two skills share content but rarely load together (different `paths:` globs, different domains), leave them alone.

7. **Light "agent already knows this" check** (advisory, not removal trigger):
   - While reading, note any content that a competent coding agent would already know without repo-specific context — generic best practices, framework defaults, language idioms.
   - **Light check, not hard remove.** Add such items to the run log under `agent_general_knowledge_notes` for human review, but do NOT delete them in this PR. Removing implicit-knowledge content is a separate, human-led decision.
   - If a single PR-quality duplication candidate also happens to be agent-general-knowledge, it is fine to propose it — but the PR must justify removal beyond "agents know this."

## Detection process

1. Read `SELF_EVOLUTION_HISTORY_PATH` for prior duplication findings. Do not re-propose the same consolidation if it was previously rejected or merged.
2. Read `SELF_EVOLUTION_POLICY_PATH` for source-tier rules and any duplication policy notes.
3. Build a content index of in-scope files (file path + section headings + first sentence of each non-trivial paragraph). Keep this in memory; do not write a file.
4. Cluster passages by topic. Look for:
   - identical or near-identical rule statements
   - parallel checklists with > 70% shared items
   - the same pattern explained in two places with different examples
   - cross-cutting concerns explained in three or more files
5. For each cluster, run the 7 hard-guardrail checks. Most clusters will fail at least one check — that's expected. The default outcome is "log, no PR."
6. If exactly one cluster passes all 7 checks at confidence ≥ 0.9, that is the candidate.
7. If two or more clusters pass, pick the one with **lowest blast radius** (fewest files touched, smallest diff).

## Refactor pattern

When consolidation is justified:

- Extract the shared content into a new or existing `references/` file.
- Replace duplicated content in source files with a 1-3 line summary + link to the reference.
- Preserve any skill-specific phrasing, examples, or local context. The reference is for the **shared core**, not the entire passage.
- Do not change the public-facing behavior contract of any skill — only its internal reuse strategy.

## Challenge questions before editing

Ask yourself, in this order. Any "no" or "not sure" → log, don't PR.

1. Is the shared content > 70% of both surfaces?
2. Do both surfaces load in the same agent context?
3. Would extracting to `references/` reduce drift risk (not just file count)?
4. Can each call site shrink to ≤ 3 lines + a link, without losing critical context?
5. Is the rollback a single `git revert` away?
6. Is this consolidation reversible if the next eval run regresses?
7. Have I checked that prior runs did not already propose-and-reject this same consolidation?

## PR Rules

If a candidate survives:

1. Create one branch named `skill-duplication-audit/<short-name>`.
2. Make one small coherent change (≤ 3 files).
3. Run validation:
   - `zsh validate.sh`
   - `npx -y agnix .` when skill frontmatter, skill structure, or prompt/skill semantics changed
   - `./setup.sh` only when a skill folder, prompt file, or reference file was added, renamed, or removed
4. Commit with `evolve: consolidate <topic> into references/<file>`.
5. Push the branch.
6. Open one PR in `OktayCopurlu/ai-shared` with required sections:
   - **What overlaps** — specific files + line ranges + percentage estimate
   - **Why this isn't intentional duplication** — explicitly refute each of the 5 "skip if" cases in Guardrail 2
   - **What stays untouched** — explicit list of similar-looking files/skills that you considered but kept
   - **Refactor summary** — old shape → new shape
   - **Rollback plan** — confirm single-revert reversibility
   - **Confidence rationale** — why ≥ 0.9
   - **Agent-general-knowledge notes** — if any in-scope content looked like things agents already know, list it here (informational; not removed in this PR)

If no candidate is strong enough, do not edit files, commit, push, or open a PR.

## Run Log

Your final write action must be one JSON line appended to `SELF_EVOLUTION_RUN_LOG_PATH`.

Format:

```json
{"run_id":"YYYYMMDD-HHMMSS","date":"YYYY-MM-DD","focus":"skill-duplication-audit","files_scanned":42,"clusters_found":7,"findings":[{"title":"...","overlap_pct":75,"files":["skills/x/SKILL.md","prompts/y.prompt.md"],"confidence":0.92,"action":"pr_opened|logged|discarded","pr":"#N or null","reason":"..."}],"agent_general_knowledge_notes":[{"file":"references/x.md","passage_hint":"first 80 chars","why":"reads like generic framework default"}],"prs_opened":0}
```

Rules:
- append exactly one line
- `prs_opened` must be `0` or `1`
- include empty arrays when no findings were detected
- always include `agent_general_knowledge_notes` (may be empty) so trends become visible over runs
- if blocked (auth, API limits, repo state), log one finding with `action: "logged"` and `reason: "<blocker>"` and exit

Do not end the run without writing the run log.
