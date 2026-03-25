Fetch the following files from https://github.com/andylizf/nonstop and install the nonstop skill:

1. Use WebFetch to read https://raw.githubusercontent.com/andylizf/nonstop/main/SKILL.md — save it to ~/.claude/skills/nonstop/SKILL.md
2. Use WebFetch to read https://raw.githubusercontent.com/andylizf/nonstop/main/nonstop.sh — save it to ~/.claude/hooks/nonstop.sh and make it executable (chmod +x)
3. Create the directory ~/.claude/hooks/state/
4. Add this Stop hook entry to ~/.claude/settings.json in the "hooks.Stop" array (create the array if it doesn't exist):
   {"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/nonstop.sh"}]}
5. Confirm installation is complete. The user can now type /nonstop to activate.
