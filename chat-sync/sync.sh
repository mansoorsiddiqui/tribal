#!/usr/bin/env bash
set -euo pipefail

# Tribal Chat Sync — Extracts knowledge from Slack/Teams messages
# Usage: sync.sh <slack|teams>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIBAL_PATH="${TRIBAL_PATH:-$(dirname "$SCRIPT_DIR")}"
TRIBAL_CLI="$TRIBAL_PATH/tribal"
CONFIG_FILE="$TRIBAL_PATH/tribal.config.yml"
STATE_FILE="$TRIBAL_PATH/.tribal-sync-state.json"

# ── Utility Functions ─────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo ":: $*"; }

# Read a nested config value (simple grep-based, not a full YAML parser)
config_get() {
  local key="$1"
  grep "^[[:space:]]*${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed "s/.*${key}:[[:space:]]*//" | sed 's/^["'"'"']//;s/["'"'"']$//' | tr -d ' '
}

# Read sync state (last processed timestamp per channel)
state_get() {
  local key="$1"
  if [ -f "$STATE_FILE" ]; then
    # Simple JSON extraction with sed/grep
    grep "\"$key\"" "$STATE_FILE" 2>/dev/null | sed 's/.*: *"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/' || echo ""
  fi
}

state_set() {
  local key="$1"
  local value="$2"
  if [ ! -f "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
  fi
  local tmp
  tmp=$(mktemp)
  if grep -q "\"$key\"" "$STATE_FILE" 2>/dev/null; then
    sed "s|\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"$key\": \"$value\"|" "$STATE_FILE" > "$tmp"
  else
    # Add new key before closing brace
    sed "s|}|, \"$key\": \"$value\"}|" "$STATE_FILE" > "$tmp"
    # Fix if it was empty object
    sed -i'' 's/{, /{/' "$tmp" 2>/dev/null || sed -i 's/{, /{/' "$tmp"
  fi
  mv "$tmp" "$STATE_FILE"
}

# ── LLM Extraction ───────────────────────────────────────────

call_anthropic() {
  local message_text="$1"
  local response
  response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "content-type: application/json" \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -d "$(cat <<REQEOF
{
  "model": "${LLM_MODEL:-claude-sonnet-4-20250514}",
  "max_tokens": 1024,
  "messages": [{"role": "user", "content": "Extract tribal knowledge from the following chat message(s). Return ONLY valid JSON with these fields: title (string), category (one of: environment, debugging, architecture, process, tooling, testing, deployment, security), tags (array of strings), confidence (low/medium/high), summary (one sentence), body (markdown with Problem/Solution/Context sections).\n\nMessage:\n${message_text}"}]
}
REQEOF
  )")
  # Extract text content from Anthropic response
  echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null
}

call_openai() {
  local message_text="$1"
  local response
  response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -d "$(cat <<REQEOF
{
  "model": "${LLM_MODEL:-gpt-4o}",
  "messages": [
    {"role": "system", "content": "Extract tribal knowledge from chat messages. Return ONLY valid JSON with: title, category (environment|debugging|architecture|process|tooling|testing|deployment|security), tags (array), confidence (low|medium|high), summary (one sentence), body (markdown with Problem/Solution/Context sections)."},
    {"role": "user", "content": "${message_text}"}
  ],
  "temperature": 0.3
}
REQEOF
  )")
  echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null
}

extract_knowledge() {
  local message_text="$1"
  local provider
  provider=$(config_get "provider")

  local result=""
  case "${provider:-anthropic}" in
    anthropic) result=$(call_anthropic "$message_text") ;;
    openai)    result=$(call_openai "$message_text") ;;
    *)         die "Unknown LLM provider: $provider" ;;
  esac

  echo "$result"
}

