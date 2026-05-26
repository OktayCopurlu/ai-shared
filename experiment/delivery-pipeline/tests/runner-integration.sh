#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$BASE_DIR/runner.sh"

created_run_dirs=()
created_tmp_dirs=()
LAST_STUB_DIR=""
LAST_FAKE_REPO=""

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

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

install_pipeline_stub() {
  local stub_dir="$BASE_DIR/tmp/test-integration-opencode-$$"
  mkdir -p "$stub_dir"
  created_tmp_dirs+=("$stub_dir")

  cat > "$stub_dir/opencode" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

message="${!#}"
run_dir="$(printf '%s\n' "$message" | sed -n 's/^RUN_DIR=//p')"
phase="$(printf '%s\n' "$message" | sed -n 's/^PHASE=//p')"
output_file="$(printf '%s\n' "$message" | sed -n 's/^Execute only this phase\. Write the required output JSON to \(.*\)\.$/\1/p')"
mode="${PIPELINE_STUB_MODE:-full}"

mkdir -p "$(dirname "$output_file")"

write_output() {
  local status="$1"
  local summary="$2"
  local artifacts_json="$3"
  local blockers_json="${4:-[]}"
  jq -n \
    --arg phase "$phase" \
    --arg status "$status" \
    --arg summary "$summary" \
    --argjson artifacts "$artifacts_json" \
    --argjson blockers "$blockers_json" \
    '{
      schema_version: "1",
      phase: $phase,
      status: $status,
      summary: $summary,
      inputs_read: ["state.json"],
      artifacts_written: $artifacts,
      evidence: [],
      fix_requests: [],
      blockers: $blockers,
      stale_artifacts: [],
      next_recommendation: (if $status == "blocked" then "pause-for-human" else "continue" end)
    }' > "$output_file"
}

write_fail_output() {
  local summary="$1"
  local artifacts_json="$2"
  local fix_requests_json="$3"
  jq -n \
    --arg phase "$phase" \
    --arg summary "$summary" \
    --argjson artifacts "$artifacts_json" \
    --argjson fix_requests "$fix_requests_json" \
    '{
      schema_version: "1",
      phase: $phase,
      status: "fail",
      summary: $summary,
      inputs_read: ["state.json"],
      artifacts_written: $artifacts,
      evidence: [],
      fix_requests: $fix_requests,
      blockers: [],
      stale_artifacts: [],
      next_recommendation: "fix"
    }' > "$output_file"
}

write_blocked_output() {
  local summary="$1"
  local blockers_json="$2"
  jq -n \
    --arg phase "$phase" \
    --arg summary "$summary" \
    --argjson blockers "$blockers_json" \
    '{
      schema_version: "1",
      phase: $phase,
      status: "blocked",
      summary: $summary,
      inputs_read: ["state.json"],
      artifacts_written: [],
      evidence: [],
      fix_requests: [],
      blockers: $blockers,
      stale_artifacts: [],
      next_recommendation: "pause-for-human"
    }' > "$output_file"
}

