#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../tools/redaction.sh
source "$BASE_DIR/tools/redaction.sh"

usage() {
  cat <<'EOF'
Usage: whatsapp.sh --config <notification.local.json> --message-file <path>

The adapter intentionally does not hardcode phone numbers or credentials. Configure
local delivery with either:

- DELIVERY_PIPELINE_WHATSAPP_COMMAND=/path/to/local-sender
- notification.local.json field: { "whatsapp": { "command": "/path/to/local-sender", "env_file": "~/.ai-automation/.env", "keychain_access_token_service": "ai-automation.whatsapp.access-token", "message_mode": "text" } }

If `~/.ai-automation/scripts/send-whatsapp.sh` exists, it is used as the default
sender command. Recipient lookup order is DELIVERY_PIPELINE_WHATSAPP_TO,
`.whatsapp.to`, `.whatsapp.to_env`, then legacy WHATSAPP_RECIPIENT.

The command is executed as: <command> <to> <message-file>
EOF
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

expand_path() {
  local path="$1"
  case "$path" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${path#\~/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

load_keychain_secret() {
  local service_name="$1"
  [[ -n "$service_name" ]] || return 0
  command -v security >/dev/null 2>&1 || return 0
  security find-generic-password -a "$USER" -s "$service_name" -w 2>/dev/null || true
}

apply_config_env_override() {
  local json_key="$1"
  local env_name="$2"
  local value

  if jq -e --arg key "$json_key" '.whatsapp | has($key)' "$CONFIG_FILE" >/dev/null; then
    value="$(jq -r --arg key "$json_key" '.whatsapp[$key] // ""' "$CONFIG_FILE")"
    export "$env_name=$value"
  fi
}

redact_output() {
  delivery_pipeline_redact_text
}

CONFIG_FILE=""
MESSAGE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_FILE="${2:?Missing --config value}"; shift 2 ;;
    --message-file)
      MESSAGE_FILE="${2:?Missing --message-file value}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$CONFIG_FILE" || -z "$MESSAGE_FILE" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "WARN: notification config not found: $CONFIG_FILE" >&2
  exit 0
fi

if [[ ! -f "$MESSAGE_FILE" ]]; then
  echo "ERROR: message file not found: $MESSAGE_FILE" >&2
  exit 1
fi

env_file="$(jq -r '.whatsapp.env_file // empty' "$CONFIG_FILE")"
if [[ -n "$env_file" ]]; then
  env_file="$(expand_path "$env_file")"
  if [[ ! -f "$env_file" ]]; then
    echo "WARN: WhatsApp env file not found: $env_file" >&2
    exit 0
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
fi

keychain_access_token_service="${DELIVERY_PIPELINE_WHATSAPP_KEYCHAIN_ACCESS_TOKEN_SERVICE:-}"
if [[ -z "$keychain_access_token_service" ]]; then
  keychain_access_token_service="$(jq -r '.whatsapp.keychain_access_token_service // empty' "$CONFIG_FILE")"
fi
if [[ -n "$keychain_access_token_service" && -z "${WHATSAPP_ACCESS_TOKEN:-}" ]]; then
  keychain_access_token="$(load_keychain_secret "$keychain_access_token_service")"
  if [[ -n "$keychain_access_token" ]]; then
    export WHATSAPP_ACCESS_TOKEN="$keychain_access_token"
  fi
fi

apply_config_env_override "message_mode" "WHATSAPP_MESSAGE_MODE"
apply_config_env_override "template_name" "WHATSAPP_TEMPLATE_NAME"
apply_config_env_override "template_language" "WHATSAPP_TEMPLATE_LANGUAGE"
apply_config_env_override "template_body_from_file" "WHATSAPP_TEMPLATE_BODY_FROM_FILE"

command_path="${DELIVERY_PIPELINE_WHATSAPP_COMMAND:-}"
if [[ -z "$command_path" ]]; then
  command_path="$(jq -r '.whatsapp.command // empty' "$CONFIG_FILE")"
fi
if [[ -z "$command_path" && -x "$HOME/.ai-automation/scripts/send-whatsapp.sh" ]]; then
  command_path="$HOME/.ai-automation/scripts/send-whatsapp.sh"
fi
if [[ -n "$command_path" ]]; then
  command_path="$(expand_path "$command_path")"
fi

recipient="${DELIVERY_PIPELINE_WHATSAPP_TO:-}"
if [[ -z "$recipient" ]]; then
  recipient="$(jq -r '.whatsapp.to // empty' "$CONFIG_FILE")"
fi
if [[ -z "$recipient" ]]; then
  recipient_env="$(jq -r '.whatsapp.to_env // "WHATSAPP_RECIPIENT"' "$CONFIG_FILE")"
  if [[ "$recipient_env" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    recipient="${!recipient_env:-}"
  fi
fi

if [[ -z "$command_path" ]]; then
  echo "WARN: WhatsApp command is not configured; set DELIVERY_PIPELINE_WHATSAPP_COMMAND or .whatsapp.command" >&2
  exit 0
fi

if [[ ! -x "$command_path" ]]; then
  echo "ERROR: WhatsApp command is not executable: $command_path" >&2
  exit 1
fi

if [[ -z "$recipient" ]]; then
  echo "WARN: WhatsApp recipient is not configured; set DELIVERY_PIPELINE_WHATSAPP_TO or .whatsapp.to" >&2
  exit 0
fi

thread_map_path="${DELIVERY_PIPELINE_WHATSAPP_THREAD_MAP:-}"
if [[ -z "$thread_map_path" ]]; then
  thread_map_path="$(jq -r '.whatsapp.thread_map_path // empty' "$CONFIG_FILE")"
fi
if [[ -z "$thread_map_path" ]]; then
  thread_map_path="$BASE_DIR/tmp/whatsapp-thread-map.jsonl"
fi
thread_map_path="$(expand_path "$thread_map_path")"

run_id="$(sed -n 's/^Run: //p' "$MESSAGE_FILE" | head -n 1)"

response_file="$(mktemp "${TMPDIR:-/tmp}/whatsapp-adapter.XXXXXX")"
cleanup() {
  rm -f "$response_file"
}
trap cleanup EXIT

if "$command_path" "$recipient" "$MESSAGE_FILE" > "$response_file" 2>&1; then
  message_id="$(jq -r '.messages[0].id // empty' "$response_file" 2>/dev/null || true)"
  if [[ -n "$message_id" && -n "$run_id" && "$run_id" != "manual" ]]; then
    mkdir -p "$(dirname "$thread_map_path")"
    jq -cn \
      --arg schema_version "1" \
      --arg message_id "$message_id" \
      --arg run_id "$run_id" \
      --arg sent_at "$(now_utc)" \
      '{schema_version:$schema_version,message_id:$message_id,run_id:$run_id,sent_at:$sent_at}' >> "$thread_map_path"
  fi
  exit 0
fi

exit_code=$?
redact_output < "$response_file" >&2
exit "$exit_code"
