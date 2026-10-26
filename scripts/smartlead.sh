#!/usr/bin/env bash
# Scout Skill — Smartlead helper (wraps the Smartlead REST API)
#
# Credentials loaded from env var SMARTLEAD_API_KEY OR from the config file
# at $SCOUT_CONFIG (defaults to ~/.claude/scout-config.json).
#
# Usage:
#   smartlead.sh health                          # verify API key
#   smartlead.sh list_campaigns                  # list all campaigns
#   smartlead.sh get_campaign <id>               # details of one campaign
#   smartlead.sh create_campaign '<name>'        # create a new PAUSED campaign, prints id
#   smartlead.sh add_sequence <id> '<json>'      # stage email sequence on a campaign
#   smartlead.sh add_lead <id> '<lead json>'     # add one lead to a campaign (refused if campaign active)
#   smartlead.sh set_settings <id> '<json>'      # configure tracking / general settings
#   smartlead.sh set_schedule <id> '<json>'      # configure sending schedule (timezone, hours, days)
#   smartlead.sh list_leads <id>                 # list leads on a campaign
#   smartlead.sh get_stats <id>                  # campaign analytics
#   smartlead.sh pause_campaign <id>             # pause a running campaign (always safe)
#   smartlead.sh start_campaign <id> --confirm   # REQUIRES --confirm, refuses if no leads or already running
#   smartlead.sh delete_campaign <id> --confirm  # REQUIRES --confirm
#
# Returns raw JSON on stdout. Pipe through `jq` for pretty output.
#
# Guardrails:
#   - start_campaign REQUIRES --confirm, validates campaign has leads and is paused
#   - add_lead refuses on campaigns that look ACTIVE
#   - API shapes based on best-available documentation; if Smartlead changes its API,
#     only this file needs updating.

set -euo pipefail

# ------------------------------------------------------------
# jq check
# ------------------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required. brew install jq (macOS) or apt install jq (Linux)." >&2
  exit 2
fi

# ------------------------------------------------------------
# Credential loading
# ------------------------------------------------------------

_load_from_config_file() {
  local config_path="${SCOUT_CONFIG:-$HOME/.claude/scout-config.json}"
  [[ ! -f "$config_path" ]] && return 1
  if [[ -z "${SMARTLEAD_API_KEY:-}" ]]; then
    SMARTLEAD_API_KEY=$(jq -r '.smartlead_api_key // empty' "$config_path" 2>/dev/null || true)
  fi
}

if [[ -z "${SMARTLEAD_API_KEY:-}" ]]; then
  _load_from_config_file || true
fi

if [[ -z "${SMARTLEAD_API_KEY:-}" ]] || [[ "$SMARTLEAD_API_KEY" == "not_yet_configured" ]]; then
  echo "ERROR: SMARTLEAD_API_KEY is not set (or is still the 'not_yet_configured' placeholder)." >&2
  echo "Either export it in your shell profile, OR put it in ~/.claude/scout-config.json." >&2
  echo "See README.md (Setup) for details." >&2
  exit 2
fi

SMARTLEAD_BASE="https://server.smartlead.ai/api/v1"

# ------------------------------------------------------------
# HTTP wrappers
# ------------------------------------------------------------

_with_key() {
  # Append api_key to a path with proper separator
  local path="$1"
  local sep="?"
  [[ "$path" == *"?"* ]] && sep="&"
  echo "${SMARTLEAD_BASE}${path}${sep}api_key=${SMARTLEAD_API_KEY}"
}

_get() {
  curl -sS "$(_with_key "$1")"
}

_post() {
  local path="$1"
  local body="$2"
  curl -sS -X POST "$(_with_key "$path")" \
    -H "Content-Type: application/json" \
    --data "$body"
}

# ------------------------------------------------------------
# Campaign status helper (used by guardrails)
# ------------------------------------------------------------

