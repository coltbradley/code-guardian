#!/bin/bash
# check-large-files.sh - Blocks staged files larger than 500KB.
# Exits with code 2 to block the commit.

MAX_BYTES=512000  # 500KB in bytes

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

BLOCKED=0
BLOCKED_FILES=()

for FILE in $STAGED_FILES; do
  [ -f "$FILE" ] || continue

  FILE_SIZE=$(wc -c < "$FILE" 2>/dev/null)

  if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -gt "$MAX_BYTES" ]; then
    SIZE_KB=$(( FILE_SIZE / 1024 ))
    BLOCKED=1
    BLOCKED_FILES+=("  $FILE  (${SIZE_KB}KB)")
  fi
done

if [ "$BLOCKED" -eq 1 ]; then
  echo ""
  echo "BLOCKED: One or more staged files exceed the 500KB size limit."
  echo ""
  echo "Oversized files:"
  for F in "${BLOCKED_FILES[@]}"; do
    echo "$F"
  done
  echo ""
  echo "Guidance:"
  echo "  - For large binary assets (images, models, datasets), use Git LFS:"
  echo "      git lfs track '*.extension'"
  echo "      git add .gitattributes"
  echo "  - For generated or build artifacts, add the file to .gitignore."
  echo "  - For large data files, consider an external storage solution"
  echo "    (S3, Google Drive, etc.) and store only a reference in the repo."
  echo ""
  exit 2
fi

exit 0
