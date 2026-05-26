#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$BASE_DIR/runner.sh"
VALIDATOR="$BASE_DIR/tools/validate-schema.mjs"
STATE_SCHEMA="$BASE_DIR/schemas/state.schema.json"

created_run_dirs=()
created_tmp_dirs=()
LAST_RUN_ID=""
LAST_STUB_DIR=""
LAST_RECORD_FILE=""

cleanup() {
  local d
  for d in "${created_run_dirs[@]:-}"; do
    rm -rf "$BASE_DIR/archive/$(basename "$d")"
    rm -rf "$d"
  done
  for d in "${created_tmp_dirs[@]:-}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

create_run() {
  local name="$1"
  local current_phase="${2:-implement}"
  local model_override="${3:-}"
  local variant_override="${4:-}"
  local run_id="test-phase-exec-${name}-$$"
  local run_dir="$BASE_DIR/runs/$run_id"

  rm -rf "$run_dir"
  mkdir -p "$run_dir/human-inputs" "$run_dir/phases"
  created_run_dirs+=("$run_dir")

  jq -n \
    --arg run_id "$run_id" \
    --arg current_phase "$current_phase" \
    --arg now "2026-05-24T00:00:00Z" \
    --arg model_override "$model_override" \
    --arg variant_override "$variant_override" \
    '{
      schema_version: "1",
      run_id: $run_id,
      status: "running",
      current_phase: $current_phase,
      created_at: $now,
      updated_at: $now,
      input: {
        ticket: "TEST-1",
        target_repo: null,
        start_phase: $current_phase,
        model_override: (if $model_override == "" then null else $model_override end),
        variant_override: (if $variant_override == "" then null else $variant_override end)
      },
      ticket: { key: "TEST-1", url: null },
      target_repo: { path: null, branch: null },
      pr: { url: null, number: null },
      phase_history: [],
      fix_loop_count: 0,
      stale_from_phase: null,
      stale_artifacts: [],
      protocol_error_retries: {},
      transition: { resume_after_local_safety_loop: null, last_decision: null },
      notification: { last_event: null, last_sent_at: null },
      retention: { mode: "active", archive_path: null, delete_after: null }
    }' > "$run_dir/state.json"

  : > "$run_dir/run-log.jsonl"
  printf '{"ticket":"TEST-1","target_repo":null,"start_phase":"%s"}\n' "$current_phase" > "$run_dir/input.json"
  node "$VALIDATOR" "$STATE_SCHEMA" "$run_dir/state.json" >/dev/null
  LAST_RUN_ID="$run_id"
}

install_recording_stub() {
  local stub_dir="$BASE_DIR/tmp/test-phase-exec-stub-$$"
  local record_file="$BASE_DIR/tmp/test-phase-exec-record-$$"
  rm -f "$record_file"
  mkdir -p "$stub_dir"
  created_tmp_dirs+=("$stub_dir")
  created_tmp_dirs+=("$record_file")

  cat > "$stub_dir/opencode" <<STUB
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "$record_file"

message="\${!#}"
run_dir="\$(printf '%s\n' "\$message" | sed -n 's/^RUN_DIR=//p')"
phase="\$(printf '%s\n' "\$message" | sed -n 's/^PHASE=//p')"
output_file="\$(printf '%s\n' "\$message" | sed -n 's/^Execute only this phase\. Write the required output JSON to \(.*\)\.\$/\1/p')"

mkdir -p "\$(dirname "\$output_file")"

# Always emit a valid blocked output so the pipeline pauses after one phase.
jq -n --arg phase "\$phase" '{
  schema_version: "1",
  phase: \$phase,
  status: "blocked",
  summary: "Test stub paused phase.",
  inputs_read: [],
  artifacts_written: [],
  evidence: [],
  fix_requests: [],
  blockers: [{ type: "test-stub", message: "Stub paused phase.", needed_from_human: "n/a" }],
  stale_artifacts: [],
  next_recommendation: "pause-for-human"
}' > "\$output_file"
STUB
  chmod +x "$stub_dir/opencode"
  LAST_STUB_DIR="$stub_dir"
  LAST_RECORD_FILE="$record_file"
}

