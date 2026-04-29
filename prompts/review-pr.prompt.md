---
description: "Full PR review: read the Jira ticket, check AC coverage against the diff, run code review, and validate behavior in the preview environment."
---

# PR Review

End-to-end PR review — from Jira requirements through code quality to functional validation.

## Inputs

The user provides:

- PR URL or PR number
- Repository name (if not obvious from context)

## Steps

### 1. Context Gathering

Collect all inputs before reviewing anything.

1. Read the PR description, diff, and linked issues via the `github-mcp` skill.
2. Extract the Jira ticket ID from the PR title, description, or branch name. Read the full ticket via the `atlassian-mcp` skill — summary, description, acceptance criteria, and links. **If no ticket ID is found**, use the PR description and any linked wiki pages as the requirement source instead — still run step 2 against those requirements. Only mark AC coverage as "unavailable" if there are truly no requirements anywhere (no ticket, no PR description requirements, no wiki pages).
3. If the ticket or PR links to Confluence wiki pages (tracking specs, solution designs, etc.), read them via `atlassian-mcp`. Extract relevant requirements.
4. Find the preview environment URL: check PR deployment status, status checks, and PR comments (in that order). If multiple deployments exist, prefer the one matching the PR's head branch.
5. Get the diff size (`gh pr diff <N> --stat | tail -1`) to scale review depth.

**Present before continuing:**
- Ticket AC list (numbered), or "unavailable — no linked ticket"
- Additional requirements from wiki pages or other links in the ticket (tracking events, A/B variants, etc.)
- Preview environment URL, or "not found"
- Diff size and chosen review depth

### 2. AC Coverage Check

Map every acceptance criterion to evidence in the PR diff.

For each AC:
1. Identify which files/changes address it.
2. Mark as **covered**, **partially covered** (explain gap), or **not covered**.

For wiki-sourced requirements (e.g., tracking specs):
1. List each expected event with its required properties.
2. Find the implementation in the diff.
3. Compare event names, property names, and values against the spec.

Output as a table:

| # | Acceptance Criterion | Status | Evidence |
|---|---|---|---|
| 1 | When X, Y happens | ✅ Covered | `file.ts:L42` — implements X logic |
| 2 | When A, B is shown | ⚠️ Partial | `comp.vue:L88` — A handled, B missing |
| 3 | Event fires on click | ❌ Not covered | No tracking call in diff |

### 3. Code Review

Load the `reviewing-code` skill and run it on the PR diff.

- Use `review-only` mode.
- Scale depth based on diff size from step 1.
- All 4 layers: surface correctness, test coverage gaps, bounded refactors, architecture signals.

### 4. Functional Validation

Before starting: check the PR's CI status checks.
- **Checks passing**: proceed with full validation.
- **Checks failing but preview is reachable**: skip full UI validation (per `validating-ui` quality-gate rule). Only do an optional smoke check — verify the page loads and the changed area renders. Report as "smoke only — CI checks failing".
- **No preview URL found**: skip this step entirely.

Always state what was validated, what was skipped, and why.

#### UI validation

Load the `validating-ui` skill and run its checklist on the preview environment.

If the PR visibly affects UI (component changes, layout, styling), also load the `a11y-audit` skill for an accessibility pass on the changed areas.

#### Tracking validation

When the ticket involves tracking:

1. Navigate to the relevant page using the `playwright-mcp` skill.
2. Trigger user actions that should fire tracking events.
3. Inspect **console logs** and **network requests** to verify:
   - Event names match the spec.
   - Event properties/payload match expected values.
   - Events fire on the correct action (click, page view, impression, etc.).
   - Events do NOT fire when they shouldn't (wrong variant, wrong page).
4. Use `browser_console_messages` or `browser_network_requests` from `playwright-mcp` for deeper network inspection.

#### A/B variant validation

When the ticket involves A/B testing:

1. Verify the **control** variant renders correctly (default behavior).
2. Verify the **treatment** variant renders the new behavior.
3. Verify tracking events include the correct variant/group property.

To switch variants: check for a **URL parameter**, **cookie**, or **localStorage** override first — these are automatable. The "AB Flag Override" Chrome extension UI is not accessible to browser automation tools. If only the extension can switch variants, ask the user to switch manually, then continue validation after confirmation.

## Output Format

```
## PR Review — [PR title or ticket ID]

### Context
- Ticket: [ID] — [summary]
- Wiki refs: [list or "none"]
- Preview: [URL or "not available"]
- Diff size: [X lines — depth chosen]

### AC Coverage
[Table from step 2]

**Uncovered items:** [list or "none"]

### Code Review
[Output from reviewing-code]

### Functional Validation
[Output from validating-ui or "Skipped — reason"]

#### Tracking
[Event-by-event results or "N/A"]

#### A/B Variants
[Variant-by-variant results or "N/A"]

### Verdict: Pass | Pass with notes | Fail
[Summary of blocking issues, if any]
```

## Guardrails

- Do not skip the wiki page if one is linked — it often contains the detailed spec that the AC only summarizes.
- Do not claim "all ACs covered" without file/line evidence per AC.
- Do not silently skip functional validation — state what was not verified and why.
- Do not claim "events fire correctly" without showing payload evidence from console or network.
- When the preview is not available, still complete steps 1–3 and note step 4 as skipped.