case "$phase" in
  context-intake)
    mkdir -p "$run_dir/context-packet"
    printf '# Ticket\n\nFixture ticket.\n' > "$run_dir/context-packet/ticket.md"
    if [[ "$mode" == "schema-invalid-output" ]]; then
      printf '{"phase":"context-intake"}\n' > "$output_file"
      exit 0
    fi
    if [[ "$mode" == "missing-context-artifact" ]]; then
      write_output pass "Context intentionally missed required artifacts." '["context-packet/ticket.md"]'
      exit 0
    fi
    if [[ "$mode" == "schema-invalid-required-artifact-omitted" ]]; then
      jq -n '[{id:"1",text:"Invalid normalized AC id."}]' > "$run_dir/context-packet/acceptance-criteria.json"
      printf 'Linked context fixture.\n' > "$run_dir/context-packet/linked-context.md"
      jq -n '{available:false,reason:"no Figma link found"}' > "$run_dir/context-packet/figma-specs.json"
      printf 'No constraints.\n' > "$run_dir/context-packet/constraints.md"
      printf 'No open questions.\n' > "$run_dir/context-packet/open-questions.md"
      printf 'Validate AC-1 locally and on PR.\n' > "$run_dir/context-packet/validation-targets.md"
      write_output pass "Context wrote an invalid required artifact but omitted it from artifacts_written." '["context-packet/ticket.md","context-packet/linked-context.md","context-packet/figma-specs.json","context-packet/constraints.md","context-packet/open-questions.md","context-packet/validation-targets.md"]'
      exit 0
    fi
    if [[ "$mode" == "missing-figma-specs-artifact" ]]; then
      jq -n '[{id:"AC-1",text:"Fixture behavior is delivered.",source:"test",priority:"must"}]' > "$run_dir/context-packet/acceptance-criteria.json"
      printf 'Linked context fixture.\n' > "$run_dir/context-packet/linked-context.md"
      printf 'No constraints.\n' > "$run_dir/context-packet/constraints.md"
      printf 'No open questions.\n' > "$run_dir/context-packet/open-questions.md"
      printf 'Validate AC-1 locally and on PR.\n' > "$run_dir/context-packet/validation-targets.md"
      write_output pass "Context intentionally skipped Figma specs." '["context-packet/ticket.md","context-packet/acceptance-criteria.json","context-packet/linked-context.md","context-packet/constraints.md","context-packet/open-questions.md","context-packet/validation-targets.md"]'
      exit 0
    fi
    jq -n '[{id:"AC-1",text:"Fixture behavior is delivered.",source:"test",priority:"must"}]' > "$run_dir/context-packet/acceptance-criteria.json"
    printf 'Linked context fixture.\n' > "$run_dir/context-packet/linked-context.md"
    printf 'No constraints.\n' > "$run_dir/context-packet/constraints.md"
    printf 'No open questions.\n' > "$run_dir/context-packet/open-questions.md"
    printf 'Validate AC-1 locally and on PR.\n' > "$run_dir/context-packet/validation-targets.md"
    jq -n '{available:false,reason:"no Figma link found"}' > "$run_dir/context-packet/figma-specs.json"
    write_output pass "Context packet complete." '["context-packet/ticket.md","context-packet/acceptance-criteria.json","context-packet/linked-context.md","context-packet/constraints.md","context-packet/open-questions.md","context-packet/validation-targets.md","context-packet/figma-specs.json"]'
    ;;
  plan)
    mkdir -p "$run_dir/implementation-plan"
    printf '# Plan\n\nFixture plan.\n' > "$run_dir/implementation-plan/plan.md"
    printf '{"files":["fixture.txt"]}\n' > "$run_dir/implementation-plan/affected-files.json"
    printf '{"commands":["npm test"]}\n' > "$run_dir/implementation-plan/validation-plan.json"
    write_output pass "Plan complete." '["implementation-plan/plan.md","implementation-plan/affected-files.json","implementation-plan/validation-plan.json"]'
    ;;
  implement)
    mkdir -p "$run_dir/current-diff"
    printf 'diff --git a/fixture.txt b/fixture.txt\n' > "$run_dir/current-diff/diff.patch"
    printf '{"files":["fixture.txt"]}\n' > "$run_dir/current-diff/changed-files.json"
    printf 'Fixture implementation summary.\n' > "$run_dir/current-diff/summary.md"
    write_output pass "Implementation complete." '["current-diff/diff.patch","current-diff/changed-files.json","current-diff/summary.md"]'
    ;;
  test-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/04-test-review.json"
    write_output pass "Tests passed." '["verdicts/04-test-review.json"]'
    ;;
  code-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/05-code-review.json"
    write_output pass "Code review passed." '["verdicts/05-code-review.json"]'
    ;;
  qa)
    mkdir -p "$run_dir/verdicts"
    if [[ "$mode" == "qa-fail-once" ]]; then
      mkdir -p "$run_dir/tmp"
      count_file="$run_dir/tmp/qa-fail-count"
      count="0"
      if [[ -f "$count_file" ]]; then
        count="$(cat "$count_file")"
      fi
      if [[ "$count" == "0" ]]; then
        printf '1\n' > "$count_file"
        printf '{"status":"fail"}\n' > "$run_dir/verdicts/06-qa.json"
        write_fail_output "QA found a fixture regression." '["verdicts/06-qa.json"]' '[{"id":"QA-001","source_phase":"qa","severity":"high","acceptance_criteria":["AC-1"],"scenario":"Fixture behavior regressed.","expected":"Fixture behavior passes.","actual":"Fixture behavior fails.","reproduction":["Run QA fixture"],"suggested_direction":"Fix the fixture behavior and rerun local safety."}]'
        exit 0
      fi
    fi
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/06-qa.json"
    write_output pass "QA passed." '["verdicts/06-qa.json"]'
    ;;
  ui-validation)
    mkdir -p "$run_dir/verdicts"
    if [[ "$mode" == "ui-blocked" ]]; then
      write_blocked_output "UI validation needs a reachable preview URL." '[{"type":"preview-url","message":"No preview URL is available for browser validation.","needed_from_human":"Provide a reachable preview URL or local dev server."}]'
      exit 0
    fi
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/07-ui-validation.json"
    write_output pass "UI validation passed." '["verdicts/07-ui-validation.json"]'
    ;;
  create-pr)
    mkdir -p "$run_dir/pr"
    if [[ "$mode" == "create-pr-blocked" ]]; then
      write_blocked_output "PR creation needs repository push access." '[{"type":"repo-access","message":"The stub cannot create a PR without push access.","needed_from_human":"Confirm branch push permission or create the PR manually."}]'
      exit 0
    fi
    printf '{"url":"https://example.test/pull/456","number":456}\n' > "$run_dir/pr/metadata.json"
    printf 'Fixture PR description.\n' > "$run_dir/pr/description.md"
    write_output pass "PR created." '["pr/metadata.json","pr/description.md"]'
    ;;
  pr-code-review)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/09-pr-code-review.json"
    write_output pass "PR code review passed." '["verdicts/09-pr-code-review.json"]'
    ;;
  pr-qa)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/10-pr-qa.json"
    write_output pass "PR QA passed." '["verdicts/10-pr-qa.json"]'
    ;;
  pr-ui-validation)
    mkdir -p "$run_dir/verdicts"
    printf '{"status":"pass"}\n' > "$run_dir/verdicts/11-pr-ui-validation.json"
    write_output pass "PR UI validation passed." '["verdicts/11-pr-ui-validation.json"]'
    ;;
  *)
    write_output blocked "Unexpected phase: $phase" '[]' '[{"type":"test-stub","message":"Unexpected phase.","needed_from_human":"n/a"}]'
    ;;
