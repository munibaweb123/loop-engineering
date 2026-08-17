---
name: docs-freshness
description: Scan every project folder's README/SKILL/agent docs for drift from the actual filesystem -- broken internal paths, dead cross-links, a stale top-level project table -- and fix only what's mechanically verifiable. Use when asked to run a docs-freshness check, audit project docs for drift, or draft today's docs-freshness fix.
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# Docs freshness — the maker's steps

You are the **maker** half of a maker-checker split. You draft a fix in an isolated
worktree you're already standing in. A separate reviewer agent grades it independently
before anything ships — you don't merge, you don't open the PR, you don't post to the
tracking issue. Your job ends at a verified, narrow diff.

## What counts as drift (in scope)

Only things a filesystem check can prove, nothing that needs taste or web access:

1. **A path that doesn't exist.** Any file/script path named in a `README.md`,
   `SKILL.md`, `AGENTS.md`, or `.claude/agents/*.md` under a project folder, that
   doesn't resolve relative to that folder. (This is exactly the class of bug found
   by hand in `fix-loop/` this week — a `check.py` invocation missing a path
   segment.)
2. **A dead cross-link.** A relative markdown link (`[text](../other-project/)`)
   whose target doesn't exist.
3. **A stale top-level table.** `../README.md`'s project table missing a folder that
   exists, or listing one that no longer does.
4. **An inconsistent `.gitignore`.** A project that writes its own runtime state
   (a spine, a run log) but doesn't gitignore it, when sibling projects do.

## What's out of scope — flag, never fix

- Anything that requires knowing *current* Claude Code CLI behavior, flags, or docs
  (this skill has no web access and shouldn't guess against a moving target).
- Numeric claims that need actually running something to verify (`"20/20"`,
  `"8 tests"`) — a wrong run here is worse than a stale doc.
- Prose, tone, or wording. Not your job.

For anything out of scope that still looks off, write one line to
`FINDINGS.md` in your worktree (create it if absent) instead of touching the file.
That's what the reviewer and the connector report to a human — you are not required
to resolve everything you notice.

## Scope: one project folder a day, not the whole repo

A real, comprehensive, mechanically-verified survey of every path in every
project's docs, done in one sitting, is genuinely expensive — measured at over
$1 for this repo's ~7 folders, and it only grows as the repo does. That's the
wrong shape for a *daily* chore: a task whose cost scales with the whole repo's
size, run every day, doesn't stay boring for long.

So: **you are told which single project folder to check today** (`run-beat.sh`
passes it in the prompt, rotating through the folder list via the spine). Check
only that folder's `README.md`/`SKILL.md`/`AGENTS.md`/`.claude/agents/*.md`, plus
the two repo-wide checks that are cheap no matter how big the repo gets (item 3
and 4 below) — always run those, every day, regardless of which folder is up.
Over a normal week this rotates through every folder at least once, at a
predictable, small cost per day, instead of one large cost up front.

## Steps

Each step below is **one Bash call** (a small script, not a chain of individual
commands), because that's what keeps a day's run cheap. Cost here comes from how
many tool-call round-trips you take, not from how much text you read — checking 15
paths in 15 separate `ls` calls costs roughly 15x what checking them in one Python
loop does, for identical information. Write one self-contained `python3 -c "..."`
or shell script per check category below, print its findings, and read the output
once. Do not fall back to checking paths one Read/ls/Glob call at a time.

1. **Survey the assigned folder, in one call.** One script that: greps the
   assigned folder's `README.md`/`SKILL.md`/`AGENTS.md`/`.claude/agents/*.md` for
   path-shaped tokens (backtick-quoted paths, `python3 <path>`, markdown link
   targets), resolves each relative to that folder, and prints only the ones that
   don't exist. Something like:
   ```
   python3 -c '
   import re, os, glob
   folder = "FOLDER_NAME"
   paths = set()
   for f in glob.glob(f"{folder}/**/*.md", recursive=True):
       text = open(f).read()
       paths.update(re.findall(r"`([\w./-]+\.\w+)`", text))
       paths.update(re.findall(r"\]\((?!https?://)([^)]+)\)", text))
   for p in sorted(paths):
       full = p if p.startswith(folder) else os.path.join(folder, p.lstrip("./"))
       if not os.path.exists(full):
           print("MISSING:", full)
   '
   ```
   Adjust the regex/logic as needed for what you actually find, but keep it to one
   call that surveys the whole folder, not one call per candidate path.
2. **Run the two repo-wide checks, one call each.** (a) Compare the top-level
   `README.md` project table against `find . -maxdepth 1 -type d`. (b) For every
   project folder, check whether it writes its own runtime state (look for
   `progress.md`/`run.log`/similar mentioned in its own docs) and whether
   `.gitignore` covers it. Each as one script, not one command per folder.
3. **Fix only what's in scope, minimally.** One drift item, one small edit. Don't
   rewrite surrounding prose. Don't touch a file just because you're already in it.
4. **Verify every fix you make**, batched the same way. An unverified "fix" is
   worse than the original drift — it just makes the next reviewer's job harder.
5. **Write `FINDINGS.md`** in the worktree root, even if empty, listing: what you
   fixed (path, one line each), and what you noticed but left out of scope (path,
   one line, why). The reviewer and the connector both read this — it's how a human
   sees what happened without reading the diff.
6. **Small is correct.** A day with nothing to fix is a good outcome, not a wasted
   run — say so in `FINDINGS.md` and stop. Do not invent work to justify the run.
