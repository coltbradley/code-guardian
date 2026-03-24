#!/bin/bash
set -euo pipefail
# check-env-files.sh - Blocks committing .env files with real secrets.
# Allows .env.example, .env.sample, and .env.template variants.
# Exits with code 2 to block the commit.

BLOCKED=0
BLOCKED_FILES=""

# Null-delimited iteration handles filenames with spaces
while IFS= read -r -d '' FILE; do
  BASENAME=$(basename "$FILE")

  # Allow safe example/sample/template variants
  case "$BASENAME" in
    .env.example|.env.sample|.env.template) continue ;;
    *.env.example|*.env.sample|*.env.template) continue ;;
  esac

  # Block .env and common environment-specific variants
  case "$BASENAME" in
    .env|.env.local|.env.production|.env.development|.env.staging|\
    .env.prod|.env.dev|.env.test|.env.ci|.env.override)
      BLOCKED=1
      BLOCKED_FILES="$BLOCKED_FILES  $FILE\n"
      ;;
    *)
      # Also catch nested variants like config/.env or services/api/.env.local
      if echo "$BASENAME" | grep -qE '^\.env(\.(local|production|development|staging|prod|dev|test|ci|override))?$'; then
        BLOCKED=1
        BLOCKED_FILES="$BLOCKED_FILES  $FILE\n"
      fi
      ;;
  esac
done < <(git diff --cached --name-only -z 2>/dev/null)

if [ "$BLOCKED" -eq 1 ]; then
  echo "" >&2
  echo "BLOCKED: Attempted to commit .env file(s) containing potential secrets." >&2
  echo "" >&2
  echo "Blocked files:" >&2
  printf "%b" "$BLOCKED_FILES" >&2
  echo "" >&2
  echo "Guidance:" >&2
  echo "  - Add these files to .gitignore to prevent accidental commits." >&2
  echo "  - Commit a .env.example file with placeholder values instead:" >&2
  echo "      cp .env .env.example" >&2
  echo "      # Replace real values with placeholders, then:" >&2
  echo "      git add .env.example" >&2
  echo "  - Use a secrets manager or CI/CD environment variables for real values." >&2
  echo "" >&2
  exit 2
fi

exit 0