install_no_output_stub() {
  local stub_dir="$BASE_DIR/tmp/test-phase-no-output-stub-$$"
  local record_file="$BASE_DIR/tmp/test-phase-no-output-record-$$"
  rm -f "$record_file"
  mkdir -p "$stub_dir"
  created_tmp_dirs+=("$stub_dir")
  created_tmp_dirs+=("$record_file")

  cat > "$stub_dir/opencode" <<STUB
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "$record_file"
exit 0
STUB
  chmod +x "$stub_dir/opencode"
  LAST_STUB_DIR="$stub_dir"
  LAST_RECORD_FILE="$record_file"
}

install_fallback_stub() {
  local stub_dir="$BASE_DIR/tmp/test-phase-fallback-stub-$$"
  local record_file="$BASE_DIR/tmp/test-phase-fallback-record-$$"
  rm -f "$record_file"
  mkdir -p "$stub_dir"
  created_tmp_dirs+=("$stub_dir")
  created_tmp_dirs+=("$record_file")

  cat > "$stub_dir/opencode" <<STUB
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "$record_file"

message="\${!#}"
model=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    --model)
      model="\$2"; shift 2 ;;
    *)
      shift ;;
  esac
done

phase="\$(printf '%s\n' "\$message" | sed -n 's/^PHASE=//p')"
output_file="\$(printf '%s\n' "\$message" | sed -n 's/^Execute only this phase\. Write the required output JSON to \(.*\)\.\$/\1/p')"

if [[ "\$model" == "anthropic/claude-opus-4.7" ]]; then
  echo "model unavailable" >&2
  exit 42
fi

mkdir -p "\$(dirname "\$output_file")"
jq -n --arg phase "\$phase" '{
  schema_version: "1",
  phase: \$phase,
  status: "blocked",
  summary: "Fallback model reached the phase.",
  inputs_read: [],
  artifacts_written: [],
  evidence: [],
  fix_requests: [],
  blockers: [{ type: "test-stub", message: "Fallback completed.", needed_from_human: "n/a" }],
  stale_artifacts: [],
  next_recommendation: "pause-for-human"
}' > "\$output_file"
STUB
  chmod +x "$stub_dir/opencode"
  LAST_STUB_DIR="$stub_dir"
  LAST_RECORD_FILE="$record_file"
}

it_run_phase_executes_a_single_phase() {
  create_run single-rerun implement
  install_recording_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" implement >/dev/null

  [[ -f "$run_dir/phases/03-implement/output.json" ]] || fail "run-phase should write phase output"
  local history_count
  history_count="$(jq '.phase_history | length' "$run_dir/state.json")"
  [[ "$history_count" == "1" ]] || fail "run-phase should append exactly one phase_history entry, got $history_count"
  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "run-phase should end paused"
  pass "run-phase executes a single phase and pauses"
}

it_run_phase_writes_command_metadata() {
  create_run command-meta implement
  install_recording_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" implement >/dev/null

  local meta_file="$run_dir/phases/03-implement/command-meta.json"
  [[ -f "$meta_file" ]] || fail "command-meta.json should exist"
  jq -e '.phase == "implement"' "$meta_file" >/dev/null || fail "command-meta must record phase id"
  jq -e '.command_path | test("commands/03-implement.md$")' "$meta_file" >/dev/null \
    || fail "command-meta must record command path"
  jq -e '.phase_config.required_outputs | length > 0' "$meta_file" >/dev/null \
    || fail "command-meta must snapshot phase_config.required_outputs"
  jq -e '.finished_at != null and .phase_status != null' "$meta_file" >/dev/null \
    || fail "command-meta must capture finished_at and phase_status after run"
  jq -e '.phase_history[-1].command_meta == "phases/03-implement/command-meta.json"' "$run_dir/state.json" >/dev/null \
    || fail "phase_history entry must link to command_meta"

  local status_output explain_output
  status_output="$($RUNNER status "$LAST_RUN_ID")"
  jq -e '.last_command_meta_summary.phase == "implement"' <<<"$status_output" >/dev/null \
    || fail "status output must include last command metadata summary"
  explain_output="$($RUNNER explain-transition "$LAST_RUN_ID")"
  jq -e '.last_command_meta_summary.phase == "implement"' <<<"$explain_output" >/dev/null \
    || fail "explain-transition output must include last command metadata summary"
  pass "run-phase writes command metadata and links it from phase_history"
}

