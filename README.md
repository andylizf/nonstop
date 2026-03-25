<p align="center">
  <h1 align="center">nonstop</h1>
  <p align="center">
    <em>"Why do you write like you're running out of time?"</em>
    <br/><br/>
    Go to sleep. Wake up to finished work.
  </p>
</p>

<p align="center">
  <a href="#install">Install</a> &middot;
  <a href="#how-it-works">How it works</a> &middot;
  <a href="#compared-to">Compared to</a>
</p>

---

Your overnight Claude session, except it actually finishes. Type `/nonstop` before you walk away. Claude asks every question now, gets your sign-off on anything dangerous, then works through the night — solving blockers, routing around problems, and knowing when to stop trying.

## The Problem

You hand Claude a 4-hour task and go to bed. You wake up and it stopped 3 minutes in:

> *"Should I use the existing auth middleware or write a new one?"*

Or it hit a permission error on step 2 of 47 and just... sat there. Waiting. For 8 hours.

**nonstop** makes Claude do what a good engineer does when the boss leaves: figure it out, work around it, or write it down and move on to the next thing.

## Install

### Tell Claude (easiest)

Paste this into Claude Code:

```
Fetch and follow the instructions at https://raw.githubusercontent.com/andylizf/nonstop/main/INSTALL.md
```

### Plugin marketplace

```
/plugin marketplace add andylizf/nonstop
/plugin install nonstop@nonstop
```

### Manual

```bash
curl -fsSL https://raw.githubusercontent.com/andylizf/nonstop/main/install.sh | bash
```

## How It Works

### Before you leave: the pre-flight

`/nonstop` triggers a 4-phase sequence. Claude won't start working until all of this is done.

**1. Mental simulation** — Claude walks through every step of your task in its head and flags anything that would make it stop:

```
Here's my plan:
1. Refactor auth module to JWT
2. Update 12 test files
3. Run full test suite
4. Push to feature branch

Potential blockers:
- Test suite needs Redis — is one running?
- I'll modify .github/workflows — OK?
- Ambiguous: should old session tokens be migrated or dropped?

Confirm before you go?
```

**2. Dangerous ops manifest** — Anything that touches the outside world gets explicit approval:

| | Examples |
|---|---|
| **Kill processes** | GPU jobs, services |
| **Delete** | rm -rf, git clean, drop tables |
| **Force push** | git push --force |
| **Social** | Post PRs, comments, Slack |
| **Paid APIs** | External calls, webhooks |
| **Resources** | Claim GPU, large disk |

You can approve all, deny all, or scope it ("delete in /tmp, not /data"). Your call.

**3. Permissions check** — Claude checks your permission mode. If you're not on bypass or auto, it'll warn you that permission prompts will block it while you're gone.

**4. Confirm and go** — Scope, workaround policy, ground rules. Then:

*"Nonstop mode ON. Go rest — I've got this."*

### While you're away: the decision framework

A stop hook blocks Claude from halting. When something goes wrong:

```
Can I solve it?           → Solve it. Keep going.
Can I work around it?     → Only if the outcome stays the same. Note what I did.
Truly stuck?              → Mark it blocked. Move to next task. Don't spin.
```

What Claude will **never** do: brute-force retry, disable safety checks, guess credentials, or take unapproved destructive actions.

Long-running ops (builds, tests) get delegated to background agents. Claude doesn't sit and wait.

### When you're back

`/nonstop off` — or just check the task list:
- **Completed** — done
- **Workaround** — done, but verify the approach
- **Blocked** — needs you

## How It's Built

Two files.

| File | Role |
|---|---|
| `SKILL.md` | Pre-flight protocol, dangerous ops manifest, blocker decision framework |
| `nonstop.sh` | Stop hook — blocks premature stops, tracks nudge count, prevents infinite loops via `stop_hook_active` |

Session-scoped. Flag file per session ID. Auto-deactivates after `NONSTOP_MAX` nudges (default 5, `export NONSTOP_MAX=0` for unlimited).

## Compared To

| | Approach | What's different |
|---|---|---|
| [taskmaster](https://github.com/blader/taskmaster) | Must emit `TASKMASTER_DONE::` token to stop | No pre-flight. No decision framework. Token-based. |
| [Ralph loop](https://github.com/frankbria/ralph-claude-code) | External bash loop restarting Claude | Loses context on restart. Nonstop stays in-session. |
| Raw stop hook | `{"decision": "block"}` | Blocks blindly. No intelligence. |
| **nonstop** | Pre-flight + smart blocking + decision framework | Thinks ahead. Handles blockers. Knows when to actually stop. |

## License

MIT
