#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$BASE_DIR/schemas/phase-output.schema.json"
FIX_REQUEST_SCHEMA="$BASE_DIR/schemas/fix-request.schema.json"
CONTEXT_PACKET_SCHEMA="$BASE_DIR/schemas/context-packet.schema.json"
ACCEPTANCE_CRITERIA_SCHEMA="$BASE_DIR/schemas/acceptance-criteria.schema.json"
FIGMA_SPECS_SCHEMA="$BASE_DIR/schemas/figma-specs.schema.json"
VALIDATOR="$BASE_DIR/tools/validate-schema.mjs"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/pipeline-schema-tests.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

write_fixture() {
  local name="$1"
  local body="$2"
  local path="$tmp_root/$name.json"
  printf '%s\n' "$body" > "$path"
  printf '%s\n' "$path"
}

expect_valid() {
  local label="$1"
  local fixture="$2"
  if ! node "$VALIDATOR" "$SCHEMA" "$fixture" >/dev/null 2>&1; then
    node "$VALIDATOR" "$SCHEMA" "$fixture" >&2 || true
    fail "$label"
  fi
  pass "$label"
}

expect_invalid() {
  local label="$1"
  local fixture="$2"
  if node "$VALIDATOR" "$SCHEMA" "$fixture" >/dev/null 2>&1; then
    fail "$label"
  fi
  pass "$label"
}

base_pass='{
  "schema_version": "1",
  "phase": "qa",
  "status": "pass",
  "summary": "ok",
  "inputs_read": [],
  "artifacts_written": [],
  "evidence": [],
  "fix_requests": [],
  "blockers": [],
  "stale_artifacts": [],
  "next_recommendation": "continue"
}'

fix_request='{
  "id": "QA-001",
  "source_phase": "qa",
  "severity": "high",
  "acceptance_criteria": ["AC-1"],
  "scenario": "User submits form.",
  "expected": "Validation blocks submission.",
  "actual": "Form submits.",
  "reproduction": ["open form", "submit"],
  "suggested_direction": "Add validation."
}'

blocker='{
  "type": "needs-access",
  "message": "Cannot reach staging.",
  "needed_from_human": "Share VPN credentials."
}'

valid_fail=$(printf '%s' "$base_pass" | jq --argjson fr "$fix_request" '.status="fail" | .fix_requests=[$fr] | .next_recommendation="fix"')
fail_no_evidence=$(printf '%s' "$base_pass" | jq '.status="fail" | .next_recommendation="fix"')
valid_blocked=$(printf '%s' "$base_pass" | jq --argjson b "$blocker" '.status="blocked" | .blockers=[$b] | .next_recommendation="pause-for-human"')
blocked_no_blockers=$(printf '%s' "$base_pass" | jq '.status="blocked" | .next_recommendation="pause-for-human"')
unknown_status=$(printf '%s' "$base_pass" | jq '.status="totally-broken"')
bad_schema_version=$(printf '%s' "$base_pass" | jq '.schema_version="2"')
missing_status=$(printf '%s' "$base_pass" | jq 'del(.status)')
missing_summary=$(printf '%s' "$base_pass" | jq 'del(.summary)')
unknown_phase=$(printf '%s' "$base_pass" | jq '.phase="not-a-phase"')
bad_severity=$(printf '%s' "$base_pass" | jq --argjson fr "$fix_request" '.status="fail" | .fix_requests=[($fr | .severity="catastrophic")] | .next_recommendation="fix"')
extra_field=$(printf '%s' "$base_pass" | jq '. + {unexpected_field: true}')
valid_protocol_error=$(printf '%s' "$base_pass" | jq --argjson b "$blocker" '.status="protocol-error" | .blockers=[$b] | .next_recommendation="pause-for-human"')
protocol_error_no_blockers=$(printf '%s' "$base_pass" | jq '.status="protocol-error" | .next_recommendation="pause-for-human"')

expect_valid "valid pass output is accepted" "$(write_fixture valid_pass "$base_pass")"
expect_valid "fail with at least one fix_request is accepted" "$(write_fixture valid_fail "$valid_fail")"
expect_valid "blocked with at least one blocker is accepted" "$(write_fixture valid_blocked "$valid_blocked")"
expect_valid "protocol-error with at least one blocker is accepted" "$(write_fixture valid_protocol_error "$valid_protocol_error")"

expect_invalid "fail without fix_requests or blockers is rejected" "$(write_fixture fail_no_evidence "$fail_no_evidence")"
expect_invalid "blocked without blockers is rejected" "$(write_fixture blocked_no_blockers "$blocked_no_blockers")"
expect_invalid "protocol-error without blockers is rejected" "$(write_fixture protocol_error_no_blockers "$protocol_error_no_blockers")"
expect_invalid "unknown status value is rejected" "$(write_fixture unknown_status "$unknown_status")"
expect_invalid "non-1 schema_version is rejected" "$(write_fixture bad_schema_version "$bad_schema_version")"
expect_invalid "missing status field is rejected" "$(write_fixture missing_status "$missing_status")"
expect_invalid "missing summary field is rejected" "$(write_fixture missing_summary "$missing_summary")"
expect_invalid "unknown phase id is rejected" "$(write_fixture unknown_phase "$unknown_phase")"
expect_invalid "fix_request with invalid severity is rejected" "$(write_fixture bad_severity "$bad_severity")"
expect_invalid "additional top-level field is rejected" "$(write_fixture extra_field "$extra_field")"

