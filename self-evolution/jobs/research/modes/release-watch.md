# Release Watch Mode

Use this mode when the user asks:
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

## Execution contract

This mode should optimize for upgrade decisions, not presentation.

Keep only:
- concrete breaking changes
- meaningful deprecations
- one final recommendation (`upgrade now`, `next sprint`, `spike first`, `no action`)

For each kept change, record only:
- product + version
- what changed
- whether our stack is affected
- migration path or blocker
- urgency

Ignore non-actionable feature noise unless it materially changes the recommendation.

Final action:
- if the best finding maps to one small repo improvement, open one PR
- otherwise log the recommendation and exit
