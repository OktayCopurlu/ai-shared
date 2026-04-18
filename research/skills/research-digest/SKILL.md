---
name: research-digest
description: "Produce a high-signal digest of recent developer tooling, AI, platform, and workflow updates. USE FOR: 'give me a weekly digest', 'what new dev tools are worth tracking?', 'any important GitHub/Google/OpenAI/Vercel/MCP updates?', 'what changed in Copilot or VS Code?', 'any useful new agent workflows or skills?'. ALWAYS use when asked for a broad ecosystem sweep or weekly research summary."
disable-model-invocation: true
---

# Research Digest Skill

Use this skill for:
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
4. For each candidate, apply the scoring rubric from `~/.copilot/research/skills/shared/policy.md`.
   - Score >= 8: top finding
   - Score 5-7: watchlist
   - Score < 5: ignore
5. Skip duplicates: check `research-history.md` for same title + same status.
6. Check `watchlist.md` for items whose re-evaluate date has passed; promote if status changed.
7. Stop when 7 top findings are reached or all Tier 1 sources are exhausted.

---

## Output format

# Research Digest

Date: {YYYY-MM-DD}
Mode: weekly-digest | company-watch
Scope: {vendors covered}
Time window: {N days}

## Top findings

### 1. {title}
- Source: {canonical URL}
- Vendor: {vendor}
- Published: {date if available}
- Status: Released | Preview | Beta | Announced | Deprecated | Breaking change | Rumor
- Summary: {2-4 sentences}
- Why it matters: {engineering value}
- Relevance to our stack: {specific call-out: Vue / Nuxt / TS / Nx / Copilot / MCP / GraphQL / Contentful / Amplitude}
- Recommendation: Try this week | Add to watchlist | Ignore for now | Create spike ticket
- Priority: P0 | P1 | P2
- Confidence: High | Medium | Low

### 2. ...

## Watchlist
Items that are promising but not yet actionable. Include a re-evaluate date for each.

## Ignore
Items that were checked but excluded. One-line reason each.

## Recommended next steps
- Try now: <1 item>
- Investigate: <1 item>
- Ignore: <1 item>

---

## Resources
- Shared policy (source registry, rubric, dedupe): [shared/policy.md](../shared/policy.md)
- Source registry: [sources.md](./sources.md)
- Output template: [templates/weekly-digest.md](./templates/weekly-digest.md)
