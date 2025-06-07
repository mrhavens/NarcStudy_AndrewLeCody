#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

GIT_REMOTE_NAME="github"
REPO_NAME=$(basename "$(pwd)")
DEFAULT_NAME="Mark Randall Havens"
DEFAULT_EMAIL="mark.r.havens@gmail.com"

# ────────────────
# Logging Helpers
# ────────────────
info()  { echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

# ────────────────
# Ensure Git is Installed
# ────────────────
if ! command -v git &>/dev/null; then
  info "Installing Git..."
  sudo apt update && sudo apt install git -y || error "Failed to install Git"
else
  info "Git already installed: $(git --version)"
fi

# ────────────────
# Ensure GitHub CLI is Installed
# ────────────────
if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install gh -y || error "Failed to install GitHub CLI"
else
  info "GitHub CLI already installed: $(gh --version | head -n 1)"
fi

# ────────────────
# Ensure GitHub CLI is Authenticated
# ────────────────
if ! gh auth status &>/dev/null; then
  info "Authenticating GitHub CLI..."
  gh auth login || error "GitHub authentication failed"
else
  info "GitHub CLI authenticated."
fi

# ────────────────
# Ensure Git Identity is Set
# ────────────────
USER_NAME=$(git config --global user.name || true)
USER_EMAIL=$(git config --global user.email || true)

if [[ -z "$USER_NAME" || -z "$USER_EMAIL" ]]; then
  info "Setting global Git identity..."
  git config --global user.name "$DEFAULT_NAME"
  git config --global user.email "$DEFAULT_EMAIL"
  info "Git identity set to: $DEFAULT_NAME <$DEFAULT_EMAIL>"
else
  info "Git identity already set to: $USER_NAME <$USER_EMAIL>"
fi

# ────────────────
# Initialize Git Repo If Missing
# ────────────────
if [ ! -d ".git" ]; then
  info "Initializing local Git repository..."
  git init || error "Failed to initialize git"
  git add . || warn "Nothing to add"
  git commit -m "Initial commit" || warn "Nothing to commit"
else
  info "Git repository already initialized."
fi

# ────────────────
# Ensure at Least One Commit Exists
# ────────────────
if ! git rev-parse HEAD &>/dev/null; then
  info "Creating first commit..."
  git add . || warn "Nothing to add"
  git commit -m "Initial commit" || warn "Nothing to commit"
fi

# ────────────────
# Create Remote GitHub Repo If Missing
# ────────────────
if ! git remote get-url "$GIT_REMOTE_NAME" &>/dev/null; then
  info "Creating GitHub repository '$REPO_NAME'..."
  gh repo create "$REPO_NAME" --public --source=. --remote="$GIT_REMOTE_NAME" || error "Failed to create GitHub repo"
else
  info "Remote '$GIT_REMOTE_NAME' already set to: $(git remote get-url $GIT_REMOTE_NAME)"
fi

# ────────────────
# Commit Changes If Needed
# ────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  info "Changes detected — committing..."
  git add .
  git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')" || warn "Nothing to commit"
else
  info "No uncommitted changes found."
fi

# ────────────────
# Final Push — Always Push, Even If No Upstream
# ────────────────
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

if ! git config --get branch."$BRANCH_NAME".remote &>/dev/null; then
  info "No upstream detected. Setting upstream and pushing..."
  git push -u "$GIT_REMOTE_NAME" "$BRANCH_NAME" || error "Failed to push and set upstream"
else
  info "Pushing to remote '$GIT_REMOTE_NAME'..."
  git push "$GIT_REMOTE_NAME" "$BRANCH_NAME" || error "Push failed"
fi
