#!/usr/bin/env bash
set -uo pipefail

# === Constants and Paths ===
BASEDIR="$(pwd)"
OSF_YAML="$BASEDIR/osf.yaml"
GITFIELD_DIR="$BASEDIR/.gitfield"
LOG_DIR="$GITFIELD_DIR/logs"
SCAN_LOG_INIT="$GITFIELD_DIR/scan_log.json"
SCAN_LOG_PUSH="$GITFIELD_DIR/push_log.json"
TMP_JSON_TOKEN="$GITFIELD_DIR/tmp_token.json"
TMP_JSON_PROJECT="$GITFIELD_DIR/tmp_project.json"
TOKEN_PATH="$HOME/.local/gitfieldlib/osf.token"
mkdir -p "$GITFIELD_DIR" "$LOG_DIR" "$(dirname "$TOKEN_PATH")"

# === Logging ===
log() {
  local level="$1" msg="$2"
  echo "[$(date -Iseconds)] [$level] $msg" >> "$LOG_DIR/gitfield_$(date +%Y%m%d).log"
  if [[ "$level" == "ERROR" || "$level" == "INFO" || "$VERBOSE" == "true" ]]; then
    echo "[$(date -Iseconds)] [$level] $msg" >&2
  fi
}

error() {
  log "ERROR" "$1"
  exit 1
}

# === Dependency Check ===
require_yq() {
  if ! command -v yq &>/dev/null || ! yq --version 2>/dev/null | grep -q 'version v4'; then
    log "INFO" "Installing 'yq' (Go version)..."
    YQ_BIN="/usr/local/bin/yq"
    ARCH=$(uname -m)
    case $ARCH in
      x86_64) ARCH=amd64 ;;
      aarch64) ARCH=arm64 ;;
      *) error "Unsupported architecture: $ARCH" ;;
    esac
    curl -sL "https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_${ARCH}" -o yq \
      && chmod +x yq && sudo mv yq "$YQ_BIN"
    log "INFO" "'yq' installed to $YQ_BIN"
  fi
}

require_jq() {
  if ! command -v jq &>/dev/null; then
    log "INFO" "Installing 'jq'..."
    sudo apt update && sudo apt install -y jq
    log "INFO" "'jq' installed"
  fi
}

require_yq
require_jq

# === Token Retrieval ===
get_token() {
  if [[ -z "${OSF_TOKEN:-}" ]]; then
    if [[ -f "$TOKEN_PATH" ]]; then
      OSF_TOKEN=$(<"$TOKEN_PATH")
    else
      echo -n "🔐 Enter your OSF_TOKEN: " >&2
      read -rs OSF_TOKEN
      echo >&2
      echo "$OSF_TOKEN" > "$TOKEN_PATH"
      chmod 600 "$TOKEN_PATH"
      log "INFO" "Token saved to $TOKEN_PATH"
    fi
  fi
  RESPONSE=$(curl -s -w "\n%{http_code}" -o "$TMP_JSON_TOKEN" "https://api.osf.io/v2/users/me/" \
    -H "Authorization: Bearer $OSF_TOKEN")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  [[ "$HTTP_CODE" == "200" ]] || error "Invalid OSF token (HTTP $HTTP_CODE)"
}