add_entry_from_json() {
  local json="$1"
  local title category tags confidence summary body

  title=$(echo "$json" | jq -r '.title // empty')
  category=$(echo "$json" | jq -r '.category // "process"')
  tags=$(echo "$json" | jq -r '.tags // [] | join(",")')
  confidence=$(echo "$json" | jq -r '.confidence // "medium"')
  summary=$(echo "$json" | jq -r '.summary // empty')
  body=$(echo "$json" | jq -r '.body // empty')

  if [ -z "$title" ] || [ -z "$body" ]; then
    echo "WARNING: LLM extraction returned empty title or body, skipping" >&2
    return 1
  fi

  bash "$TRIBAL_CLI" add \
    --title "$title" \
    --category "$category" \
    --tags "$tags" \
    --confidence "$confidence" \
    --summary "$summary" \
    --body "$body" \
    --force
}

# ── Slack Integration ─────────────────────────────────────────

slack_fetch_channel_messages() {
  local channel_id="$1"
  local oldest="${2:-0}"

  curl -s "https://slack.com/api/conversations.history" \
    -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -d "channel=${channel_id}" \
    -d "oldest=${oldest}" \
    -d "limit=100"
}

slack_fetch_reactions() {
  local channel_id="$1"
  local oldest="${2:-0}"
  local reaction_name="${3:-book}"

  # Fetch messages and filter by reaction
  local messages
  messages=$(slack_fetch_channel_messages "$channel_id" "$oldest")

  echo "$messages" | jq -c ".messages[]? | select(.reactions[]?.name == \"$reaction_name\")" 2>/dev/null
}

sync_slack() {
  local mode
  mode=$(config_get "mode")
  mode="${mode:-channel}"

  # Get channel list from config
  local channels
  channels=$(grep -A20 'slack:' "$CONFIG_FILE" | grep -A5 'channels:' | grep '^ *- ' | sed 's/^ *- //' | tr -d '"'"'" | tr -d ' ')

  if [ -z "$channels" ]; then
    info "No Slack channels configured"
    return 0
  fi

  local reaction_name
  reaction_name=$(config_get "reaction_emoji")
  reaction_name="${reaction_name:-book}"

  local count=0

  while IFS= read -r channel_id; do
    [ -z "$channel_id" ] && continue

    local last_ts
    last_ts=$(state_get "slack_${channel_id}")
    last_ts="${last_ts:-0}"

    info "Syncing Slack channel: $channel_id (since: $last_ts)"

    local messages=""
    if [ "$mode" = "channel" ]; then
      messages=$(slack_fetch_channel_messages "$channel_id" "$last_ts" | jq -c '.messages[]?' 2>/dev/null)
    elif [ "$mode" = "reaction" ]; then
      messages=$(slack_fetch_reactions "$channel_id" "$last_ts" "$reaction_name")
    fi

    local newest_ts="$last_ts"

    while IFS= read -r msg; do
      [ -z "$msg" ] && continue

      local text ts
      text=$(echo "$msg" | jq -r '.text // empty')
      ts=$(echo "$msg" | jq -r '.ts // "0"')

      if [ -z "$text" ]; then
        continue
      fi

      # Track newest timestamp
      if awk "BEGIN{exit !($ts > $newest_ts)}"; then
        newest_ts="$ts"
      fi

      info "Processing message: ${text:0:80}..."
      local json
      json=$(extract_knowledge "$text")

      if [ -n "$json" ]; then
        if add_entry_from_json "$json"; then
          count=$((count + 1))
        fi
      fi
    done <<< "$messages"

    state_set "slack_${channel_id}" "$newest_ts"
  done <<< "$channels"

  info "Slack sync complete: $count new entries"
}

# ── Teams Integration ─────────────────────────────────────────

teams_get_token() {
  local tenant_id="${TEAMS_TENANT_ID}"
  local client_id="${TEAMS_CLIENT_ID}"
  local client_secret="${TEAMS_CLIENT_SECRET}"

  local response
  response=$(curl -s -X POST \
    "https://login.microsoftonline.com/${tenant_id}/oauth2/v2.0/token" \
    -d "grant_type=client_credentials" \
    -d "client_id=${client_id}" \
    -d "client_secret=${client_secret}" \
    -d "scope=https://graph.microsoft.com/.default")

  echo "$response" | jq -r '.access_token // empty'
}

