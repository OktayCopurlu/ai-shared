---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 7 of 11 (AC + Figma UI Validation).
# READY TO COPY into onrunning/on-frontend/.github/workflows/. Then run: gh aw compile
# Secrets to create first: FIGMA_MCP_TOKEN, JIRA_API_TOKEN, JIRA_USER_EMAIL (see README.md).
# Chain: ... 06 -> 07 -> 08(opens PR) ... | on fail, dispatches back to phase-03-implement.
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

engine: copilot

permissions:
  contents: read
  pull-requests: read
  issues: read
  actions: read

network:
  allowed:
    - defaults
    - "onrunning.atlassian.net" # Jira REST (secrets.JIRA_API_TOKEN / JIRA_USER_EMAIL)
    - "api.figma.com" # Figma MCP
    - "www.figma.com" # Figma
    - "on.com" # preview base domain
    - "*.on.com" # PR preview host: on-shop-<PR#>.on.com

# Validator: on pass advance to phase 8 (PR creation), on fail send back to the Implementer.
safe-outputs:
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-08-create-pr, phase-03-implement]

# Figma MCP (UI/visual phase). Needs secrets.FIGMA_MCP_TOKEN (a Figma personal access token).
mcp-servers:
  figma:
    url: "https://mcp.figma.com/mcp"
    headers:
      Authorization: "Bearer ${{ secrets.FIGMA_MCP_TOKEN }}"

post-steps:
  - name: Comment on the Jira ticket if this phase wrote one
    if: ${{ !cancelled() && hashFiles('jira-out/comment.md') != '' }}
    env:
      JIRA_BASE_URL: https://onrunning.atlassian.net
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

# Phase 7 of 11 — AC + Figma UI Validation (gh-aw dispatch chain)

You are the **UI Validation** agent. You run in your own workflow with a fresh context.
Validate the rendered UI against the acceptance criteria and Figma specs, then hand off based
on your verdict. Do not patch code yourself — record fix requests.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`
- Fix-loop counter: `${{ inputs.loop_count }}` (max 3 — see `pipeline.json` `max_fix_loops`)

## State in / state out

Follow the artifact state contract in the imported `shared-preamble.md`:

1. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id`, then
   `git apply .pipeline/workspace.patch`.
2. Do this phase's work and write `.pipeline/verdicts/07-ui-validation.json`. On `fail`, also
   write structured requests under `.pipeline/fix-requests/`.
3. **Snapshot:** refresh `.pipeline/workspace.patch`, `tar -czf pipeline-state.tgz .pipeline`,
   and emit `upload-artifact`.

## Hand-off (fix loop)

- On `status: "pass"`: emit `dispatch-workflow` for **`phase-08-create-pr`**, passing `ticket`,
  `prev_run_id` = `${{ github.run_id }}`, `loop_count` = `${{ inputs.loop_count }}`.
- On `status: "fail"`: if `loop_count` < 3, emit `dispatch-workflow` for
  **`phase-03-implement`**, passing `ticket`, `prev_run_id` = `${{ github.run_id }}`, and
  `loop_count` = `${{ inputs.loop_count }}` + 1.
- If `loop_count` is already 3 and blockers remain, do **not** loop: post an `add-comment`
  summary and call `noop`.

{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/shared-preamble.md@main}}

## Phase work
{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/07-ui-validation.md@main}}
