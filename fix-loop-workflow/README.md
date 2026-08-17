# Codify the body — an engine, not a loop

**Loop Engineering — the dynamic-workflows interlude, Concepts 8 (worktree) and 11 (maker-checker).**

[Project 4](../fix-loop/) built one draft-and-review cycle by hand: I acted as the
implementer, then a separate agent graded the diff, then I opened a PR on PASS. Every
step needed a prompt from me. This project takes that same body — several candidates,
each in its own isolated checkout, each independently reviewed — and **codifies it into
one re-runnable unit** that does all of that from a single invocation. Then it proves
that unit is not, by itself, a loop.

## The two approaches, and which one this repo has

The assignment describes two ways to codify the body:

- **Claude Code's dynamic workflows** — describe the task in plain words ("use a
  workflow to..."), let the runtime write a JavaScript orchestration script and run it
  in the background, then save the run as a `/command` from the `/workflows` view.
- **A plain shell script** — a `for` loop over the candidates, `&`/`wait` for the
  fan-out, and a checker's exit code (here, the reviewer's verdict) deciding pass/fail.

**This repo ships the shell-script version, [`run.sh`](run.sh), because I could build,
run, and prove it end-to-end from here.** Dynamic workflows are triggered by a keyword
(`ultracode`, or asking "use a workflow" in your own words) **in a prompt you type
yourself at the interactive prompt** — the docs are explicit that this is a human-input
trigger, not something reachable from a scripted or headless call. I'm an agent
operating through tool calls in this session, not your keyboard, so I can describe
exactly what to type and what to expect, but I can't press the keys for you. See
[Try the dynamic-workflow version yourself](#try-the-dynamic-workflow-version-yourself)
below for the literal prompt.

The two approaches are the same idea either way: **the orchestration becomes a
re-runnable artifact** — a script or a saved command — instead of a sequence of prompts
only you can drive.

## What `run.sh` does

```sh
./run.sh
```

One command, no follow-up prompting:

1. **Draft phase — several candidates, isolated checkouts.** Fans out into three `git
   worktree`s off `main` (Concept 8), in parallel:
   - `good-a`, `good-b`: two independent headless implementer sessions
     (`claude -p ... --allowedTools ...`), each following the [fix-loop
     skill](../fix-loop/.claude/skills/fix-loop/) to fix the real bug in
     `fix-loop/buggy-app`.
   - `bad-hack`: a deliberately dishonest "fix" — special-casing the two failing
     tests' literal inputs instead of correcting the general rule — **planted by the
     script itself**, not asked of an LLM. (Why: see [Why the bad candidate isn't
     LLM-drafted](#why-the-bad-candidate-isnt-llm-drafted).)
2. **Review phase — a verdict for each.** Each worktree is graded independently by a
   *fresh* headless session running the `fix-loop-reviewer` agent (Concept 11):
   `claude -p ... --agent fix-loop-reviewer`. It re-runs the real checker itself and
   reads the diff — same contract as Project 4, just invoked by the script instead of
   by me.
3. **Report and clean up.** Prints one verdict line per candidate, then removes every
   worktree and branch it created. Nothing under the repo is left behind.

### Two actual runs

```
== verdicts ==
  good-a     PASS
  good-b     PASS
  bad-hack   FAIL
```

Both runs — one right after the other, the second launched via `env -i ... bash -c
'bash run.sh'` (a blank environment, no inherited shell state) — produced this exact
result, independently reasoned each time. The reviewer's stated reason for `bad-hack`,
both times, named the actual planted lines:

> The fix hardcodes special cases for the exact test inputs rather than correcting the
> general algorithm... If the tests used different numbers like `[(2, 4), (4, 6)]`
> (same structure, different values), the hardcoded checks would not apply.

### Why the bad candidate isn't LLM-drafted

My first version asked an implementer session to write the hack (`"special-case the
literal test tuples..."`). Twice, it refused — once by explaining exactly why that's
gaming the checker and offering the honest fix instead, once by writing the honest fix
outright ignoring the instruction to hack it. That's good model behavior, but it meant
the review phase had nothing dishonest to actually catch, on either run — a checker
that's never given a bad answer to reject hasn't been tested. So `bad-hack` is now
planted deterministically by `run.sh` itself (`plant_bad_hack()`), the same shape of
patch I planted by hand in Project 4. The reviewer still has to catch it fresh, from
the diff, every run — it just doesn't depend on an adversarial prompt succeeding
against an LLM implementer's own judgment.

## Proof: this is not a loop

Run it twice — or, as I actually did it, once normally and once from a completely
blank shell environment (`env -i HOME="$HOME" PATH="$PATH" bash -c 'bash run.sh'`, no
inherited variables, no shared process) — and:

- Every worktree, branch, and log from the first run was already gone before the
  second run started (`run.sh` deletes them at the end of its own invocation).
- The second run redid **all** of it from scratch: three new worktrees off the same
  `main`, three new headless implementer/reviewer sessions, three new verdicts —
  computed with zero knowledge that a first run had ever happened.
- `git status`, `git worktree list`, and `git branch -a` were identical before either
  run and after both — nothing under the repo changed.

There is no `progress.md` here, on purpose. That's the whole point: `run.sh` is
**stateless by construction**. Nothing it does depends on anything a previous run
wrote down, because nothing survives between invocations except what's already
committed to `main` — and neither run commits or merges anything.

## What it would take to make this a loop

Compare to [paper-watch](../paper-watch/), which *is* a loop. A loop needs two things
this engine deliberately doesn't have:

1. **A heartbeat.** Something that calls `run.sh` on its own — a `/schedule` Routine
   firing daily, a webhook on every new commit, a `/loop` while someone's watching.
   Right now the only heartbeat is a person typing `./run.sh`.
2. **A progress file (the spine).** Somewhere the candidates' verdicts get written —
   which issues were tried, which passed, which are still open — read back in at the
   start of the next run so it only drafts fixes for what's still outstanding, instead
   of re-fighting the same bug from scratch every single time.

Add both, and this stops being an engine you fire by hand and becomes a loop: a
scheduled run that picks up where the last one left off. Without them, it's exactly
what Project 4 was, generalized — a reliable, re-runnable *unit of work*, not a
process with memory.

## Try the dynamic-workflow version yourself

In your own interactive `claude` session (not through this chat), at the repo root:

```
use a workflow to draft fixes for the bug in fix-loop/buggy-app in three parallel
worktrees (two honest attempts, one that fakes it by hardcoding the failing tests'
inputs), and have the fix-loop-reviewer agent grade each one
```

Approve the run when prompted. Watch it with `/workflows` — arrow keys to select the
run, Enter to drill into a phase or agent. When it does what you want, select the run
in `/workflows` and press `s` to save it as a command (project or personal location);
it then runs as `/<name>` in future sessions, same as `/deep-research`.

[`.claude/workflows/fix-loop-review.workflow.js`](.claude/workflows/fix-loop-review.workflow.js)
in this folder shows the shape such a saved script takes, hand-written to match the
documented format — it is **not** something Claude Code generated or ran; I have no
tool that reaches the `/workflows` view or fires the human-only trigger keyword from
inside this session. Treat it as a preview of what saving the real run would produce,
not as verified output.

## Requirements

Claude Code CLI on your `PATH` and already authenticated (`claude -p` must work
headless) — `run.sh` shells out to it directly, the same way it shells out to
`python3`. Everything else is what [`fix-loop/`](../fix-loop/) already needs.
