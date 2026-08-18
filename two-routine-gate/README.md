# Two-Routine Gate — the human gate built from real parts

**Loop Engineering, Project 11 — A3 (API trigger), A4 (the gate), A6 (the checklist).**

A loop that drafts, a human who decides, and a second routine that acts only
when told. This is the Part 5 human gate, written as two routines and a webhook.

**This is the OpenCode version.** It runs on your machine with `opencode run`,
a simple HTTP server, and `curl`. No cloud, no vendor, no daily cap.

## The three things that must be true

1. **Routine B ran only because you fired it.** No automatic trigger, no schedule, no event.
   You review Routine A's draft, decide it's good, and fire B yourself with a `curl` call.
2. **B's transcript shows the action actually happened.** Check the server logs and the
   tracking issue — the approval comment must be there.
3. **The A6 checklist has been run over both routines.** Connectors pruned, unrestricted
   pushes off, state file chosen. See [A6 checklist](#a6-checklist) below.

## What's here

| Path | What it is |
| --- | --- |
| `routine-a.sh` | The drafter — gathers repo activity, posts a digest |
| `routine-b-server.py` | The executor — webhook receiver, runs approval action |
| `.env.example` | Template for the bearer token |
| `setup.sh` | Installs dependencies, creates `.env` |
| `check.py` | Verifies the digest against actual repo state |
| `.claude/skills/daily-digest/SKILL.md` | Routine A's playbook |
| `.claude/agents/reviewer.md` | The reviewer agent |
| `progress.md` | The spine — tracks which digests were approved |

## How it works

```
Routine A (bash/cron)                 You (human gate)           Routine B (HTTP server)
         │                                    │                            │
         │  1. bash routine-a.sh             │                            │
         │  2. Posts digest to issue          │                            │
         │                                    │                            │
         │──────────────────────────────────>│                            │
         │           3. You review            │                            │
         │           4. You decide            │                            │
         │                                    │                            │
         │                                    │──── 5. curl /approve ────>│
         │                                    │                            │
         │                                    │<──── 6. Action done ──────│
         │                                    │                            │
         │                                    │  7. You verify logs        │
```

## Build it — step by step

### 1. Run setup

```bash
cd two-routine-gate
bash setup.sh
```

This checks for required tools (`git`, `gh`, `opencode`, `python3`) and creates
your `.env` file.

### 2. Set your bearer token

```bash
# Generate a random token
openssl rand -hex 32

# Edit .env and paste it
nano .env
```

The token authenticates curl requests to Routine B. Keep it secret.

### 3. Start Routine B (the executor)

```bash
python routine-b-server.py
```

This starts an HTTP server on `localhost:8080` that listens for approval requests.

### 4. Fire Routine A (the drafter)

In another terminal:

```bash
bash routine-a.sh
```

Or schedule it with cron:
```bash
# Add to crontab: daily at 9am
crontab -e
0 9 * * * bash /path/to/two-routine-gate/routine-a.sh
```

Routine A:
- Gathers `git log`, `gh issue list`, `gh pr list`
- Formats a digest
- Posts it as a comment on the tracking issue

### 5. Review A's draft

Check the tracking issue:

```bash
gh issue view $TRACKING_ISSUE --comments
```

Review it yourself:
- Is the summary accurate?
- Does it list all commits, PRs, and issues?
- Did it avoid editing restricted files (CLAUDE.md, AGENTS.md)?
- Is the format clear?

### 6. Fire Routine B (if approved)

If the draft looks good:

```bash
source .env
curl -X POST http://localhost:8080/approve \
  -H "Authorization: Bearer $APPROVAL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Approved digest from human gate"}'
```

### 7. Verify B ran

Check three places:
1. **Tracking issue**: Should now have a "✅ Approved by human gate" comment
2. **Server logs**: The terminal running `routine-b-server.py` shows the request
3. **PRs**: Any PRs mentioned in the digest should have the "approved" label

If all three check out, the gate worked.

## A6 checklist

Run this checklist over both routines before trusting the gate:

| Item | Routine A (drafter) | Routine B (executor) |
|------|---------------------|----------------------|
| **Success condition** | Posts digest comment | Posts approval comment |
| **Limit** | Cron limits frequency | Rate limit on /approve endpoint |
| **Isolated branch** | Uses `claude/` prefix | Uses `claude/` prefix |
| **Read-only checker** | Human reviews draft | Transcript shows action |
| **State file** | `progress.md` tracks runs | `progress.md` tracks runs |
| **Human gate** | You review before firing B | N/A (B IS the approval) |
| **Log** | Terminal output + issue comment | Server logs + issue comment |

### Pre-save checklist

Before running the gate:

- [ ] **Repositories**: loop-eng repo cloned locally
- [ ] **Prompt**: Clear, safe to repeat (in `routine-a.sh`)
- [ ] **Connectors**: Pruned (none attached — manual approval only)
- [ ] **Environment**: `.env` has `APPROVAL_TOKEN` set
- [ ] **Trigger**: Manual (`bash routine-a.sh`) or cron
- [ ] **State**: `progress.md` committed
- [ ] **Human gate**: You review A's draft before firing B
- [ ] **Test run**: Fire A, review, fire B, verify

## The two rules

**Never fire B without reviewing A's draft first.** That's the whole point of the gate.
If B runs automatically, it's not a gate — it's a pass-through.

**Keep the bearer token secret.** It's in `.env`, which is gitignored. Never commit it.

## Why this matters

The human gate is the most important part of any loop that ships real work. Without it,
the loop is just automation — it does the same thing every time, whether it's right or wrong.

With it, you get the best of both worlds:
- **Routine A** does the boring work (gathering data, formatting, posting)
- **You** make the judgment call (is this accurate? should this ship?)
- **Routine B** does the follow-up (labels, comments, notifications)

The loop handles the steps. You handle the intent and accountability. That's loop
engineering — not removing the human, but putting the human where the judgment matters.

## Trying it yourself

```bash
# 1. Setup
cd two-routine-gate
bash setup.sh

# 2. Set token
openssl rand -hex 32
# Edit .env, paste the token

# 3. Start Routine B
python routine-b-server.py &

# 4. Fire Routine A
bash routine-a.sh

# 5. Review the draft
gh issue view 1 --comments

# 6. If approved, fire Routine B
source .env
curl -X POST http://localhost:8080/approve \
  -H "Authorization: Bearer $APPROVAL_TOKEN" \
  -H "Content-Type: application/json"

# 7. Verify
gh issue view 1 --comments  # Should see approval comment
```

If all three conditions are true, you've built the human gate out of real parts.
