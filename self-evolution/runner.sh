#!/usr/bin/env bash
set -euo pipefail

# ─── Generic job runner ──────────────────────────────────────────────
# Usage: runner.sh <job-name>
# Reads jobs/<job-name>/job.json for config, runs OpenCode with the
# job's command.md prompt against the target directory.

JOB_NAME="${1:?Usage: runner.sh <job-name>}"
AUTOMATION_DIR="$(cd "$(dirname "$0")" && pwd)"
JOB_DIR="$AUTOMATION_DIR/jobs/$JOB_NAME"
JOB_FILE="$JOB_DIR/job.json"

if [[ ! -f "$JOB_FILE" ]]; then
  echo "ERROR: Job config not found: $JOB_FILE" >&2
  exit 1
fi

# ─── Read job config ─────────────────────────────────────────────────
TARGET_DIR=$(jq -r '.target_dir' "$JOB_FILE" | sed "s|~|$HOME|")
COMMAND_NAME=$(jq -r '.command_name // empty' "$JOB_FILE")
COMMAND_FILE="$JOB_DIR/command.md"
MODEL=$(jq -r '.model' "$JOB_FILE")
VARIANT=$(jq -r '.variant // empty' "$JOB_FILE")
TIMEOUT=$(jq -r '.timeout // 900' "$JOB_FILE")
ROTATION_FILE="$JOB_DIR/rotation.json"
RUNNER_LOG="$JOB_DIR/logs/runner.log"
LOCK_DIR="$JOB_DIR/logs/.runner.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
RERUN_FLAG_FILE="$JOB_DIR/logs/.runner.rerun"
STATE_DIR="$HOME/.ai-shared-state/self-evolution/$JOB_NAME"
SOURCE_RUN_LOG="$JOB_DIR/run-log.jsonl"
PENDING_RUN_LOG="$STATE_DIR/run-log.pending.jsonl"
SOURCE_CHECKOUT="$TARGET_DIR"
RUN_DIR="$TARGET_DIR"
TEMP_WORKTREE=""
USED_TEMP_WORKTREE=0
RUNTIME_DIR=""
RUNTIME_HISTORY_FILE=""
RUNTIME_RUN_LOG_OUTPUT=""
RUNTIME_POLICY_FILE=""

# ─── Ensure paths ────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nvm/versions/node/v22.17.0/bin:$PATH"
mkdir -p "$JOB_DIR/logs" "$STATE_DIR"

release_lock() {
  rm -rf "$LOCK_DIR"
}

cleanup_temp_worktree() {
  if [[ -z "$TEMP_WORKTREE" ]]; then
    return 0
  fi

  if git -C "$SOURCE_CHECKOUT" worktree remove --force "$TEMP_WORKTREE" >/dev/null 2>&1; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) CLEANUP run=$RUN_ID job=$JOB_NAME worktree-removed path=$TEMP_WORKTREE" >> "$RUNNER_LOG"
  else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN run=$RUN_ID job=$JOB_NAME worktree-remove-failed path=$TEMP_WORKTREE" >> "$RUNNER_LOG"
  fi

  rm -rf "$TEMP_WORKTREE" 2>/dev/null || true
  TEMP_WORKTREE=""
}

cleanup_runner() {
  cleanup_temp_worktree
  release_lock
}

merge_pending_run_log() {
  if [[ ! -s "$PENDING_RUN_LOG" ]]; then
    return 0
  fi

  cat "$PENDING_RUN_LOG" >> "$SOURCE_RUN_LOG"
  : > "$PENDING_RUN_LOG"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO run=$RUN_ID job=$JOB_NAME pending-run-log-merged" >> "$RUNNER_LOG"
}

build_merged_history() {
  local output_file="$1"
  : > "$output_file"

  if [[ -f "$SOURCE_RUN_LOG" ]]; then
    cat "$SOURCE_RUN_LOG" >> "$output_file"
  fi

  if [[ -s "$PENDING_RUN_LOG" ]]; then
    cat "$PENDING_RUN_LOG" >> "$output_file"
  fi
}