esac
STUB

  chmod +x "$stub_dir/opencode"
  LAST_STUB_DIR="$stub_dir"
}

create_fake_repo() {
  local fake_repo
  fake_repo="$(mktemp -d "$BASE_DIR/tmp/test-fake-repo.XXXXXX")"
  mkdir -p "$fake_repo"
  printf '{"scripts":{"test":"echo ok"}}\n' > "$fake_repo/package.json"
  printf 'fixture\n' > "$fake_repo/fixture.txt"
  created_tmp_dirs+=("$fake_repo")
  LAST_FAKE_REPO="$fake_repo"
}

find_run_for_ticket() {
  local ticket="$1"
  find "$BASE_DIR/runs" -maxdepth 1 -type d -name "*$(printf '%s' "$ticket" | tr '[:upper:]' '[:lower:]')" -print | sed -n '1s|.*/||p'
}

it_pauses_when_required_artifacts_are_missing() {
  install_pipeline_stub
  local ticket="STUB-MISSING-$$"

  PIPELINE_STUB_MODE=missing-context-artifact PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --start-phase context-intake --no-notify >/dev/null 2>&1 || true

  local run_id run_dir output_file
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "missing-artifact run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  output_file="$run_dir/phases/01-context-intake/output.json"

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "missing artifacts should pause the run"
  [[ "$(jq -r '.status' "$output_file")" == "protocol-error" ]] || fail "missing artifacts should become protocol-error"
  local summary
  summary="$(jq -r '.summary' "$output_file")"
  [[ "$summary" == *"missed required artifacts"* ]] \
    || fail "protocol-error summary should mention missing required artifacts, got: $summary"
  jq -e '.protocol_error_retries["context-intake"] == 1' "$run_dir/state.json" >/dev/null \
    || fail "missing artifact protocol-error should retry once before pausing"
  pass "missing required artifacts pause after one protocol retry"
}

it_pauses_when_required_schema_artifact_is_invalid_and_omitted() {
  install_pipeline_stub
  local ticket="STUB-INVALID-OMITTED-$$"

  PIPELINE_STUB_MODE=schema-invalid-required-artifact-omitted PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --start-phase context-intake --no-notify >/dev/null 2>&1 || true

  local run_id run_dir output_file summary
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "invalid omitted artifact run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  output_file="$run_dir/phases/01-context-intake/output.json"

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "invalid omitted required artifact should pause the run"
  [[ "$(jq -r '.status' "$output_file")" == "protocol-error" ]] || fail "invalid omitted required artifact should become protocol-error"
  summary="$(jq -r '.summary' "$output_file")"
  [[ "$summary" == *"context-packet/acceptance-criteria.json failed schema validation"* ]] \
    || fail "protocol-error summary should mention invalid acceptance criteria, got: $summary"
  pass "invalid required canonical artifact is schema-validated even when omitted from artifacts_written"
}

it_pauses_when_context_intake_skips_figma_specs() {
  install_pipeline_stub
  local ticket="STUB-MISSING-FIGMA-$$"

  PIPELINE_STUB_MODE=missing-figma-specs-artifact PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --start-phase context-intake --no-notify >/dev/null 2>&1 || true

  local run_id run_dir output_file summary
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "missing figma specs run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  output_file="$run_dir/phases/01-context-intake/output.json"

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "missing figma specs should pause the run"
  [[ "$(jq -r '.status' "$output_file")" == "protocol-error" ]] || fail "missing figma specs should become protocol-error"
  summary="$(jq -r '.summary' "$output_file")"
  [[ "$summary" == *"context-packet/figma-specs.json"* ]] \
    || fail "protocol-error summary should mention missing figma specs, got: $summary"
  pass "context intake cannot pass without figma-specs.json"
}

it_start_rejects_missing_target_repo() {
  local ticket="STUB-BAD-REPO-$$"
  local missing_repo="$BASE_DIR/tmp/missing-target-repo-$$"
  local output

  if output="$($RUNNER start --ticket "$ticket" --repo "$missing_repo" --start-phase implement --no-notify 2>&1)"; then
    fail "start should reject a missing target repo"
  fi

  grep -q 'target repo does not exist or is not a directory' <<<"$output" \
    || fail "start error should explain the invalid target repo"
  [[ -z "$(find_run_for_ticket "$ticket")" ]] || fail "start with invalid target repo must not create a run"
  pass "start rejects a missing target repo before creating a run"
}

it_resume_rejects_missing_target_repo() {
  create_fake_repo
  local ticket="STUB-RESUME-BAD-REPO-$$"

  "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --start-phase implement --dry-run --no-notify >/dev/null 2>&1 || true

  local run_id run_dir output
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "resume invalid-repo fixture run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  rm -rf "$LAST_FAKE_REPO"

  if output="$($RUNNER resume "$run_id" --no-notify 2>&1)"; then
    fail "resume should reject a missing target repo"
  fi

  grep -q 'target repo does not exist or is not a directory' <<<"$output" \
    || fail "resume error should explain the invalid target repo"
  pass "resume rejects a missing target repo before rerunning phases"
}

