#!/bin/bash

# ----------------------------
# Gitfield Metadata Sync Tool
# ----------------------------

# CONFIGURATION
DRIVE_REMOTE="gdrive"
GITFIELD_ROOT="$HOME/gdrive/gitfield"
SCRIPT_NAME="sync-metadata.sh"

# Ensure rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "rclone is not installed. Installing..."
    sudo apt update && sudo apt install -y rclone
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    sudo apt update && sudo apt install -y jq
fi

# Get Git repo root
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ Not inside a Git repository."
    exit 1
fi

REPO_NAME=$(basename "$REPO_DIR")
GDRIVE_PATH="gitfield/$REPO_NAME"
SYNC_LOG="$REPO_DIR/.gitfield/sync-log.md"
README="$REPO_DIR/README.md"

echo "🔍 Detecting Google Drive folder: $GDRIVE_PATH..."

# Mount ~/gdrive if not mounted
MOUNTPOINT="$HOME/gdrive"
if ! mount | grep -q "$MOUNTPOINT"; then
    echo "⚙️ Mounting Google Drive to $MOUNTPOINT..."
    mkdir -p "$MOUNTPOINT"
    rclone mount "$DRIVE_REMOTE:/" "$MOUNTPOINT" --vfs-cache-mode writes --daemon
    sleep 3
fi

# Share link generation
SHARE_URL=$(rclone link "$DRIVE_REMOTE:$GDRIVE_PATH")
if [ -z "$SHARE_URL" ]; then
    echo "❌ Could not generate Google Drive share link."
    exit 1
fi

# Optional: Construct drv.tw link (manual fallback example)
DRV_URL="https://drv.tw/view/$(basename "$SHARE_URL")"

# Write metadata to sync log
mkdir -p "$(dirname "$SYNC_LOG")"
cat <<EOF >> "$SYNC_LOG"

## 🔄 Sync Metadata — $(date +%F)

- 📁 **Google Drive Folder**: [$REPO_NAME]($SHARE_URL)
- 🌐 **Published View**: [$DRV_URL]($DRV_URL)

EOF

# Append to README if not already present
if ! grep -q "$SHARE_URL" "$README"; then
    echo "📘 Updating README..."
    cat <<EOF >> "$README"

---

## 🔍 External Access

- 🔗 **Google Drive Folder**: [$REPO_NAME]($SHARE_URL)
- 🌐 **Published View**: [$DRV_URL]($DRV_URL)

EOF
else
    echo "✅ README already contains sync links."
fi

echo "✅ Metadata sync complete."