flush_temp_run_log() {
  if [[ -z "$RUNTIME_RUN_LOG_OUTPUT" || ! -s "$RUNTIME_RUN_LOG_OUTPUT" ]]; then
    return 0
  fi

  cat "$RUNTIME_RUN_LOG_OUTPUT" >> "$PENDING_RUN_LOG"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO run=$RUN_ID job=$JOB_NAME temp-run-log-flushed" >> "$RUNNER_LOG"
}

prepare_run_environment() {
  export SELF_EVOLUTION_POLICY_PATH="$AUTOMATION_DIR/policy.md"
  export SELF_EVOLUTION_RUN_LOG_PATH="$SOURCE_RUN_LOG"
  export SELF_EVOLUTION_HISTORY_PATH="$SOURCE_RUN_LOG"

  if ! git -C "$SOURCE_CHECKOUT" rev-parse --show-toplevel >/dev/null 2>&1; then
    return 0
  fi

  local git_status=""
  git_status=$(git -C "$SOURCE_CHECKOUT" status --porcelain)

  if [[ -z "$git_status" ]]; then
    merge_pending_run_log
    export SELF_EVOLUTION_HISTORY_PATH="$SOURCE_RUN_LOG"
    return 0
  fi

  TEMP_WORKTREE=$(mktemp -d "${TMPDIR:-/tmp}/self-evolution-$RUN_ID.XXXXXX")
  TEMP_WORKTREE=$(cd "$TEMP_WORKTREE" && pwd -P)

  if ! git -C "$SOURCE_CHECKOUT" worktree add --detach "$TEMP_WORKTREE" HEAD >/dev/null 2>&1; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR run=$RUN_ID job=$JOB_NAME worktree-create-failed" >> "$RUNNER_LOG"
    rm -rf "$TEMP_WORKTREE" 2>/dev/null || true
    TEMP_WORKTREE=""
    return 1
  fi

  RUN_DIR="$TEMP_WORKTREE"
  USED_TEMP_WORKTREE=1
  RUNTIME_DIR="$TEMP_WORKTREE/.self-evolution-runtime"
  RUNTIME_HISTORY_FILE="$RUNTIME_DIR/run-log.history.jsonl"
  RUNTIME_RUN_LOG_OUTPUT="$RUNTIME_DIR/run-log.out.jsonl"
  RUNTIME_POLICY_FILE="$RUNTIME_DIR/policy.md"
  mkdir -p "$RUNTIME_DIR"
  build_merged_history "$RUNTIME_HISTORY_FILE"
  cp "$AUTOMATION_DIR/policy.md" "$RUNTIME_POLICY_FILE"
  : > "$RUNTIME_RUN_LOG_OUTPUT"
  export SELF_EVOLUTION_TEMP_WORKTREE=1
  export SELF_EVOLUTION_RUN_LOG_PATH="$RUNTIME_RUN_LOG_OUTPUT"
  export SELF_EVOLUTION_HISTORY_PATH="$RUNTIME_HISTORY_FILE"
  export SELF_EVOLUTION_POLICY_PATH="$RUNTIME_POLICY_FILE"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO run=$RUN_ID job=$JOB_NAME isolated-run path=$TEMP_WORKTREE run_log=$RUNTIME_RUN_LOG_OUTPUT" >> "$RUNNER_LOG"
}

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_PID_FILE"
    trap release_lock EXIT
    return 0
  fi

  local existing_pid=""
  local existing_command=""

  if [[ -f "$LOCK_PID_FILE" ]]; then
    existing_pid=$(<"$LOCK_PID_FILE")
    if [[ "$existing_pid" =~ ^[0-9]+$ ]]; then
      existing_command=$(ps -p "$existing_pid" -o command= 2>/dev/null || true)
    fi
  fi

  if [[ -n "$existing_command" && "$existing_command" == *"$AUTOMATION_DIR/runner.sh $JOB_NAME"* ]]; then
    touch "$RERUN_FLAG_FILE"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SKIP run=$RUN_ID job=$JOB_NAME already-running pid=$existing_pid" >> "$RUNNER_LOG"
    exit 0
  fi

  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN run=$RUN_ID job=$JOB_NAME stale-lock-cleared pid=${existing_pid:-unknown}" >> "$RUNNER_LOG"
  rm -rf "$LOCK_DIR"

  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_PID_FILE"
    trap release_lock EXIT
    return 0
  fi

  touch "$RERUN_FLAG_FILE"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SKIP run=$RUN_ID job=$JOB_NAME lock-contended" >> "$RUNNER_LOG"
  exit 0
}

