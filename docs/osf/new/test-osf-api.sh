#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

# ╭────────────────────────────────────────────╮
# │     test-osf-api.sh :: Diagnostic Tool     │
# │    v2.7 — Cosmic. Resilient. Divine.       │
# ╰────────────────────────────────────────────╯

CONFIG_FILE="${GITFIELD_CONFIG:-gitfield.osf.yaml}"
TOKEN_FILE="${OSF_TOKEN_FILE:-$HOME/.osf_token}"
OSF_API="${OSF_API_URL:-https://api.osf.io/v2}"
DEBUG_LOG="${GITFIELD_LOG:-$HOME/.test_osf_api_debug.log}"
CURL_TIMEOUT="${CURL_TIMEOUT:-10}"
CURL_RETRIES="${CURL_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-2}"
RATE_LIMIT_DELAY="${RATE_LIMIT_DELAY:-1}"
VERBOSE="${VERBOSE:-false}"

# Initialize Debug Log
mkdir -p "$(dirname "$DEBUG_LOG")"
touch "$DEBUG_LOG"
chmod 600 "$DEBUG_LOG"

trap 'last_command=$BASH_COMMAND; echo -e "\n[ERROR] ❌ Failure at line $LINENO: $last_command" >&2; diagnose; exit 1' ERR

# Logging Functions
info() {
  echo -e "\033[1;34m[INFO]\033[0m $*" >&2
  [ "$VERBOSE" = "true" ] && [ -n "$DEBUG_LOG" ] && debug "INFO: $*"
}
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; debug "WARN: $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; debug "ERROR: $*"; exit 1; }
debug() {
  local msg="$1" lvl="${2:-DEBUG}"
  local json_output
  json_output=$(jq -n --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" --arg lvl "$lvl" --arg msg "$msg" \
    '{timestamp: $ts, level: $lvl, message: $msg}' 2>/dev/null) || {
    echo "[FALLBACK $lvl] $(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$DEBUG_LOG"
    return 1
  }
  echo "$json_output" >> "$DEBUG_LOG"
}

debug "Started test-osf-api (v2.7)"

# ── Diagnostic Function
diagnose() {
  info "Running diagnostics..."
  debug "Diagnostics started"
  echo -e "\n🔍 Diagnostic Report:"
  echo -e "1. Network Check:"
  if ping -c 1 api.osf.io >/dev/null 2>&1; then
    echo -e "   ✓ api.osf.io reachable"
  else
    echo -e "   ❌ api.osf.io unreachable. Check network or DNS."
  fi
  echo -e "2. Curl Version:"
  curl --version | head -n 1
  echo -e "3. Debug Log: $DEBUG_LOG"
  echo -e "4. Curl Error Log: $DEBUG_LOG.curlerr"
  [ -s "$DEBUG_LOG.curlerr" ] && echo -e "   Last curl error: $(cat "$DEBUG_LOG.curlerr")"
  echo -e "5. Token File: $TOKEN_FILE"
  [ -s "$TOKEN_FILE" ] && echo -e "   Token exists: $(head -c 4 "$TOKEN_FILE")..."
  echo -e "6. Suggestions:"
  echo -e "   - Check token scopes at https://osf.io/settings/tokens (needs 'nodes' and 'osf.storage')"
  echo -e "   - Test API: curl -v -H 'Authorization: Bearer \$(cat $TOKEN_FILE)' '$OSF_API/users/me/'"
  echo -e "   - Test project search: curl -v -H 'Authorization: Bearer \$(cat $TOKEN_FILE)' '$OSF_API/users/me/nodes/?filter\[title\]=git-sigil&page\[size\]=100'"
  echo -e "   - Increase timeout: CURL_TIMEOUT=30 ./test-osf-api.sh"
  debug "Diagnostics completed"
}

# ── Dependency Check (Parallel)
require_tool() {
  local tool=$1
  if ! command -v "$tool" >/dev/null 2>&1; then
    warn "$tool not found — attempting to install..."
    sudo apt update -qq && sudo apt install -y "$tool" || {
      warn "apt failed — trying snap..."
      sudo snap install "$tool" || error "Failed to install $tool"
    }
  fi
  debug "$tool path: $(command -v "$tool")"
}

info "Checking dependencies..."
declare -A dep_pids
for tool in curl jq yq python3; do
  require_tool "$tool" &
  dep_pids[$tool]=$!
done
for tool in "${!dep_pids[@]}"; do
  wait "${dep_pids[$tool]}" || error "Dependency check failed for $tool"
done
info "✓ All dependencies verified"

# ── Load Token
if [ ! -f "$TOKEN_FILE" ]; then
  read -rsp "🔐 Enter OSF Personal Access Token (with 'nodes' and 'osf.storage' scopes): " TOKEN
  echo
  echo "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  info "OSF token saved to $TOKEN_FILE"
fi
TOKEN=$(<"$TOKEN_FILE")
[[ -z "$TOKEN" ]] && error "Empty OSF token in $TOKEN_FILE"