it_pauses_on_repeated_schema_protocol_error() {
  install_pipeline_stub
  local ticket="STUB-SCHEMA-INVALID-$$"

  PIPELINE_STUB_MODE=schema-invalid-output PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --start-phase context-intake --no-notify >/dev/null 2>&1 || true

  local run_id run_dir output_file
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "schema-invalid run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  output_file="$run_dir/phases/01-context-intake/output.json"

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "repeated protocol errors should pause the run"
  [[ "$(jq -r '.status' "$output_file")" == "protocol-error" ]] || fail "schema-invalid output should become protocol-error"
  jq -e '.protocol_error_retries["context-intake"] == 1' "$run_dir/state.json" >/dev/null \
    || fail "schema-invalid output should retry once before pausing"
  grep -q 'repeated protocol errors' "$run_dir/human-request.md" \
    || fail "human request should explain repeated protocol errors"
  pass "schema-invalid protocol errors pause after one retry"
}

it_recovers_from_qa_fail_with_local_safety_loop() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-QA-FAIL-$$"

  PIPELINE_STUB_MODE=qa-fail-once PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null

  local run_id run_dir archive_dir
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "QA fail recovery run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  archive_dir="$BASE_DIR/archive/$run_id"
  created_run_dirs+=("$run_dir")

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "QA fail recovery should finish handoff-complete"
  jq -e '[.phase_history[] | select(.phase == "qa" and .status == "fail")] | length == 1' "$run_dir/state.json" >/dev/null \
    || fail "QA fail recovery should record exactly one QA failure"
  jq -e '.fix_loop_count == 0 and .stale_from_phase == null' "$run_dir/state.json" >/dev/null \
    || fail "QA fail recovery should reset local safety loop state"
  [[ -f "$archive_dir/retention-manifest.json" ]] || fail "QA fail recovery should still compact archive with retention manifest"
  pass "QA failure recovers through local safety loop"
}

it_pauses_when_ui_validation_is_blocked() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-UI-BLOCKED-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "UI blocked run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "UI blocked run should pause"
  [[ "$(jq -r '.current_phase' "$run_dir/state.json")" == "ui-validation" ]] || fail "UI blocked run should pause at ui-validation"
  jq -e '.transition.last_decision.reason == "phase blocked"' "$run_dir/state.json" >/dev/null \
    || fail "UI blocked run should record blocked transition reason"
  grep -q 'preview URL' "$run_dir/human-request.md" || fail "UI blocked human request should ask for preview URL"
  pass "UI validation blocked pauses for human input"
}

it_ingests_whatsapp_reply_and_resumes_run() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-WA-REPLY-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir tmp_dir pending_dir processed_dir failed_dir message_file thread_map metadata_file sent_at
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "WhatsApp reply run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "WhatsApp reply fixture should start from a paused run"

  tmp_dir="$BASE_DIR/tmp/test-whatsapp-reply-$$"
  pending_dir="$tmp_dir/pending"
  processed_dir="$tmp_dir/processed"
  failed_dir="$tmp_dir/failed"
  mkdir -p "$pending_dir" "$processed_dir" "$failed_dir"
  created_tmp_dirs+=("$tmp_dir")
  message_file="$pending_dir/wamid.reply.json"
  thread_map="$tmp_dir/thread-map.jsonl"

  jq -cn --arg message_id "wamid.notification" --arg run_id "$run_id" \
    '{schema_version:"1",message_id:$message_id,run_id:$run_id,sent_at:"2026-05-24T00:00:00Z"}' > "$thread_map"
  jq -n \
    --arg message_id "wamid.reply" \
    --arg context_message_id "wamid.notification" \
    --arg text $'impact: access\nPreview is ready at https://example.test/preview' \
    '{message_id:$message_id,sender:"15551234567",text:$text,timestamp:"1",context_message_id:$context_message_id,received_at:"2026-05-24T00:01:00Z"}' > "$message_file"

  PIPELINE_STUB_MODE=full PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" whatsapp-replies \
    --message-file "$message_file" \
    --processed-dir "$processed_dir" \
    --failed-dir "$failed_dir" \
    --thread-map "$thread_map" \
    --no-notify >/dev/null

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "WhatsApp reply should resume the run to completion"
  [[ -f "$processed_dir/wamid.reply.json" ]] || fail "processed WhatsApp reply should be moved to processed dir"
  [[ ! -f "$failed_dir/wamid.reply.json" ]] || fail "processed WhatsApp reply should not be moved to failed dir"
  metadata_file="$(find "$run_dir/human-inputs" -name '*-answer.metadata.json' -print | sort | tail -n 1)"
  [[ -n "$metadata_file" ]] || fail "WhatsApp reply should write human input metadata"
  jq -e '.source == "whatsapp" and .impact == "access" and (.source_id_hash | length == 64) and (.context_message_id_hash | length == 64) and (.sender_hash | length == 64)' "$metadata_file" >/dev/null \
    || fail "WhatsApp reply metadata should store hashed source identifiers"
  "$RUNNER" redact-check "$run_id" >/dev/null || fail "WhatsApp reply run should pass redact-check"
  pass "WhatsApp reply ingestion resumes mapped run"
}

