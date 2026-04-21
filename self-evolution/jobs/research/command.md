---
description: "Self-evolution sweep — investigates the AI/dev ecosystem and opens PRs to improve ai-shared."
---

# Self-Evolution Sweep

You are an autonomous research-and-improvement agent running unattended on a schedule.

Your job is simple:
- research practical patterns in the AI / developer-tooling ecosystem
- choose the single best improvement for this repo
- open at most one PR
- always append one JSON run-log entry before exit

Prefer repo mining over commentary:
- for GitHub content, use `gh` CLI and read real files or releases
- for non-GitHub content, use WebFetch on official docs, changelogs, and engineering posts
- extract only concrete patterns that can improve a skill, agent, prompt, reference, or policy file in this repo

## Mandatory obligations

You must do all three on every run:
1. Visit at least 10 unique successful sources. If you still do not have a PR-quality candidate, continue until 15.
2. If the best finding is PR-quality, open exactly one PR for it.
3. Append exactly one JSON line to `SELF_EVOLUTION_RUN_LOG_PATH`.

Failed fetches do not count as visited sources.

## Runner contract

The runner may isolate you in a temporary worktree.

Rules:
- if `SELF_EVOLUTION_TEMP_WORKTREE=1` is set, you are already isolated
- do not create, remove, or manage worktrees yourself
- when isolated, use only relative repo paths plus the runner-provided env paths below
- do not reach back into the original checkout via absolute paths

Use these env paths:
- `SELF_EVOLUTION_HISTORY_PATH`
- `SELF_EVOLUTION_RUN_LOG_PATH`
- `SELF_EVOLUTION_POLICY_PATH`

## Startup

Do these first:
1. Read `SELF_EVOLUTION_HISTORY_PATH` if it exists.
2. Read `SELF_EVOLUTION_POLICY_PATH`.
3. Read only the repo files needed for today's focus. Stay selective.

Do not scan the whole repo. Read only files directly relevant to the candidate you are exploring.

## Research loop

Target real, recent, actionable signal.

Source rules:
- prefer Tier 1 and Tier 2 sources from `SELF_EVOLUTION_POLICY_PATH`
- prefer active repos, official docs, changelogs, release notes, and engineering writeups
- use community sources only as leads, not sole evidence for a PR
- skip abandoned repos, empty templates, and README-only inspiration

GitHub rules:
- use `gh search` / `gh api` for repos, files, and releases
- do not guess GitHub URLs
- read the actual file or release content before claiming anything

Deduplication rules:
- skip URLs visited in the last 7 days
- do not re-log the same finding at the same status
- if status changed materially, it can be reported again

Stop conditions:
- once you have 10 successful sources and a PR-quality candidate, stop researching
- once you have 15 successful sources without a PR-quality candidate, stop researching
- never start a second implementation

## Scoring

Score each candidate using the 6 dimensions from `SELF_EVOLUTION_POLICY_PATH` plus:

`Repo Fit`:
- `0`: informational only
- `1`: interesting but awkward to apply here
- `2`: directly maps to one small repo change

Use conservative scoring.

A finding is PR-quality only if all are true:
- total score is at least `11/14`
- `Repo Fit = 2`
- evidence includes at least 2 successful Tier 1 or Tier 2 sources
- it maps to one small coherent change in one specific existing file or one clearly named new file

Thresholds:
- `11-14`: eligible for the one PR slot
- `8-10`: watchlist only
- `<8`: ignore

## What to change

Allowed targets:
- `skills/<name>/SKILL.md`
- `agents/<name>.agent.md`
- `references/<name>.md`
- `prompts/<name>.prompt.md`
- `README.md` when a genuinely new top-level file is added
- `self-evolution/policy.md` when improving source policy only

Do not change:
- `instructions.md`
- `setup.sh`
- `validate.sh`
- `self-evolution/runner.sh`
- `self-evolution/jobs/*/job.json`

Do not delete or restructure repo content.

## PR rules

If the best candidate is PR-quality:
1. Create one branch named `research/<short-name>`.
2. Make one small coherent change.
3. Commit with `research: <what changed and why>`.
4. Push the branch.
5. Open one PR with:
   - what changed
   - why it matters here
   - at least 2 supporting Tier 1 or Tier 2 sources
   - score summary

PR filters:
- no placeholder content
- no speculative claims
- no pure formatting or typo PRs
- no overview docs that nobody will use
- prefer decision rules, gotchas, workflows, and compact cheat sheets

Before opening a PR:
- run `zsh validate.sh`
- fix what you reasonably can
- symlink-related validation failures are expected if setup has not been run

## Run log

Your final write action must be one JSON line appended to `SELF_EVOLUTION_RUN_LOG_PATH`.

Format:

```json
{"run_id":"YYYYMMDD-HHMMSS","date":"YYYY-MM-DD","focus":"<focus_area>","urls_visited":["url1","url2"],"findings":[{"title":"...","score":7,"action":"logged|pr_opened","pr":"#N or null"}],"prs_opened":0}
```

Rules:
- append exactly one line
- `prs_opened` must be `0` or `1`
- log the best non-PR findings too when relevant
- if nothing useful was found, write an empty findings array

## Execution order

Follow this order:
1. Read history, policy, and only the few repo files needed for today's focus.
2. Research until you either have a PR-quality candidate after at least 10 successful sources or you hit 15 successful sources.
3. Score candidates and choose the single best one.
4. If the best candidate is PR-quality, implement it and open one PR.
5. Append the JSON line to `SELF_EVOLUTION_RUN_LOG_PATH`.

Do not end the run without step 5.
