#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$BASE_DIR/pipeline.json"
TMPDIR="${TMPDIR:-$BASE_DIR/tmp}"
LOCK_DIR="$BASE_DIR/tmp/.runner.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
CURRENT_RUN_LOCK_DIR=""

# shellcheck source=tools/redaction.sh
source "$BASE_DIR/tools/redaction.sh"

mkdir -p "$TMPDIR" "$BASE_DIR/runs" "$BASE_DIR/archive" "$BASE_DIR/tmp"

usage() {
  cat <<'EOF'
Usage:
  runner.sh start --ticket <ticket-or-url> [--repo <path>] [--start-phase <phase-id>] [--model <model>] [--variant <variant>] [--notify|--no-notify] [--dry-run]
  runner.sh resume <run-id> [--answer-file <path>] [--impact access|decision|scope-change] [--notify|--no-notify] [--dry-run]
  runner.sh run-phase <run-id> <phase-id> [--dry-run]
  runner.sh status <run-id>
  runner.sh list
  runner.sh explain-transition <run-id> [--phase <phase-id>] [--status <status>]
  runner.sh cleanup [--dry-run] [--run-id <run-id>] [--older-than <days>d] [--include-stale-runs] [--explain]
  runner.sh notify-test [--notify|--no-notify]
  runner.sh whatsapp-replies [--message-file <path>] [--pending-dir <path>] [--processed-dir <path>] [--failed-dir <path>] [--thread-map <path>] [--notify|--no-notify] [--dry-run]
  runner.sh answer-template <run-id>
  runner.sh redact-check <run-id>
  runner.sh doctor

This is an experimental 11-phase delivery pipeline runner. It keeps all runtime
state under experiment/delivery-pipeline/runs and archive.
EOF
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

hash_value() {
  local value="$1"
  [[ -n "$value" ]] || return 0
  printf '%s' "$value" | shasum -a 256 | awk '{print $1}'
}

default_whatsapp_thread_map() {
  printf '%s/tmp/whatsapp-thread-map.jsonl\n' "$BASE_DIR"
}

future_utc_days() {
  local days="$1"
  if date -u -v+"${days}"d +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v+"${days}"d +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d "+${days} days" +%Y-%m-%dT%H:%M:%SZ
  fi
}

iso_to_epoch() {
  local value="$1"
  if date -u -j -f %Y-%m-%dT%H:%M:%SZ "$value" +%s >/dev/null 2>&1; then
    date -u -j -f %Y-%m-%dT%H:%M:%SZ "$value" +%s
  else
    date -u -d "$value" +%s 2>/dev/null || printf '0\n'
  fi
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's|https?://||; s|[^a-z0-9._-]+|-|g; s|^-+||; s|-+$||' | cut -c1-60
}

require_tool() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "ERROR: required tool not found: $name" >&2
    exit 1
  fi
}

normalize_repo_path_or_exit() {
  local repo_path="$1"
  [[ -n "$repo_path" ]] || return 0

  if [[ ! -d "$repo_path" ]]; then
    echo "ERROR: target repo does not exist or is not a directory: $repo_path" >&2
    exit 1
  fi

  (cd "$repo_path" && pwd -P)
}

validate_run_target_repo_or_exit() {
  local run_dir="$1"
  local repo_path
  repo_path="$(jq -r '.target_repo.path // empty' "$run_dir/state.json")"
  [[ -n "$repo_path" ]] || return 0

  if [[ ! -d "$repo_path" ]]; then
    echo "ERROR: target repo does not exist or is not a directory: $repo_path" >&2
    exit 1
  fi
}

redact_text() {
  delivery_pipeline_redact_text
}

timeout_command() {
  if command -v gtimeout >/dev/null 2>&1; then
    printf 'gtimeout\n'
  elif command -v timeout >/dev/null 2>&1; then
    printf 'timeout\n'
  elif command -v perl >/dev/null 2>&1; then
    printf 'perl\n'
  else
    printf '\n'
  fi
}

run_with_perl_timeout() {
  local seconds="$1"
  shift
  perl -e '
    use strict;
    use warnings;
    use Errno qw(EINTR);
    use POSIX qw(setsid);

    my $seconds = shift @ARGV;
    my @command = @ARGV;
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;

    if ($pid == 0) {
      setsid();
      exec @command;
      die "exec failed: $!\n";
    }

    my $timed_out = 0;
    local $SIG{ALRM} = sub {
      $timed_out = 1;
      kill "TERM", -$pid;
    };

    alarm $seconds;
    while (1) {
      my $done = waitpid($pid, 0);
      last if $done == $pid;
      next if $done == -1 && $! == EINTR;
      last;
    }
    alarm 0;

    if ($timed_out) {
      select undef, undef, undef, 0.2;
      kill "KILL", -$pid;
      waitpid($pid, 0);
      exit 124;
    }

    my $status = $?;
    exit 124 if $status == -1;
    exit 128 + ($status & 127) if $status & 127;
    exit $status >> 8;
  ' "$seconds" "$@"
}

run_with_timeout() {
  local seconds="$1"
  shift
  local timeout_bin
  timeout_bin="$(timeout_command)"
  if [[ -z "$timeout_bin" || -z "$seconds" || "$seconds" == "0" ]]; then
    "$@"
    return $?
  fi

  case "$timeout_bin" in
    gtimeout|timeout)
      "$timeout_bin" --foreground "${seconds}s" "$@"
      ;;
    perl)
      run_with_perl_timeout "$seconds" "$@"
      ;;
    *)
      "$@"
      ;;
  esac
}

validate_schema() {
  local schema_file="$1"
  local data_file="$2"
  local log_file="${3:-}"
  local validator="$BASE_DIR/tools/validate-schema.mjs"

  if [[ ! -f "$validator" ]]; then
    echo "ERROR: schema validator not found: $validator" >&2
    return 2
  fi

  if [[ -n "$log_file" ]]; then
    node "$validator" "$schema_file" "$data_file" > "$log_file" 2>&1
  else
    node "$validator" "$schema_file" "$data_file"
  fi
}

validate_pipeline_config() {
  validate_schema "$BASE_DIR/schemas/pipeline.schema.json" "$CONFIG_FILE" >/dev/null
}

validate_state_file() {
  local state_file="$1"
  validate_schema "$BASE_DIR/schemas/state.schema.json" "$state_file" >/dev/null
}

validate_phase_output_schema() {
  local output_file="$1"
  local log_file="$2"
  validate_schema "$BASE_DIR/schemas/phase-output.schema.json" "$output_file" "$log_file"
}

write_json() {
  local target="$1"
  local tmp_file
  tmp_file="$(mktemp "$TMPDIR/pipeline-json.XXXXXX")"
  cat > "$tmp_file"
  mv "$tmp_file" "$target"
}

release_locks() {
  rm -rf "$LOCK_DIR"
  if [[ -n "$CURRENT_RUN_LOCK_DIR" ]]; then
    rm -rf "$CURRENT_RUN_LOCK_DIR"
  fi
}

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_PID_FILE"
    trap release_locks EXIT
    return 0
  fi

  local existing_pid=""
  if [[ -f "$LOCK_PID_FILE" ]]; then
    existing_pid="$(cat "$LOCK_PID_FILE")"
  fi

  if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "ERROR: runner already active with pid $existing_pid" >&2
    exit 1
  fi

  echo "WARN: clearing stale runner lock" >&2
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR"
  printf '%s\n' "$$" > "$LOCK_PID_FILE"
  trap release_locks EXIT
}

acquire_run_lock() {
  local run_dir="$1"
  local run_lock_dir="$run_dir/tmp/run.lock"
  local run_pid_file="$run_lock_dir/pid"

  mkdir -p "$run_dir/tmp"
  if mkdir "$run_lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "$run_pid_file"
    CURRENT_RUN_LOCK_DIR="$run_lock_dir"
    return 0
  fi

  local existing_pid=""
  if [[ -f "$run_pid_file" ]]; then
    existing_pid="$(cat "$run_pid_file")"
  fi

  if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "ERROR: run already active with pid $existing_pid" >&2
    exit 1
  fi

  rm -rf "$run_lock_dir"
  mkdir "$run_lock_dir"
  printf '%s\n' "$$" > "$run_pid_file"
  CURRENT_RUN_LOCK_DIR="$run_lock_dir"
}

phase_json() {
  local phase_id="$1"
  jq -c --arg id "$phase_id" '.phases[] | select(.id == $id)' "$CONFIG_FILE"
}

phase_exists() {
  local phase_id="$1"
  [[ -n "$(phase_json "$phase_id")" ]]
}

phase_number() {
  phase_json "$1" | jq -r '.number'
}

phase_folder() {
  local phase_id="$1"
  local number
  number="$(phase_number "$phase_id")"
  printf '%02d-%s' "$number" "$phase_id"
}

first_phase() {
  jq -r '.phases | sort_by(.number) | .[0].id' "$CONFIG_FILE"
}

append_run_log() {
  local run_dir="$1"
  local event="$2"
  local phase_id="${3:-}"
  local message="${4:-}"
  local redacted_message
  redacted_message="$(printf '%s' "$message" | redact_text)"
  jq -cn \
    --arg ts "$(now_utc)" \
    --arg event "$event" \
    --arg phase "$phase_id" \
    --arg message "$redacted_message" \
    '{timestamp:$ts,event:$event,phase:$phase,message:$message}' >> "$run_dir/run-log.jsonl"
}

update_state() {
  local run_dir="$1"
  local jq_filter="$2"
  local state_file="$run_dir/state.json"
  local tmp_file
  tmp_file="$(mktemp "$TMPDIR/state.XXXXXX")"
  jq "$jq_filter | .updated_at = \"$(now_utc)\"" "$state_file" > "$tmp_file"
  mv "$tmp_file" "$state_file"
  validate_state_file "$state_file"
}

ensure_run_dirs() {
  local run_dir="$1"
  mkdir -p \
    "$run_dir/context-packet" \
    "$run_dir/implementation-plan" \
    "$run_dir/current-diff" \
    "$run_dir/verdicts" \
    "$run_dir/fix-requests" \
    "$run_dir/pr" \
    "$run_dir/phases" \
    "$run_dir/human-inputs" \
    "$run_dir/artifacts" \
    "$run_dir/tmp"
}