# Returns the campaign's status string as reported by Smartlead, or "unknown".
# Smartlead returns statuses like DRAFTED, PAUSED, ACTIVE, COMPLETED, STOPPED
# in different fields across endpoints; this tries a few shapes.
_campaign_status() {
  local campaign_id="$1"
  local response
  response=$(_get "/campaigns/${campaign_id}")
  echo "$response" | jq -r '.status // .campaign_status // "unknown"' 2>/dev/null || echo "unknown"
}

# True if the campaign status looks like it's actively sending.
_is_campaign_active() {
  local status
  status=$(_campaign_status "$1" | tr '[:lower:]' '[:upper:]')
  case "$status" in
    ACTIVE|RUNNING|SENDING|STARTED) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------
# Read-only subcommands
# ------------------------------------------------------------

cmd_health() {
  local response
  response=$(_get "/campaigns")
  local kind
  kind=$(echo "$response" | jq -r 'if type == "array" then "array" elif type == "object" and (has("error") or has("message")) then "error" else "unknown" end' 2>/dev/null)
  case "$kind" in
    array)
      local count
      count=$(echo "$response" | jq 'length')
      echo "{\"ok\":true,\"hint\":\"Smartlead API key is valid\",\"campaigns_count\":${count}}"
      ;;
    error)
      echo "{\"ok\":false,\"hint\":\"Smartlead API rejected the request\",\"response\":$response}"
      exit 1
      ;;
    *)
      echo "{\"ok\":false,\"hint\":\"Unexpected response shape\",\"response\":$response}"
      exit 1
      ;;
  esac
}

cmd_list_campaigns() {
  _get "/campaigns"
}

cmd_get_campaign() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh get_campaign <id>" >&2; exit 64; }
  _get "/campaigns/${id}"
}

cmd_list_leads() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh list_leads <id>" >&2; exit 64; }
  _get "/campaigns/${id}/leads"
}

cmd_get_stats() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh get_stats <id>" >&2; exit 64; }
  _get "/campaigns/${id}/analytics"
}

# ------------------------------------------------------------
# Write subcommands (no sends without explicit start)
# ------------------------------------------------------------

cmd_create_campaign() {
  local name="${1:-}"
  [[ -z "$name" ]] && { echo "Usage: smartlead.sh create_campaign '<name>'" >&2; exit 64; }
  local body
  body=$(jq -n --arg name "$name" '{name: $name}')
  _post "/campaigns/create" "$body"
}

cmd_add_sequence() {
  local id="${1:-}"
  local seq_json="${2:-}"
  [[ -z "$id" || -z "$seq_json" ]] && { echo "Usage: smartlead.sh add_sequence <id> '<sequences json>'" >&2; exit 64; }
  # Payload format per Smartlead docs:
  #   { "sequences": [ { "seq_number": 1, "seq_delay_details": {"delay_in_days": 0},
  #                      "subject": "...", "email_body": "..." }, ... ] }
  # Caller is expected to provide the full payload as-is (flexibility over brittleness).
  _post "/campaigns/${id}/sequences" "$seq_json"
}

cmd_add_lead() {
  local id="${1:-}"
  local lead_json="${2:-}"
  [[ -z "$id" || -z "$lead_json" ]] && { echo "Usage: smartlead.sh add_lead <id> '<lead json>'" >&2; exit 64; }

  # Guardrail: refuse if campaign is already actively sending.
  if _is_campaign_active "$id"; then
    echo "ERROR: campaign $id appears to be ACTIVE. Refusing to add lead — would risk duplicate sends." >&2
    echo "       Pause the campaign first: smartlead.sh pause_campaign $id" >&2
    exit 1
  fi

  # Caller passes a single lead object like:
  #   {"email":"author@example.com","first_name":"Jane","last_name":"Doe","custom_fields":{...}}
  # We wrap into Smartlead's lead_list format.
  local payload
  payload=$(jq -n --argjson lead "$lead_json" '{lead_list:[$lead]}')
  _post "/campaigns/${id}/leads" "$payload"
}

cmd_set_settings() {
  local id="${1:-}"
  local settings_json="${2:-}"
  [[ -z "$id" || -z "$settings_json" ]] && { echo "Usage: smartlead.sh set_settings <id> '<settings json>'" >&2; exit 64; }
  # Flat payload — tracking, follow-up %, plain text, unsubscribe text, etc.
  # e.g. {"track_settings":["DONT_TRACK_LINK_CLICK"],"follow_up_percentage":100}
  _post "/campaigns/${id}/settings" "$settings_json"
}

