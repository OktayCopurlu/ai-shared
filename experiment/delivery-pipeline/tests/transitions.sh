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
LAST_ANSWER_FILE=""

cleanup() {
  local run_dir
  for run_dir in "${created_run_dirs[@]:-}"; do
    rm -rf "$BASE_DIR/archive/$(basename "$run_dir")"
    rm -rf "$run_dir"
  done
  local tmp_dir
  for tmp_dir in "${created_tmp_dirs[@]:-}"; do
    rm -rf "$tmp_dir"
  done
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_decision() {
  local decision="$1"
  local filter="$2"
  local message="$3"

  if ! jq -e "$filter" >/dev/null <<<"$decision"; then
    printf 'Decision did not match filter: %s\n' "$filter" >&2
    printf '%s\n' "$decision" | jq . >&2
    fail "$message"
  fi
}

create_run() {
  local name="$1"
  local current_phase="${2:-qa}"
  local fix_loop_count="${3:-0}"
  local protocol_retries="${4:-}"
  local stale_from_phase="${5:-null}"
  local resume_after="${6:-null}"
  local run_id="test-transition-${name}-$$"
  local run_dir="$BASE_DIR/runs/$run_id"

  if [[ -z "$protocol_retries" ]]; then
    protocol_retries="{}"
  fi

  rm -rf "$run_dir"
  mkdir -p "$run_dir/human-inputs"
  created_run_dirs+=("$run_dir")

  jq -n \
    --arg run_id "$run_id" \
    --arg current_phase "$current_phase" \
    --arg now "2026-05-24T00:00:00Z" \
    --argjson fix_loop_count "$fix_loop_count" \
    --argjson protocol_retries "$protocol_retries" \
    --argjson stale_from_phase "$stale_from_phase" \
    --argjson resume_after "$resume_after" \
    '{
      schema_version: "1",
      run_id: $run_id,
      status: "running",
      current_phase: $current_phase,
      created_at: $now,
      updated_at: $now,
      input: { ticket: "TEST-1", target_repo: null, start_phase: $current_phase },
      ticket: { key: "TEST-1", url: null },
      target_repo: { path: null, branch: null },
      pr: { url: null, number: null },
      phase_history: [],
      fix_loop_count: $fix_loop_count,
      stale_from_phase: $stale_from_phase,
      stale_artifacts: [],
      protocol_error_retries: $protocol_retries,
      transition: { resume_after_local_safety_loop: $resume_after, last_decision: null },
      notification: { last_event: null, last_sent_at: null },
      retention: { mode: "active", archive_path: null, delete_after: null }
    }' > "$run_dir/state.json"

  : > "$run_dir/run-log.jsonl"
  node "$VALIDATOR" "$STATE_SCHEMA" "$run_dir/state.json" >/dev/null
  LAST_RUN_ID="$run_id"
}

run_decision() {
  local run_id="$1"
  local phase="$2"
  local status="$3"
  "$RUNNER" explain-transition "$run_id" --phase "$phase" --status "$status"
}

install_stub_opencode() {
  local stub_dir="$BASE_DIR/tmp/test-opencode-$$"
  mkdir -p "$stub_dir"
  created_tmp_dirs+=("$stub_dir")

  cat > "$stub_dir/opencode" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

message="${!#}"
run_dir="$(printf '%s\n' "$message" | sed -n 's/^RUN_DIR=//p')"
phase="$(printf '%s\n' "$message" | sed -n 's/^PHASE=//p')"
output_file="$(printf '%s\n' "$message" | sed -n 's/^Execute only this phase\. Write the required output JSON to \(.*\)\.$/\1/p')"

mkdir -p "$(dirname "$output_file")"

write_output() {
  local status="$1"
  local summary="$2"
  local artifacts_json="$3"
  local fix_requests_json="${4:-[]}"
  jq -n \
    --arg phase "$phase" \
    --arg status "$status" \
    --arg summary "$summary" \
    --argjson artifacts "$artifacts_json" \
    --argjson fix_requests "$fix_requests_json" \
    '{
      schema_version: "1",
      phase: $phase,
      status: $status,
      summary: $summary,
      inputs_read: ["state.json"],
      artifacts_written: $artifacts,
      evidence: [],
      fix_requests: $fix_requests,
      blockers: [],
      stale_artifacts: [],
      next_recommendation: (if $status == "fail" then "fix" else "continue" end)
    }' > "$output_file"
}