it_run_phase_includes_latest_human_input_in_prompt() {
  create_run human-input implement
  install_recording_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  cat > "$run_dir/human-inputs/20260525-010101-answer.md" <<'EOF'
Use all ticket-listed overlays and continue with available linked context.
EOF
  jq -n \
    '{schema_version:"1",source:"whatsapp",stored_path:"human-inputs/20260525-010101-answer.md",impact:"decision",phase:"context-intake",received_at:"2026-05-25T01:01:01Z"}' \
    > "$run_dir/human-inputs/20260525-010101-answer.metadata.json"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" implement >/dev/null

  grep -q 'Latest human input:' "$LAST_RECORD_FILE" || fail "opencode prompt should include latest human input heading"
  grep -q 'Impact: decision' "$LAST_RECORD_FILE" || fail "opencode prompt should include human input impact"
  grep -q 'Use all ticket-listed overlays' "$LAST_RECORD_FILE" || fail "opencode prompt should include human answer body"
  pass "run-phase includes latest human input in opencode prompt"
}

it_run_phase_uses_configured_opencode_permission_mode() {
  create_run permission-mode implement
  install_recording_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" implement >/dev/null

  grep -q -- '--dangerously-skip-permissions' "$LAST_RECORD_FILE" \
    || fail "opencode invocation must use configured noninteractive permission approval"
  jq -e '.opencode.dangerously_skip_permissions == true' "$run_dir/phases/03-implement/command-meta.json" >/dev/null \
    || fail "command-meta must record OpenCode permission mode"
  pass "run-phase uses the configured OpenCode permission mode"
}

it_falls_back_to_default_model_when_primary_model_fails() {
  create_run fallback code-review
  install_fallback_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" code-review >/dev/null

  grep -q -- '--model anthropic/claude-opus-4.7' "$LAST_RECORD_FILE" \
    || fail "primary model should be attempted first"
  grep -q -- '--model github-copilot/gpt-5.5' "$LAST_RECORD_FILE" \
    || fail "fallback model should be attempted after primary failure"

  local meta_file="$run_dir/phases/05-code-review/command-meta.json"
  jq -e '.fallback_used == true' "$meta_file" >/dev/null || fail "command-meta must mark fallback_used"
  jq -e '.effective_model == "github-copilot/gpt-5.5"' "$meta_file" >/dev/null \
    || fail "command-meta must record fallback effective model"
  jq -e '.attempts | length == 2' "$meta_file" >/dev/null || fail "command-meta must record both attempts"
  pass "run-phase falls back to the default model when primary model fails"
}

it_run_phase_dry_run_does_not_invoke_opencode() {
  create_run dry-rerun implement
  install_recording_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" implement --dry-run >/dev/null

  [[ -f "$run_dir/phases/03-implement/output.json" ]] || fail "dry-run should still write a phase output"
  [[ ! -s "$LAST_RECORD_FILE" ]] || fail "dry-run must not invoke opencode stub"
  pass "run-phase --dry-run skips opencode invocation"
}

it_run_phase_rejects_stale_output_when_executor_writes_nothing() {
  create_run stale-output qa
  install_no_output_stub
  local run_dir="$BASE_DIR/runs/$LAST_RUN_ID"
  mkdir -p "$run_dir/phases/06-qa" "$run_dir/verdicts"

  jq -n '{
    schema_version: "1",
    phase: "qa",
    status: "pass",
    summary: "Old QA pass.",
    inputs_read: [],
    artifacts_written: ["verdicts/06-qa.json"],
    evidence: [],
    fix_requests: [],
    blockers: [],
    stale_artifacts: [],
    next_recommendation: "continue"
  }' > "$run_dir/phases/06-qa/output.json"
  printf '{"status":"pass"}\n' > "$run_dir/verdicts/06-qa.json"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" run-phase "$LAST_RUN_ID" qa >/dev/null

  [[ "$(jq -r '.status' "$run_dir/phases/06-qa/output.json")" == "protocol-error" ]] \
    || fail "stale output.json must be replaced with protocol-error when executor writes nothing"
  [[ "$(jq -r '.phase_history[-1].status' "$run_dir/state.json")" == "protocol-error" ]] \
    || fail "phase history must record protocol-error for missing fresh output"
  [[ ! -e "$run_dir/verdicts/06-qa.json" ]] || fail "stale required QA artifact should be cleared before rerun"
  pass "run-phase rejects stale output when executor writes nothing"
}

