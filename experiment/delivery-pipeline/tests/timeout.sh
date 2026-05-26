#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$BASE_DIR/runner.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

function_file="$(mktemp "$TMPDIR/runner-timeout-functions.XXXXXX")"
trap 'rm -f "$function_file"' EXIT

awk '
  /^timeout_command\(\)/ { capture = 1 }
  /^validate_schema\(\)/ { capture = 0 }
  capture { print }
' "$RUNNER" > "$function_file"

# shellcheck source=/dev/null
source "$function_file"

it_preserves_command_exit_status() {
  local exit_code
  set +e
  run_with_timeout 5 bash -c 'exit 7'
  exit_code=$?
  set -e

  [[ "$exit_code" == "7" ]] || fail "run_with_timeout should preserve command exit status"
  pass "timeout wrapper preserves command exit status"
}

it_times_out_long_running_commands() {
  local exit_code
  set +e
  run_with_timeout 1 bash -c 'while true; do sleep 1; done'
  exit_code=$?
  set -e

  [[ "$exit_code" == "124" ]] || fail "run_with_timeout should return 124 on timeout, got $exit_code"
  pass "timeout wrapper returns 124 on timeout"
}

it_preserves_command_exit_status
it_times_out_long_running_commands

printf 'All timeout fixture tests passed.\n'