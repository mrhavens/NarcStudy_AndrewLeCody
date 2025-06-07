#!/bin/bash

echo "🛠️ [GITFIELD] Beginning auto-resolution ritual..."

# Ensure we’re in a Git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Not a Git repository. Aborting."
  exit 1
fi

# Ensure at least one commit exists
if ! git log > /dev/null 2>&1; then
  echo "🌀 No commits found. Creating seed commit..."
  git add .
  git commit --allow-empty -m "🌱 Seed commit for Radicle and GitField rituals"
fi

# GPG sign commit if enabled
GPG_KEY=$(git config user.signingkey)
if [ -n "$GPG_KEY" ]; then
  echo "🔏 GPG commit signing enabled with key: $GPG_KEY"
  git commit -S --allow-empty -m "🔐 Ritual signed commit [auto]"
fi

# Stage and commit any local changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add .
  git commit -m "🔄 Auto-resolve commit from gitfield-resolve.sh"
  echo "✅ Local changes committed."
else
  echo "✅ No changes to commit."
fi

# Loop through remotes
remotes=$(git remote)
for remote in $remotes; do
  echo "🔍 Checking $remote for divergence..."
  git fetch $remote
  if git merge-base --is-ancestor $remote/master master; then
    echo "✅ $remote is already in sync."
  else
    echo "⚠️ Divergence with $remote. Attempting merge..."
    git pull --no-rebase $remote master --strategy-option=theirs --allow-unrelated-histories
    git push $remote master || echo "⚠️ Final push failed to $remote"
  fi
done

# ==== RADICLE SECTION ====

echo "🌱 [RADICLE] Verifying Radicle status..."

# Check if Radicle is initialized
if ! rad inspect > /dev/null 2>&1; then
  echo "🌿 No Radicle project detected. Attempting init..."
  RAD_INIT_OUTPUT=$(rad init --name git-sigil --description "GitField Ritual Repo")
  echo "$RAD_INIT_OUTPUT"
fi

# Push to Radicle and announce
echo "📡 Announcing to Radicle network..."
rad push --announce

# Get project ID
PROJECT_ID=$(rad inspect | grep "Project ID" | awk '{print $NF}')
if [ -n "$PROJECT_ID" ]; then
  echo "📜 Logging Radicle project ID to .gitfield/radicle.sigil.md"
  mkdir -p .gitfield
  echo "# Radicle Sigil" > .gitfield/radicle.sigil.md
  echo "**Project ID:** \`$PROJECT_ID\`" >> .gitfield/radicle.sigil.md
fi

echo "✅ GitField resolution ritual complete."
