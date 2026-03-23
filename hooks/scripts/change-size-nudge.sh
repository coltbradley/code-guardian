#!/bin/bash
# change-size-nudge.sh - Advisory PostToolUse hook (always exits 0).
# Reads JSON from stdin and nudges the user when many files have changed.

THRESHOLD=5

# Read JSON payload from stdin
INPUT=$(cat)

# Check if the triggering tool was Write or Edit
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"\s*:\s*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi

# Count files with unstaged or staged changes
CHANGED_COUNT=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$(( CHANGED_COUNT + STAGED_COUNT ))

if [ "$TOTAL" -ge "$THRESHOLD" ]; then
  echo ""
  echo "Advisory: $TOTAL files have been modified in the working tree."
  echo "Consider running /code-guardian:quick-check to review your changes"
  echo "before continuing or committing."
  echo ""
fi

exit 0