write_initial_state() {
  local run_dir="$1"
  local run_id="$2"
  local ticket="$3"
  local target_repo="$4"
  local start_phase="$5"
  local model_override="${6:-}"
  local variant_override="${7:-}"
  local notify_override="${8:-}"
  local now
  now="$(now_utc)"

  jq -n \
    --arg run_id "$run_id" \
    --arg now "$now" \
    --arg ticket "$ticket" \
    --arg target_repo "$target_repo" \
    --arg start_phase "$start_phase" \
    --arg model_override "$model_override" \
    --arg variant_override "$variant_override" \
    --arg notify_override "$notify_override" \
    '{
      schema_version: "1",
      run_id: $run_id,
      status: "initialized",
      current_phase: $start_phase,
      created_at: $now,
      updated_at: $now,
      input: {
        ticket: $ticket,
        target_repo: (if $target_repo == "" then null else $target_repo end),
        start_phase: $start_phase,
        model_override: (if $model_override == "" then null else $model_override end),
        variant_override: (if $variant_override == "" then null else $variant_override end),
        notify_override: (if $notify_override == "" then null else $notify_override end)
      },
      ticket: { key: null, url: (if ($ticket | test("^https?://")) then $ticket else null end) },
      target_repo: { path: (if $target_repo == "" then null else $target_repo end), branch: null },
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

  validate_state_file "$run_dir/state.json"

  jq -n \
    --arg ticket "$ticket" \
    --arg target_repo "$target_repo" \
    --arg start_phase "$start_phase" \
    '{ticket:$ticket,target_repo:(if $target_repo == "" then null else $target_repo end),start_phase:$start_phase}' > "$run_dir/input.json"
}

notify_event() {
  local run_dir="$1"
  local event="$2"
  local message="$3"
  local redacted_message
  redacted_message="$(printf '%s' "$message" | redact_text)"
  dispatch_notification "$run_dir" "$event" "$redacted_message" ""
  update_state "$run_dir" ".notification.last_event = \"$event\" | .notification.last_sent_at = \"$(now_utc)\""
}

