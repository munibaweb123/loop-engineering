# Break It on Purpose — observability drill

**Loop Engineering, Project 7 — Observability, Concept 13 (cost), Concept 14 (failing loudly).**

Sabotage your own loop, then diagnose it from the spine alone. If you can't
figure out what went wrong from the logs, your loop isn't observable enough.

## What you learn

- How to read a spine to understand what happened
- Why "green does not mean done"
- How to make loops that fail loudly instead of silently
- Cost awareness: what each run actually costs

## The drill

1. **Run a loop you trust** — any project that has run at least once
2. **Break it on purpose** — plant a subtle bug, disable a check, corrupt the spine
3. **Wait for it to run** — let the loop fire with the break in place
4. **Diagnose from the spine alone** — without looking at the code, figure out:
   - What failed?
   - When did it start?
   - How many runs were affected?
   - What would you change to catch this earlier?

## What makes a good break

- **Silent failures** — the loop runs but produces wrong output
- **Cost spikes** — a run that costs 10x normal
- **Spine corruption** — entries that don't match reality
- **Checker bypass** — the reviewer passes something it shouldn't

## What you check

- [ ] Can you read the spine and understand what happened?
- [ ] Does the spine tell you when the problem started?
- [ ] Can you tell which runs were affected?
- [ ] Does the loop have a way to alert you (not just log silently)?
- [ ] Is the cost per run documented?

## Why this matters

A loop that fails silently is worse than no loop at all. You think it's running
fine, but it's been broken for days. The only defense is observability: logs that
tell you what happened, costs that are visible, and failures that come to you
instead of hiding in a file.

## Files

| Path | What it is |
| --- | --- |
| `.claude/skills/break-it-on-purpose/SKILL.md` | The drill's playbook |
| `README.md` | This file |
