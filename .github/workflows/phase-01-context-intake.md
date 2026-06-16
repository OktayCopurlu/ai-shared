---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 1 of 11 (Context Intake).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
#
# This is the FIRST phase in a per-phase dispatch chain. Each phase is its own workflow =
# its own run = its own fresh agent context. A phase does one phase's work, snapshots state
# into the pipeline-state.tgz artifact, then dispatches the next phase. See shared-preamble.md.
#
# Chain: 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08(opens PR) -> 09 -> 10 -> 11
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-1234)"
        required: true
        type: string
      prev_run_id:
        description: "Run ID of the previous phase to download state from (empty for phase 1)"
        required: false
        type: string
        default: ""
      loop_count:
        description: "Fix-loop counter (0 on the first build pass)"
        required: false
        type: string
        default: "0"

# Org-wide token is already provisioned, so the Copilot engine needs no extra secret.
engine:
  id: copilot
  model: gemini-3.1-pro-preview

# Keep exploratory phases from growing unbounded contexts. Override only when a
# ticket proves this ceiling is too small for a specific phase.
max-runs: 80
max-effective-tokens: 5M

# The agent runs read-only. All writes happen through safe-outputs, never the agent itself.
# `actions: read` lets the agent download the previous phase's pipeline-state.tgz artifact.
permissions:
  contents: read
  pull-requests: read
  issues: read
  actions: read

# Scope outbound network. `defaults` covers infra + GitHub. Add ticket/design/preview
# hosts the early phases need (Jira, Figma, preview env) as explicit domains.
network:
  allowed:
    - defaults
    # - "*.atlassian.net"
    # - "api.figma.com"
    # - "www.figma.com"
    # - "<your-preview-host>"

# This phase carries state forward (pipeline-state.tgz) and hands off to phase 2.
safe-outputs:
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-02-plan]
  # noop / missing-tool / missing-data are auto-enabled; the body instructs the agent to use them.

# MCP servers the early phases rely on. Uncomment and add the matching CI secrets.
# AUTH IN CI: local MCP auth is interactive OAuth (a browser opens). CI has no browser, so
# every server here must use a NON-interactive, token-based secret. See README "Auth in CI".
# mcp-servers:
#   figma:
#     url: "https://mcp.figma.com/mcp"
#     headers:
#       Authorization: "Bearer ${{ secrets.FIGMA_MCP_TOKEN }}"

# Pre-step (runs BEFORE the read-only agent, on the runner host with full network): fetch the
# Jira ticket with the credential and write jira-in/ticket.json so the agent can READ the ticket
# without ever holding the token. jira-in/ is run-local scratch (not tarred, never committed),
# the read-side mirror of the jira-out/ write path. Skips quietly if the Jira secrets are unset.
steps:
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

  - name: Pre-fetch the Jira ticket for the agent to read
    if: ${{ inputs.ticket != '' }}
    env:
      JIRA_BASE_URL: ${{ vars.JIRA_BASE_URL }}
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
        jq -r --arg key "$key" '
          def text: if type == "string" then . else tostring end;
          [
            "# Jira Ticket Summary",
            "",
            "- Key: " + (.key // $key),
            "- Summary: " + (.fields.summary // ""),
            "- Status: " + (.fields.status.name // ""),
            "- Issue type: " + (.fields.issuetype.name // ""),
            "- Priority: " + (.fields.priority.name // ""),
            "",
            "## Description",
            ((.fields.description // "") | text),
            "",
            "## Recent comments",
            ((.fields.comment.comments // []) | .[-5:] | map("- " + ((.author.displayName // "unknown") + ": " + (((.body // "") | text) | gsub("\r"; "") | gsub("\n+"; " ")))) | join("\n"))
          ] | join("\n")
        ' jira-in/ticket.json > jira-in/ticket-summary.md
        jq -r '.. | strings | scan("https?://[^[:space:]<>)\\\"]+")' jira-in/ticket.json | sort -u > jira-in/linked-urls.txt
        echo "Wrote compact ticket summary and linked URL index for the agent."
      else
        echo "Could not fetch Jira issue $key (check token/email/permissions); the agent will report a blocker."
        rm -f jira-in/ticket.json
      fi

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
  # `:*` is required so phases can run repo build/test/lint commands and the git/gh state
  # plumbing (download artifact, git apply, tar). Narrow to an explicit allowlist if fixed.
  bash: [":*"]
  edit:
  web-fetch:
  github:
    toolsets: [repos, issues, pull_requests]

timeout-minutes: 60
---

# Phase 1 of 11 — Context Intake (gh-aw dispatch chain)

You are the **Context Intake** agent, the first phase of an 11-phase delivery chain. You run
in your own workflow with a fresh context. Do **only** this phase's work, then hand off to
phase 2.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}` (empty on the first run)
- Fix-loop counter: `${{ inputs.loop_count }}`

## State in / state out

Follow the artifact state contract in the imported `shared-preamble.md`:

1. **Restore (only if `prev_run_id` above is non-empty):** download and extract
   `pipeline-state.tgz` from that run, then `git apply .pipeline/workspace.patch` if present.
   On the very first run there is no prior state — create a fresh `.pipeline/` directory.
2. Do this phase's work and write `.pipeline/verdicts/01-context-intake.json`.
3. **Snapshot:** `git add -A && git diff --staged > .pipeline/workspace.patch`, then
   `tar -czf pipeline-state.tgz .pipeline`, and emit the `upload-artifact` safe output for it.

## Hand-off

- On `status: "pass"`, emit the `dispatch-workflow` safe output for **`phase-02-plan`**, passing
  inputs: `ticket` = the ticket above, `prev_run_id` = `${{ github.run_id }}`, `loop_count` = `0`.
- On `status: "blocked"`, do **not** dispatch. Report the blocker with `missing-data` (and
  `add-comment`/`create-issue` if useful) and call `noop` with a short reason.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import phases/01-context-intake.md}}
