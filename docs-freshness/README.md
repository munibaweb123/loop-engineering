# Docs Freshness — the capstone daily loop

**Loop Engineering — capstone, all six parts.**

A real, boring, recurring chore, automated end to end: keep this repo's own project
docs from drifting away from what's actually on disk. It already caught two real bugs
by hand this week (a broken `check.py` path in three files, a `main` branch that sat
unpushed) — this loop is that same check, running itself, daily, unattended.

## The six parts

| Part | Where |
| --- | --- |
| **Heartbeat** | A local `cron` entry, weekdays 9am PKT, firing [`run-beat.sh`](run-beat.sh). See [why not `/schedule`](#why-a-local-cron-and-not-schedule). |
| **Worktree** | One isolated `git worktree` per day, off `main` (Concept 8). |
| **Skill** | [`.claude/skills/docs-freshness/SKILL.md`](.claude/skills/docs-freshness/SKILL.md) — the implementer's playbook. |
| **Maker-checker** | The implementer drafts; [`.claude/agents/reviewer.md`](.claude/agents/reviewer.md) independently re-verifies every claim before anything ships (Concept 11). |
| **Connector** | [Tracking issue #2](https://github.com/munibaweb123/loop-engineering/issues/2) — one comment per day, whatever happened. A PR opens only on a verified fix. |
| **Spine** | [`progress.md`](progress.md) (gitignored, per-repo runtime state) — folder rotation, idempotency, and the trailing-week cost, read first and written last. |

## The chore, precisely

One project folder a day (rotating — see [Why one folder a day](#why-one-folder-a-day-not-the-whole-repo)),
checked for:

1. A path named in that folder's `README.md`/`SKILL.md`/`AGENTS.md`/
   `.claude/agents/*.md` that doesn't actually exist.
2. A dead relative link to another project folder.
3. The top-level `README.md`'s project table drifting from the real folder list.
4. A project writing its own runtime state without gitignoring it.

Full scope rules, and what's deliberately *out* of scope (anything needing live
CLI/web knowledge, anything needing a test run to verify, prose/tone), are in the
skill — read it before trusting what this ships.

## Budget guards

- **Per-call cap.** `--max-budget-usd` on both the implementer and the reviewer.
  Currently $1.20 / $0.30 — see [What $1.20 actually bought](#what-120-actually-bought-a-real-cost-story)
  for why that number is what it is, not a guess.
- **Weekly cap.** `run-beat.sh` sums the trailing 7 days' logged cost from the
  spine; at $5.00 it skips the maker entirely and posts a `NEEDS_HUMAN` comment
  instead of spending more, until a human clears it.
- **One PR at a time.** Before opening a PR, it checks for an existing open one
  from this loop and holds rather than stacks — a human's review queue is a
  budget too.
- **Idempotency.** One run per calendar day, checked against the spine, so a
  double-fired schedule can't double-spend.

## Why a local cron, and not `/schedule`

`/schedule` creates a **cloud** routine: a fresh, isolated cloud session with its
own git clone, not a job on this machine. Two real problems with pointing it at
`run-beat.sh` as originally planned: GitHub wasn't connected for this repo in the
cloud environment yet (`/web-setup` required, a human OAuth step I can't do), and
`run-beat.sh` as built assumes local execution — local absolute paths, and it was
proven today shelling out to the *locally*-authenticated `claude` and `gh` CLIs,
neither verified to behave the same in a fresh cloud sandbox. Rather than bet the
capstone's first week on an unverified rewrite, the heartbeat is a local `crontab`
entry instead — the exact mechanism already proven working, end to end, today:

```
PATH=/home/munibapc/.npm-global/bin:/home/munibapc/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 9 * * 1-5 bash <absolute-repo-path>/docs-freshness/run-beat.sh >> <absolute-repo-path>/docs-freshness/.cron.log 2>&1
```

Verified for real, not assumed: scheduled a one-off test fire two minutes out,
watched `.cron.log` for it, and cron correctly resolved `PATH`, invoked `bash`,
and `run-beat.sh` correctly resolved its own paths and hit the idempotency guard
(`already ran today`) — free, since no `claude -p` call happens on that path.

**The honest caveat**: this machine runs Claude Code inside WSL2. Cron only fires
while the WSL2 instance is up, which (on this machine) means while at least one
WSL session is attached — not automatically "while you sleep" the way a cloud
routine would be, unless the machine and WSL stay running overnight. Check with
`crontab -l` and `service cron status`; if a scheduled morning is missing from
[the tracking issue](https://github.com/munibaweb123/loop-engineering/issues/2)
entirely (not even a `NEEDS_HUMAN` comment), the machine being off overnight is
the first thing to check, before suspecting the loop itself.

## Why one folder a day, not the whole repo

The first design surveyed the *entire* repo every run. Measured, that was a
$1+ task — and it only grows as the repo does. That's the wrong shape for
something that's supposed to run **daily, forever**: a chore whose cost scales
with total repo size doesn't stay boring. So the spine now tracks a rotation
pointer (`next-folder:`) and each day's run is scoped to exactly one project
folder, plus two repo-wide checks cheap enough to always run. A normal week
touches every folder in the repo at least once, at a small, predictable cost per
day, instead of one large cost up front.

## What $1.20 actually bought — a real cost story

Every number below is measured, not estimated, from actually running this loop
today:

| Attempt | What happened | Cost |
| --- | --- | --- |
| 1 | Full-repo survey, $0.50 cap | Hit the cap mid-survey — too big a task |
| 2 | Full-repo survey, $1.00 cap | Hit the cap again, closer to done — confirmed the *scope*, not the cap, was wrong |
| 3 | Redesigned to one folder/day (`doorbell`), $0.60 cap | Hit the cap at 26 tool-call turns — the *implementer* was checking one path per `ls` call because my own `--allowedTools` restriction blocked it from writing one combined script |
| 4 | Same folder, broadened `allowedTools` to batch checks | **$0.07** before hitting an unrelated account rate limit — confirmed the batching fix, not just luck |
| 5 | `doorbell`, full run after the rate limit cleared | **$0.49**, clean day, correctly posted to the tracking issue |
| 6 | `fix-loop` (larger folder — more files), $0.60 cap | Hit the cap again — a bigger folder genuinely costs more, not a bug |
| 7 | Same folder, $1.20 cap | Maker completed, but the reviewer crashed: `--agent 'docs-freshness-reviewer' not found` |
| 8 | Same run, after fixing `run-beat.sh` to `cd` into the worktree before invoking `claude -p` | Reviewer still not found — turned out agent discovery needs cwd to be the *exact* folder holding `.claude/agents/`, confirmed with a throwaway worktree; `cd "$WT"` (the repo root) wasn't specific enough |
| 9 | Same run, reviewer now `cd`'d to `$WT/docs-freshness` specifically | **Complete.** Maker: $0.95. Reviewer: $0.086, `VERDICT: PASS`. PR opened, tracking issue posted, worktree cleaned up. |

Four real, different root causes, four real fixes, in order: survey scope, a tool
restriction blocking batching, per-folder cost variance, then two distinct
cwd-scoping bugs in how `run-beat.sh` invoked `claude -p` itself. None of this was
hypothetical — every row is a logged run in a real `.maker-*.json`/`.review-*.json`
from `claude -p --output-format json`, or a crash message read directly off the
terminal.

## The shipped fix

To prove the "found something → reviewer verifies it → PR opens" path actually
fires — not just the clean-day path — I planted a real, small, reversible drift on
purpose: a fabricated `scripts/verify.sh` row added to `fix-loop/README.md`'s
table, a file that doesn't exist. The loop, unprompted beyond its normal daily
run, found it, removed the false claim, and — notably — also investigated and
*dismissed* two false positives its own survey script had raised (a `../` path it
mis-joined, a leading dot its own `lstrip` call ate), and flagged one genuine
ambiguity in `fix-loop`'s own docs as worth a human's judgment rather than
guessing a fix for it. Reviewed independently, verdict PASS, and
[opened as a real PR](https://github.com/munibaweb123/loop-engineering/pull/3) —
still open, waiting on a human (me, over the coming week) to actually merge it.
The loop ships PRs; it doesn't merge them.

## Trying it yourself

```sh
./run-beat.sh
```

Idempotent (skips if today already ran), reads the spine for which folder is up,
and does the whole body — draft, review, ship or hold, log — without further
prompting. To rehearse a day with something to fix, plant a small real drift
first (a fabricated path, like above) and revert it once you've seen the result.

## Concept 15, honestly

*"Did your understanding of the project keep up with what the loop changed?"*

Today: yes, because I read every failure as it happened and changed the design
each time — this README's cost table **is** that record, not a summary written
after the fact. But today was one sitting with me watching every run. The real
test is the week ahead: whether I keep reading [issue #2](https://github.com/munibaweb123/loop-engineering/issues/2)
daily, or start trusting a green checkmark instead. I'm not claiming that yet —
this file gets an honest update once there's a week of unattended runs to judge
it against, not before. If a day comes where I can't explain what the loop
shipped without re-reading the diff myself, that's the signal to slow the
schedule down, not to stop reading.
