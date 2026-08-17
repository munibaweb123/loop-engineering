# Observability — cost, sabotage, and diagnosing from the spine alone

**Loop Engineering — Observability, Concept 13 (cost), Concept 14.**

This project's loop ([paper-watch](README.md), the spine) already had a heartbeat
and a memory. What it didn't have was any record of a run that *failed* — only
`progress.md`, which is written on success. Run it unattended overnight, hit an
error, and the only evidence was a stdout message nobody was watching, gone the
instant the schedule's process exited. That's a silent failure: the loop just
doesn't answer tomorrow, and you have no way to tell "it found nothing new" from
"it never ran" from "it crashed at 9:03am."

This document does three things: measures what one beat actually costs, breaks the
loop on purpose to prove the silent-failure problem was real, and shows the fix —
[`run-beat.sh`](run-beat.sh) — closing it.

## 1. What one beat costs

Measured a real, steady-state beat (the common case: the spine already has
everything on arXiv, so the run finds nothing new) with Claude Code's own reported
usage:

```sh
claude -p 'show me what'"'"'s new on arXiv about "LLM agents and agentic ai"' \
  --output-format json
```

```json
"total_cost_usd": 0.1252386,
"usage": {
  "input_tokens": 6,
  "cache_creation_input_tokens": 15941,
  "cache_read_input_tokens": 80432,
  "output_tokens": 363
}
```

~96,700 tokens processed, **$0.1252 per beat**. This is a cold-cache number on
purpose — a schedule firing once a day almost never lands inside another run's
prompt-cache window, so this is the realistic cost per firing, not the optimistic
same-session number.

**Cadence → monthly cost** (Concept 13's math, applied to this loop):

| Cadence | Runs/month | Monthly cost |
| --- | --- | --- |
| Weekdays at 9am (this project's own recommended schedule) | 21.7 | **≈ $2.72** |
| Every day | 30.4 | ≈ $3.81 |

Trivial at this scale. The number that matters isn't the total — it's that you now
*have* a number, instead of a guess, before turning on a schedule that runs
unattended indefinitely.

## 2. Sabotage: point the command at a file that doesn't exist

Before breaking anything, the wrapper needed to exist, because the failure had to
land somewhere. [`run-beat.sh`](run-beat.sh) runs `paperwatch.py`, captures its
exit code and output no matter what happens, and appends one line to `run.log`
every time — `status=OK` or `status=FAIL ... action=NEEDS_HUMAN`. It has to live
*outside* `paperwatch.py`: a bad script path fails before `paperwatch.py`'s own
code ever runs, so no fix inside that file could ever log it.

**Rehearsal**, exactly as it would happen overnight — a schedule's command
drifting from the real script (a rename, a refactor, a typo):

```sh
$ ./run-beat.sh                                              # control run: healthy
      nothing new since last run  ✓

$ PAPERWATCH_SCRIPT=".claude/skills/paper-watch/scripts/paperwatch_v2.py" ./run-beat.sh
python3: can't open file '.../paperwatch_v2.py': [Errno 2] No such file or directory
$ echo $?
2

$ ./run-beat.sh                                              # path fixed: recovers
      nothing new since last run  ✓
```

## 3. Diagnosis, from `run.log` and `progress.md` alone — no replay

This is the actual incident, read cold, the way you'd read it the next morning:

```
$ cat run.log
2026-08-17T13:58:57Z status=OK   topic="LLM agents and agentic ai" new=0 note="nothing new since last run  ✓"
2026-08-17T13:59:04Z status=FAIL topic="LLM agents and agentic ai" exit=2 action=NEEDS_HUMAN reason="python3: can't open file '/home/munibapc/projects/agentfactory-labs/crash-course/loop-eng/paper-watch/.claude/skills/paper-watch/scripts/paperwatch_v2.py': [Errno 2] No such file or directory"
2026-08-17T13:59:19Z status=OK   topic="LLM agents and agentic ai" new=0 note="nothing new since last run  ✓"
```

- **What failed, and when**: the 13:59:04Z run, exit code 2. `reason=` names the
  cause outright — the wrapper tried to run `paperwatch_v2.py`, which doesn't
  exist. Not an arXiv outage, not a bug in the fetch logic: a bad path.
- **A clear "needs a human" note, not a silent failure**: `action=NEEDS_HUMAN` is
  the one field designed to be grep-able —
  `grep NEEDS_HUMAN run.log` — so a human (or another agent) scanning overnight
  runs doesn't have to parse every line to find the one that matters.
- **The spine wasn't corrupted**: `progress.md` was byte-identical before and
  after the failed run (checked with `diff`) — the crash happened before
  `paperwatch.py` ever touched it. A reader trusting `progress.md` alone would
  correctly conclude nothing new has been seen since the last real success, which
  is true.
- **No replay needed**: everything above came from reading two files. I didn't
  have to re-run the beat to find out what happened to it.

## Done

- [x] What failed and when, from the spine alone: 13:59:04Z, exit 2, bad script path.
- [x] A clear "needs a human" note instead of a silent failure: `action=NEEDS_HUMAN` in `run.log`, added by `run-beat.sh` specifically because `paperwatch.py` alone could not have logged this class of failure.
- [x] Monthly cost at current cadence: **≈ $2.72/month** at the weekday-9am schedule this project already recommends.