case "$phase" in
  implement)
    mkdir -p "$run_dir/current-diff"
    printf 'diff --git a/example b/example\n' > "$run_dir/current-diff/diff.patch"
    printf '{"files":["example"]}\n' > "$run_dir/current-diff/changed-files.json"
    printf 'Implemented fixture fix.\n' > "$run_dir/current-diff/summary.md"
    write_output pass "Fixture implementation completed." '["current-diff/diff.patch","current-diff/changed-files.json","current-diff/summary.md"]'
    ;;
  test-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/04-test-review.json"
    write_output pass "Fixture test review passed." '["verdicts/04-test-review.json"]'
    ;;
  code-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/05-code-review.json"
    write_output pass "Fixture code review passed." '["verdicts/05-code-review.json"]'
    ;;
  qa)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/06-qa.json"
    write_output pass "Fixture QA passed." '["verdicts/06-qa.json"]'
    ;;
  ui-validation)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/07-ui-validation.json"
    write_output pass "Fixture UI validation passed." '["verdicts/07-ui-validation.json"]'
    ;;
  create-pr)
    mkdir -p "$run_dir/pr"
    printf '{"url":"https://example.test/pr/123","number":123}\n' > "$run_dir/pr/metadata.json"
    printf 'Fixture PR description.\n' > "$run_dir/pr/description.md"
    write_output pass "Fixture PR updated." '["pr/metadata.json","pr/description.md"]'
    ;;
  pr-code-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/09-pr-code-review.json"
    write_output pass "Fixture PR code review passed." '["verdicts/09-pr-code-review.json"]'
    ;;
  pr-qa)
    mkdir -p "$run_dir/verdicts" "$run_dir/tmp"
    count_file="$run_dir/tmp/pr-qa-count"
    count="0"
    if [[ -f "$count_file" ]]; then
      count="$(cat "$count_file")"
    fi

    if [[ "$count" == "0" ]]; then
      printf '1\n' > "$count_file"
      write_output fail "Fixture PR QA failed first pass." '[]' '[{"id":"PRQA-001","source_phase":"pr-qa","severity":"high","acceptance_criteria":["AC-2"],"scenario":"Preview checkout submits without email.","expected":"Preview blocks submit.","actual":"Preview submits.","reproduction":["Open preview","Clear email","Submit"],"suggested_direction":"Fix preview validation."}]'
    else
      printf '{"status":"pass"}\n' > "$run_dir/verdicts/10-pr-qa.json"
      write_output pass "Fixture PR QA passed second pass." '["verdicts/10-pr-qa.json"]'
    fi
    ;;
  pr-ui-validation)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/11-pr-ui-validation.json"
    write_output pass "Fixture PR UI validation passed." '["verdicts/11-pr-ui-validation.json"]'
    ;;
  *)
    write_output blocked "Unexpected fixture phase: $phase" '[]'
    ;;
esac
STUB

  chmod +x "$stub_dir/opencode"
  LAST_STUB_DIR="$stub_dir"
}

create_answer_file() {
  local tmp_dir="$BASE_DIR/tmp/test-answer-$$"
  mkdir -p "$tmp_dir"
  created_tmp_dirs+=("$tmp_dir")
  printf 'Human answer fixture.\n' > "$tmp_dir/answer.md"
  LAST_ANSWER_FILE="$tmp_dir/answer.md"
}

write_phase_fail_output() {
  local run_id="$1"
  local phase="$2"
  local folder output_file
  folder="06-qa"
  if [[ "$phase" == "pr-qa" ]]; then
    folder="10-pr-qa"
  fi
  output_file="$BASE_DIR/runs/$run_id/phases/$folder/output.json"
  mkdir -p "$(dirname "$output_file")"

  jq -n \
    --arg phase "$phase" \
    '{
      schema_version: "1",
      phase: $phase,
      status: "fail",
      summary: "Validation found unresolved behavior.",
      inputs_read: ["context-packet", "current-diff"],
      artifacts_written: ["verdicts/06-qa.json"],
      evidence: [],
      fix_requests: [
        {
          id: "QA-001",
          source_phase: "qa",
          severity: "high",
          acceptance_criteria: ["AC-2"],
          scenario: "Checkout submits without required email.",
          expected: "Checkout blocks submit and shows inline validation.",
          actual: "Checkout proceeds to payment.",
          reproduction: ["Open checkout", "Clear email", "Submit"],
          suggested_direction: "Validate email before submit."
        }
      ],
      blockers: [],
      stale_artifacts: [],
      next_recommendation: "fix"
    }' > "$output_file"
}

