---
name: release-watch
description: "Track release notes, changelogs, deprecations, and breaking changes across developer platforms and tools. USE FOR: 'what changed in X?', 'any breaking changes in Y?', 'check the changelog for Z', 'are there deprecations I should know about?', 'what's new in Vue/Nuxt/TypeScript/Node/Nx?', 'should I upgrade?'. ALWAYS use when asked about specific version changes, upgrade risks, or deprecation status."
disable-model-invocation: true
---

# Release Watch Skill

Use this skill when the user asks:
- what changed in X recently?
- any breaking changes in Y?
- should I upgrade to this version?
- any deprecations I should know about?
- what are the migration risks?

---

## Workflow

1. Identify the subject: product name and, if given, version range.
2. Find the canonical changelog / release notes URL from the shared policy **Tier 1A and Tier 1B** source registry.
   - For platform vendors (GitHub, OpenAI, Anthropic, Vercel…): use Tier 1A
   - For frontend/tooling (Vue, Nuxt, TS, Vite, Vitest, ESLint, Nx…): use Tier 1B
   - If the subject is not listed, check `github.com/<org>/<repo>/releases` first, then the project's official docs.
3. Read the delta since the last known version or the configured time window (30 days default).
4. Classify each change using the severity matrix below.
5. Run each breaking change through the migration risk checklist.
6. Apply the upgrade recommendation thresholds.
7. Render the output.

---

## Breaking-change severity matrix

| Severity | Criteria |
|---|---|
| Critical | API removed or renamed, data schema change, security patch, auth / session behavior change |
| High | Behavioral change that requires a code change to maintain current functionality |
| Medium | Deprecation warning added, opt-in behavior becomes the default |
| Low | Documentation change, performance improvement, non-breaking API addition |
| Informational | New feature with no migration required |

---

## Migration risk checklist

For each breaking change, verify:
- [ ] Does it affect our codebase (Vue / Nuxt / TS / Nx / Apollo / Node) directly?
- [ ] Is an automated codemod available?
- [ ] Is a migration guide published at the official source?
- [ ] Is there a compatibility layer or grace period before the old behavior is removed?
- [ ] What is the rollback plan if the upgrade fails?
- [ ] What is the urgency: security patch, end-of-support deadline, or deprecation timeline?

---

## Upgrade recommendation thresholds

| Condition | Recommendation |
|---|---|
| Security patch | Upgrade immediately |
| Breaking change affecting our code, no codemod | Plan a migration sprint |
| Breaking change with codemod available | Upgrade next sprint |
| Feature release, no breaking changes | Upgrade opportunistically |
| Major version with extensive breaking changes | Create a spike ticket first |
| No meaningful changes in the version range | No action needed |

---

## Output format

# Release Watch

Date: <YYYY-MM-DD>
Subject: <product and version range>
Time window: <N days or "version X to version Y">

## Summary
One paragraph describing the overall scope and risk level of the changes.

## Breaking changes
List each breaking change separately:

- **Product + version**
- Change type: <severity level>
- What changed: <specific description>
- Impact on our code: Yes / No / Unknown — explain briefly
- Migration path: <codemod available? manual steps? guide URL?>
- Urgency: Critical / High / Medium / Low
- Confidence: High / Medium / Low

## Deprecations
Separate list. Include the planned removal version or timeline if known.

## Migrations to consider
Structured checklist: one row per affected area with owner-ready action items.

## New features (non-breaking)
Brief list only. No deep analysis unless relevant to something actively in progress.

## Upgrade recommendation
Final verdict per product:
- Upgrade now
- Plan for next sprint
- Create spike first
- No action needed

## Noisy items
Updates checked but not worth acting on. One-line reason each.