# ── Validate Token
info "Validating OSF token..."
execute_curl() {
  local url=$1 method=${2:-GET} data=${3:-} is_upload=${4:-false} attempt=1 max_attempts=$CURL_RETRIES
  local response http_code curl_err
  while [ $attempt -le "$max_attempts" ]; do
    debug "Curl attempt $attempt/$max_attempts: $method $url"
    if [ "$is_upload" = "true" ]; then
      response=$(curl -s -S -w "%{http_code}" --connect-timeout "$CURL_TIMEOUT" \
        -X "$method" -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/octet-stream" --data-binary "$data" "$url" 2> "$DEBUG_LOG.curlerr")
    else
      response=$(curl -s -S -w "%{http_code}" --connect-timeout "$CURL_TIMEOUT" \
        -X "$method" -H "Authorization: Bearer $TOKEN" \
        ${data:+-H "Content-Type: application/json" -d "$data"} "$url" 2> "$DEBUG_LOG.curlerr")
    fi
    http_code="${response: -3}"
    curl_err=$(cat "$DEBUG_LOG.curlerr")
    [ -s "$DEBUG_LOG.curlerr" ] && debug "Curl error: $curl_err"
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
      echo "${response:: -3}"
      return 0
    elif [ "$http_code" = "401" ]; then
      warn "Invalid token (HTTP 401). Please provide a valid OSF token."
      read -rsp "🔐 Enter OSF Personal Access Token (with 'nodes' and 'osf.storage' scopes): " NEW_TOKEN
      echo
      echo "$NEW_TOKEN" > "$TOKEN_FILE"
      chmod 600 "$TOKEN_FILE"
      TOKEN="$NEW_TOKEN"
      info "New token saved. Retrying..."
    elif [ "$http_code" = "429" ]; then
      warn "Rate limit hit, retrying after $((RETRY_DELAY * attempt)) seconds..."
      sleep $((RETRY_DELAY * attempt))
    elif [ "$http_code" = "403" ]; then
      warn "Forbidden (HTTP 403). Possible token scope issue."
      [ $attempt -eq "$max_attempts" ] && {
        read -rsp "🔐 Re-enter OSF token with 'nodes' and 'osf.storage' scopes: " NEW_TOKEN
        echo
        echo "$NEW_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        TOKEN="$NEW_TOKEN"
        info "New token saved. Retrying..."
      }
    elif [[ "$curl_err" == *"bad range in URL"* ]]; then
      error "Malformed URL: $url. Ensure query parameters are escaped (e.g., filter\[title\])."
    else
      debug "API response (HTTP $http_code): ${response:: -3}"
      [ $attempt -eq "$max_attempts" ] && error "API request failed (HTTP $http_code): ${response:: -3}"
    fi
    sleep $((RETRY_DELAY * attempt))
    ((attempt++))
  done
}

RESPONSE=$(execute_curl "$OSF_API/users/me/")
USER_ID=$(echo "$RESPONSE" | jq -r '.data.id // empty')
[[ -z "$USER_ID" ]] && error "Could not extract user ID"
info "✓ OSF token validated for user ID: $USER_ID"

# ── Load Config
[[ ! -f "$CONFIG_FILE" ]] && error "Missing config: $CONFIG_FILE"
PROJECT_TITLE=$(yq -r '.project.title // empty' "$CONFIG_FILE")
PROJECT_DESCRIPTION=$(yq -r '.project.description // empty' "$CONFIG_FILE")
[[ -z "$PROJECT_TITLE" ]] && error "Missing project title in $CONFIG_FILE"
debug "Parsed config: title=$PROJECT_TITLE, description=$PROJECT_DESCRIPTION"

# ── Project Search
build_url() {
  local base="$1" title="$2"
  local escaped_title
  escaped_title=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$title'''))")
  echo "$base/users/me/nodes/?filter\[title\]=$escaped_title&page\[size\]=100"
}

PROJECT_ID=""
NEXT_URL=$(build_url "$OSF_API" "$PROJECT_TITLE")

info "Searching for project '$PROJECT_TITLE'..."
while [ -n "$NEXT_URL" ]; do
  debug "Querying: $NEXT_URL"
  RESPONSE=$(execute_curl "$NEXT_URL")
  PROJECT_ID=$(echo "$RESPONSE" | jq -r --arg TITLE "$PROJECT_TITLE" \
    '.data[] | select(.attributes.title == $TITLE) | .id // empty' || true)
  if [ -n "$PROJECT_ID" ]; then
    debug "Found project ID: $PROJECT_ID"
    break
  fi
  NEXT_URL=$(echo "$RESPONSE" | jq -r '.links.next // empty' | sed 's/filter\[title\]/filter\\\[title\\\]/g;s/page\[size\]/page\\\[size\\\]/g' || true)
  debug "Next URL: $NEXT_URL"
  [ -n "$NEXT_URL" ] && info "Fetching next page..." && sleep "$RATE_LIMIT_DELAY"
done

# ── Create Project if Not Found
if [ -z "$PROJECT_ID" ]; then
  info "Project not found. Attempting to create '$PROJECT_TITLE'..."
  JSON=$(jq -n --arg title="$PROJECT_TITLE" --arg desc="$PROJECT_DESCRIPTION" \
    '{data: {type: "nodes", attributes: {title: $title, category: "project", description: $desc}}}')
  RESPONSE=$(execute_curl "$OSF_API/nodes/" POST "$JSON")
  PROJECT_ID=$(echo "$RESPONSE" | jq -r '.data.id // empty')
  [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]] && error "Could not extract project ID"
  info "✅ Project created: $PROJECT_ID"
else
  info "✓ Found project ID: $PROJECT_ID"
fi

echo -e "\n🔗 View project: https://osf.io/$PROJECT_ID/"
debug "Test completed successfully"
