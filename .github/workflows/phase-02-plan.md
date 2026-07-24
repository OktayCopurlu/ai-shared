---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 2 of 11 (Implementation Planning).
# Self-delivery pipeline: runs in and targets this repository. Then run: gh aw compile
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
        required: true
        type: string
      loop_count:
        description: "Fix-loop counter"
        required: false
        type: string
        default: "0"

engine:
  id: copilot
model: claude-sonnet-5

max-turns: 50
max-ai-credits: 1000

permissions:
  contents: read
  pull-requests: read
  issues: read
  actions: read
  copilot-requests: write

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

pre-steps:
  - name: Checkout workflow helpers
    uses: actions/checkout@v4
    with:
      persist-credentials: false
  - name: Verify and fetch previous phase state
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      PREV_RUN_ID: ${{ inputs.prev_run_id }}
      EXPECTED_PREVIOUS_WORKFLOWS: .github/workflows/phase-01-context-intake.lock.yml
    run: bash .github/scripts/restore-pipeline-state.sh

post-steps:
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
  github:
    toolsets: [default]

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

- On `status: "pass"`, call the exact `phase_03_implement` safe-output tool (never the generic
  `dispatch_workflow` tool), passing `ticket`, `prev_run_id` = `${{ github.run_id }}`,
  `loop_count` = `${{ inputs.loop_count }}`.
- On `status: "blocked"`, do not dispatch. Surface the blocker and call `noop`.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **Self-delivery:** you are running in and targeting this repository.
> Its files are checked out in the working tree at the repository root.
> **Edit the product code in the working tree (repo root); never touch `.github/workflows/` or `*.lock.yml`.**

{{#runtime-import phases/02-plan.md}}
