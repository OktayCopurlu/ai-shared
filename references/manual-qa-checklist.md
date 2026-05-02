# Manual QA Checklist

Use this checklist with the `manual-qa` skill to turn requirements and diffs into executable QA checks.

## Plan Template

```md
# Manual QA Run

- Source: <ticket / PR / local diff>
- Environment: <preview URL / local URL / command path>
- Created: <timestamp>

## Context
- Ticket summary:
- Change summary:
- Feature flags / variants:
- Test data:

## Checks
| ID | Area | Steps | Expected result | Status | Evidence |
|---|---|---|---|---|---|

## Regression
| ID | Changed area | Risk | Check | Status | Evidence |
|---|---|---|---|---|---|

## Not Verified
- <item> - <reason>
```

## Scenario Sources

Build scenarios from both requirements and code changes:

| Source | QA signal |
|---|---|
| Acceptance criteria | Primary happy path and required behavior |
| Ticket description | Edge cases, constraints, and copy/content expectations |
| Linked Figma/spec/wiki | Layout, states, variants, tracking, and product rules |
| PR/local diff | Real implementation surface and regression risk |
| Changed files outside ticket scope | Regression checks even when no AC mentions them |

## Status Values

| Status | Meaning |
|---|---|
| Planned | Written before execution |
| Pass | Executed and matched expected result |
| Fail | Executed and did not match expected result |
| Blocked | Could not execute because of access, environment, data, or tooling |
| Not verified | Intentionally skipped or impossible to verify in the current run |

## Risk Cues

- Shared UI component: check the changed ticket flow and one other consumer.
- Data mapper or GraphQL/API query: check expected shape and one existing consumer path.
- Feature flag or experiment: check enabled and disabled variants when controllable.
- Tracking: check event name, trigger, and payload through browser console logs or network requests.
- Form or checkout: check validation, submit, failure, retry, and disabled/loading states.
- Routing or auth: check allowed and disallowed access paths.
- Localization/content: check missing, long, and fallback content where feasible.
- Styling/layout: check desktop and mobile viewports.
