#!/usr/bin/env bash
# Scout Skill — Google Sheets helper (wraps the Apps Script web app)
#
# Prerequisites:
#   - The Apps Script at scripts/appsscript_backend.gs is deployed as a web app
#   - Credentials are available via EITHER:
#       (a) env vars SHEETS_WEBAPP_URL and SHEETS_SECRET, OR
#       (b) a config file at $SCOUT_CONFIG (defaults to ~/.claude/scout-config.json)
#     Env vars win when both are set. See README.md (Setup) for details.
#
# Usage:
#   scripts/sheets.sh append '<author json>'
#   scripts/sheets.sh update_by_email '<email>' '<partial json>'
#   scripts/sheets.sh read_all
#   scripts/sheets.sh read_by_status '<filter json>'          # e.g. '{"research_status":"researched","email_status":"pending"}'
#   scripts/sheets.sh read_missing_data '<fields json>' '<filter json>'   # e.g. '["instagram_followers","goodreads_ratings"]' '{"research_status":"discovered_by_user"}'
#   scripts/sheets.sh health
#
# Returns raw JSON from the Apps Script on stdout. Pipe through `jq` for pretty output.
# Exits non-zero on HTTP or transport errors; logical errors come through as { "ok": false, ... } in the JSON.

set -euo pipefail

# ------------------------------------------------------------
# jq check (needed for both config loading and payload building)
# ------------------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required. brew install jq (macOS) or apt install jq (Linux)." >&2
  exit 2
fi

# ------------------------------------------------------------
# Credential loading
#
# Priority order:
#   1. Env vars SHEETS_WEBAPP_URL and SHEETS_SECRET (both must be set)
#   2. Config file at $SCOUT_CONFIG (defaults to ~/.claude/scout-config.json)
#
# The config file fallback lets Claude Code app users (who don't use a terminal)
# skip shell profile setup entirely — they just drop a JSON file and go.
# ------------------------------------------------------------

_load_from_config_file() {
  local config_path="${SCOUT_CONFIG:-$HOME/.claude/scout-config.json}"
  if [[ ! -f "$config_path" ]]; then
    return 1
  fi

  # Only fill in values that aren't already set via env vars
  if [[ -z "${SHEETS_WEBAPP_URL:-}" ]]; then
    SHEETS_WEBAPP_URL=$(jq -r '.sheets_webapp_url // empty' "$config_path" 2>/dev/null || true)
  fi
  if [[ -z "${SHEETS_SECRET:-}" ]]; then
    SHEETS_SECRET=$(jq -r '.sheets_secret // empty' "$config_path" 2>/dev/null || true)
  fi
}

# Try config file fallback if either credential is missing
if [[ -z "${SHEETS_WEBAPP_URL:-}" ]] || [[ -z "${SHEETS_SECRET:-}" ]]; then
  _load_from_config_file || true
fi

# Final check after both sources
if [[ -z "${SHEETS_WEBAPP_URL:-}" ]]; then
  echo "ERROR: SHEETS_WEBAPP_URL is not set." >&2
  echo "Either export it in your shell profile, OR put it in ~/.claude/scout-config.json." >&2
  echo "See README.md (Setup) for details." >&2
  exit 2
fi

if [[ -z "${SHEETS_SECRET:-}" ]]; then
  echo "ERROR: SHEETS_SECRET is not set." >&2
  echo "Either export it in your shell profile, OR put it in ~/.claude/scout-config.json." >&2
  echo "See README.md (Setup) for details." >&2
  exit 2
fi

# ------------------------------------------------------------
# Core POST wrapper
# ------------------------------------------------------------

_post() {
  local payload="$1"
  # Apps Script web apps return a 302 redirect from script.google.com to
  # script.googleusercontent.com, which serves the execution result and
  # accepts only GET. Forcing POST across redirects (-X POST or --post302)
  # would return 405 Method Not Allowed on the second hop.
  #
  # The --data flag sends the initial request as POST automatically, and
  # curl's default behavior converts POST → GET on 302 redirects, which is
  # exactly what Apps Script expects.
  curl -sSL \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$SHEETS_WEBAPP_URL"
}

# ------------------------------------------------------------
# Subcommands
# ------------------------------------------------------------

cmd_append() {
  local data="${1:-}"
  if [[ -z "$data" ]]; then
    echo "Usage: sheets.sh append '<author json>'" >&2
    exit 64
  fi
  local payload
  payload=$(jq -n --arg s "$SHEETS_SECRET" --argjson d "$data" \
    '{action:"append", secret:$s, data:$d}')
  _post "$payload"
}

cmd_update_by_email() {
  local email="${1:-}"
  local data="${2:-}"
  if [[ -z "$email" || -z "$data" ]]; then
    echo "Usage: sheets.sh update_by_email '<email>' '<partial json>'" >&2
    exit 64
  fi
  local payload
  payload=$(jq -n --arg s "$SHEETS_SECRET" --arg e "$email" --argjson d "$data" \
    '{action:"update_by_email", secret:$s, email:$e, data:$d}')
  _post "$payload"
}

cmd_read_all() {
  local payload
  payload=$(jq -n --arg s "$SHEETS_SECRET" \
    '{action:"read_all", secret:$s}')
  _post "$payload"
}

cmd_read_by_status() {
  # Default to '{}' (empty filter). Assigned via if-block because bash's
  # ${1:-{}} default-value syntax mis-parses the nested braces and appends
  # an extra closing brace to the result.
  local filter="${1:-}"
  [[ -z "$filter" ]] && filter='{}'
  local payload
  payload=$(jq -n --arg s "$SHEETS_SECRET" --argjson f "$filter" \
    '{action:"read_by_status", secret:$s, filter:$f}')
  _post "$payload"
}

cmd_read_missing_data() {
  local fields="${1:-}"
  local filter="${2:-}"
  [[ -z "$filter" ]] && filter='{}'
  if [[ -z "$fields" ]]; then
    echo "Usage: sheets.sh read_missing_data '<fields json>' ['<filter json>']" >&2
    exit 64
  fi
  local payload
  payload=$(jq -n --arg s "$SHEETS_SECRET" --argjson fld "$fields" --argjson flt "$filter" \
    '{action:"read_missing_data", secret:$s, fields:$fld, filter:$flt}')
  _post "$payload"
}

cmd_health() {
  curl -sSL "$SHEETS_WEBAPP_URL"
}

# ------------------------------------------------------------
# Dispatch
# ------------------------------------------------------------

action="${1:-}"
shift || true

case "$action" in
  append)            cmd_append "$@" ;;
  update_by_email)   cmd_update_by_email "$@" ;;
  read_all)          cmd_read_all "$@" ;;
  read_by_status)    cmd_read_by_status "$@" ;;
  read_missing_data) cmd_read_missing_data "$@" ;;
  health)            cmd_health ;;
  ""|-h|--help|help)
    sed -n '2,30p' "$0"
    ;;
  *)
    echo "Unknown action: $action. Run 'sheets.sh --help' for usage." >&2
    exit 64
    ;;
esac