cmd_set_schedule() {
  local id="${1:-}"
  local sched_json="${2:-}"
  [[ -z "$id" || -z "$sched_json" ]] && { echo "Usage: smartlead.sh set_schedule <id> '<schedule json>'" >&2; exit 64; }
  # Flat payload per Smartlead /schedule endpoint:
  #   {"timezone":"America/New_York","days_of_the_week":[1,2,3,4,5],
  #    "start_hour":"09:00","end_hour":"17:00",
  #    "min_time_btw_emails":10,"max_new_leads_per_day":30,
  #    "schedule_start_time":"2026-04-23T09:00:00.000Z"}
  _post "/campaigns/${id}/schedule" "$sched_json"
}

cmd_pause_campaign() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh pause_campaign <id>" >&2; exit 64; }
  _post "/campaigns/${id}/pause" '{}'
}

# ------------------------------------------------------------
# Dangerous subcommands (require --confirm)
# ------------------------------------------------------------

cmd_start_campaign() {
  local id="${1:-}"
  local confirm="${2:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh start_campaign <id> --confirm" >&2; exit 64; }

  if [[ "$confirm" != "--confirm" ]]; then
    echo "ERROR: start_campaign requires explicit --confirm flag." >&2
    echo "       Example: smartlead.sh start_campaign $id --confirm" >&2
    echo "       This will begin sending emails to every lead in the campaign." >&2
    exit 64
  fi

  # Guardrail 1: campaign must exist and have leads
  local lead_count
  lead_count=$(_get "/campaigns/${id}/leads" | jq 'if type=="array" then length else (.leads // [] | length) end' 2>/dev/null || echo 0)
  if [[ "$lead_count" == "0" ]] || [[ "$lead_count" == "null" ]]; then
    echo "ERROR: campaign $id has no leads. Refusing to start an empty campaign." >&2
    exit 1
  fi

  # Guardrail 2: campaign should not already be active
  if _is_campaign_active "$id"; then
    echo "ERROR: campaign $id already appears to be ACTIVE. Nothing to start." >&2
    exit 1
  fi

  # OK, start it.
  _post "/campaigns/${id}/start" '{}'
}

cmd_delete_campaign() {
  local id="${1:-}"
  local confirm="${2:-}"
  [[ -z "$id" ]] && { echo "Usage: smartlead.sh delete_campaign <id> --confirm" >&2; exit 64; }
  if [[ "$confirm" != "--confirm" ]]; then
    echo "ERROR: delete_campaign requires explicit --confirm flag." >&2
    echo "       This permanently deletes the campaign and its leads from Smartlead." >&2
    exit 64
  fi
  curl -sS -X DELETE "$(_with_key "/campaigns/${id}")"
}

# ------------------------------------------------------------
# Dispatch
# ------------------------------------------------------------

action="${1:-}"
shift || true

case "$action" in
  health)           cmd_health ;;
  list_campaigns)   cmd_list_campaigns ;;
  get_campaign)     cmd_get_campaign "$@" ;;
  list_leads)       cmd_list_leads "$@" ;;
  get_stats)        cmd_get_stats "$@" ;;
  create_campaign)  cmd_create_campaign "$@" ;;
  add_sequence)     cmd_add_sequence "$@" ;;
  add_lead)         cmd_add_lead "$@" ;;
  set_settings)     cmd_set_settings "$@" ;;
  set_schedule)     cmd_set_schedule "$@" ;;
  pause_campaign)   cmd_pause_campaign "$@" ;;
  start_campaign)   cmd_start_campaign "$@" ;;
  delete_campaign)  cmd_delete_campaign "$@" ;;
  ""|-h|--help|help)
    sed -n '2,30p' "$0"
    ;;
  *)
    echo "Unknown action: $action. Run 'smartlead.sh --help' for usage." >&2
    exit 64
    ;;
esac