it_ingests_contextless_whatsapp_reply_when_single_paused_thread_exists() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-WA-CONTEXTLESS-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir tmp_dir pending_dir processed_dir failed_dir message_file thread_map metadata_file
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "contextless WhatsApp reply run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "contextless WhatsApp reply fixture should start paused"

  tmp_dir="$BASE_DIR/tmp/test-whatsapp-contextless-reply-$$"
  pending_dir="$tmp_dir/pending"
  processed_dir="$tmp_dir/processed"
  failed_dir="$tmp_dir/failed"
  mkdir -p "$pending_dir" "$processed_dir" "$failed_dir"
  created_tmp_dirs+=("$tmp_dir")
  message_file="$pending_dir/wamid.contextless-reply.json"
  thread_map="$tmp_dir/thread-map.jsonl"

  sent_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -cn --arg message_id "wamid.notification" --arg run_id "$run_id" --arg sent_at "$sent_at" \
    '{schema_version:"1",message_id:$message_id,run_id:$run_id,sent_at:$sent_at}' > "$thread_map"
  jq -n \
    --arg message_id "wamid.contextless-reply" \
    --arg received_at "$sent_at" \
    --arg text $'impact: access\nPreview is ready at https://example.test/preview' \
    '{message_id:$message_id,sender:"15551234567",text:$text,timestamp:"1",context_message_id:null,received_at:$received_at}' > "$message_file"

  PIPELINE_STUB_MODE=full PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" whatsapp-replies \
    --message-file "$message_file" \
    --processed-dir "$processed_dir" \
    --failed-dir "$failed_dir" \
    --thread-map "$thread_map" \
    --no-notify >/dev/null

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "contextless WhatsApp reply should resume the only paused mapped run"
  [[ -f "$processed_dir/wamid.contextless-reply.json" ]] || fail "contextless WhatsApp reply should move to processed dir"
  metadata_file="$(find "$run_dir/human-inputs" -name '*-answer.metadata.json' -print | sort | tail -n 1)"
  [[ -n "$metadata_file" ]] || fail "contextless WhatsApp reply should write metadata"
  jq -e '.source == "whatsapp" and .impact == "access" and (.context_message_id_hash | not)' "$metadata_file" >/dev/null \
    || fail "contextless WhatsApp reply metadata should omit missing context hash"
  pass "contextless WhatsApp reply resumes the only paused mapped run"
}

it_ingests_whatsapp_reply_with_explicit_dotted_run_id() {
  install_pipeline_stub
  create_fake_repo
  local ticket="onrunning.atlassian.net-browse-STUB-WA-DOTTED-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir tmp_dir pending_dir processed_dir failed_dir message_file thread_map metadata_file answer_file
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "dotted run id WhatsApp reply run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  [[ "$run_id" == *"onrunning.atlassian.net"* ]] || fail "fixture run id should contain dots"
  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "dotted run id WhatsApp fixture should start paused"

  tmp_dir="$BASE_DIR/tmp/test-whatsapp-dotted-run-id-$$"
  pending_dir="$tmp_dir/pending"
  processed_dir="$tmp_dir/processed"
  failed_dir="$tmp_dir/failed"
  mkdir -p "$pending_dir" "$processed_dir" "$failed_dir"
  created_tmp_dirs+=("$tmp_dir")
  message_file="$pending_dir/wamid.dotted-run-id.json"
  thread_map="$tmp_dir/thread-map.jsonl"
  : > "$thread_map"

  jq -n \
    --arg message_id "wamid.dotted-run-id" \
    --arg run_id "$run_id" \
    --arg text $'impact: decision\nrun: __RUN_ID__\n\nProceed with all ticket-listed overlays.' \
    '{message_id:$message_id,sender:"15551234567",text:($text | sub("__RUN_ID__"; $run_id)),timestamp:"1",context_message_id:null,received_at:"2026-05-24T00:01:00Z"}' > "$message_file"

  PIPELINE_STUB_MODE=full PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" whatsapp-replies \
    --message-file "$message_file" \
    --processed-dir "$processed_dir" \
    --failed-dir "$failed_dir" \
    --thread-map "$thread_map" \
    --no-notify >/dev/null

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "explicit dotted run id WhatsApp reply should resume the run"
  [[ -f "$processed_dir/wamid.dotted-run-id.json" ]] || fail "explicit dotted run id reply should move to processed dir"
  [[ ! -f "$failed_dir/wamid.dotted-run-id.json" ]] || fail "explicit dotted run id reply should not move to failed dir"
  metadata_file="$(find "$run_dir/human-inputs" -name '*-answer.metadata.json' -print | sort | tail -n 1)"
  [[ -n "$metadata_file" ]] || fail "explicit dotted run id reply should write metadata"
  jq -e '.source == "whatsapp" and .impact == "decision"' "$metadata_file" >/dev/null \
    || fail "explicit dotted run id reply metadata should keep decision impact"
  answer_file="$run_dir/$(jq -r '.stored_path' "$metadata_file")"
  ! grep -q '^run:' "$answer_file" || fail "explicit dotted run id directive should be stripped from answer body"
  pass "WhatsApp reply resumes explicit dotted run id"
}

