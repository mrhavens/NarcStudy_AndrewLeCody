#!/bin/bash
# gitfield-resolve.sh — 🧠 Recursive GitField Self-Healing Sync Engine
# Author: Solaria + Mark Randall Havens 🌀
# Version: 𝛂∞.21

LOG_FILE=".gitfield/last_resolution.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "🛠️ [GITFIELD] Beginning auto-resolution ritual..."

SIGIL_FILES=$(git diff --name-only --diff-filter=U | grep '\.sigil\.md$')
PUSHED_LOG=".gitfield/pushed.log"

resolve_sigil_conflicts() {
  for file in $SIGIL_FILES; do
    echo "⚖️ Resolving conflict in: $file"

    OUR_TIME=$(grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8}' "$file" | head -n1)
    THEIR_TIME=$(grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8}' "$file" | tail -n1)

    if [[ "$OUR_TIME" > "$THEIR_TIME" ]]; then
      echo "🧭 Keeping local version ($OUR_TIME)"
      git checkout --ours "$file"
    else
      echo "🧭 Keeping remote version ($THEIR_TIME)"
      git checkout --theirs "$file"
    fi
    git add "$file"
  done
}

resolve_log_conflict() {
  if [[ -f "$PUSHED_LOG" && $(git ls-files -u | grep "$PUSHED_LOG") ]]; then
    echo "📜 Resolving pushed.log by merging unique lines..."
    git checkout --ours "$PUSHED_LOG"
    cp "$PUSHED_LOG" .log_ours

    git checkout --theirs "$PUSHED_LOG"
    cp "$PUSHED_LOG" .log_theirs

    cat .log_ours .log_theirs | sort | uniq > "$PUSHED_LOG"
    rm .log_ours .log_theirs

    git add "$PUSHED_LOG"
  fi
}

commit_resolution() {
  if git diff --cached --quiet; then
    echo "✅ No changes to commit."
  else
    echo "🖋️ Committing auto-resolved changes with GPG signature..."
    git commit -S -m "🔄 Auto-resolved sigil + log conflicts via gitfield-resolve"
  fi
}

check_and_sync_remotes() {
  for remote in $(git remote); do
    echo "🔍 Checking $remote for divergence..."
    git fetch "$remote" master

    BASE=$(git merge-base master "$remote/master")
    LOCAL=$(git rev-parse master)
    REMOTE=$(git rev-parse "$remote/master")

    if [ "$LOCAL" = "$REMOTE" ]; then
      echo "✅ $remote is already in sync."
    elif [ "$LOCAL" = "$BASE" ]; then
      echo "⬇️ Local is behind $remote. Pulling changes..."
      git pull --no-rebase "$remote" master || echo "⚠️ Pull failed for $remote"
      resolve_sigil_conflicts
      resolve_log_conflict
      commit_resolution
      git push "$remote" master || echo "⚠️ Push failed to $remote"
    elif [ "$REMOTE" = "$BASE" ]; then
      echo "⬆️ Local is ahead of $remote. Pushing..."
      git push "$remote" master || echo "⚠️ Push failed to $remote"
    else
      echo "⚠️ Divergence with $remote. Attempting merge..."
      git pull --no-rebase "$remote" master || echo "❌ Merge failed: Manual fix required."
      resolve_sigil_conflicts
      resolve_log_conflict
      commit_resolution
      git push "$remote" master || echo "⚠️ Final push failed to $remote"
    fi
  done
}

final_force_github() {
  if git remote get-url github &>/dev/null; then
    echo "🧙 Final override: Forcing sync to GitHub..."
    git push --force github master && echo "✅ GitHub forcibly realigned with local truth." || echo "❌ Force push failed. Manual intervention required."
  fi
}

# --- Ritual Sequence ---
resolve_sigil_conflicts
resolve_log_conflict
commit_resolution
check_and_sync_remotes
final_force_github

echo "✅ GitField resolution ritual complete."
