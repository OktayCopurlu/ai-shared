---
# Figma + Jira READ smoke test (gh-aw).
#
# Goal: prove that a gh-aw Copilot agent can READ both Jira and Figma in CI using the
# exact mechanisms the delivery pipeline uses:
#   - Jira  -> a pre-step (frontmatter `steps:`) fetches the ticket with the credential and
#              writes jira-in/ticket.json; the read-only agent reads that file (never holds the token).
#   - Figma -> the Figma MCP server (bearer FIGMA_MCP_TOKEN); the agent calls Figma MCP tools.
#
# Secrets to create in this repo (Settings -> Secrets and variables -> Actions):
#   COPILOT_GITHUB_TOKEN, FIGMA_MCP_TOKEN, JIRA_API_TOKEN, JIRA_USER_EMAIL
# Then: gh aw compile, push to the default branch, and run this workflow from the Actions tab.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL (e.g. B2C-1234)"
        required: true
        type: string
      figma_url:
        description: "Figma node URL (must include ?node-id=...)"
        required: true
        type: string

engine: copilot

permissions:
  contents: read

# Agent network is sandboxed to these hosts. The pre-step runs on the runner host (outside the
# sandbox) so it reaches Jira regardless; Figma hosts are listed for the agent's MCP calls.
network:
  allowed:
    - defaults
    - "onrunning.atlassian.net"
    - "api.figma.com"
    - "www.figma.com"
    - "mcp.figma.com"

# Figma MCP over a non-interactive bearer token (no OAuth browser in CI).
mcp-servers:
  figma:
    url: "https://mcp.figma.com/mcp"
    headers:
      Authorization: "Bearer ${{ secrets.FIGMA_MCP_TOKEN }}"

# Pre-step: fetch the Jira ticket BEFORE the read-only agent runs, so the agent never holds the
# token. Runs on the runner host with full network. Writes jira-in/ticket.json for the agent.
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
        echo "Jira secrets not set (need JIRA_USER_EMAIL + JIRA_API_TOKEN); agent will report Jira UNREADABLE."
        exit 0
      fi
      key="$(printf '%s' "$TICKET_INPUT" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || true)"
      if [ -z "$key" ]; then
        echo "No Jira key found in input '$TICKET_INPUT'; agent will report Jira UNREADABLE."
        exit 0
      fi
      if curl -fsS -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json" \
           "$JIRA_BASE_URL/rest/api/2/issue/$key?fields=summary,status,description,comment" \
           -o jira-in/ticket.json; then
        echo "Pre-fetched Jira issue $key to jira-in/ticket.json ($(wc -c < jira-in/ticket.json) bytes)."
      else
        echo "Could not fetch Jira issue $key (check token/email/permissions); agent will report Jira UNREADABLE."
        rm -f jira-in/ticket.json
      fi

# The agent writes one small report file and uploads it; it takes no other action.
safe-outputs:
  upload-artifact:
    retention-days: 7
    max-uploads: 1
  noop:

tools:
  bash: [":*"]
  edit:

timeout-minutes: 15
---

# Figma + Jira read smoke test

You are a smoke-test agent. Your only job is to prove you can **read** Jira and Figma in CI.
Do not change any code, do not open PRs, and never print secret values.

- Jira ticket input: `${{ inputs.ticket }}`
- Figma URL input: `${{ inputs.figma_url }}`

Do exactly these four steps:

1. **Jira (via pre-fetched file).** Read `jira-in/ticket.json`. A pre-step already fetched it
   with this repo's Jira credentials (you hold no token, so do not curl Jira yourself). It is
   standard Jira REST v2 JSON. Extract `.key`, `.fields.summary`, and `.fields.status.name`.
   If the file is missing or empty, treat Jira as **UNREADABLE** and note the likely reason
   (secrets unset, wrong email/token, or no permission).

2. **Figma (via MCP).** Use the Figma MCP tools to read the node referenced by the Figma URL
   above (parse the `node-id`). Report the node/frame **name** and its **type**. If the MCP
   call fails or returns nothing, treat Figma as **UNREADABLE** and note the error briefly.

3. **Write the result.** Create `smoke-result.md` with exactly these two lines, filled in:

   ```
   Jira: READABLE — <KEY> — <summary> — <status>
   Figma: READABLE — <node name> — <type>
   ```

   Replace a `READABLE` line with `Jira: UNREADABLE — <short reason>` or
   `Figma: UNREADABLE — <short reason>` when a source could not be read. Then emit the
   `upload-artifact` safe output for `smoke-result.md` so it is downloadable from the run.

4. **Finish.** Call the `noop` safe output with a one-line summary like
   `Jira READABLE, Figma READABLE` (or whichever failed). Take no other action.