it_ingests_plain_whatsapp_reply_when_single_recent_paused_thread_exists() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-WA-PLAIN-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir tmp_dir pending_dir processed_dir failed_dir message_file thread_map
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "plain WhatsApp reply run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")
  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "plain WhatsApp reply fixture should start paused"

  tmp_dir="$BASE_DIR/tmp/test-whatsapp-plain-reply-$$"
  pending_dir="$tmp_dir/pending"
  processed_dir="$tmp_dir/processed"
  failed_dir="$tmp_dir/failed"
  mkdir -p "$pending_dir" "$processed_dir" "$failed_dir"
  created_tmp_dirs+=("$tmp_dir")
  message_file="$pending_dir/wamid.plain-reply.json"
  thread_map="$tmp_dir/thread-map.jsonl"

  jq -cn --arg message_id "wamid.notification" --arg run_id "$run_id" --arg sent_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:"1",message_id:$message_id,run_id:$run_id,sent_at:$sent_at}' > "$thread_map"
  jq -n \
    --arg message_id "wamid.plain-reply" \
    --arg text 'Preview URL is ready at https://example.test/preview' \
    '{message_id:$message_id,sender:"15551234567",text:$text,timestamp:"1",context_message_id:null,received_at:"2026-05-24T00:01:00Z"}' > "$message_file"

  PIPELINE_STUB_MODE=full PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" whatsapp-replies \
    --message-file "$message_file" \
    --processed-dir "$processed_dir" \
    --failed-dir "$failed_dir" \
    --thread-map "$thread_map" \
    --no-notify >/dev/null

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "plain WhatsApp reply should resume the only recent paused mapped run"
  [[ -f "$processed_dir/wamid.plain-reply.json" ]] || fail "plain WhatsApp reply should move to processed dir"
  pass "plain WhatsApp reply resumes the only recent paused mapped run"
}

it_whatsapp_resume_failure_moves_failed_and_continues_batch() {
  install_pipeline_stub
  create_fake_repo
  local bad_ticket="STUB-WA-BAD-RESUME-$$"
  local bad_repo="$LAST_FAKE_REPO"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$bad_ticket" --repo "$bad_repo" --no-notify >/dev/null 2>&1 || true

  local bad_run_id bad_run_dir
  bad_run_id="$(find_run_for_ticket "$bad_ticket")"
  [[ -n "$bad_run_id" ]] || fail "bad WhatsApp resume fixture run should be created"
  bad_run_dir="$BASE_DIR/runs/$bad_run_id"
  created_run_dirs+=("$bad_run_dir")
  [[ "$(jq -r '.status' "$bad_run_dir/state.json")" == "paused" ]] || fail "bad WhatsApp resume fixture should start paused"
  rm -rf "$bad_repo"

  create_fake_repo
  local good_ticket="STUB-WA-GOOD-AFTER-BAD-$$"

  PIPELINE_STUB_MODE=ui-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$good_ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local good_run_id good_run_dir tmp_dir pending_dir processed_dir failed_dir thread_map rc
  good_run_id="$(find_run_for_ticket "$good_ticket")"
  [[ -n "$good_run_id" ]] || fail "good WhatsApp resume fixture run should be created"
  good_run_dir="$BASE_DIR/runs/$good_run_id"
  created_run_dirs+=("$good_run_dir")
  [[ "$(jq -r '.status' "$good_run_dir/state.json")" == "paused" ]] || fail "good WhatsApp resume fixture should start paused"

  tmp_dir="$BASE_DIR/tmp/test-whatsapp-batch-resume-$$"
  pending_dir="$tmp_dir/pending"
  processed_dir="$tmp_dir/processed"
  failed_dir="$tmp_dir/failed"
  thread_map="$tmp_dir/thread-map.jsonl"
  mkdir -p "$pending_dir" "$processed_dir" "$failed_dir"
  created_tmp_dirs+=("$tmp_dir")

  jq -cn --arg message_id "wamid.bad-notification" --arg run_id "$bad_run_id" \
    '{schema_version:"1",message_id:$message_id,run_id:$run_id,sent_at:"2026-05-24T00:00:00Z"}' > "$thread_map"
  jq -cn --arg message_id "wamid.good-notification" --arg run_id "$good_run_id" \
    '{schema_version:"1",message_id:$message_id,run_id:$run_id,sent_at:"2026-05-24T00:00:00Z"}' >> "$thread_map"
  jq -n \
    --arg message_id "wamid.bad-reply" \
    --arg context_message_id "wamid.bad-notification" \
    --arg text $'impact: access\nThis resume should fail because the target repo is gone.' \
    '{message_id:$message_id,sender:"15551234567",text:$text,timestamp:"1",context_message_id:$context_message_id,received_at:"2026-05-24T00:01:00Z"}' > "$pending_dir/001-bad.json"
  jq -n \
    --arg message_id "wamid.good-reply" \
    --arg context_message_id "wamid.good-notification" \
    --arg text $'impact: access\nPreview is ready at https://example.test/preview' \
    '{message_id:$message_id,sender:"15551234567",text:$text,timestamp:"2",context_message_id:$context_message_id,received_at:"2026-05-24T00:02:00Z"}' > "$pending_dir/002-good.json"

  set +e
  PIPELINE_STUB_MODE=full PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" whatsapp-replies \
    --pending-dir "$pending_dir" \
    --processed-dir "$processed_dir" \
    --failed-dir "$failed_dir" \
    --thread-map "$thread_map" \
    --no-notify >/dev/null 2>&1
  rc=$?
  set -e

  [[ "$rc" != "0" ]] || fail "WhatsApp batch should report a failure when one resume fails"
  [[ -f "$failed_dir/001-bad.json" ]] || fail "failed WhatsApp resume should move message to failed dir"
  [[ -f "$processed_dir/002-good.json" ]] || fail "later WhatsApp reply should still be processed"
  [[ "$(jq -r '.status' "$good_run_dir/state.json")" == "handoff-complete" ]] || fail "later WhatsApp reply should resume to completion"
  pass "WhatsApp resume failure moves failed message and continues the batch"
}

