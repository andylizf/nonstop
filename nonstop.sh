#!/bin/bash
# nonstop.sh — Session-scoped Stop hook for nonstop mode.
#
# Activation handshake:
#   1. Claude touches ~/.claude/hooks/state/nonstop.activate
#   2. On next Stop, this hook sees .activate, creates nonstop-<session_id>.active,
#      removes .activate, and blocks the stop.
#   3. Subsequent stops check nonstop-<session_id>.active as usual.
#
# Deactivation:
#   Claude touches ~/.claude/hooks/state/nonstop.deactivate
#   On next Stop, this hook removes the session-scoped flag and allows stop.

STATE_DIR="$HOME/.claude/hooks/state"
NONSTOP_MAX="${NONSTOP_MAX:-5}"  # max nudges before auto-deactivation; 0 = unlimited

# --- Read hook input from stdin ---
input=$(cat)

# --- Extract session_id and stop_hook_active ---
# shellcheck disable=SC2154  # variables assigned via eval
eval "$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'session_id={d.get(\"session_id\", \"default\")}')
print(f'stop_hook_active={str(d.get(\"stop_hook_active\", False)).lower()}')
" 2>/dev/null)"

# shellcheck disable=SC2154
active_file="$STATE_DIR/nonstop-${session_id}.active"
counter_file="$STATE_DIR/nonstop-${session_id}.count"

# --- Deactivation handshake ---
if [ -f "$STATE_DIR/nonstop.deactivate" ]; then
  rm -f "$STATE_DIR/nonstop.deactivate" "$active_file" "$counter_file"
  exit 0
fi

# --- Activation handshake ---
if [ -f "$STATE_DIR/nonstop.activate" ]; then
  rm -f "$STATE_DIR/nonstop.activate"
  touch "$active_file"
  # Fall through to block this stop
fi

# --- Check if nonstop mode is active for THIS session ---
[ -f "$active_file" ] || exit 0

# --- If already nudged once this turn, allow stop (prevent infinite loop) ---
# shellcheck disable=SC2154
[ "$stop_hook_active" = "true" ] && exit 0

# --- Counter: track nudges, bail after NONSTOP_MAX ---
count=0
[ -f "$counter_file" ] && count=$(cat "$counter_file")
count=$((count + 1))
echo "$count" > "$counter_file"

if [ "$NONSTOP_MAX" -gt 0 ] && [ "$count" -gt "$NONSTOP_MAX" ]; then
  rm -f "$active_file" "$counter_file"
  exit 0
fi

# --- Block and nudge with decision framework ---
cat <<EOF
{"decision":"block","reason":"[nonstop mode — nudge] Do NOT stop. Follow the nonstop protocol:\n\n1. CHECK TASKS: Review your task list. Is every task completed?\n2. IF BLOCKED on something:\n   a. Can you solve it yourself? (search code, read docs, fix errors) → Do it.\n   b. Can you work around it WITHOUT changing the outcome? → Do it, update the task with what you did.\n   c. Is it a HIGH-RISK op not pre-approved? → Mark task as blocked, move to next task.\n   d. Truly stuck on everything? → Deactivate nonstop: touch ~/.claude/hooks/state/nonstop.deactivate\n3. FOR LONG-RUNNING OPS: Spawn a background Agent, don't block.\n4. NEVER: brute-force retry, disable safety checks, guess credentials, or take destructive actions not pre-approved.\n\nKeep working."}
EOF
