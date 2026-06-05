---
# Source workflow for GitHub Agentic Workflows (gh-aw) — Phase 8 of 11 (Create PR).
# READY TO COPY into onrunning/on-frontend/.github/workflows/. Then run: gh aw compile
# Secrets to create first: FIGMA_MCP_TOKEN, JIRA_API_TOKEN, JIRA_USER_EMAIL (see README.md).
#
# Phase 8 is the hinge: it turns the accumulated working-tree changes into a real PR, then
# dispatches the PR-review chain (phases 9-11) that operate on the *live* PR.
# Chain: ... 07 -> 08(opens PR) -> 09 -> 10 -> 11
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
      dry_run:
        description: "Preview only — do not open a PR or dispatch the review chain"
        required: false
        type: boolean
        default: true

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

# Phase 8 opens the PR (create-pull-request) and dispatches the first PR-review phase.
safe-outputs:
  create-pull-request:
    draft: true
    title-prefix: "[delivery] "
  upload-artifact:
    retention-days: 14
    max-uploads: 1
  dispatch-workflow: [phase-09-pr-code-review]

# mcp-servers: see phase-01 and README "Auth in CI".

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

# Phase 8 of 11 — Create PR (gh-aw dispatch chain)

You are the **PR Creation** agent. You run in your own workflow with a fresh context. Turn the
accumulated changes into a draft pull request, then hand off to the PR-review chain.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (`RUN_ID`, pass as `prev_run_id` to the next phase): `${{ github.run_id }}`
- Previous run ID to restore state from: `${{ inputs.prev_run_id }}`
- Fix-loop counter: `${{ inputs.loop_count }}`
- Dry run: `${{ inputs.dry_run }}`

## State in

1. **Restore:** download and extract `pipeline-state.tgz` from `prev_run_id`, then
   `git apply .pipeline/workspace.patch` so the working tree holds every accumulated change.
2. **Keep `.pipeline/` out of the PR:** the PR must contain only real product changes. Add
   `.pipeline/` and `pipeline-state.tgz` to `.git/info/exclude` (or `.gitignore`) before the
   PR commit so pipeline bookkeeping is never committed to the PR branch.

## Open the PR

3. Read the verdicts under `.pipeline/verdicts/` and write the PR title and body into
   `.pipeline/pr/` and a verdict `.pipeline/verdicts/08-create-pr.json`. The title must include
   the ticket (the `[delivery] ` prefix is added automatically); the body must summarize the
   change, the acceptance criteria, and the validation evidence (no secrets, no preview creds).
4. **If `dry_run` is `true`:** do NOT emit `create-pull-request` and do NOT dispatch phase 9.
   Snapshot state (below), then call `noop` with a summary of the staged PR.
5. **If `dry_run` is `false`:** emit the `create-pull-request` safe output. It opens the PR
   after you finish (you do not push or call `gh pr create`).

## State out + hand-off

6. **Snapshot:** `git add -A && git diff --staged > .pipeline/workspace.patch` (this captures
   only `.pipeline/` if product files are already on the PR branch), `tar -czf pipeline-state.tgz
   .pipeline`, and emit `upload-artifact`.
7. **Hand-off (only when `dry_run` is `false`):** emit `dispatch-workflow` for
   **`phase-09-pr-code-review`**, passing `ticket`, `prev_run_id` = `${{ github.run_id }}`,
   `loop_count` = `${{ inputs.loop_count }}`. The PR number is not known yet at dispatch time
   (the PR is opened by the safe-outputs job afterwards), so phase 9 resolves it by searching
   open PRs whose title starts with `[delivery] ` and contains the ticket.

{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/shared-preamble.md@main}}

## Phase work
{{#runtime-import OktayCopurlu/ai-shared/experiment/github-delivery-pipeline/phases/08-create-pr.md@main}}
