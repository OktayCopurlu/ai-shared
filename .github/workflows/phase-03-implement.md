---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 3 of 11 (Implementation).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
# Chain: 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08(opens PR) -> 09 -> 10 -> 11
# Phase 3 is also the fix-loop landing spot: validators (04-07) dispatch back here on fail.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-1234)"
        required: true
        type: string
      prev_run_id:
        description: "Run ID of the previous phase to download state from"
        required: false
        type: string
        default: ""
      loop_count:
        description: "Fix-loop counter (incremented each time a validator sends work back here)"
        required: false
        type: string
        default: "0"

engine: copilot

permissions:
  contents: read
  pull-requests: read
  issues: read
  actions: read

network:
  allowed:
    - defaults
    # - "*.atlassian.net"
    # - "api.figma.com"
    # - "www.figma.com"
    # - "<your-preview-host>"

safe-outputs:
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-04-test-review]

# mcp-servers: see phase-01 and README "Auth in CI".

post-steps:

  - name: Checkout on-frontend repository (POC)
    uses: actions/checkout@v4
    with:
      repository: 'onrunning/on-frontend'
      token: ${{ secrets.ON_FRONTEND_PAT }}
      path: 'on-frontend-workspace'
      persist-credentials: false
  - name: Comment on the Jira ticket if this phase wrote one
    if: ${{ !cancelled() && hashFiles('jira-out/comment.md') != '' }}
    env:
      JIRA_BASE_URL: ${{ vars.JIRA_BASE_URL }}
      JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
      TICKET_INPUT: ${{ inputs.ticket }}
    run: |
      set -euo pipefail
      if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_USER_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
        echo "Jira not configured (need JIRA_BASE_URL + JIRA_USER_EMAIL + JIRA_API_TOKEN); skipping comment."
        exit 0
      fi
      key="$(cat .pipeline/jira/issue-key.txt 2>/dev/null || true)"
      [ -n "$key" ] || key="$TICKET_INPUT"
      key="$(printf '%s' "$key" | tr -d '[:space:]')"
      body="$(jq -Rs . < jira-out/comment.md)"
      curl -fsS -X POST \
        -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"body\": $body}" \
        "$JIRA_BASE_URL/rest/api/2/issue/$key/comment" >/dev/null
      echo "Posted a comment to Jira issue $key."

tools:
  bash: [":*"]
  edit:
  web-fetch:
  github:
    toolsets: [repos, issues, pull_requests]
  playwright:

timeout-minutes: 60
---

# Phase 3 of 11 — Implementation (gh-aw dispatch chain)

You are the **Implementer/Fixer** agent. You run in your own workflow with a fresh context.
Write product code to satisfy the plan and any open fix requests, then hand off to phase 4.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`
- Fix-loop counter: `${{ inputs.loop_count }}`

## State in / state out

Follow the artifact state contract in the imported `shared-preamble.md`:

1. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id`, then
   `git apply .pipeline/workspace.patch` so your working tree has all prior code changes.
2. Read the plan under `.pipeline/implementation-plan/` and any open requests under
   `.pipeline/fix-requests/`. Write/modify product code to address them. Do NOT open a PR —
   phase 8 does that. Write `.pipeline/verdicts/03-implement.json`.
3. **Snapshot:** `git add -A && git diff --staged > .pipeline/workspace.patch`,
   `tar -czf pipeline-state.tgz .pipeline`, and emit `upload-artifact`.

## Hand-off

- When changes are staged and the patch is refreshed, emit `dispatch-workflow` for
  **`phase-04-test-review`**, passing `ticket`, `prev_run_id` = `${{ github.run_id }}`,
  `loop_count` = `${{ inputs.loop_count }}` (carry the counter forward unchanged).
- On `status: "blocked"`, do not dispatch. Surface the blocker and call `noop`.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import phases/03-implement.md}}
