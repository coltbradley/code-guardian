#!/bin/bash
set -euo pipefail

# pre-commit-checks.sh — Combined pre-commit hook.
# Runs three checks on staged files in a single pass:
#   1. Secret detection (API keys, tokens, passwords)
#   2. .env file protection
#   3. Large file blocking (>500KB)
# Exits with code 2 to block the commit if any check fails.

# --- Configuration ---

MAX_BYTES=512000  # 500KB

# Secret patterns (combined regex, single grep -E call per file)
SECRET_PATTERN='sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9\-]{20,}|xox[baprs]-[a-zA-Z0-9\-]{10,}|sk_live_[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]{20,}|SG\.[a-zA-Z0-9_\-]{22,}\.[a-zA-Z0-9_\-]{22,}|AIza[a-zA-Z0-9_\-]{35}|password[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{4,}|secret[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{4,}|api_key[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{4,}'

# --- State ---

SECRETS_FOUND=0
SECRET_FILES=""
ENV_BLOCKED=0
ENV_FILES=""
LARGE_BLOCKED=0
LARGE_FILES=""

# --- Single pass over staged files ---

while IFS= read -r -d '' FILE; do

  # -- Secret detection --
  if [ -f "$FILE" ]; then
    # Skip example/sample/template files
    case "$FILE" in
      *.example|*.sample|*.template) ;;
      # Skip test/mock/spec files
      test/*|tests/*|spec/*|__tests__/*) ;;
      *_test.*|*_spec.*|*.test.*|*.spec.*|*_mock.*|*.mock.*) ;;
      *)
        MATCHES=$(git diff --cached -- "$FILE" | grep '^+' | grep -v '^+++' | grep -E "$SECRET_PATTERN" 2>/dev/null || true)
        if [ -n "$MATCHES" ]; then
          SECRETS_FOUND=1
          SECRET_FILES="$SECRET_FILES  $FILE\n"
        fi
        ;;
    esac
  fi

  # -- .env file protection --
  BASENAME=$(basename "$FILE")
  case "$BASENAME" in
    .env.example|.env.sample|.env.template) ;;
    *.env.example|*.env.sample|*.env.template) ;;
    .env|.env.local|.env.production|.env.development|.env.staging|\
    .env.prod|.env.dev|.env.test|.env.ci|.env.override)
      ENV_BLOCKED=1
      ENV_FILES="$ENV_FILES  $FILE\n"
      ;;
  esac

  # -- Large file check (staged size, not working tree) --
  if [ -f "$FILE" ]; then
    FILE_SIZE=$(git cat-file -s ":$FILE" 2>/dev/null || echo "0")
    if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -gt "$MAX_BYTES" ]; then
      SIZE_KB=$(( FILE_SIZE / 1024 ))
      LARGE_BLOCKED=1
      LARGE_FILES="$LARGE_FILES  $FILE  (${SIZE_KB}KB)\n"
    fi
  fi

done < <(git diff --cached --name-only -z 2>/dev/null)

# --- Report results ---

BLOCKED=0

if [ "$SECRETS_FOUND" -eq 1 ]; then
  BLOCKED=1
  echo ""
  echo "BLOCKED: Potential secrets detected in staged files."
  echo ""
  echo "Flagged files:"
  printf "%b" "$SECRET_FILES"
  echo ""
  echo "Guidance:"
  echo "  - Remove secrets from source files before committing."
  echo "  - Use environment variables or a secrets manager instead."
  echo "  - If this is a false positive, add the file to .gitignore"
  echo "    or use a .env.example file with placeholder values."
fi

if [ "$ENV_BLOCKED" -eq 1 ]; then
  BLOCKED=1
  echo ""
  echo "BLOCKED: Attempted to commit .env file(s) containing potential secrets."
  echo ""
  echo "Blocked files:"
  printf "%b" "$ENV_FILES"
  echo ""
  echo "Guidance:"
  echo "  - Add these files to .gitignore to prevent accidental commits."
  echo "  - Commit a .env.example file with placeholder values instead:"
  echo "      cp .env .env.example"
  echo "      # Replace real values with placeholders, then:"
  echo "      git add .env.example"
fi

if [ "$LARGE_BLOCKED" -eq 1 ]; then
  BLOCKED=1
  echo ""
  echo "BLOCKED: One or more staged files exceed the 500KB size limit."
  echo ""
  echo "Oversized files:"
  printf "%b" "$LARGE_FILES"
  echo ""
  echo "Guidance:"
  echo "  - For large binary assets, use Git LFS: git lfs track '*.extension'"
  echo "  - For generated or build artifacts, add the file to .gitignore."
  echo "  - For large data files, consider external storage (S3, Google Drive)."
fi

if [ "$BLOCKED" -eq 1 ]; then
  echo ""
  exit 2
fi

exit 0
