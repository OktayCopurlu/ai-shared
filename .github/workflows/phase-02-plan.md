---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 2 of 11 (Implementation Planning).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
# Chain: 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08(opens PR) -> 09 -> 10 -> 11
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
        description: "Fix-loop counter"
        required: false
        type: string
        default: "0"

engine:
  id: copilot
  model: claude-opus-4.8?effort=high

max-runs: 80
max-effective-tokens: 15M

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
  dispatch-workflow: [phase-03-implement]

# mcp-servers: see phase-01 and README "Auth in CI".

post-steps:
  - name: Checkout ai-shared (base repo)
    uses: actions/checkout@v4
    with:
      persist-credentials: false
  - name: Checkout on-frontend repository (POC)
    uses: actions/checkout@v4
    with:
      repository: 'onrunning/on-frontend'
      token: ${{ secrets.ON_FRONTEND_PAT }}
      path: 'on-frontend-workspace'
      persist-credentials: false
  - name: Download previous phase state
    if: ${{ inputs.prev_run_id != '' }}
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      PREV_RUN_ID: ${{ inputs.prev_run_id }}
    run: |
      gh run download "$PREV_RUN_ID" -n safe-outputs-upload-artifacts --dir . || true
      if [ -f pipeline-state.tgz.zip ]; then
        unzip -o pipeline-state.tgz.zip
      fi
      if [ -f pipeline-state.tgz ]; then
        tar -xzf pipeline-state.tgz
      fi

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

timeout-minutes: 60
---

# Phase 2 of 11 — Implementation Planning (gh-aw dispatch chain)

You are the **Implementation Planning** agent. You run in your own workflow with a fresh
context. Do **only** this phase's work, then hand off to phase 3.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`
- Fix-loop counter: `${{ inputs.loop_count }}`

## State in / state out

Follow the artifact state contract in the imported `shared-preamble.md`:

1. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id`, then
   `git apply .pipeline/workspace.patch` if present.
2. Do this phase's work and write `.pipeline/verdicts/02-plan.json`.
3. **Snapshot:** refresh `.pipeline/workspace.patch`, `tar -czf pipeline-state.tgz .pipeline`,
   and emit `upload-artifact`.

## Hand-off

- On `status: "pass"`, emit `dispatch-workflow` for **`phase-03-implement`**, passing `ticket`,
  `prev_run_id` = `${{ github.run_id }}`, `loop_count` = `${{ inputs.loop_count }}`.
- On `status: "blocked"`, do not dispatch. Surface the blocker and call `noop`.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import phases/02-plan.md}}
