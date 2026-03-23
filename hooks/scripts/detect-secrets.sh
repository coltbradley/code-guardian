#!/bin/bash
# detect-secrets.sh - Detects common secret patterns in staged git files.
# Exits with code 2 to block the commit if secrets are found.

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'glpat-[a-zA-Z0-9\-]{20,}'
  'password\s*[=:]\s*["'"'"'][^"'"'"']{4,}'
  'secret\s*[=:]\s*["'"'"'][^"'"'"']{4,}'
  'api_key\s*[=:]\s*["'"'"'][^"'"'"']{4,}'
)

FOUND=0
FINDINGS=()

for FILE in $STAGED_FILES; do
  # Skip files that don't exist (deleted files)
  [ -f "$FILE" ] || continue

  # Skip example, sample, template, test, and mock files
  case "$FILE" in
    *.example|*.sample|*.template) continue ;;
    *example*|*sample*|*template*|*test*|*mock*|*spec*) continue ;;
  esac

  for PATTERN in "${PATTERNS[@]}"; do
    MATCHES=$(git diff --cached -- "$FILE" | grep '^+' | grep -v '^+++' | grep -P "$PATTERN" 2>/dev/null)
    if [ -n "$MATCHES" ]; then
      FOUND=1
      FINDINGS+=("  $FILE  (pattern: $PATTERN)")
    fi
  done
done

if [ "$FOUND" -eq 1 ]; then
  echo ""
  echo "BLOCKED: Potential secrets detected in staged files."
  echo ""
  echo "Flagged locations:"
  for FINDING in "${FINDINGS[@]}"; do
    echo "$FINDING"
  done
  echo ""
  echo "Guidance:"
  echo "  - Remove secrets from source files before committing."
  echo "  - Use environment variables or a secrets manager instead."
  echo "  - If this is a false positive, add the file to .gitignore"
  echo "    or use a .env.example file with placeholder values."
  echo ""
  exit 2
fi

exit 0
