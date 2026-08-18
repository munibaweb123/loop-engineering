# Rehearse a Routine for Free

**Loop Engineering, Project 9 — A1, A3 (one-off schedules), A5 (reading runs).**

Prove a prompt with one-off runs before you commit it to a schedule.
A one-off does not count against your daily run cap — it's a free rehearsal.

## What you learn

- How to test a Routine without spending daily runs
- How to read run transcripts to verify behavior
- How to iterate on a prompt before scheduling it

## The drill

1. **Write a prompt** for something you want automated
2. **Fire a one-off** — schedule it to run once, immediately or in 2 minutes
3. **Read the transcript** — check what it actually did
4. **Iterate** — fix the prompt, fire another one-off
5. **Repeat** until the output is right
6. **Then schedule it** — only when you trust the prompt

## The key insight

A one-off schedule (`/schedule in 2 minutes, ...`) does not count against your
daily run limit. This means you can test a prompt as many times as you want,
for free, before committing to a schedule.

## What you check

- [ ] Did the Routine do what you expected?
- [ ] Did it use the right tools?
- [ ] Did it produce the right output?
- [ ] Did it avoid doing things you didn't ask for?
- [ ] Is the prompt clear enough that a fresh session understands it?

## Example

```bash
# Test the prompt once (free)
/schedule in 2 minutes, run the sky-watch skill and show me the forecast

# Read the transcript
# Check claude.ai/code/routines for the run

# If it's right, schedule it for real
/schedule every day at midnight, run the sky-watch skill and email me the forecast
```

## Why this matters

The worst feeling is scheduling a Routine and discovering it does the wrong thing
at 3am. Rehearsing with one-offs catches problems before they become scheduled
failures. It's the loop engineering equivalent of "test before you ship."

## Files

| Path | What it is |
| --- | --- |
| `.claude/skills/rehearse-routine/SKILL.md` | The drill's playbook |
| `README.md` | This file |