# ─── Determine today's focus (if rotation.json exists) ───────────────
FOCUS=""
RUN_ID=$(date +%Y%m%d-%H%M%S)

acquire_lock

trap cleanup_runner EXIT

if [[ -f "$ROTATION_FILE" ]]; then
  DOW=$(date +%u)  # 1=Monday .. 7=Sunday
  FOCUS=$(jq -r --argjson dow "$DOW" '.rotation[] | select(.day == $dow) | .focus' "$ROTATION_FILE")
  DESCRIPTION=$(jq -r --argjson dow "$DOW" '.rotation[] | select(.day == $dow) | .description' "$ROTATION_FILE")

  if [[ -z "$FOCUS" || "$FOCUS" == "null" ]]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR run=$RUN_ID job=$JOB_NAME No task for day $DOW" >> "$RUNNER_LOG"
    exit 1
  fi

  MESSAGE="Today's focus: $FOCUS

$DESCRIPTION

Run ID: $RUN_ID"
else
  MESSAGE="Run ID: $RUN_ID"
fi

if ! prepare_run_environment; then
  exit 1
fi

# ─── Log start ───────────────────────────────────────────────────────
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) START run=$RUN_ID job=$JOB_NAME focus=${FOCUS:-none} isolated=$USED_TEMP_WORKTREE" >> "$RUNNER_LOG"

# ─── Build OpenCode args ─────────────────────────────────────────────
if [[ -n "$COMMAND_NAME" ]]; then
  ARGS=(opencode run --command "$COMMAND_NAME" --dir "$RUN_DIR" --model "$MODEL")
  [[ -n "$VARIANT" ]] && ARGS+=(--variant "$VARIANT")
  ARGS+=("$MESSAGE")
elif [[ -f "$COMMAND_FILE" ]]; then
  ARGS=(opencode run --dir "$RUN_DIR" --model "$MODEL" --file "$COMMAND_FILE")
  [[ -n "$VARIANT" ]] && ARGS+=(--variant "$VARIANT")
  ARGS+=("$MESSAGE")
else
  echo "ERROR: No command_name in job.json and no command.md found" >&2
  exit 1
fi

# ─── Execute with timeout (perl fork+alarm) ──────────────────────────
EXIT_CODE=0
TIMEOUT_SECONDS="$TIMEOUT" perl -e '
  my $pid = fork();
  if ($pid == 0) {
    exec @ARGV;
    die "exec failed: $!";
  }
  my $timeout = $ENV{TIMEOUT_SECONDS} || 900;
  eval {
    local $SIG{ALRM} = sub { kill("TERM", $pid); die "timeout\n" };
    alarm($timeout);
    waitpid($pid, 0);
    alarm(0);
  };
  if ($@ eq "timeout\n") {
    waitpid($pid, 0);
    exit 124;
  }
  exit($? >> 8);
' "${ARGS[@]}" || EXIT_CODE=$?

# ─── Log result ──────────────────────────────────────────────────────
if [[ $USED_TEMP_WORKTREE -eq 1 ]]; then
  flush_temp_run_log
fi

if [[ $EXIT_CODE -eq 124 ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) TIMEOUT run=$RUN_ID job=$JOB_NAME focus=${FOCUS:-none} (${TIMEOUT}s)" >> "$RUNNER_LOG"
elif [[ $EXIT_CODE -ne 0 ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR run=$RUN_ID job=$JOB_NAME focus=${FOCUS:-none} exit=$EXIT_CODE" >> "$RUNNER_LOG"
else
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DONE run=$RUN_ID job=$JOB_NAME focus=${FOCUS:-none} exit=0" >> "$RUNNER_LOG"
fi

if [[ -f "$RERUN_FLAG_FILE" ]]; then
  rm -f "$RERUN_FLAG_FILE"
  cleanup_temp_worktree
  release_lock
  trap - EXIT
  exec "$AUTOMATION_DIR/runner.sh" "$JOB_NAME"
fi

exit $EXIT_CODE
