#!/bin/bash
set -euo pipefail
# check-large-files.sh - Blocks staged files larger than 500KB.
# Exits with code 2 to block the commit.

MAX_BYTES=512000  # 500KB in bytes

BLOCKED=0
BLOCKED_FILES=""

# Null-delimited iteration handles filenames with spaces
while IFS= read -r -d '' FILE; do
  [ -f "$FILE" ] || continue

  FILE_SIZE=$(wc -c < "$FILE" 2>/dev/null)

  if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -gt "$MAX_BYTES" ]; then
    SIZE_KB=$(( FILE_SIZE / 1024 ))
    BLOCKED=1
    BLOCKED_FILES="$BLOCKED_FILES  $FILE  (${SIZE_KB}KB)\n"
  fi
done < <(git diff --cached --name-only -z 2>/dev/null)

if [ "$BLOCKED" -eq 1 ]; then
  echo "" >&2
  echo "BLOCKED: One or more staged files exceed the 500KB size limit." >&2
  echo "" >&2
  echo "Oversized files:" >&2
  printf "%b" "$BLOCKED_FILES" >&2
  echo "" >&2
  echo "Guidance:" >&2
  echo "  - For large binary assets (images, models, datasets), use Git LFS:" >&2
  echo "      git lfs track '*.extension'" >&2
  echo "      git add .gitattributes" >&2
  echo "  - For generated or build artifacts, add the file to .gitignore." >&2
  echo "  - For large data files, consider an external storage solution" >&2
  echo "    (S3, Google Drive, etc.) and store only a reference in the repo." >&2
  echo "" >&2
  exit 2
fi

exit 0