it_routes_validator_failures_to_implement() {
  local decision
  create_run validator-fail qa 0 '{}' null null
  decision="$(run_decision "$LAST_RUN_ID" qa fail)"

  assert_decision "$decision" '.action == "continue"' "validator failure should continue to implementation"
  assert_decision "$decision" '.next_phase == "implement"' "validator failure should route to implement"
  assert_decision "$decision" '.increment_fix_loop == true and .fix_loop_count == 1' "validator failure should increment the fix loop"
  assert_decision "$decision" '.stale_from_phase == "qa"' "validator failure should record stale_from_phase"
  assert_decision "$decision" '(.stale_artifacts | index("verdicts/06-qa.json")) != null' "validator failure should mark the failed verdict stale"
  assert_decision "$decision" '(.stale_artifacts | index("pr/metadata.json")) != null' "validator failure should mark downstream PR artifacts stale"
  pass "validator failures route to implement with stale artifacts"
}

it_retries_protocol_errors_once() {
  local decision
  create_run protocol-first qa 0 '{}' null null
  decision="$(run_decision "$LAST_RUN_ID" qa protocol-error)"

  assert_decision "$decision" '.action == "continue"' "first protocol error should continue"
  assert_decision "$decision" '.next_phase == "qa"' "first protocol error should retry the same phase"
  assert_decision "$decision" '.protocol_retry == true' "first protocol error should mark protocol_retry"
  pass "protocol errors retry once"
}

it_pauses_repeated_protocol_errors() {
  local decision
  create_run protocol-repeat qa 0 '{"qa":1}' null null
  decision="$(run_decision "$LAST_RUN_ID" qa protocol-error)"

  assert_decision "$decision" '.action == "pause"' "repeated protocol error should pause"
  assert_decision "$decision" '.next_phase == "pause-for-human"' "repeated protocol error should pause for human"
  assert_decision "$decision" '.reason == "repeated protocol error"' "repeated protocol error should explain why"
  pass "repeated protocol errors pause"
}

it_pauses_when_max_fix_loops_are_exceeded() {
  local decision
  create_run max-loop qa 3 '{}' null null
  decision="$(run_decision "$LAST_RUN_ID" qa fail)"

  assert_decision "$decision" '.action == "pause"' "max loop failure should pause"
  assert_decision "$decision" '.pause_event == "blocked"' "max loop failure should notify as blocked"
  assert_decision "$decision" '.reason == "max fix loops exceeded"' "max loop failure should explain why"
  pass "max fix loop exhaustion pauses"
}

it_includes_fix_request_summary_when_max_fix_loops_are_exceeded() {
  local decision
  create_run max-loop-summary qa 3 '{}' null null
  write_phase_fail_output "$LAST_RUN_ID" qa
  decision="$(run_decision "$LAST_RUN_ID" qa fail)"

  assert_decision "$decision" '(.human_message | contains("QA-001"))' "max loop summary should include the fix request id"
  assert_decision "$decision" '(.human_message | contains("high"))' "max loop summary should include severity"
  assert_decision "$decision" '(.human_message | contains("Checkout submits without required email."))' "max loop summary should include scenario"
  pass "max fix loop summary includes unresolved fix requests"
}

it_routes_pr_validation_failures_through_pr_update() {
  local decision
  create_run pr-fail pr-qa 0 '{}' null null
  decision="$(run_decision "$LAST_RUN_ID" pr-qa fail)"

  assert_decision "$decision" '.next_phase == "implement"' "PR validation failure should route to implement"
  assert_decision "$decision" '.resume_after_local_safety_loop == "create-pr"' "PR validation failure should resume through create-pr after local safety"
  assert_decision "$decision" '(.stale_artifacts | index("verdicts/10-pr-qa.json")) != null' "PR validation failure should mark PR QA verdict stale"
  pass "PR validation failures route through PR update"
}

it_routes_create_pr_failures_through_local_fix_loop() {
  local decision
  create_run create-pr-fail create-pr 0 '{}' null null
  decision="$(run_decision "$LAST_RUN_ID" create-pr fail)"

  assert_decision "$decision" '.action == "continue"' "create-pr failure should continue into fix loop"
  assert_decision "$decision" '.next_phase == "implement"' "create-pr failure should route to implement"
  assert_decision "$decision" '.increment_fix_loop == true and .fix_loop_count == 1' "create-pr failure should increment the fix loop"
  assert_decision "$decision" '.resume_after_local_safety_loop == "create-pr"' "create-pr failure should resume through create-pr after local safety"
  assert_decision "$decision" '(.stale_artifacts | index("pr/metadata.json")) != null' "create-pr failure should mark PR metadata stale"
  pass "create-pr failures route through local fix loop"
}