teams_fetch_messages() {
  local token="$1"
  local team_id="$2"
  local channel_id="$3"
  local since="${4:-}"

  local url="https://graph.microsoft.com/v1.0/teams/${team_id}/channels/${channel_id}/messages"
  if [ -n "$since" ]; then
    local since_iso
    since_iso=$(date -u -d "@${since}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                date -u -r "${since}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
    if [ -n "$since_iso" ]; then
      url="${url}?\$filter=lastModifiedDateTime gt ${since_iso}"
    fi
  fi

  curl -s -H "Authorization: Bearer ${token}" "$url"
}

sync_teams() {
  local team_id
  team_id=$(config_get "team_id")
  [ -z "$team_id" ] && die "teams.team_id not configured"

  local token
  token=$(teams_get_token)
  [ -z "$token" ] && die "Failed to obtain Teams access token"

  local mode
  mode=$(config_get "mode")
  mode="${mode:-channel}"

  local channels
  channels=$(grep -A20 'teams:' "$CONFIG_FILE" | grep -A5 'channels:' | grep '^ *- ' | sed 's/^ *- //' | tr -d '"'"'" | tr -d ' ')

  if [ -z "$channels" ]; then
    info "No Teams channels configured"
    return 0
  fi

  local reaction_name
  reaction_name=$(config_get "reaction_emoji")
  reaction_name="${reaction_name:-book}"

  local count=0

  while IFS= read -r channel_id; do
    [ -z "$channel_id" ] && continue

    local last_ts
    last_ts=$(state_get "teams_${channel_id}")
    last_ts="${last_ts:-0}"

    info "Syncing Teams channel: $channel_id (since: $last_ts)"

    local response
    response=$(teams_fetch_messages "$token" "$team_id" "$channel_id" "$last_ts")

    local messages
    if [ "$mode" = "reaction" ]; then
      messages=$(echo "$response" | jq -c ".value[]? | select(.reactions[]?.reactionType == \"$reaction_name\")" 2>/dev/null)
    else
      messages=$(echo "$response" | jq -c '.value[]?' 2>/dev/null)
    fi

    local newest_ts="$last_ts"

    while IFS= read -r msg; do
      [ -z "$msg" ] && continue

      local text created_dt
      text=$(echo "$msg" | jq -r '.body.content // empty')
      created_dt=$(echo "$msg" | jq -r '.createdDateTime // empty')

      if [ -z "$text" ]; then
        continue
      fi

      # Convert ISO datetime to epoch for comparison
      local msg_epoch
      msg_epoch=$(date -d "$created_dt" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$created_dt" +%s 2>/dev/null || echo 0)

      if [ "$msg_epoch" -gt "$newest_ts" ] 2>/dev/null; then
        newest_ts="$msg_epoch"
      fi

      # Strip HTML from Teams messages
      text=$(echo "$text" | sed 's/<[^>]*>//g')

      info "Processing message: ${text:0:80}..."
      local json
      json=$(extract_knowledge "$text")

      if [ -n "$json" ]; then
        if add_entry_from_json "$json"; then
          count=$((count + 1))
        fi
      fi
    done <<< "$messages"

    state_set "teams_${channel_id}" "$newest_ts"
  done <<< "$channels"

  info "Teams sync complete: $count new entries"
}

# ── Main ──────────────────────────────────────────────────────

main() {
  local platform="${1:-}"

  [ -f "$CONFIG_FILE" ] || die "Config not found: $CONFIG_FILE"
  command -v jq >/dev/null 2>&1 || die "jq is required for chat sync"
  command -v curl >/dev/null 2>&1 || die "curl is required for chat sync"

  # Read LLM model from config
  LLM_MODEL=$(config_get "model")

  case "$platform" in
    slack) sync_slack ;;
    teams) sync_teams ;;
    *)     die "Usage: sync.sh <slack|teams>" ;;
  esac
}

main "$@"