notification_config_path() {
  local configured
  configured="$(jq -r '.notifications.config_path // "notification.local.json"' "$CONFIG_FILE")"
  if [[ "$configured" = /* ]]; then
    printf '%s\n' "$configured"
  else
    printf '%s/%s\n' "$BASE_DIR" "$configured"
  fi
}

notification_override() {
  local run_dir="$1"
  if [[ -n "$run_dir" && -f "$run_dir/state.json" ]]; then
    jq -r '.input.notify_override // empty' "$run_dir/state.json"
  fi
}

notification_event_enabled() {
  local event="$1"
  jq -e --arg event "$event" '(.notifications.events // []) | index($event) != null' "$CONFIG_FILE" >/dev/null
}

notification_external_enabled() {
  local run_dir="$1"
  local override="${2:-}"
  if [[ -z "$override" ]]; then
    override="$(notification_override "$run_dir")"
  fi

  case "$override" in
    enabled) return 0 ;;
    disabled) return 1 ;;
  esac

  jq -e '.notifications.enabled == true' "$CONFIG_FILE" >/dev/null
}

notification_rate_limited() {
  local run_dir="$1"
  local event="$2"

  if [[ -z "$run_dir" || ! -f "$run_dir/state.json" ]]; then
    return 1
  fi

  local rate_limit_seconds last_event last_sent last_epoch now_epoch
  rate_limit_seconds="$(jq -r '.notifications.rate_limit_seconds // 0' "$CONFIG_FILE")"
  if [[ "$rate_limit_seconds" == "0" ]]; then
    return 1
  fi

  last_event="$(jq -r '.notification.last_event // empty' "$run_dir/state.json")"
  last_sent="$(jq -r '.notification.last_sent_at // empty' "$run_dir/state.json")"
  if [[ "$last_event" != "$event" || -z "$last_sent" ]]; then
    return 1
  fi

  last_epoch="$(iso_to_epoch "$last_sent")"
  now_epoch="$(date -u +%s)"
  [[ "$last_epoch" != "0" && $((now_epoch - last_epoch)) -lt "$rate_limit_seconds" ]]
}

notification_log() {
  local log_file="$1"
  local event="$2"
  local message="$3"
  printf '%s [%s] %s\n' "$(now_utc)" "$event" "$message" >> "$log_file"
}

notification_message() {
  local run_dir="$1"
  local event="$2"
  local message="$3"
  local run_id phase resume_command

  if [[ -n "$run_dir" && -f "$run_dir/state.json" ]]; then
    run_id="$(basename "$run_dir")"
    phase="$(jq -r '.current_phase // "-"' "$run_dir/state.json")"
    resume_command="experiment/delivery-pipeline/runner.sh resume $run_id --answer-file <path> --impact access"
  else
    run_id="manual"
    phase="-"
    resume_command="n/a"
  fi

  cat <<EOF | redact_text
Run: $run_id
Event: $event
Phase: $phase
Status: paused and waiting for a human reply

What happened:
$message

What I need from you:
Reply with a short plain-English answer. Put one of these on the first line:
impact: access
impact: decision
impact: scope-change

Example:
impact: access
The sheet is available now. Continue.

Resume:
$resume_command
Path: ${run_dir:-$BASE_DIR}
EOF
}

dispatch_notification() {
  local run_dir="$1"
  local event="$2"
  local message="$3"
  local override="${4:-}"
  local log_file

  if [[ -n "$run_dir" ]]; then
    log_file="$run_dir/notifications.log"
  else
    log_file="$BASE_DIR/tmp/notifications.log"
  fi

  local formatted_message
  formatted_message="$(notification_message "$run_dir" "$event" "$message")"
  notification_log "$log_file" "$event" "$formatted_message"

  if ! notification_external_enabled "$run_dir" "$override"; then
    notification_log "$log_file" "$event" "external notification disabled"
    return 0
  fi

  if ! notification_event_enabled "$event"; then
    notification_log "$log_file" "$event" "event is not configured for external notification"
    return 0
  fi

  if notification_rate_limited "$run_dir" "$event"; then
    notification_log "$log_file" "$event" "external notification rate-limited"
    return 0
  fi

  local config_path
  config_path="$(notification_config_path)"

  jq -c '.notifications.channels[]? | select(.type == "whatsapp" and .mode == "send")' "$CONFIG_FILE" | while IFS= read -r channel; do
    local adapter required message_file
    adapter="$(printf '%s' "$channel" | jq -r '.adapter // "notifications/whatsapp.sh"')"
    required="$(printf '%s' "$channel" | jq -r '.required // false')"
    if [[ "$adapter" != /* ]]; then
      adapter="$BASE_DIR/$adapter"
    fi

    if [[ ! -f "$config_path" ]]; then
      notification_log "$log_file" "$event" "WARN: notification config missing: $config_path"
      if [[ "$required" == "true" ]]; then
        return 1
      fi
      continue
    fi

    if [[ ! -x "$adapter" ]]; then
      notification_log "$log_file" "$event" "WARN: WhatsApp adapter missing or not executable: $adapter"
      if [[ "$required" == "true" ]]; then
        return 1
      fi
      continue
    fi

    message_file="$(mktemp "$TMPDIR/notification-message.XXXXXX")"
    printf '%s\n' "$formatted_message" > "$message_file"
    if "$adapter" --config "$config_path" --message-file "$message_file" 2>&1 | redact_text >> "$log_file"; then
      notification_log "$log_file" "$event" "WhatsApp adapter completed"
    else
      notification_log "$log_file" "$event" "WARN: WhatsApp adapter failed"
      if [[ "$required" == "true" ]]; then
        rm -f "$message_file"
        return 1
      fi
    fi
    rm -f "$message_file"
  done
}

safe_gc() {
  mkdir -p "$BASE_DIR/runs" "$BASE_DIR/archive" "$BASE_DIR/tmp"

  find "$BASE_DIR/tmp" -mindepth 1 -maxdepth 1 -type d -name 'pipeline-*' -mtime +1 -print -exec rm -rf {} + 2>/dev/null || true

  local partial_ttl_hours
  partial_ttl_hours="$(jq -r '.retention.partial_run_ttl_hours // 24' "$CONFIG_FILE")"
  local partial_days=$(( (partial_ttl_hours + 23) / 24 ))
  find "$BASE_DIR/runs" -mindepth 1 -maxdepth 1 -type d -mtime +"$partial_days" ! -exec test -f '{}/state.json' \; -print -exec rm -rf {} + 2>/dev/null || true
}

write_human_request() {
  local run_dir="$1"
  local phase_id="$2"
  local message="$3"
  cat > "$run_dir/human-request.md" <<EOF
# Human Input Needed

- Run: $(basename "$run_dir")
- Phase: $phase_id
- Time: $(now_utc)

What happened:

$message

What to send back:

Write a short plain-language reply. Start the first line with one of:

- `impact: access`
- `impact: decision`
- `impact: scope-change`

Example:

`impact: access`
The sheet is available now. Continue.

Resume with:

\`experiment/delivery-pipeline/runner.sh resume $(basename "$run_dir") --answer-file <path> --impact access\`

Impact choices:

- \`access\`: missing credential, URL, flag, local setup, or other access-only unblock.
- \`decision\`: narrow product/design answer that does not change acceptance criteria.
- \`scope-change\`: acceptance criteria or scope changed; this replays from Planning.

Template:

\`experiment/delivery-pipeline/runner.sh answer-template $(basename "$run_dir")\`
EOF
}

cmd_answer_template() {
  local run_id="${1:-}"
  if [[ -z "$run_id" ]]; then
    echo "ERROR: answer-template requires <run-id>" >&2
    exit 1
  fi

  local run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -f "$run_dir/state.json" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  local phase status human_request
  phase="$(jq -r '.current_phase // .input.start_phase // "-"' "$run_dir/state.json")"
  status="$(jq -r '.status' "$run_dir/state.json")"
  human_request="$run_dir/human-request.md"

  cat <<EOF
# Pipeline Human Answer

- Run: $run_id
- Current status: $status
- Current phase: $phase
- Source: file
- Impact: access

## Answer


## Notes


## Reference

Human request: ${human_request#$BASE_DIR/}

Set impact to one of: access, decision, scope-change. Write the rest in plain English.
EOF
}

write_protocol_error_output() {
  local run_dir="$1"
  local phase_id="$2"
  local message="$3"
  local folder
  folder="$(phase_folder "$phase_id")"
  mkdir -p "$run_dir/phases/$folder"
  jq -n \
    --arg phase "$phase_id" \
    --arg summary "$message" \
    '{schema_version:"1",phase:$phase,status:"protocol-error",summary:$summary,inputs_read:[],artifacts_written:[],evidence:[],fix_requests:[],blockers:[{type:"protocol-error",message:$summary,needed_from_human:"Inspect the phase prompt or runner logs."}],stale_artifacts:[],next_recommendation:"pause-for-human"}' \
    > "$run_dir/phases/$folder/output.json"
}

phase_output_file() {
  local run_dir="$1"
  local phase_id="$2"
  printf '%s/phases/%s/output.json' "$run_dir" "$(phase_folder "$phase_id")"
}

stale_artifacts_from_phase() {
  local phase_id="$1"
  jq -c --arg phase "$phase_id" '
    (.phases[] | select(.id == $phase).number) as $from |
    [
      .phases[] |
      select(.number >= $from) |
      .required_outputs[]?
    ] | unique
  ' "$CONFIG_FILE"
}

combined_stale_artifacts() {
  local run_dir="$1"
  local phase_id="$2"
  local output_file
  output_file="$(phase_output_file "$run_dir" "$phase_id")"
  local configured_stale output_stale
  configured_stale="$(stale_artifacts_from_phase "$phase_id")"
  output_stale="[]"

  if [[ -f "$output_file" ]]; then
    output_stale="$(jq -c '.stale_artifacts // []' "$output_file" 2>/dev/null || printf '[]')"
  fi

  jq -cn --argjson configured "$configured_stale" --argjson output "$output_stale" '$configured + $output | unique'
}

unresolved_fix_request_summary() {
  local run_dir="$1"
  local phase_id="$2"
  local output_file
  output_file="$(phase_output_file "$run_dir" "$phase_id")"

  if [[ ! -f "$output_file" ]] || ! jq -e '(.fix_requests // []) | length > 0' "$output_file" >/dev/null 2>&1; then
    printf 'No structured fix requests were found in the current phase output.'
    return 0
  fi

  jq -r '
    (.fix_requests // []) as $requests |
    ($requests[0:5] | map("- " + .id + " [" + .severity + "] " + .scenario + " Expected: " + .expected + " Actual: " + .actual) | join("\n")) as $summary |
    if ($requests | length) > 5 then
      $summary + "\n- ... " + ((($requests | length) - 5) | tostring) + " more fix request(s) omitted from this short summary."
    else
      $summary
    end
  ' "$output_file"
}

phase_blocker_summary() {
  local run_dir="$1"
  local phase_id="$2"
  local output_file
  output_file="$(phase_output_file "$run_dir" "$phase_id")"

  if [[ ! -f "$output_file" ]] || ! jq -e '(.blockers // []) | length > 0' "$output_file" >/dev/null 2>&1; then
    printf 'No structured blockers were found in the current phase output.'
    return 0
  fi

  jq -r '
    (.blockers // []) as $blockers |
    ($blockers[0:5] | map("- " + .type + ": " + .message + " Needed: " + .needed_from_human) | join("\n")) as $summary |
    if ($blockers | length) > 5 then
      $summary + "\n- ... " + ((($blockers | length) - 5) | tostring) + " more blocker(s) omitted from this short summary."
    else
      $summary
    end
  ' "$output_file"
}

phase_is_pr_validation() {
  case "$1" in
    pr-code-review|pr-qa|pr-ui-validation) return 0 ;;
    *) return 1 ;;
  esac
}

sync_pr_metadata() {
  local run_dir="$1"
  local metadata_file="$run_dir/pr/metadata.json"

  if [[ ! -f "$metadata_file" ]] || ! jq -e . "$metadata_file" >/dev/null 2>&1; then
    return 0
  fi

  local url number tmp_file
  url="$(jq -r '.url // .pr_url // .html_url // empty' "$metadata_file")"
  number="$(jq -r '(.number // .pr_number // empty) | tostring' "$metadata_file")"

  if [[ -z "$url" && -z "$number" ]]; then
    return 0
  fi

  tmp_file="$(mktemp "$TMPDIR/pr-state.XXXXXX")"
  jq \
    --arg url "$url" \
    --arg number "$number" \
    --arg now "$(now_utc)" \
    '.pr.url = (if $url == "" then .pr.url else $url end)
     | .pr.number = (if $number == "" then .pr.number else ($number | tonumber) end)
     | .updated_at = $now' \
    "$run_dir/state.json" > "$tmp_file"
  mv "$tmp_file" "$run_dir/state.json"
  validate_state_file "$run_dir/state.json"
}

latest_human_input_block() {
  local run_dir="$1"
  local metadata_file stored_path answer_file impact answered_phase received_at

  [[ -d "$run_dir/human-inputs" ]] || return 0

  metadata_file="$(find "$run_dir/human-inputs" -maxdepth 1 -type f -name '*-answer.metadata.json' -print 2>/dev/null | sort | tail -n 1)"
  [[ -n "$metadata_file" ]] || return 0

  if ! stored_path="$(jq -r '.stored_path // empty' "$metadata_file" 2>/dev/null)"; then
    return 0
  fi
  [[ -n "$stored_path" ]] || return 0

  answer_file="$run_dir/$stored_path"
  [[ -f "$answer_file" ]] || return 0

  impact="$(jq -r '.impact // "unknown"' "$metadata_file" 2>/dev/null || printf unknown)"
  answered_phase="$(jq -r '.phase // "unknown"' "$metadata_file" 2>/dev/null || printf unknown)"
  received_at="$(jq -r '.received_at // "unknown"' "$metadata_file" 2>/dev/null || printf unknown)"

  cat <<EOF

Latest human input:
- Path: $stored_path
- Impact: $impact
- Phase answered: $answered_phase
- Received: $received_at

Answer:
$(sed -n '1,200p' "$answer_file")
EOF
}

transition_decision() {
  local run_dir="$1"
  local phase_id="$2"
  local phase_status="$3"

  local action="continue" next_phase="" reason="" pause_event="" human_message=""
  local increment_fix_loop="false" reset_fix_loop="false" protocol_retry="false"
  local stale_from_phase="" resume_after="" next_resume_after="" stale_artifacts_json="[]"
  local current_fix_loop max_fix_loops next_fix_loop protocol_retry_count current_stale_from

  current_fix_loop="$(jq -r '.fix_loop_count // 0' "$run_dir/state.json")"
  max_fix_loops="$(jq -r '.max_fix_loops // 3' "$CONFIG_FILE")"
  next_fix_loop="$current_fix_loop"
  protocol_retry_count="$(jq -r --arg phase "$phase_id" '.protocol_error_retries[$phase] // 0' "$run_dir/state.json")"
  current_stale_from="$(jq -r '.stale_from_phase // empty' "$run_dir/state.json")"
  resume_after="$(jq -r '.transition.resume_after_local_safety_loop // empty' "$run_dir/state.json")"

  case "$phase_status" in
    pass|not-applicable)
      if [[ "$phase_id" == "ui-validation" && -n "$current_stale_from" ]]; then
        reset_fix_loop="true"
        if [[ -n "$resume_after" ]]; then
          next_phase="$resume_after"
          reason="local safety loop passed; resuming $resume_after"
        else
          next_phase="$(phase_json "$phase_id" | jq -r '.next_on_pass')"
          reason="local safety loop passed; continuing"
        fi
      else
        next_phase="$(phase_json "$phase_id" | jq -r '.next_on_pass')"
        reason="phase passed"
      fi
      ;;
    fail)
      case "$phase_id" in
        context-intake|plan)
          action="pause"
          next_phase="pause-for-human"
          pause_event="failed"
          reason="phase failed and requires human review"
          human_message="Pipeline paused after $phase_id failed. Inspect phase output, fix requests, and blockers."
          ;;
        create-pr)
          next_fix_loop=$((current_fix_loop + 1))
          if (( next_fix_loop > max_fix_loops )); then
            action="pause"
            next_phase="pause-for-human"
            pause_event="blocked"
            reason="max fix loops exceeded"
            human_message="Max fix loops exceeded after $phase_id failed. Review unresolved fix requests before resuming.

Unresolved fix requests:
$(unresolved_fix_request_summary "$run_dir" "$phase_id")"
          else
            increment_fix_loop="true"
            stale_from_phase="$phase_id"
            stale_artifacts_json="$(combined_stale_artifacts "$run_dir" "$phase_id")"
            next_resume_after="create-pr"
            reason="create-pr checks failed; route to implement, replay local safety loop, then retry create-pr"
            next_phase="implement"
          fi
          ;;
        *)
          next_fix_loop=$((current_fix_loop + 1))
          if (( next_fix_loop > max_fix_loops )); then
            action="pause"
            next_phase="pause-for-human"
            pause_event="blocked"
            reason="max fix loops exceeded"
            human_message="Max fix loops exceeded after $phase_id failed. Review unresolved fix requests before resuming.

Unresolved fix requests:
$(unresolved_fix_request_summary "$run_dir" "$phase_id")"
          else
            increment_fix_loop="true"
            stale_from_phase="$phase_id"
            stale_artifacts_json="$(combined_stale_artifacts "$run_dir" "$phase_id")"
            if phase_is_pr_validation "$phase_id"; then
              next_resume_after="create-pr"
              reason="PR validation failed; fix locally, replay safety loop, update PR, then restart PR validation"
            else
              reason="phase failed; route to implement and replay local safety loop"
            fi
            next_phase="implement"
          fi
          ;;
      esac
      ;;
    blocked)
      action="pause"
      next_phase="pause-for-human"
      pause_event="blocked"
      reason="phase blocked"
      human_message="Pipeline paused because $phase_id is blocked. Inspect phase output and provide the missing input or access.

    Blockers:
    $(phase_blocker_summary "$run_dir" "$phase_id")"
      ;;
    protocol-error)
      if (( protocol_retry_count < 1 )); then
        protocol_retry="true"
        next_phase="$phase_id"
        reason="protocol error; retrying phase once"
      else
        action="pause"
        next_phase="pause-for-human"
        pause_event="pause-for-human"
        reason="repeated protocol error"
        human_message="Pipeline paused because $phase_id produced repeated protocol errors. Inspect phase output and validation logs."
      fi
      ;;
    *)
      action="pause"
      next_phase="pause-for-human"
      pause_event="pause-for-human"
      reason="unknown phase status"
      human_message="Pipeline paused because $phase_id returned an unknown status: $phase_status."
      ;;
  esac

  if [[ "$next_phase" == "finished" ]]; then
    action="finish"
  fi

  jq -cn \
    --arg phase "$phase_id" \
    --arg phase_status "$phase_status" \
    --arg action "$action" \
    --arg next_phase "$next_phase" \
    --arg reason "$reason" \
    --arg pause_event "$pause_event" \
    --arg human_message "$human_message" \
    --arg stale_from_phase "$stale_from_phase" \
    --arg resume_after_local_safety_loop "$next_resume_after" \
    --argjson fix_loop_count "$next_fix_loop" \
    --argjson increment_fix_loop "$increment_fix_loop" \
    --argjson reset_fix_loop "$reset_fix_loop" \
    --argjson protocol_retry "$protocol_retry" \
    --argjson stale_artifacts "$stale_artifacts_json" \
    '{
      phase: $phase,
      status: $phase_status,
      action: $action,
      next_phase: (if $next_phase == "" then null else $next_phase end),
      reason: $reason,
      pause_event: (if $pause_event == "" then null else $pause_event end),
      human_message: (if $human_message == "" then null else $human_message end),
      increment_fix_loop: $increment_fix_loop,
      reset_fix_loop: $reset_fix_loop,
      fix_loop_count: $fix_loop_count,
      stale_from_phase: (if $stale_from_phase == "" then null else $stale_from_phase end),
      stale_artifacts: $stale_artifacts,
      resume_after_local_safety_loop: (if $resume_after_local_safety_loop == "" then null else $resume_after_local_safety_loop end),
      protocol_retry: $protocol_retry
    }'
}

append_transition_log() {
  local run_dir="$1"
  local decision="$2"
  jq -cn \
    --arg ts "$(now_utc)" \
    --argjson decision "$decision" \
    '$decision + {timestamp:$ts,event:"transition"}' >> "$run_dir/run-log.jsonl"
}

apply_transition_decision() {
  local run_dir="$1"
  local decision="$2"
  local tmp_file
  tmp_file="$(mktemp "$TMPDIR/transition-state.XXXXXX")"
  jq \
    --arg now "$(now_utc)" \
    --argjson decision "$decision" \
    '.transition = (.transition // {})
     | .protocol_error_retries = (.protocol_error_retries // {})
     | .stale_artifacts = (.stale_artifacts // [])
     | .transition.last_decision = $decision
     | if $decision.increment_fix_loop then .fix_loop_count = $decision.fix_loop_count else . end
     | if $decision.stale_from_phase != null then
         .stale_from_phase = $decision.stale_from_phase
         | .stale_artifacts = ((.stale_artifacts + $decision.stale_artifacts) | unique)
       else . end
     | if $decision.resume_after_local_safety_loop != null then
         .transition.resume_after_local_safety_loop = $decision.resume_after_local_safety_loop
       else . end
     | if $decision.protocol_retry then
         .protocol_error_retries[$decision.phase] = ((.protocol_error_retries[$decision.phase] // 0) + 1)
       else . end
     | if $decision.reset_fix_loop then
         .fix_loop_count = 0
         | .stale_from_phase = null
         | .stale_artifacts = []
         | .transition.resume_after_local_safety_loop = null
       else . end
     | .updated_at = $now' \
    "$run_dir/state.json" > "$tmp_file"
  mv "$tmp_file" "$run_dir/state.json"
  validate_state_file "$run_dir/state.json"
}

validate_required_outputs() {
  local run_dir="$1"
  local phase_id="$2"
  local phase_status="$3"

  if [[ "$phase_status" != "pass" && "$phase_status" != "not-applicable" ]]; then
    return 0
  fi

  local missing=()
  while IFS= read -r required_path; do
    [[ -z "$required_path" ]] && continue
    if [[ ! -e "$run_dir/$required_path" ]]; then
      missing+=("$required_path")
    fi
  done < <(phase_json "$phase_id" | jq -r '.required_outputs[]?')

  if (( ${#missing[@]} > 0 )); then
    write_protocol_error_output "$run_dir" "$phase_id" "Phase reported $phase_status but missed required artifacts: ${missing[*]}"
    return 1
  fi

  return 0
}

clear_phase_attempt_artifacts() {
  local run_dir="$1"
  local phase_id="$2"
  local output_file="$3"

  rm -f -- "$output_file"

  while IFS= read -r required_path; do
    [[ -z "$required_path" ]] && continue
    case "$required_path" in
      /*|*..*) continue ;;
    esac
    rm -f -- "$run_dir/$required_path"
  done < <(phase_json "$phase_id" | jq -r '.required_outputs[]?')
}

schema_for_artifact() {
  local artifact_path="$1"
  case "$artifact_path" in
    context-packet/acceptance-criteria.json)
      printf '%s/schemas/acceptance-criteria.schema.json\n' "$BASE_DIR"
      ;;
    context-packet/figma-specs.json)
      printf '%s/schemas/figma-specs.schema.json\n' "$BASE_DIR"
      ;;
    fix-requests/*.json)
      printf '%s/schemas/fix-request.schema.json\n' "$BASE_DIR"
      ;;
  esac
}

validate_artifact_schema() {
  local run_dir="$1"
  local phase_id="$2"
  local artifact_path="$3"
  local schema_file
  schema_file="$(schema_for_artifact "$artifact_path")"

  if [[ -z "$schema_file" || ! -f "$schema_file" ]]; then
    return 0
  fi

  local log_file="$run_dir/phases/$(phase_folder "$phase_id")/artifact-validation-error.log"
  if ! validate_schema "$schema_file" "$run_dir/$artifact_path" "$log_file"; then
    write_protocol_error_output "$run_dir" "$phase_id" "Artifact $artifact_path failed schema validation; see phases/$(phase_folder "$phase_id")/artifact-validation-error.log"
    return 1
  fi

  return 0
}

validate_canonical_artifacts() {
  local run_dir="$1"
  local phase_id="$2"
  local output_file
  output_file="$(phase_output_file "$run_dir" "$phase_id")"

  if [[ ! -f "$output_file" ]]; then
    return 0
  fi

  while IFS= read -r artifact_path; do
    [[ -z "$artifact_path" || ! -f "$run_dir/$artifact_path" ]] && continue
    validate_artifact_schema "$run_dir" "$phase_id" "$artifact_path" || return 1
  done < <(
    {
      phase_json "$phase_id" | jq -r '.required_outputs[]?'
      jq -r '.artifacts_written[]?' "$output_file"
    } | awk 'NF && !seen[$0]++'
  )

  if [[ -d "$run_dir/fix-requests" ]]; then
    while IFS= read -r fix_request_file; do
      [[ -z "$fix_request_file" ]] && continue
      local relative_path="${fix_request_file#$run_dir/}"
      validate_artifact_schema "$run_dir" "$phase_id" "$relative_path" || return 1
    done < <(find "$run_dir/fix-requests" -type f -name '*.json' -print)
  fi

  return 0
}

command_attempts_json() {
  local attempts_file="$1"
  if [[ -s "$attempts_file" ]]; then
    jq -s '.' "$attempts_file"
  else
    printf '[]\n'
  fi
}

run_opencode_attempt() {
  local phase_dir="$1"
  local timeout_seconds="$2"
  local work_dir="$3"
  local model="$4"
  local variant="$5"
  local command_path="$6"
  local message="$7"
  local label="$8"
  local skip_permissions="${9:-false}"
  local attempts_file="$phase_dir/command-attempts.jsonl"
  local started finished opencode_rc
  local args=(opencode run --dir "$work_dir" --model "$model" --file "$command_path")

  if [[ "$skip_permissions" == "true" ]]; then
    args+=(--dangerously-skip-permissions)
  fi

  if [[ -n "$variant" && "$variant" != "null" ]]; then
    args+=(--variant "$variant")
  fi
  args+=("$message")

  started="$(now_utc)"
  printf 'attempt=%s model=%s variant=%s started=%s\n' "$label" "$model" "${variant:-null}" "$started" >> "$phase_dir/opencode.log"

  set +e
  run_with_timeout "$timeout_seconds" "${args[@]}" 2>&1 | redact_text >> "$phase_dir/opencode.log"
  opencode_rc=${PIPESTATUS[0]}
  set -e

  finished="$(now_utc)"
  jq -cn \
    --arg label "$label" \
    --arg model "$model" \
    --arg variant "$variant" \
    --arg started "$started" \
    --arg finished "$finished" \
    --argjson exit_code "$opencode_rc" \
    '{label:$label,model:$model,variant:(if $variant == "" or $variant == "null" then null else $variant end),started_at:$started,finished_at:$finished,exit_code:$exit_code}' >> "$attempts_file"

  return "$opencode_rc"
}

run_phase() {
  local run_dir="$1"
  local phase_id="$2"
  local dry_run="$3"

  local phase_cfg command_path model variant timeout_seconds phase_dir target_repo work_dir output_file started_at
  phase_cfg="$(phase_json "$phase_id")"
  command_path="$BASE_DIR/$(printf '%s' "$phase_cfg" | jq -r '.command')"
  model="$(printf '%s' "$phase_cfg" | jq -r '.model // empty')"
  variant="$(printf '%s' "$phase_cfg" | jq -r '.variant // empty')"
  timeout_seconds="$(printf '%s' "$phase_cfg" | jq -r '.timeout_seconds // empty')"
  if [[ -z "$timeout_seconds" ]]; then
    timeout_seconds="$(jq -r '.default_timeout_seconds // empty' "$CONFIG_FILE")"
  fi
  local model_override variant_override fallback_enabled fallback_model fallback_variant opencode_skip_permissions
  model_override="$(jq -r '.input.model_override // empty' "$run_dir/state.json")"
  variant_override="$(jq -r '.input.variant_override // empty' "$run_dir/state.json")"
  fallback_enabled="$(jq -r '.model_fallback.enabled // true' "$CONFIG_FILE")"
  fallback_model="$(jq -r '.model_fallback.model // .default_model.model // empty' "$CONFIG_FILE")"
  fallback_variant="$(jq -r '.model_fallback.variant // .default_model.variant // empty' "$CONFIG_FILE")"
  opencode_skip_permissions="$(jq -r '.opencode.dangerously_skip_permissions // false' "$CONFIG_FILE")"
  if [[ -n "$model_override" ]]; then
    model="$model_override"
  fi
  if [[ -n "$variant_override" ]]; then
    variant="$variant_override"
  fi
  phase_dir="$run_dir/phases/$(phase_folder "$phase_id")"
  output_file="$phase_dir/output.json"
  target_repo="$(jq -r '.target_repo.path // empty' "$run_dir/state.json")"
  work_dir="$BASE_DIR"
  started_at="$(now_utc)"

  if [[ -n "$target_repo" ]]; then
    if [[ ! -d "$target_repo" ]]; then
      echo "ERROR: target repo does not exist or is not a directory: $target_repo" >&2
      exit 1
    fi
    work_dir="$target_repo"
  fi

  mkdir -p "$phase_dir"
  jq -n \
    --arg phase "$phase_id" \
    --arg command "$command_path" \
    --arg model "$model" \
    --arg variant "$variant" \
    --arg timeout "$timeout_seconds" \
    --arg fallback_enabled "$fallback_enabled" \
    --arg fallback_model "$fallback_model" \
    --arg fallback_variant "$fallback_variant" \
    --arg model_override "$model_override" \
    --arg variant_override "$variant_override" \
    --arg dry_run "$dry_run" \
    --arg started "$started_at" \
    --argjson opencode_skip_permissions "$opencode_skip_permissions" \
    --argjson phase_cfg "$phase_cfg" \
    '{
      phase: $phase,
      command_path: $command,
      model: (if $model == "" then null else $model end),
      variant: (if $variant == "" or $variant == "null" then null else $variant end),
      fallback: {
        enabled: ($fallback_enabled == "true"),
        model: (if $fallback_model == "" then null else $fallback_model end),
        variant: (if $fallback_variant == "" or $fallback_variant == "null" then null else $fallback_variant end)
      },
      timeout_seconds: (if $timeout == "" then null else ($timeout|tonumber) end),
      overrides: {
        model: (if $model_override == "" then null else $model_override end),
        variant: (if $variant_override == "" then null else $variant_override end)
      },
      opencode: {
        dangerously_skip_permissions: $opencode_skip_permissions
      },
      dry_run: ($dry_run == "1"),
      started_at: $started,
      attempts: [],
      phase_config: $phase_cfg
    }' > "$phase_dir/command-meta.json"
  update_state "$run_dir" ".status = \"running\" | .current_phase = \"$phase_id\""
  append_run_log "$run_dir" "phase-start" "$phase_id" "Starting phase"

  if [[ ! -f "$command_path" ]]; then
    write_protocol_error_output "$run_dir" "$phase_id" "Command file not found: $command_path"
  elif [[ "$dry_run" == "1" ]]; then
    jq -n \
      --arg phase "$phase_id" \
      --arg command "$command_path" \
      '{schema_version:"1",phase:$phase,status:"blocked",summary:("Dry run: would execute " + $command),inputs_read:[],artifacts_written:[],evidence:[],fix_requests:[],blockers:[{type:"dry-run",message:"Dry run requested.",needed_from_human:"Run again without --dry-run."}],stale_artifacts:[],next_recommendation:"pause-for-human"}' \
      > "$output_file"
  else
    require_tool opencode
    local message latest_human_input
    latest_human_input="$(latest_human_input_block "$run_dir")"
    message="RUN_DIR=$run_dir
STATE_PATH=$run_dir/state.json
INPUT_PATH=$run_dir/input.json
TARGET_REPO=$target_repo
PHASE=$phase_id
  $latest_human_input

Execute only this phase. Write the required output JSON to $output_file."

    local opencode_rc=0 fallback_used="false" effective_model="$model" effective_variant="$variant" attempts_file="$phase_dir/command-attempts.jsonl"
    : > "$phase_dir/opencode.log"
    : > "$attempts_file"

    clear_phase_attempt_artifacts "$run_dir" "$phase_id" "$output_file"
    run_opencode_attempt "$phase_dir" "$timeout_seconds" "$work_dir" "$model" "$variant" "$command_path" "$message" "primary" "$opencode_skip_permissions" || opencode_rc=$?

    if [[ "$opencode_rc" != "0" && "$opencode_rc" != "124" && "$opencode_rc" != "137" && "$fallback_enabled" == "true" && -z "$model_override" && -n "$fallback_model" ]]; then
      if [[ "$fallback_model" != "$model" || "${fallback_variant:-}" != "${variant:-}" ]]; then
        fallback_used="true"
        effective_model="$fallback_model"
        effective_variant="$fallback_variant"
        opencode_rc=0
        clear_phase_attempt_artifacts "$run_dir" "$phase_id" "$output_file"
        run_opencode_attempt "$phase_dir" "$timeout_seconds" "$work_dir" "$fallback_model" "$fallback_variant" "$command_path" "$message" "fallback" "$opencode_skip_permissions" || opencode_rc=$?
      fi
    fi

    local attempts_json meta_tmp_after_attempts
    attempts_json="$(command_attempts_json "$attempts_file")"
    meta_tmp_after_attempts="$(mktemp "$TMPDIR/command-meta.XXXXXX")"
    jq \
      --arg effective_model "$effective_model" \
      --arg effective_variant "$effective_variant" \
      --argjson fallback_used "$fallback_used" \
      --argjson opencode_exit_code "$opencode_rc" \
      --argjson attempts "$attempts_json" \
      '.effective_model = $effective_model
       | .effective_variant = (if $effective_variant == "" or $effective_variant == "null" then null else $effective_variant end)
       | .fallback_used = $fallback_used
       | .opencode_exit_code = $opencode_exit_code
       | .attempts = $attempts' \
      "$phase_dir/command-meta.json" > "$meta_tmp_after_attempts"
    mv "$meta_tmp_after_attempts" "$phase_dir/command-meta.json"

    if [[ "$opencode_rc" == "124" || "$opencode_rc" == "137" ]]; then
      write_protocol_error_output "$run_dir" "$phase_id" "Phase $phase_id timed out after ${timeout_seconds}s"
    elif [[ "$opencode_rc" != "0" ]]; then
      write_protocol_error_output "$run_dir" "$phase_id" "OpenCode command failed for phase $phase_id (exit $opencode_rc)"
    fi
  fi

  if [[ ! -f "$output_file" ]]; then
    write_protocol_error_output "$run_dir" "$phase_id" "Phase did not write output.json"
  elif ! jq -e . "$output_file" >/dev/null 2>&1; then
    write_protocol_error_output "$run_dir" "$phase_id" "Phase wrote invalid JSON output"
  elif ! validate_phase_output_schema "$output_file" "$phase_dir/validation-error.log"; then
    write_protocol_error_output "$run_dir" "$phase_id" "Phase output failed schema validation; see phases/$(phase_folder "$phase_id")/validation-error.log"
  fi

  local phase_status
  phase_status="$(jq -r '.status' "$output_file")"
  if ! validate_required_outputs "$run_dir" "$phase_id" "$phase_status"; then
    phase_status="protocol-error"
  elif ! validate_canonical_artifacts "$run_dir" "$phase_id"; then
    phase_status="protocol-error"
  fi

  if [[ "$phase_id" == "create-pr" && "$phase_status" == "pass" ]]; then
    sync_pr_metadata "$run_dir"
  fi

  local finished_at
  finished_at="$(now_utc)"
  local meta_file="$phase_dir/command-meta.json"
  if [[ -f "$meta_file" ]]; then
    local meta_tmp
    meta_tmp="$(mktemp "$TMPDIR/command-meta.XXXXXX")"
    jq --arg finished "$finished_at" --arg status "$phase_status" \
      '. + {finished_at:$finished, phase_status:$status}' "$meta_file" > "$meta_tmp"
    mv "$meta_tmp" "$meta_file"
  fi
  local tmp_file
  tmp_file="$(mktemp "$TMPDIR/history.XXXXXX")"
  jq \
    --arg phase "$phase_id" \
    --arg phase_status "$phase_status" \
    --arg started "$started_at" \
    --arg finished "$finished_at" \
    --arg output "${output_file#$run_dir/}" \
    --arg command_meta "${meta_file#$run_dir/}" \
    '.phase_history += [{phase:$phase,status:$phase_status,started_at:$started,finished_at:$finished,output:$output,command_meta:$command_meta}] | .updated_at = $finished' \
    "$run_dir/state.json" > "$tmp_file"
  mv "$tmp_file" "$run_dir/state.json"
  validate_state_file "$run_dir/state.json"

  append_run_log "$run_dir" "phase-finish" "$phase_id" "$phase_status"
  printf '%s\n' "$phase_status"
}

prune_bulky_artifacts_after_archive() {
  local run_dir="$1"

  if ! jq -e '.retention.delete_bulky_artifacts_after_archive == true' "$CONFIG_FILE" >/dev/null; then
    return 0
  fi

  find "$run_dir" -type f \( \
    -name '*.png' -o \
    -name '*.jpg' -o \
    -name '*.jpeg' -o \
    -name '*.webp' -o \
    -name '*.mp4' -o \
    -name 'trace.zip' \
  \) -print -delete >> "$run_dir/cleanup.log" 2>/dev/null || true

  find "$run_dir" -type d -name node_modules -prune -print -exec rm -rf {} + >> "$run_dir/cleanup.log" 2>/dev/null || true
}

write_retention_manifest() {
  local archive_dir="$1"
  local run_id="$2"
  local delete_after="$3"
  local generated_at
  generated_at="$(now_utc)"

  jq -n \
    --arg schema_version "1" \
    --arg run_id "$run_id" \
    --arg generated_at "$generated_at" \
    --arg delete_after "$delete_after" \
    '{
      schema_version: $schema_version,
      run_id: $run_id,
      generated_at: $generated_at,
      mode: "compact-archive",
      delete_after: $delete_after,
      retained_paths: [
        "final-state.json",
        "run-log.jsonl",
        "pr-metadata.json",
        "summary.md",
        "final-verdicts/*.json",
        "retention-manifest.json"
      ],
      excluded_categories: [
        {
          category: "raw ticket and linked context",
          examples: ["context-packet/ticket.md", "context-packet/linked-context.md", "context-packet/constraints.md"],
          reason: "may contain private product, customer, or auth-gated context"
        },
        {
          category: "human replies",
          examples: ["human-inputs/*.md", "human-request.md"],
          reason: "may contain credentials, access details, or decision context intended only for the local run"
        },
        {
          category: "phase execution logs",
          examples: ["phases/*/opencode.log", "phases/*/command-meta.json", "phases/*/output.json"],
          reason: "may contain model output, local paths, command details, or copied ticket context"
        },
        {
          category: "notification payloads and local config",
          examples: ["notifications.log", "notification.local.json", "*.local.json", ".env", "secrets/**"],
          reason: "may contain delivery metadata, recipients, or local secret references"
        },
        {
          category: "bulky UI and dependency artifacts",
          examples: ["**/*.png", "**/*.jpg", "**/*.webp", "**/*.mp4", "**/trace.zip", "**/node_modules/**"],
          reason: "large artifacts are local-only and can contain private UI or environment data"
        }
      ],
      sharing_rule: "Share compact archives only after running redact-check; share full run directories only after manual review."
    }' > "$archive_dir/retention-manifest.json"
}

