#!/bin/bash
set -euo pipefail

# nonstop installer — adds skill + stop hook to Claude Code

SKILL_DIR="$HOME/.claude/skills/nonstop"
HOOKS_DIR="$HOME/.claude/hooks"
STATE_DIR="$HOOKS_DIR/state"
SETTINGS="$HOME/.claude/settings.json"

REPO_URL="https://raw.githubusercontent.com/andylizf/nonstop/main"

echo "Installing nonstop..."

# 1. Download skill
mkdir -p "$SKILL_DIR"
curl -fsSL "$REPO_URL/SKILL.md" -o "$SKILL_DIR/SKILL.md"
echo "  Skill installed to $SKILL_DIR/SKILL.md"

# 2. Download hook
mkdir -p "$HOOKS_DIR" "$STATE_DIR"
curl -fsSL "$REPO_URL/nonstop.sh" -o "$HOOKS_DIR/nonstop.sh"
chmod +x "$HOOKS_DIR/nonstop.sh"
echo "  Hook installed to $HOOKS_DIR/nonstop.sh"

# 3. Register hook in settings.json
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/nonstop.sh"}]
      }
    ]
  }
}
EOF
  echo "  Created $SETTINGS with nonstop hook"
elif grep -q "nonstop.sh" "$SETTINGS" 2>/dev/null; then
  echo "  Hook already registered in $SETTINGS"
else
  echo ""
  echo "  NOTE: Add this to the \"Stop\" array in your $SETTINGS:"
  echo ""
  echo '  {'
  echo '    "matcher": "",'
  echo '    "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/nonstop.sh"}]'
  echo '  }'
  echo ""
fi

echo ""
echo "Done! Restart Claude Code, then type /nonstop to activate."
