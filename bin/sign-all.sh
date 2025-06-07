#!/bin/bash
# sign-all.sh — Recursive Signature Script
# Author: Solaria & Mark Randall Havens 🌀
# Purpose: Automatically GPG-sign all matching files with .asc signatures

# ───── CONFIGURABLE OPTIONS ───────────────────────────────────────────────
EXTENSIONS=("md" "txt")           # File types to sign
RECURSIVE=true                    # true = recurse into subdirectories
FORCE=false                       # true = re-sign even if .asc exists
SIGNATURE_SUFFIX=".asc"          # .asc for armored detached signature
OUTPUT_LOG="gitfield-signed.log" # Signature log file
GPG_FLAGS="--armor --detach-sign"

# ───── RITUAL HEADER ──────────────────────────────────────────────────────
echo ""
echo "🌀 [SIGN-ALL] Beginning recursive signing ritual..."
echo "📅 Timestamp: $(date)"
echo "🔑 Using GPG Key: $(gpg --list-secret-keys --with-colons | grep '^uid' | cut -d':' -f10 | head -n1)"
echo ""

# ───── FIND AND SIGN FILES ────────────────────────────────────────────────
for ext in "${EXTENSIONS[@]}"; do
  if [ "$RECURSIVE" = true ]; then
    FILES=$(find . -type f -name "*.${ext}")
  else
    FILES=$(find . -maxdepth 1 -type f -name "*.${ext}")
  fi

  for file in $FILES; do
    sigfile="${file}${SIGNATURE_SUFFIX}"

    if [ -f "$sigfile" ] && [ "$FORCE" = false ]; then
      echo "⚠️  Skipping already signed: $file"
      continue
    fi

    echo "🔏 Signing: $file"
    gpg $GPG_FLAGS --output "$sigfile" "$file"
    
    if [ $? -eq 0 ]; then
      echo "✅ Signed: $file -> $sigfile" | tee -a "$OUTPUT_LOG"
    else
      echo "❌ Error signing: $file" | tee -a "$OUTPUT_LOG"
    fi
  done
done

# ───── WRAP UP ─────────────────────────────────────────────────────────────
echo ""
echo "🧾 Log saved to: $OUTPUT_LOG"
echo "🗝️  To verify: gpg --verify filename${SIGNATURE_SUFFIX}"
echo "✨ Recursive signature ritual complete."