valid_fix_request='{
  "schema_version": "1",
  "id": "QA-001",
  "source_phase": "qa",
  "severity": "high",
  "acceptance_criteria": ["AC-1"],
  "scenario": "User submits the form.",
  "expected": "Validation blocks submission.",
  "actual": "Submission proceeds.",
  "reproduction": ["Open form", "Submit"],
  "suggested_direction": "Add required validation."
}'
invalid_fix_request=$(printf '%s' "$valid_fix_request" | jq 'del(.schema_version)')
valid_acceptance_criteria='[
  { "id": "AC-1", "text": "Fixture behavior is delivered.", "source": "test" }
]'
invalid_acceptance_criteria='[
  { "id": "1", "text": "Missing normalized AC id." }
]'
valid_context_packet='{
  "schema_version": "1",
  "ticket": "TEST-1",
  "acceptance_criteria": [
    { "id": "AC-1", "text": "Fixture behavior is delivered." }
  ]
}'
invalid_context_packet='{ "unexpected": true }'
invalid_context_packet_nested_figma='{
  "schema_version": "1",
  "figma_specs": { "foo": "bar" }
}'
valid_figma_unavailable='{
  "available": false,
  "reason": "no Figma link found"
}'
valid_figma_structured='{
  "available": true,
  "source": "https://figma.example/file/abc",
  "node": "1:2",
  "screens": [
    {
      "name": "Checkout form",
      "node": "1:2",
      "bounds": { "x": 0, "y": 0, "width": 390, "height": 844 },
      "spacing": { "gap": 16 },
      "typography": [{ "role": "heading", "fontSize": 24 }],
      "colors": [{ "role": "background", "hex": "#ffffff" }]
    }
  ]
}'
invalid_figma_bogus='{ "foo": "bar" }'
invalid_figma_url_only='{
  "available": true,
  "source": "https://figma.example/file/abc"
}'

if ! node "$VALIDATOR" "$FIX_REQUEST_SCHEMA" "$(write_fixture valid_fix_request "$valid_fix_request")" >/dev/null 2>&1; then
  fail "valid fix-request artifact is accepted"
fi
pass "valid fix-request artifact is accepted"

if node "$VALIDATOR" "$FIX_REQUEST_SCHEMA" "$(write_fixture invalid_fix_request "$invalid_fix_request")" >/dev/null 2>&1; then
  fail "fix-request artifact without schema_version is rejected"
fi
pass "fix-request artifact without schema_version is rejected"

if ! node "$VALIDATOR" "$ACCEPTANCE_CRITERIA_SCHEMA" "$(write_fixture valid_acceptance_criteria "$valid_acceptance_criteria")" >/dev/null 2>&1; then
  fail "valid acceptance criteria artifact is accepted"
fi
pass "valid acceptance criteria artifact is accepted"

if node "$VALIDATOR" "$ACCEPTANCE_CRITERIA_SCHEMA" "$(write_fixture invalid_acceptance_criteria "$invalid_acceptance_criteria")" >/dev/null 2>&1; then
  fail "acceptance criteria artifact with non-normalized id is rejected"
fi
pass "acceptance criteria artifact with non-normalized id is rejected"

if ! node "$VALIDATOR" "$CONTEXT_PACKET_SCHEMA" "$(write_fixture valid_context_packet "$valid_context_packet")" >/dev/null 2>&1; then
  fail "valid aggregate context packet is accepted"
fi
pass "valid aggregate context packet is accepted"

if node "$VALIDATOR" "$CONTEXT_PACKET_SCHEMA" "$(write_fixture invalid_context_packet "$invalid_context_packet")" >/dev/null 2>&1; then
  fail "bogus aggregate context packet is rejected"
fi
pass "bogus aggregate context packet is rejected"

if node "$VALIDATOR" "$CONTEXT_PACKET_SCHEMA" "$(write_fixture invalid_context_packet_nested_figma "$invalid_context_packet_nested_figma")" >/dev/null 2>&1; then
  fail "aggregate context packet with bogus Figma specs is rejected"
fi
pass "aggregate context packet with bogus Figma specs is rejected"

if ! node "$VALIDATOR" "$FIGMA_SPECS_SCHEMA" "$(write_fixture valid_figma_unavailable "$valid_figma_unavailable")" >/dev/null 2>&1; then
  fail "valid unavailable Figma specs artifact is accepted"
fi
pass "valid unavailable Figma specs artifact is accepted"

if ! node "$VALIDATOR" "$FIGMA_SPECS_SCHEMA" "$(write_fixture valid_figma_structured "$valid_figma_structured")" >/dev/null 2>&1; then
  fail "valid structured Figma specs artifact is accepted"
fi
pass "valid structured Figma specs artifact is accepted"

if node "$VALIDATOR" "$FIGMA_SPECS_SCHEMA" "$(write_fixture invalid_figma_bogus "$invalid_figma_bogus")" >/dev/null 2>&1; then
  fail "bogus Figma specs artifact is rejected"
fi
pass "bogus Figma specs artifact is rejected"

if node "$VALIDATOR" "$FIGMA_SPECS_SCHEMA" "$(write_fixture invalid_figma_url_only "$invalid_figma_url_only")" >/dev/null 2>&1; then
  fail "available Figma specs without structured screens or components are rejected"
fi
pass "available Figma specs without structured screens or components are rejected"

printf 'All schema failure-path tests passed.\n'
