#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$BASE_DIR/runner.sh"

created_archives=()
created_runs=()
LAST_CREATED_ARCHIVE_ID=""
LAST_CREATED_ARCHIVE_DIR=""
LAST_CREATED_RUN_DIR=""

cleanup() {
  local path
  for path in "${created_archives[@]:-}" "${created_runs[@]:-}"; do
    rm -rf "$path"
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

past_utc_days() {
  local days="$1"
  if date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d "-${days} days" +%Y-%m-%dT%H:%M:%SZ
  fi
}

future_utc_days() {
  local days="$1"
  if date -u -v+"${days}"d +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v+"${days}"d +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d "+${days} days" +%Y-%m-%dT%H:%M:%SZ
  fi
}

create_archive() {
  local name="$1"
  local delete_after="$2"
  local run_id="test-cleanup-${name}-$$"
  local archive_dir="$BASE_DIR/archive/$run_id"

  rm -rf "$archive_dir"
  mkdir -p "$archive_dir"
  created_archives+=("$archive_dir")

  if [[ "$delete_after" == "null" ]]; then
    jq -n '{retention:{mode:"compact",delete_after:null}}' > "$archive_dir/final-state.json"
  else
    jq -n --arg delete_after "$delete_after" \
      '{retention:{mode:"compact",delete_after:$delete_after}}' > "$archive_dir/final-state.json"
  fi
  printf '# %s\n' "$run_id" > "$archive_dir/summary.md"

  LAST_CREATED_ARCHIVE_ID="$run_id"
  LAST_CREATED_ARCHIVE_DIR="$archive_dir"
}

create_run() {
  local name="$1"
  local status="$2"
  local run_id="test-cleanup-run-${name}-$$"
  local run_dir="$BASE_DIR/runs/$run_id"

  rm -rf "$run_dir"
  mkdir -p "$run_dir/tmp"
  created_runs+=("$run_dir")
  jq -n --arg run_id "$run_id" --arg status "$status" '{run_id:$run_id,status:$status}' > "$run_dir/state.json"
  LAST_CREATED_RUN_DIR="$run_dir"
}

it_does_not_remove_archives_with_future_delete_after() {
  local run_id archive_dir output
  create_archive future "$(future_utc_days 7)"
  run_id="$LAST_CREATED_ARCHIVE_ID"
  archive_dir="$LAST_CREATED_ARCHIVE_DIR"

  output="$("$RUNNER" cleanup 2>&1 || true)"

  [[ -d "$archive_dir" ]] || fail "future delete_after archive should be kept"
  grep -q "$run_id" <<<"$output" && fail "cleanup output should not mention future archives"
  pass "future delete_after archives are kept"
}

it_removes_expired_archives() {
  local run_id archive_dir output
  create_archive expired "$(past_utc_days 1)"
  run_id="$LAST_CREATED_ARCHIVE_ID"
  archive_dir="$LAST_CREATED_ARCHIVE_DIR"

  output="$("$RUNNER" cleanup 2>&1 || true)"

  [[ ! -d "$archive_dir" ]] || fail "expired archive should be removed"
  grep -q "removed.*$run_id" <<<"$output" || fail "cleanup output should announce removal"
  pass "expired archives are removed"
}

it_supports_dry_run_for_expired_archives() {
  local run_id archive_dir output
  create_archive expired-dry "$(past_utc_days 1)"
  run_id="$LAST_CREATED_ARCHIVE_ID"
  archive_dir="$LAST_CREATED_ARCHIVE_DIR"

  output="$("$RUNNER" cleanup --dry-run 2>&1 || true)"

  [[ -d "$archive_dir" ]] || fail "dry run should not remove expired archive"
  grep -q "would remove.*$run_id" <<<"$output" || fail "dry run should announce intended removal"
  pass "dry run reports without removing expired archives"
}

it_removes_a_specific_archive_by_run_id() {
  local target_id kept_id target_dir kept_dir
  create_archive specific-target "$(future_utc_days 14)"
  target_id="$LAST_CREATED_ARCHIVE_ID"
  target_dir="$LAST_CREATED_ARCHIVE_DIR"
  create_archive specific-kept "$(future_utc_days 14)"
  kept_id="$LAST_CREATED_ARCHIVE_ID"
  kept_dir="$LAST_CREATED_ARCHIVE_DIR"

  "$RUNNER" cleanup --run-id "$target_id" >/dev/null

  [[ ! -d "$target_dir" ]] || fail "targeted archive should be removed"
  [[ -d "$kept_dir" ]] || fail "non-targeted archive should remain"
  pass "cleanup --run-id removes only the requested archive"
}

it_ignores_archives_without_delete_after() {
  local run_id archive_dir
  create_archive no-delete-after null
  run_id="$LAST_CREATED_ARCHIVE_ID"
  archive_dir="$LAST_CREATED_ARCHIVE_DIR"

  "$RUNNER" cleanup >/dev/null

  [[ -d "$archive_dir" ]] || fail "archive without delete_after should not be removed without --older-than"
  pass "archives without delete_after are kept unless --older-than is used"
}

it_does_not_remove_run_directories_with_state_file() {
  local run_id run_dir
  run_id="test-cleanup-active-$$"
  run_dir="$BASE_DIR/runs/$run_id"
  mkdir -p "$run_dir"
  created_runs+=("$run_dir")
  printf '{"schema_version":"1","run_id":"%s","status":"running"}\n' "$run_id" > "$run_dir/state.json"

  "$RUNNER" cleanup >/dev/null

  [[ -d "$run_dir" ]] || fail "active run with state.json must never be deleted by safe_gc"
  [[ -f "$run_dir/state.json" ]] || fail "active run state.json must be preserved"
  pass "active runs with state.json are preserved"
}

it_explains_kept_run_directories() {
  local paused_run failed_run output
  create_run explain-paused paused
  paused_run="$LAST_CREATED_RUN_DIR"
  create_run explain-failed failed
  failed_run="$LAST_CREATED_RUN_DIR"

  output="$($RUNNER cleanup --dry-run --explain 2>&1 || true)"

  [[ -d "$paused_run" ]] || fail "paused run should be kept"
  [[ -d "$failed_run" ]] || fail "failed run should be kept"
  grep -q "keep .*$(basename "$paused_run").*--include-stale-runs" <<<"$output" \
    || fail "cleanup --explain should explain paused run retention"
  grep -q "keep .*$(basename "$failed_run").*--include-stale-runs" <<<"$output" \
    || fail "cleanup --explain should explain failed run retention"
  pass "cleanup --explain reports why paused and failed runs are kept"
}

it_removes_stale_failed_runs_only_when_explicit() {
  local failed_run
  create_run stale-failed failed
  failed_run="$LAST_CREATED_RUN_DIR"
  touch -t 202001010000 "$failed_run"

  "$RUNNER" cleanup >/dev/null
  [[ -d "$failed_run" ]] || fail "stale failed run should be kept without explicit stale-run cleanup"

  "$RUNNER" cleanup --include-stale-runs >/dev/null
  [[ ! -d "$failed_run" ]] || fail "stale failed run should be removed with --include-stale-runs"
  pass "stale failed runs require explicit cleanup opt-in"
}

it_does_not_remove_locked_stale_runs() {
  local locked_run output
  create_run locked-failed failed
  locked_run="$LAST_CREATED_RUN_DIR"
  mkdir -p "$locked_run/tmp/run.lock"
  printf '%s\n' "$$" > "$locked_run/tmp/run.lock/pid"
  touch -t 202001010000 "$locked_run"

  output="$($RUNNER cleanup --include-stale-runs --explain 2>&1 || true)"

  [[ -d "$locked_run" ]] || fail "locked stale run should be preserved"
  grep -q "keep .*$(basename "$locked_run").*locked" <<<"$output" \
    || fail "cleanup --explain should report locked run retention"
  pass "locked stale runs are preserved"
}

it_does_not_remove_run_directories_with_state_file
it_explains_kept_run_directories
it_removes_stale_failed_runs_only_when_explicit
it_does_not_remove_locked_stale_runs
it_ignores_archives_without_delete_after
it_does_not_remove_archives_with_future_delete_after
it_removes_expired_archives
it_supports_dry_run_for_expired_archives
it_removes_a_specific_archive_by_run_id

printf 'All cleanup fixture tests passed.\n'
