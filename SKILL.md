---
name: nonstop
description: Autonomous work mode that lets Claude work continuously while the user is away. Activates pre-flight risk assessment, dangerous-ops approval, and a blocker decision framework. Use "/nonstop" to activate, "/nonstop off" to deactivate. Use this skill whenever the user says things like "go nonstop", "keep working", "don't stop", "I'm going AFK", "work while I sleep", "finish this without me", or wants Claude to work autonomously without interruption.
---

# Nonstop Mode

A session-scoped autonomous work mode. When activated, Claude works continuously without stopping to ask the user, handling blockers intelligently.

## Activation — `/nonstop` or `/nonstop on`

When the user triggers nonstop mode, complete a **pre-flight sequence** before doing any work. The pre-flight exists because once the user walks away, there is no one to answer questions — every ambiguity must be resolved now.

### Phase 1: Mental Simulation — Anticipate Every Blocker

Mentally simulate the entire execution path of the task from start to finish. This is not a generic checklist — it is a task-specific dry run.

**How to think:**
1. Break the task into concrete steps (what will you actually do, in order?)
2. For EACH step, imagine yourself executing it right now. Ask: "What could go wrong here? What would make me stop and ask the user?"
3. Think about the environment: what machines, services, credentials, permissions does this touch?
4. Think about dependencies between steps: if step 3 fails, can step 4 still run?
5. Think about the edges: what if the test fails? what if the build takes 30 minutes? what if a file doesn't exist?

**Surface to the user:**
- Anything that would make you stop and ask — surface it NOW
- Ambiguous requirements where you'd need to make a judgment call — clarify NOW
- Credentials, tokens, permissions you might need — confirm NOW
- Decision points with multiple valid paths — pick one together NOW
- External dependencies that might be slow or unavailable — plan a fallback NOW
- Any step where you're not 100% sure how to proceed — ask NOW

The goal: **after this phase, there should be ZERO reasons to stop and ask the user anything.**

Present your findings as: "Here's what I plan to do [ordered list], and here's what might block me [list with proposed solutions]. Can you confirm/clarify these before you go?"

### Phase 2: Dangerous Operations Manifest

Present a **Dangerous Operations Manifest** — high-risk actions that MIGHT be needed during execution. Get explicit yes/no for each relevant category:

| Category | Examples |
|---|---|
| **Kill processes** | Kill others' GPU jobs, restart services |
| **Delete files/dirs** | rm -rf, git clean, drop tables |
| **Force push / rewrite history** | git push --force, git reset --hard |
| **Deploy / release** | Push to prod, publish package, merge to main |
| **Modify infra** | Change cloud resources, modify CI/CD, edit configs |
| **Social / comms** | Post GitHub comments/issues/PRs, send Slack messages, reply to reviews |
| **External APIs** | Call paid APIs, trigger webhooks, write to external DBs |
| **Resource contention** | Claim GPU, take locks, use large disk/memory |

The key principle: **anything that leaves a trace in the outside world that others can see or that costs money** needs approval. Reading is always fine; writing/posting/sending is what needs a decision.

Only present categories that are relevant to the task. For each approved category, record the scope (e.g. "OK to kill MY GPU processes but not others'"). The user may also say "approve all" — that's fine, it's their call.

For anything NOT approved: do not attempt it. Create a task marked as blocked with the reason, and move on.

### Phase 3: Permissions Check

Ask the user: **"What's your current permission mode? (check the bottom status bar)"**

- **Bypass permissions** → good to go, no prompts will interrupt.
- **Auto mode** → mostly fine. The auto classifier may block some operations; Claude will attempt alternatives when that happens.
- **Default / other** → warn: "Permission prompts will block me when you're not here. I recommend switching to auto mode (Shift+Tab to cycle) or bypass before you leave."

### Phase 4: Confirm and Activate

Present the summary and ask the user to confirm. **Do NOT activate until the user explicitly replies.**

1. **Scope**: "Here's what I'll do: [list]. Anything to add or remove?"
2. **Workaround policy**: "If I hit a blocker, should I: (a) skip and continue, (b) attempt a workaround, or (c) stop and wait?"
3. **Fallback for unapproved ops**: "Dangerous ops you didn't pre-approve will be marked as blocked and skipped. OK?"

**STOP HERE. Wait for the user to reply.** Do not proceed until you receive an explicit confirmation (e.g. "go", "yes", "confirmed", "looks good"). The user triggering /nonstop is NOT confirmation — it starts the pre-flight, not the work.

Once the user confirms, activate:

```bash
mkdir -p ~/.claude/hooks/state && touch ~/.claude/hooks/state/nonstop-$SESSION_ID.active
```

Say: "Nonstop mode ON. Go rest — I've got this."

## During Nonstop Mode — Blocker Decision Framework

When you encounter something that would normally make you stop and ask the user, follow this decision tree:

### Level 1: Can I solve it myself?
- Missing info → search the codebase, read docs, check git history
- Test failing → read the error, fix it
- Build error → diagnose and fix
- **If yes → solve it and move on. Don't stop.**

### Level 2: Can I work around it?
- Permission denied → check if there's an alternative path (different API, different approach)
- External service down → skip that part, continue with other tasks
- Ambiguous requirement → pick the most reasonable interpretation, document your choice
- **Critical check**: will the workaround change the outcome of the task?
  - If the result stays equivalent → proceed with workaround, note what you did in the task
  - If the result would be materially different → do NOT proceed, mark the task as blocked

### Level 3: Truly blocked
- Update the task status to blocked, noting: what you tried, why it failed, what the user needs to do
- Move on to the next task. Do NOT spin on unsolvable problems.
- **NEVER**: brute-force retry the same failing action, disable safety checks to bypass a blocker, make destructive changes to work around permissions, or guess at credentials/tokens.

### Subagent Delegation
- For long-running operations (builds, tests, deploys), spawn a background Agent to monitor
- Don't block the main thread waiting for results
- Continue with other work while subagents run

## Deactivation — `/nonstop off`

1. Remove the flag:
   ```bash
   rm -f ~/.claude/hooks/state/nonstop-$SESSION_ID.active ~/.claude/hooks/state/nonstop-$SESSION_ID.count
   ```
2. Present a summary from the task list:
   - Tasks completed
   - Tasks where you took workarounds (and why)
   - Tasks marked as blocked that need the user's attention
3. Say: "Nonstop mode OFF. Here's what happened while you were away."

## Auto-deactivation

Nonstop mode auto-deactivates after NONSTOP_MAX nudges (default 5, env var `NONSTOP_MAX`, 0 = unlimited). This prevents runaway loops when Claude is genuinely stuck on everything.

## Technical Details

- Session-scoped: flag file is `~/.claude/hooks/state/nonstop-<session_id>.active`
- Stop hook: `~/.claude/hooks/nonstop.sh` checks flag and blocks premature stops
- `stop_hook_active` flag prevents infinite loops (allows stop on 2nd attempt per turn)
- Nudge counter tracks blocks per session; auto-cleans on deactivation
