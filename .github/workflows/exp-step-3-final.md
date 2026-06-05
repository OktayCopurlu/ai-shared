---
# Experiment step 3/3 — Receive the plan. Do nothing for now (terminal step). Ends the chain.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL"
        required: true
        type: string
      prev_run_id:
        description: "Run ID of step 2 to restore state from"
        required: false
        type: string
        default: ""

engine:
  id: copilot
  model: claude-sonnet-4.6

permissions:
  contents: read
  actions: read

network:
  allowed:
    - defaults

steps:
  - name: Restore previous step state
    if: ${{ inputs.prev_run_id != '' }}
    env:
      GH_TOKEN: ${{ github.token }}
      PREV: ${{ inputs.prev_run_id }}
    run: |
      set -euo pipefail
      rm -rf /tmp/exp-prev && mkdir -p /tmp/exp-prev
      gh run download "$PREV" --repo "$GITHUB_REPOSITORY" --dir /tmp/exp-prev || { echo "no prior artifact yet"; exit 0; }
      tgz="$(find /tmp/exp-prev -name 'exp-state.tgz' | head -1)"
      if [ -n "$tgz" ]; then tar -xzf "$tgz" -C . && echo "Restored .exp from $tgz"; ls -la .exp || true; else echo "exp-state.tgz not found"; fi

# Terminal step: just record what it received and stop. noop keeps the run from completing silently.
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

# Experiment — Step 3 of 3: Receive the plan (no-op terminal step)

You are the final step of a 3-stage experiment chain. You intentionally do **no** real work yet —
this run only proves the plan reached the last agent.

- Ticket: `${{ inputs.ticket }}`
- Previous run ID (already restored for you): `${{ inputs.prev_run_id }}`

Do exactly this:

1. **Read what you received.** A pre-step restored the previous step's state. Read
   `.exp/impl-plan.md` and `.exp/ac-list.md` if present.
2. **Record receipt.** Write `.exp/done.md` containing: the ticket key, a one-line confirmation
   that the AC list and implementation plan were received, and the count of `AC-` items you saw.
   If state was missing, say so in one line instead.
3. **Snapshot for inspection.** Run `tar -czf exp-state.tgz .exp`, then emit the `upload-artifact`
   safe output for `exp-state.tgz` so the full chain output is downloadable.
4. **Stop.** Emit the `noop` safe output with a one-line summary like
   `Chain complete: received plan for <ticket>`. Do not implement anything, do not open a PR,
   do not dispatch any further workflow.
