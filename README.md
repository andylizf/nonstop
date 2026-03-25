<p align="center">
  <h1 align="center">nonstop</h1>
  <p align="center">
    <em>"Why do you write like you're running out of time?"</em>
    <br/>
    <strong>Autonomous work mode for Claude Code.</strong>
    <br/>
    Go to sleep. Wake up to finished work.
  </p>
</p>

<p align="center">
  <a href="#install">Install</a> &middot;
  <a href="#how-it-works">How it works</a> &middot;
  <a href="#usage">Usage</a> &middot;
  <a href="#configuration">Configuration</a>
</p>

---

**nonstop** is a Claude Code skill + stop hook that lets Claude work autonomously while you're away. It's not just "don't stop" — it's an intelligent autonomous work protocol:

1. **Before you leave** — Claude does a full mental dry-run of the task, surfaces every possible blocker, and gets your sign-off on dangerous operations
2. **While you're away** — A stop hook prevents Claude from halting. When blocked, Claude follows a decision framework: solve it, work around it, or skip it and move on
3. **When you're back** — Check the task list to see what's done, what was worked around, and what needs you

## The Problem

You give Claude a complex task, walk away, and come back to find it stopped 2 minutes in asking "should I use tabs or spaces?" Or it hit a permission error and just... gave up.

**nonstop** fixes this by:
- Forcing Claude to think ahead and ask all questions **before** you leave
- Giving Claude a clear decision framework for handling blockers autonomously
- Preventing premature stops with a session-scoped stop hook

## Install

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/andylizf/nonstop/main/install.sh | bash
```

Or manually:

```bash
# 1. Copy the skill
mkdir -p ~/.claude/skills/nonstop
cp SKILL.md ~/.claude/skills/nonstop/

# 2. Copy the stop hook
mkdir -p ~/.claude/hooks ~/.claude/hooks/state
cp nonstop.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/nonstop.sh

# 3. Register the hook in ~/.claude/settings.json
# Add this to the "Stop" array in "hooks":
# {
#   "matcher": "",
#   "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/nonstop.sh"}]
# }
```

## How It Works

### Pre-flight: Before You Walk Away

When you type `/nonstop`, Claude doesn't just start working. It runs a **3-phase pre-flight sequence**:

#### Phase 1: Mental Simulation

Claude mentally executes every step of your task and surfaces anything that might cause a stop:

```
Here's what I plan to do:
1. Refactor the auth module to use JWT
2. Update all 12 test files
3. Run the full test suite
4. Push to feature branch

Here's what might block me:
- The test suite needs a running Redis instance — is one available?
- I'll need to update the CI config — OK to modify .github/workflows?
- There's an ambiguous requirement: should the old session tokens be migrated or dropped?

Can you confirm these before you go?
```

#### Phase 2: Dangerous Operations Manifest

Claude presents every category of risky action and gets explicit approval:

| Category | Examples | Your call |
|---|---|---|
| **Kill processes** | GPU jobs, services | Approve/deny with scope |
| **Delete files** | rm, git clean, drop tables | Approve/deny with scope |
| **Force push** | git push --force | Approve/deny |
| **Social / comms** | Post PRs, comments, Slack | Approve/deny with scope |
| **External APIs** | Paid APIs, webhooks | Approve/deny |
| ... | ... | ... |

The principle: **anything that leaves a trace in the outside world or costs money** needs your sign-off. You can approve all, deny all, or set scoped permissions ("OK to delete in /tmp, not /data").

#### Phase 3: Confirm and Go

Claude confirms the scope, workaround policy, and activates. You walk away.

### During: The Decision Framework

When Claude hits a blocker, it follows a strict decision tree:

```
Level 1: Can I solve it myself?
  Yes → solve it, keep going

Level 2: Can I work around it without changing the outcome?
  Yes → work around it, note what I did
  No  → the workaround would change the result

Level 3: Truly blocked
  → Mark task as blocked (what I tried, why it failed, what you need to do)
  → Move to next task
  → NEVER: brute-force retry, disable safety checks, guess credentials
```

### After: Check the Task List

When you're back, run `/nonstop off` or just check the task list:
- **Completed** — done
- **Workarounds taken** — done, but check the approach
- **Blocked** — needs your input

## Usage

```
/nonstop          # activate (starts pre-flight)
/nonstop on       # same as above
/nonstop off      # deactivate + show summary
```

Nonstop mode is **session-scoped** — it only affects the current session and doesn't persist across restarts.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `NONSTOP_MAX` | `5` | Max nudges before auto-deactivating. Set to `0` for unlimited. |

```bash
export NONSTOP_MAX=10  # allow more nudges before giving up
export NONSTOP_MAX=0   # never auto-deactivate (use with caution)
```

## How It's Built

Two files. That's it.

| File | What it does |
|---|---|
| `SKILL.md` | The skill definition — tells Claude the pre-flight protocol and decision framework |
| `nonstop.sh` | The stop hook — blocks Claude from stopping, with loop protection and nudge counting |

The stop hook reads the Claude Code hook JSON from stdin, checks for a session-scoped flag file, and returns `{"decision": "block"}` with the decision framework as the reason. The `stop_hook_active` flag from Claude Code prevents infinite loops.

## Compared To

| Tool | Approach | Difference |
|---|---|---|
| [taskmaster](https://github.com/blader/taskmaster) | Requires `TASKMASTER_DONE::` token to stop | Token-based; no pre-flight, no decision framework |
| [Ralph loop](https://github.com/frankbria/ralph-claude-code) | External bash loop re-running Claude | Restarts Claude; nonstop works within one session |
| Raw stop hook | `{"decision": "block"}` | No intelligence — just blocks blindly |
| **nonstop** | Pre-flight + smart blocking + decision framework | Thinks ahead, handles blockers, knows when to actually stop |

## License

MIT