it_resumes_after_local_safety_loop() {
  local decision
  create_run safety-resume ui-validation 2 '{}' '"pr-qa"' '"create-pr"'
  decision="$(run_decision "$LAST_RUN_ID" ui-validation pass)"

  assert_decision "$decision" '.action == "continue"' "passing safety loop should continue"
  assert_decision "$decision" '.next_phase == "create-pr"' "passing safety loop should resume at create-pr"
  assert_decision "$decision" '.reset_fix_loop == true' "passing safety loop should reset fix-loop state"
  pass "local safety loop resumes at stored phase"
}

it_completes_stubbed_pr_failure_recovery() {
  local stub_dir ticket run_id run_dir phases
  install_stub_opencode
  stub_dir="$LAST_STUB_DIR"
  ticket="STUB-PR-FAIL-$$"

  PATH="$stub_dir:$PATH" "$RUNNER" start --ticket "$ticket" --start-phase pr-qa >/dev/null

  run_id="$(find "$BASE_DIR/runs" -maxdepth 1 -type d -name "*$(printf '%s' "$ticket" | tr '[:upper:]' '[:lower:]')" -print | sed -n '1s|.*/||p')"
  if [[ -z "$run_id" ]]; then
    fail "stubbed PR recovery run should create a run directory"
  fi

  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "stubbed PR recovery should finish handoff-complete"
  [[ "$(jq -r '.pr.url' "$run_dir/state.json")" == "https://example.test/pr/123" ]] || fail "stubbed PR recovery should sync PR metadata"

  phases="$(jq -r '[.phase_history[].phase] | join(",")' "$run_dir/state.json")"
  [[ "$phases" == "pr-qa,implement,test-review,code-review,qa,ui-validation,create-pr,pr-code-review,pr-qa,pr-ui-validation" ]] || {
    printf 'Unexpected phase sequence: %s\n' "$phases" >&2
    fail "stubbed PR recovery should replay local safety and resume PR validation"
  }

  jq -e 'select(.event == "transition" and .phase == "pr-qa" and .next_phase == "implement")' "$run_dir/run-log.jsonl" >/dev/null || fail "stubbed PR recovery should log PR QA fail transition"
  jq -e 'select(.event == "transition" and .phase == "ui-validation" and .next_phase == "create-pr")' "$run_dir/run-log.jsonl" >/dev/null || fail "stubbed PR recovery should log safety-loop resume transition"
  pass "stubbed PR validation failure recovers through local safety and PR update"
}

it_replays_from_planning_when_resume_answer_changes_scope() {
  local answer_file phase
  create_run resume-scope qa 0 '{}' null null
  create_answer_file
  answer_file="$LAST_ANSWER_FILE"

  "$RUNNER" resume "$LAST_RUN_ID" --answer-file "$answer_file" --impact scope-change --dry-run >/dev/null || true

  phase="$(jq -r '.phase_history[-1].phase' "$BASE_DIR/runs/$LAST_RUN_ID/state.json")"
  [[ "$phase" == "plan" ]] || fail "scope-changing resume should replay from plan"
  [[ "$(jq -r '.stale_from_phase' "$BASE_DIR/runs/$LAST_RUN_ID/state.json")" == "plan" ]] || fail "scope-changing resume should mark plan as stale source"
  pass "scope-changing resume replays from planning"
}

it_resumes_blocked_phase_when_answer_is_access_only() {
  local answer_file phase
  create_run resume-access qa 0 '{}' null null
  create_answer_file
  answer_file="$LAST_ANSWER_FILE"

  "$RUNNER" resume "$LAST_RUN_ID" --answer-file "$answer_file" --impact access --dry-run >/dev/null || true

  phase="$(jq -r '.phase_history[-1].phase' "$BASE_DIR/runs/$LAST_RUN_ID/state.json")"
  [[ "$phase" == "qa" ]] || fail "access-only resume should rerun the blocked phase"
  pass "access-only resume reruns blocked phase"
}

it_routes_validator_failures_to_implement
it_retries_protocol_errors_once
it_pauses_repeated_protocol_errors
it_pauses_when_max_fix_loops_are_exceeded
it_includes_fix_request_summary_when_max_fix_loops_are_exceeded
it_routes_pr_validation_failures_through_pr_update
it_routes_create_pr_failures_through_local_fix_loop
it_resumes_after_local_safety_loop
it_completes_stubbed_pr_failure_recovery
it_replays_from_planning_when_resume_answer_changes_scope
it_resumes_blocked_phase_when_answer_is_access_only

printf 'All transition fixture tests passed.\n'