it_start_propagates_model_and_variant_overrides() {
  install_recording_stub
  # cmd_start will create its own run_id; capture before/after diff under runs/.
  local before
  before="$(ls "$BASE_DIR/runs" 2>/dev/null | wc -l)"
  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start \
    --ticket "test-override-$$" \
    --start-phase implement \
    --model fixture-model \
    --variant fixture-variant >/dev/null 2>&1 || true

  local new_run_id new_run_dir
  new_run_id="$(ls -1t "$BASE_DIR/runs" | head -n1)"
  new_run_dir="$BASE_DIR/runs/$new_run_id"
  created_run_dirs+=("$new_run_dir")

  [[ "$(jq -r '.input.model_override' "$new_run_dir/state.json")" == "fixture-model" ]] \
    || fail "model override must be persisted in state.input"
  [[ "$(jq -r '.input.variant_override' "$new_run_dir/state.json")" == "fixture-variant" ]] \
    || fail "variant override must be persisted in state.input"

  grep -q -- '--model fixture-model' "$LAST_RECORD_FILE" \
    || fail "opencode must be invoked with overridden model"
  grep -q -- '--variant fixture-variant' "$LAST_RECORD_FILE" \
    || fail "opencode must be invoked with overridden variant"
  pass "start --model and --variant propagate to opencode invocation"
}

it_start_dry_run_does_not_invoke_opencode() {
  install_recording_stub
  local ticket="test-start-dry-run-$$"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start \
    --ticket "$ticket" \
    --start-phase implement \
    --dry-run \
    --no-notify >/dev/null 2>&1 || true

  local new_run_id new_run_dir
  new_run_id="$(ls -1t "$BASE_DIR/runs" | head -n1)"
  new_run_dir="$BASE_DIR/runs/$new_run_id"
  created_run_dirs+=("$new_run_dir")

  [[ ! -s "$LAST_RECORD_FILE" ]] || fail "start --dry-run must not invoke opencode"
  [[ "$(jq -r '.phase_history[-1].phase' "$new_run_dir/state.json")" == "implement" ]] \
    || fail "start --dry-run should run the requested phase only"
  [[ "$(jq -r '.phase_history[-1].status' "$new_run_dir/state.json")" == "blocked" ]] \
    || fail "start --dry-run should write a blocked phase output"
  pass "start --dry-run skips opencode invocation"
}

it_command_required_artifact_lists_match_pipeline() {
  local phase_cfg phase_id number command_path folder expected actual actual_normalized

  while IFS= read -r phase_cfg; do
    phase_id="$(jq -r '.id' <<<"$phase_cfg")"
    number="$(jq -r '.number' <<<"$phase_cfg")"
    command_path="$BASE_DIR/$(jq -r '.command' <<<"$phase_cfg")"
    folder="$(printf '%02d-%s' "$number" "$phase_id")"
    expected="$(jq -c --arg output_path "phases/$folder/output.json" '.required_outputs + [$output_path]' <<<"$phase_cfg")"
    actual="$(perl -ne 'if (/^Required artifact list:\s*`(\[.*\])`\./) { print $1; exit }' "$command_path")"

    [[ -n "$actual" ]] || fail "command file must include Required artifact list: ${command_path#$BASE_DIR/}"
    if ! actual_normalized="$(jq -c . <<<"$actual" 2>/dev/null)"; then
      fail "Required artifact list must be valid JSON in ${command_path#$BASE_DIR/}"
    fi
    [[ "$actual_normalized" == "$expected" ]] \
      || fail "Required artifact list in ${command_path#$BASE_DIR/} must match pipeline.json required_outputs plus output.json"
  done < <(jq -c '.phases[] | {id,number,command,required_outputs}' "$BASE_DIR/pipeline.json")

  pass "command required artifact lists match pipeline config"
}

it_doctor_reports_timeout_helper_status() {
  local output
  output="$("$RUNNER" doctor 2>&1 || true)"
  printf '%s' "$output" | grep -Eq 'timeout helper available|timeout/gtimeout missing' \
    || fail "doctor must mention timeout helper status"
  pass "doctor mentions timeout helper status"
}

it_doctor_reports_timeout_helper_status
it_command_required_artifact_lists_match_pipeline
it_run_phase_executes_a_single_phase
it_run_phase_writes_command_metadata
it_run_phase_includes_latest_human_input_in_prompt
it_run_phase_uses_configured_opencode_permission_mode
it_run_phase_dry_run_does_not_invoke_opencode
it_run_phase_rejects_stale_output_when_executor_writes_nothing
it_start_dry_run_does_not_invoke_opencode
it_start_propagates_model_and_variant_overrides
it_falls_back_to_default_model_when_primary_model_fails

printf 'All phase execution tests passed.\n'
