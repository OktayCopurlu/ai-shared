---
# Experiment step 1/3 — Read Jira, produce an AC list, hand off to step 2.
#
# A minimal 3-stage dispatch-chain to validate: per-stage agent + artifact state passing +
# dispatch hand-off, using the SAME mechanisms as the real delivery pipeline, but self-contained
# (no runtime-imports, no Figma, no code changes). Run THIS one; it chains 1 -> 2 -> 3 itself.
#
# Secrets needed in this repo: COPILOT_GITHUB_TOKEN, JIRA_API_TOKEN, JIRA_USER_EMAIL.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. DSC-2307)"
        required: true
        type: string

engine:
  id: copilot
  model: claude-sonnet-4.6

permissions:
  contents: read
  actions: read

network:
  allowed:
    - defaults
    - "onrunning.atlassian.net"

# Pre-step: fetch the Jira ticket with the credential (agent stays read-only) -> jira-in/ticket.json.
steps:
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
      if [ -z "${JIRA_USER_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
        echo "Jira secrets not set; agent will report a blocker."
        exit 0
      fi
      key="$(printf '%s' "$TICKET_INPUT" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || true)"
      if [ -z "$key" ]; then echo "No Jira key in '$TICKET_INPUT'."; exit 0; fi
      if curl -fsS -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json" \
           "$JIRA_BASE_URL/rest/api/2/issue/$key?fields=summary,description,status,comment,issuetype,labels" \
           -o jira-in/ticket.json; then
        echo "Pre-fetched Jira issue $key ($(wc -c < jira-in/ticket.json) bytes)."
      else
        echo "Could not fetch Jira issue $key."; rm -f jira-in/ticket.json
      fi

safe-outputs:
  upload-artifact:
    retention-days: 7
    max-uploads: 1
  dispatch-workflow: [exp-step-2-plan]

tools:
  bash: [":*"]
  edit:

timeout-minutes: 15
---

# Experiment — Step 1 of 3: Read Jira → Acceptance-Criteria list

You are step 1 of a 3-stage experiment chain. Do only this step, then hand off to step 2.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (pass as `prev_run_id` to step 2): `${{ github.run_id }}`

Do exactly this:

1. **Read the ticket.** A pre-step fetched it to `jira-in/ticket.json` (standard Jira REST v2
   JSON). Read `.fields.summary`, `.fields.description`, and `.fields.status.name`. You hold no
   Jira token, so do not curl Jira yourself. If the file is missing/empty, write a one-line
   blocker into `.exp/ac-list.md` instead and still continue.
2. **Produce an acceptance-criteria list.** Create the directory `.exp/` and write
   `.exp/ac-list.md`: the ticket key + summary on the first line, then a numbered list of
   acceptance criteria with stable IDs (`AC-1`, `AC-2`, …). Derive them from the description;
   if the ticket has no explicit ACs, infer 2–4 reasonable ones from the summary. Keep it short.
3. **Snapshot state.** Run `tar -czf exp-state.tgz .exp`, then emit the `upload-artifact` safe
   output for `exp-state.tgz`.
4. **Hand off.** Emit the `dispatch-workflow` safe output for **`exp-step-2-plan`**, passing
   inputs: `ticket` = the ticket above, `prev_run_id` = `${{ github.run_id }}`.

Take no other action. Do not write code or open PRs.