# === Auto-Generate osf.yaml ===
init_mode() {
  log "INFO" "Scanning project directory..."
  mapfile -t ALL_FILES < <(find "$BASEDIR" -type f \( \
    -name '*.md' -o -name '*.pdf' -o -name '*.tex' -o -name '*.csv' -o -name '*.txt' \
    -o -name '*.rtf' -o -name '*.doc' -o -name '*.docx' -o -name '*.odt' \
    -o -name '*.xls' -o -name '*.xlsx' -o -name '*.ods' -o -name '*.ppt' -o -name '*.pptx' \
    -o -name '*.odp' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.gif' \
    -o -name '*.svg' -o -name '*.tiff' -o -name '*.bmp' -o -name '*.webp' \
    -o -name '*.sh' -o -name '*.py' -o -name '*.rb' -o -name '*.pl' -o -name '*.js' \
    -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.xml' \
    -o -name 'LICENSE*' -o -name 'COPYING*' \
    \) ! -path "*/.git/*" ! -path "*/.gitfield/*" ! -path "*/.legacy-gitfield/*" | sort -u)

  if [[ ${#ALL_FILES[@]} -gt 0 ]]; then
    IGNORED_FILES=$(git check-ignore "${ALL_FILES[@]}" 2>/dev/null || true)
    if [[ -n "$IGNORED_FILES" ]]; then
      log "INFO" "Ignored files due to .gitignore: $IGNORED_FILES"
      mapfile -t ALL_FILES < <(printf '%s\n' "${ALL_FILES[@]}" | grep -vF "$IGNORED_FILES" | sort -u)
    fi
  fi

  [[ ${#ALL_FILES[@]} -gt 0 ]] || log "WARN" "No files detected in the repository!"
  log "INFO" "Files detected: ${ALL_FILES[*]}"

  detect_file() {
    local keywords=("$@")
    for file in "${ALL_FILES[@]}"; do
      for kw in "${keywords[@]}"; do
        if [[ "${file,,}" == *"${kw,,}"* ]]; then
          echo "$file"
          return 0
        fi
      done
    done
  }

  WIKI_PATH=$(detect_file "wiki.md" "wiki" "home.md")
  README_PATH=$(detect_file "readme.md" "README.md")
  PAPER_PATH=$(detect_file "main.pdf" "theory.pdf" "paper.pdf" "manuscript.pdf")

  DOCS=()
  ESSAYS=()
  IMAGES=()
  SCRIPTS=()
  DATA=()
  FILES=()
  for f in "${ALL_FILES[@]}"; do
    case "$f" in
      "$WIKI_PATH"|"$README_PATH"|"$PAPER_PATH") continue ;;
    esac

    if [[ "$f" =~ \.(jpg|jpeg|png|gif|svg|tiff|bmp|webp)$ ]]; then
      IMAGES+=("$f")
    elif [[ "$f" =~ \.(sh|py|rb|pl|js)$ ]]; then
      SCRIPTS+=("$f")
    elif [[ "$f" =~ \.(csv|json|xml|yaml|yml)$ ]]; then
      DATA+=("$f")
    elif [[ "$f" =~ \.(md|pdf|tex|doc|docx|odt|xls|xlsx|ods|ppt|pptx|odp|txt|rtf)$ ]] || [[ "$(basename "$f")" =~ ^(LICENSE|COPYING) ]]; then
      if [[ "$f" =~ /docs/ ]] || [[ "${f,,}" =~ (guide|tutorial|howto|manual|documentation|workflow|readme) ]]; then
        DOCS+=("$f")
      elif [[ "$f" =~ /essays/|/notes/ ]] || [[ "${f,,}" =~ (essay|note|draft|reflection) ]]; then
        ESSAYS+=("$f")
      else
        FILES+=("$f")
      fi
    fi
  done

  log "INFO" "Generating osf.yaml..."
  {
    echo "# osf.yaml - Configuration for publishing to OSF"
    echo "# Generated on $(date -Iseconds)"
    echo "# Edit this file to customize what gets published to OSF."
    echo
    echo "title: \"$(basename "$BASEDIR")\""
    echo "description: \"Auto-generated by GitField OSF publisher on $(date -Iseconds)\""
    echo "category: \"project\""
    echo "public: false"
    echo "tags: [gitfield, auto-generated]"

    echo
    echo "# Wiki: Main wiki page for your OSF project (wiki.md, home.md)."
    if [[ -n "$WIKI_PATH" ]]; then
      echo "wiki:"
      echo "  path: \"${WIKI_PATH#$BASEDIR/}\""
      echo "  overwrite: true"
    else
      echo "# wiki: Not found. Place a 'wiki.md' in your repository to auto-detect."
    fi

    echo
    echo "# Readme: Main README file (readme.md, README.md)."
    if [[ -n "$README_PATH" ]]; then
      echo "readme:"
      echo "  path: \"${README_PATH#$BASEDIR/}\""
    else
      echo "# readme: Not found. Place a 'README.md' in your repository root."
    fi

    echo
    echo "# Paper: Primary academic paper (main.pdf, paper.pdf)."
    if [[ -n "$PAPER_PATH" ]]; then
      echo "paper:"
      echo "  path: \"${PAPER_PATH#$BASEDIR/}\""
      echo "  name: \"$(basename "$PAPER_PATH")\""
    else
      echo "# paper: Not found. Place a PDF (e.g., 'main.pdf') in your repository."
    fi

    if ((${#DOCS[@]})); then
      echo
      echo "# Docs: Documentation files (.md, .pdf, etc.) in docs/ or with keywords like 'guide'."
      echo "docs:"
      for doc in "${DOCS[@]}"; do
        relative_path="${doc#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi

    if ((${#ESSAYS[@]})); then
      echo
      echo "# Essays: Written essays (.md, .pdf, etc.) in essays/ or with keywords like 'essay'."
      echo "essays:"
      for essay in "${ESSAYS[@]}"; do
        relative_path="${essay#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi

    if ((${#IMAGES[@]})); then
      echo
      echo "# Images: Image files (.jpg, .png, etc.)."
      echo "images:"
      for image in "${IMAGES[@]}"; do
        relative_path="${image#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi

    if ((${#SCRIPTS[@]})); then
      echo
      echo "# Scripts: Executable scripts (.sh, .py, etc.) in bin/, scripts/, or tools/."
      echo "scripts:"
      for script in "${SCRIPTS[@]}"; do
        relative_path="${script#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi

    if ((${#DATA[@]})); then
      echo
      echo "# Data: Structured data files (.csv, .yaml, etc.)."
      echo "data:"
      for datum in "${DATA[@]}"; do
        relative_path="${datum#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi

    if ((${#FILES[@]})); then
      echo
      echo "# Files: Miscellaneous files (.md, LICENSE, etc.)."
      echo "files:"
      for file in "${FILES[@]}"; do
        relative_path="${file#$BASEDIR/}"
        echo "  - path: \"$relative_path\""
        echo "    name: \"$relative_path\""
      done
    fi
  } > "$OSF_YAML"

  log "INFO" "Wiki: $WIKI_PATH, Readme: $README_PATH, Paper: $PAPER_PATH"
  log "INFO" "Docs: ${DOCS[*]}"
  log "INFO" "Essays: ${ESSAYS[*]}"
  log "INFO" "Images: ${IMAGES[*]}"
  log "INFO" "Scripts: ${SCRIPTS[*]}"
  log "INFO" "Data: ${DATA[*]}"
  log "INFO" "Files: ${FILES[*]}"

  jq -n \
    --argjson all "$(printf '%s\n' "${ALL_FILES[@]}" | jq -R . | jq -s .)" \
    --argjson docs "$(printf '%s\n' "${DOCS[@]}" | jq -R . | jq -s .)" \
    --argjson files "$(printf '%s\n' "${FILES[@]}" | jq -R . | jq -s .)" \
    --argjson scripts "$(printf '%s\n' "${SCRIPTS[@]}" | jq -R . | jq -s .)" \
    --arg osf_yaml "$OSF_YAML" \
    '{detected_files: $all, classified: {docs: $docs, files: $files, scripts: $scripts}, osf_yaml_path: $osf_yaml}' > "$SCAN_LOG_INIT"

  log "INFO" "Generated $OSF_YAML and scan log"
  echo "✅ osf.yaml generated at $OSF_YAML." >&2
}

# === Generate Default Wiki with Links ===
generate_wiki() {
  local wiki_path
  wiki_path=$(yq e '.wiki.path' "$OSF_YAML")
  if [[ "$wiki_path" != "null" && ! -f "$wiki_path" ]]; then
    log "INFO" "Generating default wiki at $wiki_path..."
    mkdir -p "$(dirname "$wiki_path")"
    {
      echo "# Auto-Generated Wiki for $(yq e '.title' "$OSF_YAML")"
      echo
      echo "## Project Overview"
      echo "$(yq e '.description' "$OSF_YAML")"
      echo
      echo "## Repository Info"
      echo "- **Last Commit**: $(git log -1 --pretty=%B 2>/dev/null || echo "No git commits")"
      echo "- **Commit Hash**: $(git rev-parse HEAD 2>/dev/null || echo "N/A")"
      if [[ -f "$(yq e '.readme.path' "$OSF_YAML")" ]]; then
        echo
        echo "## README Preview"
        head -n 10 "$(yq e '.readme.path' "$OSF_YAML")"
      fi
      echo
      echo "## Internal Documents"
      echo "Links to documents uploaded to OSF (will be populated after --push/--overwrite):"
      for section in docs essays images scripts data files; do
        local count
        count=$(yq e ".${section} | length" "$OSF_YAML")
        if [[ "$count" != "0" && "$count" != "null" ]]; then
          echo
          echo "### $(echo "$section" | tr '[:lower:]' '[:upper:]')"
          for ((i = 0; i < count; i++)); do
            local name
            name=$(yq e ".${section}[$i].name" "$OSF_YAML")
            echo "- [$name](https://osf.io/{NODE_ID}/files/osfstorage/$name)"
          done
        fi
      done
    } > "$wiki_path"
    log "INFO" "Default wiki generated at $wiki_path"
  fi
}

# === Validate YAML ===
validate_yaml() {
  log "INFO" "Validating $OSF_YAML..."
  [[ -f "$OSF_YAML" ]] || init_mode
  for field in title description category public; do
    [[ $(yq e ".$field" "$OSF_YAML") != "null" ]] || error "Missing field: $field in $OSF_YAML"
  done
}

# === Validate and Read push_log.json ===
read_project_id() {
  if [[ ! -f "$SCAN_LOG_PUSH" ]] || ! jq -e '.' "$SCAN_LOG_PUSH" >/dev/null 2>&1; then
    log "WARN" "No valid push_log.json found"
    echo ""
    return
  fi
  NODE_ID=$(jq -r '.project_id // ""' "$SCAN_LOG_PUSH")
  echo "$NODE_ID"
}

# === Search for Existing Project by Title ===
find_project_by_title() {
  local title="$1"
  log "INFO" "Searching for project: $title"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-$(uuidgen)"
    return
  fi
  ENCODED_TITLE=$(jq -r -n --arg title "$title" '$title|@uri')
  RESPONSE=$(curl -s -w "\n%{http_code}" -o "$TMP_JSON_PROJECT" "https://api.osf.io/v2/nodes/?filter[title]=$ENCODED_TITLE" \
    -H "Authorization: Bearer $OSF_TOKEN")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  if [[ "$HTTP_CODE" != "200" ]]; then
    log "WARN" "Failed to search for project (HTTP $HTTP_CODE)"
    echo ""
    return
  fi
  NODE_ID=$(jq -r '.data[0].id // ""' "$TMP_JSON_PROJECT")
  [[ -n "$NODE_ID" ]] && log "INFO" "Found project '$title': $NODE_ID"
  echo "$NODE_ID"
}

# === Upload Helpers ===
sanitize_filename() {
  local name="$1"
  echo "$name" | tr -d '\n' | sed 's/[^[:alnum:]._-]/_/g'
}

upload_file() {
  local path="$1" name="$2"
  local sanitized_name encoded_name
  sanitized_name=$(sanitize_filename "$name")
  encoded_name=$(jq -r -n --arg name "$sanitized_name" '$name|@uri')
  log "INFO" "Uploading $name (sanitized: $sanitized_name) from $path"
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  CHECK_URL="https://api.osf.io/v2/nodes/$NODE_ID/files/osfstorage/?filter[name]=$encoded_name"
  RESPONSE=$(curl -s -w "\n%{http_code}" -o "$TMP_JSON_PROJECT" "$CHECK_URL" \
    -H "Authorization: Bearer $OSF_TOKEN")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

  if [[ -z "$HTTP_CODE" ]]; then
    log "WARN" "No HTTP status for $sanitized_name check. Assuming file does not exist."
  elif [[ "$HTTP_CODE" == "200" ]]; then
    FILE_ID=$(jq -r '.data[0].id // ""' "$TMP_JSON_PROJECT")
    if [[ -n "$FILE_ID" ]]; then
      if [[ "$MODE" == "overwrite" ]]; then
        log "INFO" "Deleting existing file $sanitized_name (ID: $FILE_ID)..."
        DEL_RESPONSE=$(curl -s -w "%{http_code}" -X DELETE "https://api.osf.io/v2/files/$FILE_ID/" \
          -H "Authorization: Bearer $OSF_TOKEN")
        [[ "$DEL_RESPONSE" == "204" ]] || log "WARN" "Failed to delete $sanitized_name (HTTP $DEL_RESPONSE)"
      else
        log "WARN" "File $sanitized_name exists. Use --overwrite to replace."
        return 1
      fi
    fi
  elif [[ "$HTTP_CODE" != "404" ]]; then
    log "WARN" "Check for $sanitized_name failed (HTTP $HTTP_CODE)"
  fi

  UPLOAD_URL="https://files.osf.io/v1/resources/$NODE_ID/providers/osfstorage/?kind=file&name=$encoded_name"
  RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$UPLOAD_URL" \
    -H "Authorization: Bearer $OSF_TOKEN" \
    -F "file=@$path")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  if [[ "$HTTP_CODE" != "201" ]]; then
    log "WARN" "Failed to upload $name (HTTP $HTTP_CODE)"
    return 1
  fi
  echo "📤 Uploaded $name to https://osf.io/$NODE_ID/" >&2
  UPLOADED_FILES+=("$name")
  return 0
}

upload_group() {
  local section="$1"
  local count
  count=$(yq e ".${section} | length" "$OSF_YAML")
  log "INFO" "Uploading $section group ($count items)"
  if [[ "$count" == "0" || "$count" == "null" ]]; then
    return 0
  fi
  local success_count=0
  for ((i = 0; i < count; i++)); do
    local path name
    path=$(yq e ".${section}[$i].path" "$OSF_YAML")
    name=$(yq e ".${section}[$i].name" "$OSF_YAML")
    if [[ -f "$BASEDIR/$path" ]]; then
      upload_file "$BASEDIR/$path" "$name" && ((success_count++))
    else
      log "WARN" "File $path not found, skipping"
    fi
  done
  log "INFO" "Uploaded $success_count/$count items in $section"
  return 0
}

upload_wiki() {
  local wiki_path
  wiki_path=$(yq e '.wiki.path' "$OSF_YAML")
  if [[ "$wiki_path" != "null" && -f "$BASEDIR/$wiki_path" ]]; then
    log "INFO" "Pushing wiki from $wiki_path"
    if [[ "$DRY_RUN" == "true" ]]; then
      return 0
    fi
    # Update wiki content with actual OSF links
    local wiki_content
    wiki_content=$(cat "$BASEDIR/$wiki_path")
    for file in "${UPLOADED_FILES[@]}"; do
      wiki_content=$(echo "$wiki_content" | sed "s|https://osf.io/{NODE_ID}/files/osfstorage/$file|https://osf.io/$NODE_ID/files/osfstorage/$file|g")
    done
    echo "$wiki_content" > "$BASEDIR/$wiki_path.updated"
    CONTENT=$(jq -Rs . < "$BASEDIR/$wiki_path.updated")
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "https://api.osf.io/v2/nodes/$NODE_ID/wikis/home/" \
      -H "Authorization: Bearer $OSF_TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      -d @- <<EOF
{
  "data": {
    "type": "wikis",
    "attributes": {
      "content": $CONTENT
    }
  }
}
EOF
    )
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    if [[ "$HTTP_CODE" != "200" ]]; then
      log "WARN" "Failed to upload wiki (HTTP $HTTP_CODE)"
      return 1
    fi
    echo "📜 Pushed wiki to https://osf.io/$NODE_ID/" >&2
    rm -f "$BASEDIR/$wiki_path.updated"
    return 0
  fi
  log "INFO" "No wiki to upload"
  return 0
}

# === Push Mode ===
push_mode() {
  local MODE="$1"
  validate_yaml
  generate_wiki
  get_token

  local title description category public
  title=$(yq e '.title' "$OSF_YAML")
  description=$(yq e '.description' "$OSF_YAML")
  category=$(yq e '.category' "$OSF_YAML")
  public=$(yq e '.public' "$OSF_YAML" | grep -E '^(true|false)$' || error "Invalid 'public' value")

  NODE_ID=""
  if [[ "$MODE" == "overwrite" || "$MODE" == "push" ]]; then
    NODE_ID=$(read_project_id)
    if [[ -n "$NODE_ID" ]]; then
      log "INFO" "Using existing OSF project ID: $NODE_ID"
      RESPONSE=$(curl -s -w "\n%{http_code}" -o "$TMP_JSON_PROJECT" "https://api.osf.io/v2/nodes/$NODE_ID/" \
        -H "Authorization: Bearer $OSF_TOKEN")
      HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
      if [[ "$HTTP_CODE" != "200" ]]; then
        log "WARN" "Project $NODE_ID not found (HTTP $HTTP_CODE)"
        NODE_ID=""
      fi
    fi
  fi

  if [[ -z "$NODE_ID" ]] && [[ "$MODE" == "overwrite" || "$MODE" == "push" ]]; then
    NODE_ID=$(find_project_by_title "$title")
  fi

  if [[ -z "$NODE_ID" ]]; then
    log "INFO" "Creating new OSF project..."
    if [[ "$DRY_RUN" == "true" ]]; then
      NODE_ID="dry-run-$(uuidgen)"
    else
      RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.osf.io/v2/nodes/" \
        -H "Authorization: Bearer $OSF_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        -d @- <<EOF
{
  "data": {
    "type": "nodes",
    "attributes": {
      "title": "$title",
      "description": "$description",
      "category": "$category",
      "public": $public
    }
  }
}
EOF
      )
      HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
      [[ "$HTTP_CODE" == "201" ]] || error "Project creation failed (HTTP $HTTP_CODE)"
      NODE_ID=$(jq -r '.data.id' "$TMP_JSON_PROJECT")
      [[ "$NODE_ID" != "null" && -n "$NODE_ID" ]] || error "No valid OSF project ID returned"
      log "INFO" "Project created: $NODE_ID"
    fi
  fi

  [[ -n "$NODE_ID" ]] || error "Failed to determine OSF project ID"

  log "INFO" "Starting file uploads to project $NODE_ID"
  declare -a UPLOADED_FILES
  local overall_success=0
  if [[ $(yq e '.readme.path' "$OSF_YAML") != "null" ]]; then
    path=$(yq e '.readme.path' "$OSF_YAML")
    [[ -f "$BASEDIR/$path" ]] && upload_file "$BASEDIR/$path" "$(basename "$path")" && overall_success=1
  fi
  if [[ $(yq e '.paper.path' "$OSF_YAML") != "null" ]]; then
    path=$(yq e '.paper.path' "$OSF_YAML")
    name=$(yq e '.paper.name' "$OSF_YAML")
    [[ -f "$BASEDIR/$path" ]] && upload_file "$BASEDIR/$path" "$name" && overall_success=1
  fi
  upload_group "docs" && overall_success=1
  upload_group "essays" && overall_success=1
  upload_group "images" && overall_success=1
  upload_group "scripts" && overall_success=1
  upload_group "data" && overall_success=1
  upload_group "files" && overall_success=1
  upload_wiki && overall_success=1

  if [[ "$DRY_RUN" != "true" ]]; then
    jq -n \
      --arg node_id "$NODE_ID" \
      --arg title "$title" \
      --arg pushed_at "$(date -Iseconds)" \
      '{project_id: $node_id, project_title: $title, pushed_at: $pushed_at}' > "$SCAN_LOG_PUSH"
  fi

  if [[ "$overall_success" -eq 1 ]]; then
    log "INFO" "OSF Push Complete! View project: https://osf.io/$NODE_ID/"
    echo "✅ OSF Push Complete! View project: https://osf.io/$NODE_ID/" >&2
  else
    error "OSF Push Failed: No files uploaded"
  fi
}

# === Validate Mode ===
validate_mode() {
  validate_yaml
  log "INFO" "Checking file existence..."
  for section in readme paper docs essays images scripts data files wiki; do
    if [[ "$section" == "docs" || "$section" == "essays" || "$section" == "images" || "$section" == "scripts" || "$section" == "data" || "$section" == "files" ]]; then
      local count
      count=$(yq e ".${section} | length" "$OSF_YAML")
      for ((i = 0; i < count; i++)); do
        local path
        path=$(yq e ".${section}[$i].path" "$OSF_YAML")
        [[ -f "$BASEDIR/$path" ]] || log "WARN" "File $path in $section not found"
      done
    elif [[ "$section" != "wiki" ]]; then
      local path
      path=$(yq e ".${section}.path" "$OSF_YAML")
      if [[ "$path" != "null" && -n "$path" && ! -f "$BASEDIR/$path" ]]; then
        log "WARN" "File $path in $section not found"
      fi
    fi
  done
  log "INFO" "Validation complete"
  echo "✅ Validation complete. Check logs: $LOG_DIR/gitfield_$(date +%Y%m%d).log" >&2
}

# === Clean Mode ===
clean_mode() {
  log "INFO" "Cleaning .gitfield directory..."
  rm -rf "$GITFIELD_DIR"
  mkdir -p "$GITFIELD_DIR" "$LOG_DIR"
  log "INFO" "Cleaned .gitfield directory"
  echo "✅ Cleaned .gitfield directory" >&2
}

# === Help Menu ===
show_help() {
  local verbose="$1"
  if [[ "$verbose" == "true" ]]; then
    cat <<EOF
Usage: $0 [OPTION]

Publish content from a Git repository to OSF.

Options:
  --init          Generate osf.yaml and scan log without pushing to OSF
  --push          Push to existing OSF project or create new
  --overwrite     Reuse existing OSF project and overwrite files
  --force         Alias for --overwrite
  --dry-run       Simulate actions (use with --push or --overwrite)
  --validate      Check osf.yaml and file existence without pushing
  --clean         Remove .gitfield logs and start fresh
  --help          Show this help message (--help --verbose for more details)

Examples:
  $0 --init       # Create osf.yaml based on repo contents
  $0 --push       # Push to OSF
  $0 --overwrite  # Push to OSF, overwriting files
  $0 --dry-run --push  # Simulate a push

Repository Structure and Supported Files:
  - Wiki: wiki.md, home.md (root or docs/)
  - Readme: readme.md, README.md (root)
  - Paper: main.pdf, paper.pdf (root or docs/)
  - Docs: .md, .pdf, etc., in docs/ or with keywords like 'guide'
  - Essays: .md, .pdf, etc., in essays/ or with keywords like 'essay'
  - Images: .jpg, .png, etc., in any directory
  - Scripts: .sh, .py, etc., in bin/, scripts/, or tools/
  - Data: .csv, .yaml, etc., in any directory
  - Files: Miscellaneous files (.md, LICENSE, etc.)

After running --init, open osf.yaml to customize.
EOF
  else
    cat <<EOF
Usage: $0 [OPTION]

Publish content from a Git repository to OSF.

Options:
  --init          Generate osf.yaml
  --push          Push to OSF
  --overwrite     Push to OSF, overwrite files
  --force         Alias for --overwrite
  --dry-run       Simulate actions (with --push/--overwrite)
  --validate      Check osf.yaml and files
  --clean         Remove .gitfield logs
  --help          Show this help (--help --verbose for more)

Examples:
  $0 --init       # Create osf.yaml
  $0 --push       # Push to OSF
EOF
  fi
}

# === CLI Dispatcher ===
DRY_RUN="false"
VERBOSE="false"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --init) MODE="init" ;;
    --push) MODE="push" ;;
    --overwrite|--force) MODE="overwrite" ;;
    --dry-run) DRY_RUN="true" ;;
    --validate) MODE="validate" ;;
    --clean) MODE="clean" ;;
    --verbose) VERBOSE="true" ;;
    --help) show_help "$VERBOSE"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; show_help "false"; exit 1 ;;
  esac
  shift
done

case "$MODE" in
  init) init_mode ;;
  push|overwrite) push_mode "$MODE" ;;
  validate) validate_mode ;;
  clean) clean_mode ;;
  *) show_help "false"; exit 0 ;;
esac
