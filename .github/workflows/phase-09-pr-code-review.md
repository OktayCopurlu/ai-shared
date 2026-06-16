---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 9 of 11 (PR Code Review).
# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile
#
# Phases 9-11 review the *live* PR opened in phase 8. They run linearly (no loop back to the
# build); a blocking finding is posted as a requested change on the PR.
# Chain: ... 08(opens PR) -> 09 -> 10 -> 11
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-1234)"
        required: true
        type: string
      pr_number:
        description: "PR number to review (empty: resolve from the [delivery] <ticket> title)"
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

engine:
  id: copilot
  model: gemini-3-flash

max-runs: 80
max-effective-tokens: 5M

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

# PR review: post findings as a comment on the PR, then advance to PR QA.
safe-outputs:
  add-comment:
    target: "*"
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-10-pr-qa]

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
  playwright:
    mode: cli

timeout-minutes: 60
---

# Phase 9 of 11 — PR Code Review (gh-aw dispatch chain)

You are the **PR Code Review** agent. You run in your own workflow with a fresh context.
Review the live pull request opened in phase 8, then hand off to PR QA.

- Ticket: `${{ inputs.ticket }}`
- PR number (may be empty — resolve it): `${{ inputs.pr_number }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`

## Resolve the PR

1. If `pr_number` above is empty, resolve it:
   `gh pr list --state open --search "[delivery] ${{ inputs.ticket }} in:title" --json number,title,headRefName`
   and pick the newest matching open PR. If none is found, write a `blocked` verdict, report it
   with `missing-data`, and call `noop` (do not dispatch).

## State in / state out

Follow the artifact state contract in the imported `shared-preamble.md`:

2. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id` to append to the
   verdict history. The PR itself (its diff, files, checks) is the source of truth here — read
   it with the `github` tools.
3. Review the PR diff against the acceptance criteria and standards. Write
   `.pipeline/verdicts/09-pr-code-review.json`. Refresh `.pipeline/workspace.patch`,
   `tar -czf pipeline-state.tgz .pipeline`, and emit `upload-artifact`.

## Post findings + hand-off

4. Post your review summary on the PR with the `add-comment` safe output (it supports any PR;
   include the resolved PR number in the tool call). State a clear verdict — approve-equivalent
   or specific requested changes with reproduction and AC references. Never post secrets.
5. Emit `dispatch-workflow` for **`phase-10-pr-qa`**, passing `ticket`, the resolved
   `pr_number`, `prev_run_id` = `${{ github.run_id }}`, `loop_count` = `${{ inputs.loop_count }}`.

{{#runtime-import phases/shared-preamble.md}}

## Phase work

> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**

{{#runtime-import phases/09-pr-code-review.md}}