it_pauses_when_pr_creation_is_blocked() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-PR-BLOCKED-$$"

  PIPELINE_STUB_MODE=create-pr-blocked PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null 2>&1 || true

  local run_id run_dir
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "PR blocked run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  created_run_dirs+=("$run_dir")

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "paused" ]] || fail "PR blocked run should pause"
  [[ "$(jq -r '.current_phase' "$run_dir/state.json")" == "create-pr" ]] || fail "PR blocked run should pause at create-pr"
  jq -e '.transition.last_decision.reason == "phase blocked"' "$run_dir/state.json" >/dev/null \
    || fail "PR blocked run should record blocked transition reason"
  grep -q 'push access' "$run_dir/human-request.md" || fail "PR blocked human request should ask for repository access"
  pass "PR creation blocked pauses for human input"
}

it_runs_all_phases_with_a_stubbed_executor() {
  install_pipeline_stub
  create_fake_repo
  local ticket="STUB-FULL-$$"

  PATH="$LAST_STUB_DIR:$PATH" "$RUNNER" start --ticket "$ticket" --repo "$LAST_FAKE_REPO" --no-notify >/dev/null

  local run_id run_dir archive_dir phase_count
  run_id="$(find_run_for_ticket "$ticket")"
  [[ -n "$run_id" ]] || fail "full stub run should be created"
  run_dir="$BASE_DIR/runs/$run_id"
  archive_dir="$BASE_DIR/archive/$run_id"
  created_run_dirs+=("$run_dir")

  [[ "$(jq -r '.status' "$run_dir/state.json")" == "handoff-complete" ]] || fail "full stub run should finish handoff-complete"
  [[ "$(jq -r '.pr.url' "$run_dir/state.json")" == "https://example.test/pull/456" ]] || fail "full stub run should sync PR metadata"
  phase_count="$(jq '.phase_history | length' "$run_dir/state.json")"
  [[ "$phase_count" == "11" ]] || fail "full stub run should record 11 phases, got $phase_count"
  [[ -f "$archive_dir/final-state.json" ]] || fail "full stub run should create compact archive"
  [[ -f "$archive_dir/retention-manifest.json" ]] || fail "full stub run should create a retention manifest"
  jq -e '.retained_paths | index("final-state.json")' "$archive_dir/retention-manifest.json" >/dev/null \
    || fail "retention manifest should list compact archive state"
  jq -e '.excluded_categories[] | select(.category == "raw ticket and linked context")' "$archive_dir/retention-manifest.json" >/dev/null \
    || fail "retention manifest should document raw context exclusion"
  [[ ! -e "$archive_dir/context-packet" ]] || fail "compact archive should not include raw context packet"
  [[ ! -e "$archive_dir/phases" ]] || fail "compact archive should not include phase execution logs"
  [[ ! -e "$archive_dir/notifications.log" ]] || fail "compact archive should not include notification payload logs"
  "$RUNNER" redact-check "$run_id" >/dev/null || fail "redact-check should pass on compact full stub run"
  grep -q 'finished' "$run_dir/notifications.log" || fail "full stub run should write notification audit log"
  pass "full 11-phase stub run reaches handoff-complete"
}

it_writes_notify_test_audit_log() {
  rm -f "$BASE_DIR/tmp/notifications.log"

  "$RUNNER" notify-test --no-notify >/dev/null

  [[ -f "$BASE_DIR/tmp/notifications.log" ]] || fail "notify-test should write an audit log"
  grep -q 'Delivery pipeline notify-test' "$BASE_DIR/tmp/notifications.log" \
    || fail "notify-test audit log should include the test message"
  grep -q 'external notification disabled' "$BASE_DIR/tmp/notifications.log" \
    || fail "notify-test --no-notify should record disabled external notification"
  pass "notify-test writes a local audit log"
}

it_whatsapp_adapter_uses_legacy_env_file() {
  local tmp_dir sender config message record thread_map tilde_env_file adapter_output
  tmp_dir="$BASE_DIR/tmp/test-whatsapp-adapter-$$"
  mkdir -p "$tmp_dir"
  created_tmp_dirs+=("$tmp_dir")
  sender="$tmp_dir/sender.sh"
  config="$tmp_dir/notification.local.json"
  message="$tmp_dir/message.txt"
  record="$tmp_dir/record.txt"
  thread_map="$tmp_dir/thread-map.jsonl"

  cat > "$sender" <<STUB
#!/usr/bin/env bash
set -euo pipefail
printf 'recipient=%s\nmessage=%s\n' "\$1" "\$(cat "\$2")" > "$record"
printf '{"messages":[{"id":"wamid.stub-notification"}],"message_status":"accepted"}\n'
STUB
  chmod +x "$sender"
  printf 'WHATSAPP_RECIPIENT=15551234567\n' > "$tmp_dir/.env"
  tilde_env_file="${tmp_dir/#$HOME/~}/.env"
  printf 'Run: test-run-123\n\nadapter test\n' > "$message"
  jq -n \
    --arg command "$sender" \
    --arg env_file "$tilde_env_file" \
    --arg thread_map "$thread_map" \
    '{whatsapp:{command:$command,env_file:$env_file,to_env:"WHATSAPP_RECIPIENT",thread_map_path:$thread_map}}' > "$config"

  adapter_output="$("$BASE_DIR/notifications/whatsapp.sh" --config "$config" --message-file "$message")"

  [[ -z "$adapter_output" ]] || fail "adapter should suppress successful sender output"
  grep -q 'recipient=15551234567' "$record" || fail "adapter should read recipient from legacy env file"
  grep -q 'message=Run: test-run-123' "$record" || fail "adapter should pass the message file to the sender"
  jq -e 'select(.message_id == "wamid.stub-notification" and .run_id == "test-run-123")' "$thread_map" >/dev/null \
    || fail "adapter should store WhatsApp message-id to run-id mapping"
  pass "WhatsApp adapter uses legacy env-file recipient"
}

