# Research Digest Mode

Use this mode for:
- **weekly-digest**: broad ecosystem sweep across all tracked vendors (7-day window)
- **company-watch**: focused depth on one or more specific vendors (14-day window)

---

## Variants

### weekly-digest
Sweep all vendors in the shared source registry Tier 1 and Tier 2.
Aim for 3-7 high-scoring findings. Prefer signal over volume.

### company-watch
Narrow to the vendor(s) the user specified. Go deeper across multiple source types for that vendor. Still apply the shared rubric and stop at 7 top findings.

---

## Workflow

1. Confirm variant (weekly-digest or company-watch).
2. Set the time window from shared policy (7 or 14 days).
3. Check sources in this order:
   - **weekly-digest**: sweep all Tier 1A vendors first, then sample Tier 1B only if a finding bubbles up from Tier 3 (community signal). Tier 2 only for verification.
   - **company-watch**: go deep on the named vendor(s) — check all Tier 1A + Tier 1B sources for that vendor, plus their GitHub Releases page (Tier 2), plus any Tier 3 community discussion about them.
4. For each candidate, apply the scoring rubric from `self-evolution/policy.md`.
   - Score >= 8: top finding
   - Score 5-7: watchlist
   - Score < 5: ignore
5. Skip duplicates: check `SELF_EVOLUTION_HISTORY_PATH` for same title + same status when running under self-evolution.
6. Stop when 7 top findings are reached or all Tier 1 sources are exhausted.

---

## Execution contract

This mode is internal to the scheduled research job. Do not spend tokens on a polished digest unless a human explicitly asks for one.

Produce only:
- the 1 best PR-worthy candidate, if one exists
- a short watchlist of strong non-PR candidates
- concise reasons for ignored high-noise items

Keep notes compact. For each kept candidate, capture only:
- title
- canonical source URL
- status
- 1-2 sentence why-it-matters summary
- score / action (`pr_opened`, `logged`, or `ignore`)

Final action:
- if a PR-worthy candidate exists, use the notes to open exactly one PR
- otherwise append the run-log and exit without generating a human-facing digest

---

## Resources
- Shared policy (source registry, rubric, dedupe): `self-evolution/policy.md`
