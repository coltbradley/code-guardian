#!/bin/bash
# check-env-files.sh - Blocks committing .env files with real secrets.
# Allows .env.example, .env.sample, and .env.template variants.
# Exits with code 2 to block the commit.

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

BLOCKED=0
BLOCKED_FILES=()

for FILE in $STAGED_FILES; do
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
      BLOCKED_FILES+=("  $FILE")
      ;;
    *)
      # Also catch nested variants like config/.env or services/api/.env.local
      if echo "$BASENAME" | grep -qP '^\.env(\.(local|production|development|staging|prod|dev|test|ci|override))?$'; then
        BLOCKED=1
        BLOCKED_FILES+=("  $FILE")
      fi
      ;;
  esac
done

if [ "$BLOCKED" -eq 1 ]; then
  echo ""
  echo "BLOCKED: Attempted to commit .env file(s) containing potential secrets."
  echo ""
  echo "Blocked files:"
  for F in "${BLOCKED_FILES[@]}"; do
    echo "$F"
  done
  echo ""
  echo "Guidance:"
  echo "  - Add these files to .gitignore to prevent accidental commits."
  echo "  - Commit a .env.example file with placeholder values instead:"
  echo "      cp .env .env.example"
  echo "      # Replace real values with placeholders, then:"
  echo "      git add .env.example"
  echo "  - Use a secrets manager or CI/CD environment variables for real values."
  echo ""
  exit 2
fi

exit 0
