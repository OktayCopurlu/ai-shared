---
# Experiment step 2/3 — Read the AC list, write an implementation plan, hand off to step 3.
on:
  workflow_dispatch:
    inputs:
      ticket:
        description: "Jira ticket key or URL"
        required: true
        type: string
      prev_run_id:
        description: "Run ID of step 1 to restore state from"
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

# Pre-step: restore the previous step's .exp/ state from its uploaded artifact (uses github.token,
# needs actions: read). Robust to the artifact name — finds exp-state.tgz wherever it landed.
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
      # gh run download creates a directory per artifact (e.g. /tmp/exp-prev/exp-state.tgz/),
      # so target the actual FILE inside it, not the directory.
      tgz="$(find /tmp/exp-prev -type f -name 'exp-state.tgz' | head -1)"
      if [ -n "$tgz" ]; then
        tar -xzf "$tgz" -C . && echo "Restored .exp from $tgz"; ls -la .exp || true
      else
        echo "exp-state.tgz file not found under /tmp/exp-prev; contents:"; find /tmp/exp-prev -maxdepth 3 || true
      fi

safe-outputs:
  upload-artifact:
    retention-days: 7
    max-uploads: 1
  dispatch-workflow: [exp-step-3-final]

tools:
  bash: [":*"]
  edit:

timeout-minutes: 15
---

# Experiment — Step 2 of 3: AC list → Implementation plan

You are step 2 of a 3-stage experiment chain. Do only this step, then hand off to step 3.

- Ticket: `${{ inputs.ticket }}`
- This run's ID (pass as `prev_run_id` to step 3): `${{ github.run_id }}`
- Previous run ID (already restored for you): `${{ inputs.prev_run_id }}`

Do exactly this:

1. **Read the AC list.** A pre-step restored the previous step's state, so read `.exp/ac-list.md`.
   If it is missing, write a one-line note into `.exp/impl-plan.md` saying state was not received,
   and still continue.
2. **Write an implementation plan.** Create `.exp/impl-plan.md`: for each `AC-N`, a short plan —
   the area/files likely involved, the approach, and the concrete steps. This is a planning-only
   exercise; do not inspect or change any repository code.
3. **Snapshot state.** Run `tar -czf exp-state.tgz .exp`, then emit the `upload-artifact` safe
   output for `exp-state.tgz`.
4. **Hand off.** Emit the `dispatch-workflow` safe output for **`exp-step-3-final`**, passing
   inputs: `ticket` = the ticket above, `prev_run_id` = `${{ github.run_id }}`.

Take no other action. Do not write code or open PRs.
