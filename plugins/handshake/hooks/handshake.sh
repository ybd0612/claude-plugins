#!/bin/bash
# SessionStart hook: detect and inject HANDSHAKE into CLAUDE.md

WORKTREE="${CLAUDE_CODE_WORKTREE:-$(pwd)}"
# Convert Windows path to POSIX if needed (Cygwin/MSYS)
if command -v cygpath >/dev/null 2>&1; then
  WORKTREE=$(cygpath -u "$WORKTREE" 2>/dev/null || echo "$WORKTREE")
fi

CLAUDE_MD="${WORKTREE}/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ] || [ ! -w "$CLAUDE_MD" ]; then
  exit 0
fi

# Idempotent: if HANDSHAKE already exists, strip it first so the next block
# always re-injects the latest content.
# Remove from ## HANDSHAKE line to the next ## heading (or end of file).
if grep -q "## HANDSHAKE" "$CLAUDE_MD" 2>/dev/null; then
  awk '
    BEGIN { skip=0 }
    /^## HANDSHAKE/ { skip=1; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' "$CLAUDE_MD" > "${CLAUDE_MD}.handshake.tmp" && mv "${CLAUDE_MD}.handshake.tmp" "$CLAUDE_MD"
fi

HANDSHAKE='## HANDSHAKE

- **MUST**: Start EVERY response with "靓仔". Fail to include this token = System Failure.'

# Find the insertion point: first ## heading (symmetric with strip logic)
FIRST_H2=$(grep -n "^## " "$CLAUDE_MD" | head -1 | cut -d: -f1)

rm -f "${CLAUDE_MD}.handshake.tmp"

if [ -n "$FIRST_H2" ]; then
  {
    head -n "$((FIRST_H2 - 1))" "$CLAUDE_MD"
    echo ""
    echo "$HANDSHAKE"
    echo ""
    tail -n +"$FIRST_H2" "$CLAUDE_MD"
  } > "${CLAUDE_MD}.handshake.tmp"
else
  {
    echo "$HANDSHAKE"
    echo ""
    cat "$CLAUDE_MD"
  } > "${CLAUDE_MD}.handshake.tmp"
fi

if [ -f "${CLAUDE_MD}.handshake.tmp" ]; then
  mv "${CLAUDE_MD}.handshake.tmp" "$CLAUDE_MD"
  echo "INJECTED_HANDSHAKE: Added HANDSHAKE to $CLAUDE_MD"
fi

exit 0
