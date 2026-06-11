---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 11 of 11 (UI Validation on PR).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
# Chain: ... 10 -> 11 (final). No further dispatch; this phase closes out the pipeline.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-1234)"
        required: true
        type: string
      pr_number:
        description: "PR number to validate (empty: resolve from the [delivery] <ticket> title)"
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
    # - "*.atlassian.net"
    # - "api.figma.com"
    # - "www.figma.com"
    # - "<your-preview-host>"

# Final PR validation: post findings as a comment on the PR. No further phase to dispatch.
safe-outputs:
  add-comment:
    target: "*"
  upload-artifact:
    retention-days: 14
    max-uploads: 1

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
  - name: Move the Jira ticket to In Review when the pipeline finished cleanly
    if: ${{ !cancelled() && hashFiles('jira-out/transition.txt') != '' }}
    env:
      JIRA_BASE_URL: ${{ vars.JIRA_BASE_URL }}
      JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
      JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
      TICKET_INPUT: ${{ inputs.ticket }}
    run: |
      set -euo pipefail
      if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_USER_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
        echo "Jira not configured; skipping transition."
        exit 0
      fi
      key="$(cat .pipeline/jira/issue-key.txt 2>/dev/null || true)"
      [ -n "$key" ] || key="$TICKET_INPUT"
      key="$(printf '%s' "$key" | tr -d '[:space:]')"
      target="$(head -n1 jira-out/transition.txt | tr -d '\r' | sed 's/^ *//;s/ *$//')"
      [ -n "$target" ] || target="In Review"
      tid="$(curl -fsS -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
        "$JIRA_BASE_URL/rest/api/2/issue/$key/transitions" \
        | jq -r --arg n "$target" '.transitions[] | select((.name|ascii_downcase)==($n|ascii_downcase)) | .id' | head -n1)"
      if [ -z "$tid" ]; then
        echo "No '$target' transition available for $key from its current status; leaving status unchanged."
        exit 0
      fi
      curl -fsS -X POST \
        -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"transition\": {\"id\": \"$tid\"}}" \
        "$JIRA_BASE_URL/rest/api/2/issue/$key/transitions" >/dev/null
      echo "Transitioned Jira issue $key to '$target'."

tools:
  bash: [":*"]
  edit:
  web-fetch:
  github:
    toolsets: [repos, issues, pull_requests]
  playwright:

timeout-minutes: 60
---

# Phase 11 of 11 — UI Validation on PR (gh-aw dispatch chain)

You are the **PR UI Validation** agent and the final phase of the chain. You run in your own
workflow with a fresh context. Validate the rendered UI of the live pull request against the
acceptance criteria and Figma specs, post the final verdict, and close out the pipeline.

- Ticket: `${{ inputs.ticket }}`
- PR number (may be empty — resolve it): `${{ inputs.pr_number }}`
- This run's ID: `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`

## Resolve the PR

1. If `pr_number` above is empty, resolve it:
   `gh pr list --state open --search "[delivery] ${{ inputs.ticket }} in:title" --json number,title,headRefName`
   and pick the newest matching open PR. If none is found, write a `blocked` verdict, report it
   with `missing-data`, and call `noop`.

## State + work

Follow the artifact state contract in the imported `shared-preamble.md`:

2. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id` for verdict history.
   Read the PR and exercise its preview/UI with the `playwright` and `github` tools.
3. Validate the UI against the acceptance criteria and Figma specs. Write
   `.pipeline/verdicts/11-pr-ui-validation.json`, refresh `.pipeline/workspace.patch`,
   `tar -czf pipeline-state.tgz .pipeline`, and emit `upload-artifact`.

## Post the final verdict

4. Post the final UI-validation summary on the PR with `add-comment` (include the resolved PR
   number). State a clear pass/blocking verdict with screenshots/trace references under
   `.pipeline/` (never embed secrets or preview credentials).
5. This is the last phase — there is no next phase to dispatch. After commenting, you are done.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import phases/11-pr-ui-validation.md}}