it_whatsapp_adapter_overrides_env_file_delivery_mode() {
  local tmp_dir sender config message record thread_map tilde_env_file
  tmp_dir="$BASE_DIR/tmp/test-whatsapp-adapter-mode-$$"
  mkdir -p "$tmp_dir"
  created_tmp_dirs+=("$tmp_dir")
  sender="$tmp_dir/sender.sh"
  config="$tmp_dir/notification.local.json"
  message="$tmp_dir/message.txt"
  record="$tmp_dir/record.txt"
  thread_map="$tmp_dir/thread-map.jsonl"

  cat > "$sender" <<STUB
#!/usr/bin/env bash
set -euo pipefail
printf 'mode=%s\ntemplate=%s\nbody_from_file=%s\n' "\${WHATSAPP_MESSAGE_MODE:-}" "\${WHATSAPP_TEMPLATE_NAME:-}" "\${WHATSAPP_TEMPLATE_BODY_FROM_FILE:-}" > "$record"
printf '{"messages":[{"id":"wamid.stub-mode"}],"message_status":"accepted"}\n'
STUB
  chmod +x "$sender"
  cat > "$tmp_dir/.env" <<'ENV'
WHATSAPP_RECIPIENT=15551234567
WHATSAPP_MESSAGE_MODE=template
WHATSAPP_TEMPLATE_NAME=hello_world
WHATSAPP_TEMPLATE_BODY_FROM_FILE=false
ENV
  tilde_env_file="${tmp_dir/#$HOME/~}/.env"
  printf 'Run: test-run-456\n\nadapter mode test\n' > "$message"
  jq -n \
    --arg command "$sender" \
    --arg env_file "$tilde_env_file" \
    --arg thread_map "$thread_map" \
    '{whatsapp:{command:$command,env_file:$env_file,to_env:"WHATSAPP_RECIPIENT",thread_map_path:$thread_map,message_mode:"text",template_name:"",template_body_from_file:"true"}}' > "$config"

  "$BASE_DIR/notifications/whatsapp.sh" --config "$config" --message-file "$message" >/dev/null

  grep -q 'mode=text' "$record" || fail "adapter should let notification config override env-file message mode"
  grep -q 'template=hello_world' "$record" && fail "empty notification template override should clear env-file template name"
  grep -q 'body_from_file=true' "$record" || fail "adapter should apply template body override when configured"
  pass "WhatsApp adapter overrides env-file delivery mode"
}

it_redact_check_flags_basic_auth_urls() {
  local run_id run_dir output
  run_id="test-redact-basic-auth-$$"
  run_dir="$BASE_DIR/runs/$run_id"
  rm -rf "$run_dir"
  mkdir -p "$run_dir/artifacts"
  created_run_dirs+=("$run_dir")
  printf 'preview=https://reviewer:secret@example.test/preview\n' > "$run_dir/artifacts/leak.txt"

  if output="$($RUNNER redact-check "$run_id" 2>&1)"; then
    fail "redact-check should fail when an artifact contains a basic-auth URL"
  fi

  grep -q 'leak.txt' <<<"$output" || fail "redact-check output should identify the leaking artifact"
  pass "redact-check flags basic-auth URLs"
}

it_pauses_when_required_artifacts_are_missing
it_pauses_when_required_schema_artifact_is_invalid_and_omitted
it_pauses_when_context_intake_skips_figma_specs
it_start_rejects_missing_target_repo
it_resume_rejects_missing_target_repo
it_pauses_on_repeated_schema_protocol_error
it_recovers_from_qa_fail_with_local_safety_loop
it_pauses_when_ui_validation_is_blocked
it_ingests_whatsapp_reply_and_resumes_run
it_ingests_contextless_whatsapp_reply_when_single_paused_thread_exists
it_ingests_whatsapp_reply_with_explicit_dotted_run_id
it_ingests_plain_whatsapp_reply_when_single_recent_paused_thread_exists
it_whatsapp_resume_failure_moves_failed_and_continues_batch
it_pauses_when_pr_creation_is_blocked
it_runs_all_phases_with_a_stubbed_executor
it_writes_notify_test_audit_log
it_whatsapp_adapter_uses_legacy_env_file
it_whatsapp_adapter_overrides_env_file_delivery_mode
it_redact_check_flags_basic_auth_urls

printf 'All runner integration tests passed.\n'
