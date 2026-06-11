---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 10 of 11 (QA on PR).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
# Secrets to create first: FIGMA_MCP_TOKEN, JIRA_API_TOKEN, JIRA_USER_EMAIL (see README.md).
# Chain: ... 09 -> 10 -> 11
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-1234)"
        required: true
        type: string
      pr_number:
        description: "PR number to QA (empty: resolve from the [delivery] <ticket> title)"
        required: false
        type: string
        default: ""
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

# PR QA: post findings as a comment on the PR, then advance to PR UI validation.
safe-outputs:
  add-comment:
    target: "*"
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-11-pr-ui-validation]

# mcp-servers: see phase-01 and README "Auth in CI".

# Pre-step (runs BEFORE the read-only agent, on the runner host with full network): fetch the
# Jira ticket with the credential and write jira-in/ticket.json so the agent can READ the ticket
# without ever holding the token. jira-in/ is run-local scratch (not tarred, never committed),
# the read-side mirror of the jira-out/ write path. Skips quietly if the Jira secrets are unset.
steps:

  - name: Checkout on-frontend repository (POC)
    uses: actions/checkout@v4
    with:
      repository: 'onrunning/on-frontend'
      token: ${{ secrets.ON_FRONTEND_PAT }}
      path: 'on-frontend-workspace'
      persist-credentials: false
  - name: Pre-fetch the Jira ticket for the agent to read
    if: ${{ inputs.ticket != '' }}
    env:
      JIRA_BASE_URL: https://onrunning.atlassian.net
      JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
      TICKET_INPUT: ${{ inputs.ticket }}
    run: |
      set -euo pipefail
      mkdir -p jira-in
      if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_USER_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
        echo "Jira not configured (need JIRA_BASE_URL + JIRA_USER_EMAIL + JIRA_API_TOKEN); the agent will use other context or report a blocker."
        exit 0
      fi
      key="$(printf '%s' "$TICKET_INPUT" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || true)"
      if [ -z "$key" ]; then
        echo "No Jira key found in input '$TICKET_INPUT'; skipping pre-fetch."
        exit 0
      fi
      fields="summary,description,status,issuetype,priority,labels,components,fixVersions,parent,assignee,reporter,issuelinks,subtasks,attachment,comment"
      if curl -fsS -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json" \
           "$JIRA_BASE_URL/rest/api/2/issue/$key?fields=$fields" -o jira-in/ticket.json; then
        echo "Pre-fetched Jira issue $key to jira-in/ticket.json ($(wc -c < jira-in/ticket.json) bytes)."
      else
        echo "Could not fetch Jira issue $key (check token/email/permissions); the agent will report a blocker."
        rm -f jira-in/ticket.json
      fi

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

# Phase 10 of 11 — QA on PR (gh-aw dispatch chain)

You are the **PR QA** agent. You run in your own workflow with a fresh context. Functionally
QA the live pull request against the acceptance criteria, then hand off to PR UI validation.

- Ticket: `${{ inputs.ticket }}`
- PR number (may be empty — resolve it): `${{ inputs.pr_number }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`

## Resolve the PR

1. If `pr_number` above is empty, resolve it:
   `gh pr list --state open --search "[delivery] ${{ inputs.ticket }} in:title" --json number,title,headRefName`
   and pick the newest matching open PR. If none is found, write a `blocked` verdict, report it
   with `missing-data`, and call `noop`.

## State + work

Follow the artifact state contract in the imported `shared-preamble.md`:

2. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id` for verdict history.
   Read the PR (diff, files, checks) with the `github` tools.
3. QA the change against the acceptance criteria. Write `.pipeline/verdicts/10-pr-qa.json`,
   refresh `.pipeline/workspace.patch`, `tar -czf pipeline-state.tgz .pipeline`, and emit
   `upload-artifact`.

## Post findings + hand-off

4. Post your QA summary on the PR with `add-comment` (include the resolved PR number). State a
   clear pass/blocking verdict with evidence. Never post secrets or preview credentials.
5. Emit `dispatch-workflow` for **`phase-11-pr-ui-validation`**, passing `ticket`, the resolved
   `pr_number`, `prev_run_id` = `${{ github.run_id }}`, `loop_count` = `${{ inputs.loop_count }}`.

{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/shared-preamble.md@main}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/10-pr-qa.md@main}}