finish_run() {
  local run_dir="$1"
  local run_id
  run_id="$(basename "$run_dir")"
  local keep_days delete_after archive_dir
  keep_days="$(jq -r '.retention.handoff_complete_days // 7' "$CONFIG_FILE")"
  delete_after="$(future_utc_days "$keep_days")"
  archive_dir="$BASE_DIR/archive/$run_id"
  mkdir -p "$archive_dir/final-verdicts"

  cp "$run_dir/state.json" "$archive_dir/final-state.json" 2>/dev/null || true
  cp "$run_dir/run-log.jsonl" "$archive_dir/run-log.jsonl" 2>/dev/null || true
  cp "$run_dir/pr/metadata.json" "$archive_dir/pr-metadata.json" 2>/dev/null || true
  cp "$run_dir/verdicts"/*.json "$archive_dir/final-verdicts/" 2>/dev/null || true
  write_retention_manifest "$archive_dir" "$run_id" "$delete_after"

  cat > "$archive_dir/summary.md" <<EOF
# Delivery Pipeline Run Summary

- Run: $run_id
- Finished: $(now_utc)
- Delete after: $delete_after
- Retention manifest: retention-manifest.json

The 11 delivery phases completed. The PR is ready for human review.
EOF

  update_state "$run_dir" ".status = \"handoff-complete\" | .current_phase = null | .retention.mode = \"compact\" | .retention.archive_path = \"$archive_dir\" | .retention.delete_after = \"$delete_after\""
  validate_state_file "$run_dir/state.json"
  cp "$run_dir/state.json" "$archive_dir/final-state.json" 2>/dev/null || true
  prune_bulky_artifacts_after_archive "$run_dir"
  append_run_log "$run_dir" "finished" "" "handoff-complete"
  notify_event "$run_dir" "finished" "Run $run_id completed. Compact archive kept until $delete_after."
}

run_loop() {
  local run_dir="$1"
  local phase_id="$2"
  local dry_run="$3"

  while true; do
    local phase_status decision action next_phase reason pause_event human_message
    phase_status="$(run_phase "$run_dir" "$phase_id" "$dry_run")"
    decision="$(transition_decision "$run_dir" "$phase_id" "$phase_status")"
    apply_transition_decision "$run_dir" "$decision"
    append_transition_log "$run_dir" "$decision"

    action="$(printf '%s\n' "$decision" | jq -r '.action')"
    next_phase="$(printf '%s\n' "$decision" | jq -r '.next_phase // empty')"
    reason="$(printf '%s\n' "$decision" | jq -r '.reason')"

    if [[ "$action" == "finish" ]]; then
      finish_run "$run_dir"
      return 0
    fi

    if [[ "$action" == "pause" ]]; then
      pause_event="$(printf '%s\n' "$decision" | jq -r '.pause_event // "pause-for-human"')"
      human_message="$(printf '%s\n' "$decision" | jq -r '.human_message // empty')"
      update_state "$run_dir" ".status = \"paused\""
      if [[ -z "$human_message" ]]; then
        human_message="Pipeline paused after $phase_id returned $phase_status. Reason: $reason."
      fi
      write_human_request "$run_dir" "$phase_id" "$human_message"
      notify_event "$run_dir" "$pause_event" "Run $(basename "$run_dir") paused at $phase_id: $reason."
      return 2
    fi

    phase_id="$next_phase"
  done
}

cmd_start() {
  local ticket="" target_repo="" start_phase="" dry_run="0" model_override="" variant_override="" notify_override=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ticket)
        ticket="${2:?Missing --ticket value}"; shift 2 ;;
      --repo)
        target_repo="${2:?Missing --repo value}"; shift 2 ;;
      --start-phase)
        start_phase="${2:?Missing --start-phase value}"; shift 2 ;;
      --model)
        model_override="${2:?Missing --model value}"; shift 2 ;;
      --variant)
        variant_override="${2:?Missing --variant value}"; shift 2 ;;
      --notify)
        notify_override="enabled"; shift ;;
      --no-notify)
        notify_override="disabled"; shift ;;
      --dry-run)
        dry_run="1"; shift ;;
      -h|--help)
        usage; exit 0 ;;
      *)
        echo "ERROR: unknown start argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  if [[ -z "$ticket" ]]; then
    echo "ERROR: --ticket is required" >&2
    exit 1
  fi

  if [[ -z "$start_phase" ]]; then
    start_phase="$(first_phase)"
  fi

  if ! phase_exists "$start_phase"; then
    echo "ERROR: unknown phase: $start_phase" >&2
    exit 1
  fi

  target_repo="$(normalize_repo_path_or_exit "$target_repo")"

  acquire_lock
  safe_gc

  local run_id run_dir
  run_id="$(date -u +%Y%m%d-%H%M%S)-$(slugify "$ticket")"
  run_dir="$BASE_DIR/runs/$run_id"
  mkdir -p "$run_dir"
  ensure_run_dirs "$run_dir"
  acquire_run_lock "$run_dir"
  : > "$run_dir/run-log.jsonl"
  write_initial_state "$run_dir" "$run_id" "$ticket" "$target_repo" "$start_phase" "$model_override" "$variant_override" "$notify_override"
  append_run_log "$run_dir" "run-start" "$start_phase" "ticket=$ticket"

  run_loop "$run_dir" "$start_phase" "$dry_run"
}

cmd_resume() {
  local run_id="${1:-}"
  shift || true
  local answer_file="" answer_impact="access" dry_run="0" notify_override=""
  local answer_source="file" answer_source_id="" answer_context_id="" answer_sender="" answer_sender_hash=""

  if [[ -z "$run_id" ]]; then
    echo "ERROR: resume requires <run-id>" >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --answer-file)
        answer_file="${2:?Missing --answer-file value}"; shift 2 ;;
      --impact)
        answer_impact="${2:?Missing --impact value}"; shift 2 ;;
      --source)
        answer_source="${2:?Missing --source value}"; shift 2 ;;
      --source-id)
        answer_source_id="${2:?Missing --source-id value}"; shift 2 ;;
      --context-id)
        answer_context_id="${2:?Missing --context-id value}"; shift 2 ;;
      --sender)
        answer_sender="${2:?Missing --sender value}"; shift 2 ;;
      --sender-hash)
        answer_sender_hash="${2:?Missing --sender-hash value}"; shift 2 ;;
      --notify)
        notify_override="enabled"; shift ;;
      --no-notify)
        notify_override="disabled"; shift ;;
      --dry-run)
        dry_run="1"; shift ;;
      *)
        echo "ERROR: unknown resume argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  local run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -f "$run_dir/state.json" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  validate_run_target_repo_or_exit "$run_dir"

  acquire_lock
  acquire_run_lock "$run_dir"

  case "$answer_impact" in
    access|decision|scope-change) ;;
    *)
      echo "ERROR: unknown resume impact: $answer_impact" >&2
      exit 1
      ;;
  esac

  case "$answer_source" in
    file|whatsapp) ;;
    *)
      echo "ERROR: unknown resume source: $answer_source" >&2
      exit 1
      ;;
  esac

  if [[ -n "$answer_file" ]]; then
    mkdir -p "$run_dir/human-inputs"
    local answer_stamp answer_target metadata_target answered_phase
    answer_stamp="$(date -u +%Y%m%d-%H%M%S)"
    answer_target="$run_dir/human-inputs/${answer_stamp}-answer.md"
    metadata_target="$run_dir/human-inputs/${answer_stamp}-answer.metadata.json"
    answered_phase="$(jq -r '.current_phase // .input.start_phase // empty' "$run_dir/state.json")"
    cp "$answer_file" "$answer_target"
    local source_id_hash context_id_hash sender_hash
    source_id_hash="$(hash_value "$answer_source_id")"
    context_id_hash="$(hash_value "$answer_context_id")"
    sender_hash="$answer_sender_hash"
    if [[ -z "$sender_hash" ]]; then
      sender_hash="$(hash_value "$answer_sender")"
    fi
    jq -n \
      --arg schema_version "1" \
      --arg source "$answer_source" \
      --arg original_path "$answer_file" \
      --arg stored_path "${answer_target#$run_dir/}" \
      --arg impact "$answer_impact" \
      --arg phase "$answered_phase" \
      --arg received_at "$(now_utc)" \
      --arg source_id_hash "$source_id_hash" \
      --arg context_id_hash "$context_id_hash" \
      --arg sender_hash "$sender_hash" \
      '{schema_version:$schema_version,source:$source,original_path:$original_path,stored_path:$stored_path,impact:$impact,phase:$phase,received_at:$received_at}
       | if $source_id_hash != "" then .source_id_hash = $source_id_hash else . end
       | if $context_id_hash != "" then .context_message_id_hash = $context_id_hash else . end
       | if $sender_hash != "" then .sender_hash = $sender_hash else . end' > "$metadata_target"
    append_run_log "$run_dir" "human-answer" "" "impact=$answer_impact path=${answer_target#$run_dir/}"
  fi

  if [[ -n "$notify_override" ]]; then
    update_state "$run_dir" ".input.notify_override = \"$notify_override\""
  fi

  local phase_id
  if [[ "$answer_impact" == "scope-change" ]]; then
    local stale_artifacts_json tmp_file
    stale_artifacts_json="$(stale_artifacts_from_phase plan)"
    tmp_file="$(mktemp "$TMPDIR/resume-scope.XXXXXX")"
    jq \
      --arg now "$(now_utc)" \
      --argjson stale_artifacts "$stale_artifacts_json" \
      '.status = "running"
       | .current_phase = "plan"
       | .fix_loop_count = 0
       | .stale_from_phase = "plan"
       | .stale_artifacts = $stale_artifacts
       | .protocol_error_retries = {}
       | .transition.resume_after_local_safety_loop = null
       | .updated_at = $now' \
      "$run_dir/state.json" > "$tmp_file"
    mv "$tmp_file" "$run_dir/state.json"
    validate_state_file "$run_dir/state.json"
    append_run_log "$run_dir" "resume-impact" "plan" "scope-change: replaying from planning"
    phase_id="plan"
  else
    phase_id="$(jq -r '.current_phase // .input.start_phase' "$run_dir/state.json")"
    if [[ -z "$phase_id" || "$phase_id" == "null" ]]; then
      phase_id="$(first_phase)"
    fi
    append_run_log "$run_dir" "resume-impact" "$phase_id" "$answer_impact: rerunning blocked/current phase"
  fi

  update_state "$run_dir" ".status = \"running\""
  run_loop "$run_dir" "$phase_id" "$dry_run"
}

lookup_whatsapp_run_id_from_thread() {
  local context_message_id="$1"
  local thread_map="$2"
  [[ -n "$context_message_id" && -f "$thread_map" ]] || return 0

  jq -r --arg context_message_id "$context_message_id" \
    'select(.message_id == $context_message_id) | .run_id // empty' "$thread_map" 2>/dev/null | tail -n 1
}

lookup_single_paused_whatsapp_run_from_thread_map() {
  local thread_map="$1"
  [[ -f "$thread_map" ]] || return 0

  local ttl_seconds="${WHATSAPP_PIPELINE_CONTEXTLESS_REPLY_TTL_SECONDS:-86400}"
  local now_epoch
  now_epoch="$(date -u +%s)"

  local candidates=() seen_run_ids="" run_id sent_at sent_epoch age_seconds run_dir run_status
  while IFS=$'\t' read -r run_id sent_at; do
    [[ -n "$run_id" ]] || continue
    case " $seen_run_ids " in
      *" $run_id "*) continue ;;
    esac
    seen_run_ids="$seen_run_ids $run_id"

    sent_epoch="$(iso_to_epoch "$sent_at")"
    [[ "$sent_epoch" =~ ^[0-9]+$ && "$sent_epoch" != "0" ]] || continue
    age_seconds=$((now_epoch - sent_epoch))
    if (( ttl_seconds > 0 )); then
      if (( age_seconds < -300 || age_seconds > ttl_seconds )); then
        continue
      fi
    fi

    run_dir="$BASE_DIR/runs/$run_id"
    [[ -f "$run_dir/state.json" ]] || continue
    run_status="$(jq -r '.status // empty' "$run_dir/state.json")"
    if [[ "$run_status" == "paused" ]]; then
      candidates+=("$run_id")
    fi
  done < <(jq -sr 'reverse | .[] | [.run_id // "", .sent_at // ""] | @tsv' "$thread_map" 2>/dev/null)

  if (( ${#candidates[@]} == 1 )); then
    printf '%s\n' "${candidates[0]}"
  fi
}

extract_whatsapp_run_id_from_text() {
  perl -ne 'if (/\b(20\d{6}-\d{6}-[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?)\b/) { print lc($1); exit }'
}

extract_whatsapp_impact_from_text() {
  perl -ne '
    if (/^\s*(?:impact|etki)\s*[:=]\s*(access|decision|scope-change)\s*$/i) { print lc($1); exit }
    if (/^\s*\/(access|decision|scope-change)\s*$/i) { print lc($1); exit }
  '
}

strip_whatsapp_reply_directives() {
  perl -0pe '
    s/^\s*(?:impact|etki)\s*[:=]\s*(?:access|decision|scope-change)\s*\n?//gmi;
    s/^\s*\/(?:access|decision|scope-change)\s*\n?//gmi;
    s/^\s*(?:run|run_id|run-id)\s*[:=]\s*20\d{6}-\d{6}-[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?\s*\n?//gmi;
    s/\A\s+|\s+\z//g;
  '
}

move_whatsapp_message_file() {
  local message_file="$1"
  local target_dir="$2"
  [[ -n "$target_dir" ]] || return 0
  mkdir -p "$target_dir"
  mv "$message_file" "$target_dir/$(basename "$message_file")"
}

process_whatsapp_reply_file() {
  local message_file="$1"
  local processed_dir="$2"
  local failed_dir="$3"
  local thread_map="$4"
  local notify_override="$5"
  local dry_run="$6"

  if [[ ! -f "$message_file" ]] || ! jq -e . "$message_file" >/dev/null 2>&1; then
    [[ -f "$message_file" ]] && move_whatsapp_message_file "$message_file" "$failed_dir"
    return 1
  fi

  local message_id context_message_id sender text run_id impact answer_body answer_file run_dir
  message_id="$(jq -r '.message_id // empty' "$message_file")"
  context_message_id="$(jq -r '.context_message_id // empty' "$message_file")"
  sender="$(jq -r '.sender // empty' "$message_file")"
  text="$(jq -r '.text // empty' "$message_file")"
  impact="$(printf '%s\n' "$text" | extract_whatsapp_impact_from_text)"

  run_id="$(lookup_whatsapp_run_id_from_thread "$context_message_id" "$thread_map")"
  if [[ -z "$run_id" ]]; then
    run_id="$(printf '%s\n' "$text" | extract_whatsapp_run_id_from_text)"
  fi
  if [[ -z "$run_id" ]]; then
    run_id="$(lookup_single_paused_whatsapp_run_from_thread_map "$thread_map")"
  fi

  if [[ -z "$run_id" ]]; then
    printf 'No delivery-pipeline run mapping found for WhatsApp message: %s\n' "$(basename "$message_file")" >&2
    return 0
  fi

  run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -f "$run_dir/state.json" ]]; then
    printf 'Mapped delivery-pipeline run does not exist: %s\n' "$run_id" >&2
    move_whatsapp_message_file "$message_file" "$failed_dir"
    return 1
  fi

  if [[ -z "$impact" ]]; then
    impact="access"
  fi

  answer_body="$(printf '%s\n' "$text" | strip_whatsapp_reply_directives)"
  if [[ -z "$answer_body" ]]; then
    answer_body="$text"
  fi

  answer_file="$(mktemp "$TMPDIR/whatsapp-answer.XXXXXX")"
  printf '%s\n' "$answer_body" > "$answer_file"

  local resume_args resume_rc
  resume_args=("$run_id" --answer-file "$answer_file" --impact "$impact" --source whatsapp)
  [[ -n "$message_id" ]] && resume_args+=(--source-id "$message_id")
  [[ -n "$context_message_id" ]] && resume_args+=(--context-id "$context_message_id")
  if [[ -n "$sender" ]]; then
    resume_args+=(--sender-hash "$(hash_value "$sender")")
  fi
  if [[ -n "$notify_override" ]]; then
    resume_args+=("--$notify_override")
  fi
  if [[ "$dry_run" == "1" ]]; then
    resume_args+=(--dry-run)
  fi

  set +e
  "$0" resume "${resume_args[@]}"
  resume_rc=$?
  set -e
  rm -f "$answer_file"

  if [[ "$resume_rc" == "0" || "$resume_rc" == "2" ]]; then
    move_whatsapp_message_file "$message_file" "$processed_dir"
    return 0
  fi

  move_whatsapp_message_file "$message_file" "$failed_dir"
  return "$resume_rc"
}

cmd_whatsapp_replies() {
  local message_file="" pending_dir="" processed_dir="" failed_dir="" thread_map="" notify_override="" dry_run="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --message-file)
        message_file="${2:?Missing --message-file value}"; shift 2 ;;
      --pending-dir)
        pending_dir="${2:?Missing --pending-dir value}"; shift 2 ;;
      --processed-dir)
        processed_dir="${2:?Missing --processed-dir value}"; shift 2 ;;
      --failed-dir)
        failed_dir="${2:?Missing --failed-dir value}"; shift 2 ;;
      --thread-map)
        thread_map="${2:?Missing --thread-map value}"; shift 2 ;;
      --notify)
        notify_override="notify"; shift ;;
      --no-notify)
        notify_override="no-notify"; shift ;;
      --dry-run)
        dry_run="1"; shift ;;
      *)
        echo "ERROR: unknown whatsapp-replies argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  if [[ -z "$thread_map" ]]; then
    thread_map="$(default_whatsapp_thread_map)"
  fi

  if [[ -n "$message_file" ]]; then
    local message_dir
    message_dir="$(cd "$(dirname "$message_file")" && pwd)"
    if [[ -z "$processed_dir" ]]; then
      processed_dir="$message_dir/../processed"
    fi
    if [[ -z "$failed_dir" ]]; then
      failed_dir="$message_dir/../failed"
    fi
    process_whatsapp_reply_file "$message_file" "$processed_dir" "$failed_dir" "$thread_map" "$notify_override" "$dry_run"
    return $?
  fi

  if [[ -z "$pending_dir" ]]; then
    pending_dir="$HOME/.ai-automation/.automation-state/whatsapp-webhook/incoming/pending"
  fi
  if [[ -z "$processed_dir" ]]; then
    processed_dir="$HOME/.ai-automation/.automation-state/whatsapp-webhook/incoming/processed"
  fi
  if [[ -z "$failed_dir" ]]; then
    failed_dir="$HOME/.ai-automation/.automation-state/whatsapp-webhook/incoming/failed"
  fi

  [[ -d "$pending_dir" ]] || return 0

  local found="0" rc="0" pending_file
  while IFS= read -r pending_file; do
    found="1"
    process_whatsapp_reply_file "$pending_file" "$processed_dir" "$failed_dir" "$thread_map" "$notify_override" "$dry_run" || rc="$?"
  done < <(find "$pending_dir" -maxdepth 1 -type f -name '*.json' -print | sort)

  if [[ "$found" == "0" ]]; then
    printf 'No pending WhatsApp replies found.\n'
  fi
  return "$rc"
}

cmd_run_phase() {
  local run_id="${1:-}"
  local phase_id="${2:-}"
  shift 2 2>/dev/null || true
  local dry_run="0"

  if [[ -z "$run_id" || -z "$phase_id" ]]; then
    echo "ERROR: run-phase requires <run-id> <phase-id>" >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run="1"; shift ;;
      *) echo "ERROR: unknown run-phase argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  local run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -f "$run_dir/state.json" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  validate_run_target_repo_or_exit "$run_dir"

  if ! phase_exists "$phase_id"; then
    echo "ERROR: unknown phase: $phase_id" >&2
    exit 1
  fi

  acquire_lock
  acquire_run_lock "$run_dir"
  ensure_run_dirs "$run_dir"
  append_run_log "$run_dir" "run-phase" "$phase_id" "single-phase rerun"

  local phase_status
  phase_status="$(run_phase "$run_dir" "$phase_id" "$dry_run")"

  update_state "$run_dir" ".status = \"paused\""
  printf 'phase=%s status=%s\n' "$phase_id" "$phase_status"
}

latest_command_meta_summary() {
  local run_dir="$1"
  local state_file="$run_dir/state.json"
  local command_meta_path
  command_meta_path="$(jq -r '.phase_history[-1].command_meta // empty' "$state_file")"

  if [[ -z "$command_meta_path" || ! -f "$run_dir/$command_meta_path" ]]; then
    printf 'null\n'
    return 0
  fi

  jq '{
    phase,
    model,
    variant,
    effective_model,
    effective_variant,
    fallback_used: (.fallback_used // false),
    timeout_seconds,
    dry_run,
    phase_status,
    started_at,
    finished_at,
    attempts: (.attempts // [] | map({label, model, variant, exit_code}))
  }' "$run_dir/$command_meta_path"
}

cmd_status() {
  local run_id="${1:-}"
  if [[ -z "$run_id" ]]; then
    echo "ERROR: status requires <run-id>" >&2
    exit 1
  fi

  local state_file="$BASE_DIR/runs/$run_id/state.json"
  if [[ ! -f "$state_file" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  local run_dir meta_summary
  run_dir="$BASE_DIR/runs/$run_id"
  meta_summary="$(latest_command_meta_summary "$run_dir")"
  jq --argjson meta "$meta_summary" '. + {last_command_meta_summary:$meta}' "$state_file"
}

cmd_list() {
  find "$BASE_DIR/runs" -mindepth 2 -maxdepth 2 -name state.json -print | sort | while IFS= read -r state_file; do
    jq -r '[.run_id, .status, (.current_phase // "-"), (.pr.url // "-")] | @tsv' "$state_file"
  done
}

cmd_explain_transition() {
  local run_id="${1:-}"
  shift || true
  local phase_id="" phase_status=""

  if [[ -z "$run_id" ]]; then
    echo "ERROR: explain-transition requires <run-id>" >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --phase)
        phase_id="${2:?Missing --phase value}"; shift 2 ;;
      --status)
        phase_status="${2:?Missing --status value}"; shift 2 ;;
      *)
        echo "ERROR: unknown explain-transition argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  local run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -f "$run_dir/state.json" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  if [[ -z "$phase_id" ]]; then
    phase_id="$(jq -r '(.phase_history[-1].phase // .current_phase // .input.start_phase // empty)' "$run_dir/state.json")"
  fi

  if [[ -z "$phase_id" ]]; then
    echo "ERROR: cannot infer phase for run: $run_id" >&2
    exit 1
  fi

  if [[ -z "$phase_status" ]]; then
    phase_status="$(jq -r '(.phase_history[-1].status // empty)' "$run_dir/state.json")"
  fi

  if [[ -z "$phase_status" ]]; then
    local output_file
    output_file="$(phase_output_file "$run_dir" "$phase_id")"
    if [[ -f "$output_file" ]]; then
      phase_status="$(jq -r '.status // empty' "$output_file")"
    fi
  fi

  if [[ -z "$phase_status" ]]; then
    echo "ERROR: cannot infer phase status for run: $run_id" >&2
    exit 1
  fi

  local meta_summary
  meta_summary="$(latest_command_meta_summary "$run_dir")"
  transition_decision "$run_dir" "$phase_id" "$phase_status" | jq --argjson meta "$meta_summary" '. + {last_command_meta_summary:$meta}'
}

remove_path() {
  local dry_run="$1"
  local path="$2"
  if [[ "$dry_run" == "1" ]]; then
    printf 'would remove %s\n' "$path"
  else
    rm -rf "$path"
    printf 'removed %s\n' "$path"
  fi
}

explain_keep() {
  local enabled="$1"
  local path="$2"
  local reason="$3"
  if [[ "$enabled" == "1" ]]; then
    printf 'keep %s (%s)\n' "$path" "$reason"
  fi
}

run_is_locked() {
  local run_dir="$1"
  local run_lock_dir="$run_dir/tmp/run.lock"
  local run_pid_file="$run_lock_dir/pid"

  if [[ ! -d "$run_lock_dir" ]]; then
    return 1
  fi

  local existing_pid=""
  if [[ -f "$run_pid_file" ]]; then
    existing_pid="$(cat "$run_pid_file")"
  fi

  if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
    return 0
  fi

  rm -rf "$run_lock_dir"
  return 1
}

cleanup_archive_candidate() {
  local archive_path="$1"
  local dry_run="$2"
  local explain="$3"
  local older_than_days="$4"
  local now_epoch="$5"
  local delete_after delete_epoch
  delete_after="$(jq -r '.retention.delete_after // empty' "$archive_path/final-state.json" 2>/dev/null || true)"

  if [[ -n "$older_than_days" ]]; then
    if [[ $(find "$archive_path" -maxdepth 0 -mtime +"$older_than_days" -print) ]]; then
      remove_path "$dry_run" "$archive_path"
    else
      explain_keep "$explain" "$archive_path" "not older than ${older_than_days}d"
    fi
  elif [[ -n "$delete_after" ]]; then
    delete_epoch="$(iso_to_epoch "$delete_after")"
    if [[ "$delete_epoch" != "0" && "$delete_epoch" -lt "$now_epoch" ]]; then
      remove_path "$dry_run" "$archive_path"
    else
      explain_keep "$explain" "$archive_path" "delete_after not reached"
    fi
  else
    explain_keep "$explain" "$archive_path" "no delete_after"
  fi
}

cleanup_run_candidate() {
  local run_path="$1"
  local dry_run="$2"
  local explain="$3"
  local include_stale_runs="$4"
  local state_file="$run_path/state.json"

  if [[ ! -f "$state_file" ]]; then
    explain_keep "$explain" "$run_path" "no state file; startup safe_gc owns partial-run cleanup"
    return 0
  fi

  if run_is_locked "$run_path"; then
    explain_keep "$explain" "$run_path" "locked by active runner"
    return 0
  fi

  local status keep_days
  status="$(jq -r '.status // "unknown"' "$state_file")"
  case "$status" in
    paused)
      keep_days="$(jq -r '.retention.keep_paused_days // 30' "$CONFIG_FILE")"
      ;;
    failed)
      keep_days="$(jq -r '.retention.keep_failed_days // 30' "$CONFIG_FILE")"
      ;;
    *)
      explain_keep "$explain" "$run_path" "status=$status is preserved by cleanup"
      return 0
      ;;
  esac

  if [[ "$include_stale_runs" != "1" ]]; then
    explain_keep "$explain" "$run_path" "status=$status requires --include-stale-runs"
    return 0
  fi

  if [[ $(find "$run_path" -maxdepth 0 -mtime +"$keep_days" -print) ]]; then
    remove_path "$dry_run" "$run_path"
  else
    explain_keep "$explain" "$run_path" "status=$status within ${keep_days}d retention"
  fi
}

cmd_cleanup() {
  local dry_run="0" run_id="" older_than_days="" include_stale_runs="0" explain="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run="1"; shift ;;
      --run-id)
        run_id="${2:?Missing --run-id value}"; shift 2 ;;
      --older-than)
        older_than_days="${2:?Missing --older-than value}"; older_than_days="${older_than_days%d}"; shift 2 ;;
      --include-stale-runs)
        include_stale_runs="1"; shift ;;
      --explain)
        explain="1"; shift ;;
      *)
        echo "ERROR: unknown cleanup argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  safe_gc

  if [[ -n "$run_id" ]]; then
    local archive_path="$BASE_DIR/archive/$run_id"
    if [[ -d "$archive_path" ]]; then
      remove_path "$dry_run" "$archive_path"
    fi
    return 0
  fi

  local now_epoch
  now_epoch="$(date -u +%s)"

  find "$BASE_DIR/archive" -mindepth 1 -maxdepth 1 -type d -print | while IFS= read -r archive_path; do
    cleanup_archive_candidate "$archive_path" "$dry_run" "$explain" "$older_than_days" "$now_epoch"
  done

  find "$BASE_DIR/runs" -mindepth 1 -maxdepth 1 -type d -print | while IFS= read -r run_path; do
    cleanup_run_candidate "$run_path" "$dry_run" "$explain" "$include_stale_runs"
  done
}

cmd_notify_test() {
  local notify_override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --notify)
        notify_override="enabled"; shift ;;
      --no-notify)
        notify_override="disabled"; shift ;;
      *)
        echo "ERROR: unknown notify-test argument: $1" >&2; usage; exit 1 ;;
    esac
  done

  dispatch_notification "" "pause-for-human" "Delivery pipeline notify-test from $(now_utc)." "$notify_override"
  printf 'notify-test complete; audit log: %s\n' "$BASE_DIR/tmp/notifications.log"
}

cmd_redact_check() {
  local run_id="${1:-}"
  if [[ -z "$run_id" ]]; then
    echo "ERROR: redact-check requires <run-id>" >&2
    exit 1
  fi

  local run_dir="$BASE_DIR/runs/$run_id"
  if [[ ! -d "$run_dir" ]]; then
    echo "ERROR: run not found: $run_id" >&2
    exit 1
  fi

  local pattern matches archive_dir scan_paths
  pattern='(https?://[^/[:space:]@]+:[^/[:space:]@]+@|Authorization:|Bearer [A-Za-z0-9._~+/=-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|"wa_id"[[:space:]]*:|wamid\.|(api[_-]?key|access[_-]?token|refresh[_-]?token|token|password|secret)=)'
  archive_dir="$BASE_DIR/archive/$run_id"
  scan_paths=("$run_dir")
  if [[ -d "$archive_dir" ]]; then
    scan_paths+=("$archive_dir")
  fi
  matches="$(LC_ALL=C grep -RIlE "$pattern" "${scan_paths[@]}" 2>/dev/null || true)"

  if [[ -z "$matches" ]]; then
    printf 'redact-check passed: no obvious secret patterns found in %s\n' "$run_id"
    return 0
  fi

  printf 'redact-check found potential secret patterns in:\n' >&2
  printf '%s\n' "$matches" | sed "s|^$run_dir/|- |" >&2
  return 1
}

cmd_doctor() {
  local failures=0

  echo "Delivery pipeline doctor"

  if command -v jq >/dev/null 2>&1; then
    echo "[ok] jq found"
  else
    echo "[fail] jq missing"
    failures=$((failures + 1))
  fi

  if command -v node >/dev/null 2>&1; then
    echo "[ok] node found"
  else
    echo "[fail] node missing"
    failures=$((failures + 1))
  fi

  if [[ -d "$BASE_DIR/node_modules/ajv" ]]; then
    echo "[ok] ajv dependency installed"
  else
    echo "[fail] ajv dependency missing; run: npm install --prefix experiment/delivery-pipeline"
    failures=$((failures + 1))
  fi

  if command -v opencode >/dev/null 2>&1; then
    echo "[ok] opencode found"
  else
    echo "[warn] opencode missing; real phase execution will fail until installed/configured"
  fi

  local timeout_bin
  timeout_bin="$(timeout_command)"
  if [[ -n "$timeout_bin" ]]; then
    echo "[ok] timeout helper available: $timeout_bin"
  else
    echo "[warn] timeout helper missing; per-phase timeouts will be skipped (install coreutils for gtimeout on macOS or ensure perl is available)"
  fi

  if jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "[ok] pipeline.json parses"
  else
    echo "[fail] pipeline.json is invalid JSON"
    failures=$((failures + 1))
  fi

  if validate_schema "$BASE_DIR/schemas/pipeline.schema.json" "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "[ok] pipeline.json validates against schema"
  else
    echo "[fail] pipeline.json schema validation failed"
    failures=$((failures + 1))
  fi

  for schema_path in "$BASE_DIR/schemas/state.schema.json" "$BASE_DIR/schemas/phase-output.schema.json" "$BASE_DIR/schemas/fix-request.schema.json" "$BASE_DIR/schemas/context-packet.schema.json" "$BASE_DIR/schemas/acceptance-criteria.schema.json" "$BASE_DIR/schemas/figma-specs.schema.json"; do
    if [[ -f "$schema_path" ]]; then
      echo "[ok] schema exists: ${schema_path#$BASE_DIR/}"
    else
      echo "[fail] schema missing: ${schema_path#$BASE_DIR/}"
      failures=$((failures + 1))
    fi
  done

  local notification_config
  notification_config="$(notification_config_path)"
  if [[ -f "$notification_config" ]]; then
    echo "[ok] notification config found: ${notification_config#$BASE_DIR/}"
  else
    echo "[warn] notification config missing: ${notification_config#$BASE_DIR/}; WhatsApp sends will be skipped unless local config is added"
  fi

  if [[ -x "$BASE_DIR/notifications/whatsapp.sh" ]]; then
    echo "[ok] WhatsApp adapter executable"
  else
    echo "[warn] WhatsApp adapter is not executable"
  fi

  while IFS= read -r command_path; do
    if [[ -f "$BASE_DIR/$command_path" ]]; then
      echo "[ok] command exists: $command_path"
    else
      echo "[fail] command missing: $command_path"
      failures=$((failures + 1))
    fi
  done < <(jq -r '.phases[].command' "$CONFIG_FILE")

  mkdir -p "$BASE_DIR/runs" "$BASE_DIR/archive" "$BASE_DIR/tmp"
  echo "[ok] runtime directories available"

  if (( failures > 0 )); then
    echo "Doctor found $failures problem(s)."
    return 1
  fi

  echo "Doctor passed."
}

main() {
  require_tool jq

  local command="${1:-}"
  shift || true

  case "$command" in
    -h|--help|help|doctor) ;;
    *) validate_pipeline_config ;;
  esac

  case "$command" in
    doctor) cmd_doctor "$@" ;;
    start) cmd_start "$@" ;;
    resume) cmd_resume "$@" ;;
    status) cmd_status "$@" ;;
    list) cmd_list "$@" ;;
    explain-transition) cmd_explain_transition "$@" ;;
    run-phase) cmd_run_phase "$@" ;;
    cleanup) cmd_cleanup "$@" ;;
    notify-test) cmd_notify_test "$@" ;;
    whatsapp-replies) cmd_whatsapp_replies "$@" ;;
    answer-template) cmd_answer_template "$@" ;;
    redact-check) cmd_redact_check "$@" ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
