#!/bin/bash

# ──────────────────────────────────────────────────────────────
# ⚙️  GitField GDrive Sync Script
#    Ensures Google Drive is mounted at ~/gdrive and syncs 
#    the current Git repo into ~/gdrive/gitfield/<repo_name>
# ──────────────────────────────────────────────────────────────

set -e

# ⛓ Ensure rsync is installed
if ! command -v rsync &> /dev/null; then
    echo "rsync not found. Attempting to install..."
    sudo apt update && sudo apt install -y rsync
fi

# ⛓ Ensure ~/gdrive exists and is mounted
GDRIVE_PATH="$HOME/gdrive"
GITFIELD_PATH="$GDRIVE_PATH/gitfield"

if [ ! -d "$GDRIVE_PATH" ]; then
    echo "Google Drive folder not found at $GDRIVE_PATH."
    echo "Create it or mount your gdrive before syncing."
    exit 1
fi

mkdir -p "$GITFIELD_PATH"

# ⛓ Ensure current directory is inside a Git repo
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Not inside a Git repository. Aborting sync."
    exit 1
fi

# 🏷 Determine repo name and paths
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
DEST="$GITFIELD_PATH/$REPO_NAME"

# ♻️ Perform rsync (mirror entire repo, preserve structure, show progress)
echo "Syncing '$REPO_NAME' to $DEST..."
rsync -av --delete "$REPO_ROOT/" "$DEST/"

echo "✅ GitField sync complete: $REPO_NAME ➝ $DEST"
