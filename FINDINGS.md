# Docs-freshness findings — 2026-08-17

Assigned folder: `fix-loop/`. Plus the two always-run repo-wide checks.

## Fixed

- `fix-loop/README.md`: removed the table row `| \`scripts/verify.sh\` | Convenience
  wrapper around \`check.py\`. |`. No `scripts/` directory exists anywhere in the
  repo and no `verify.sh` exists anywhere in the repo — the row referenced a file
  that was never created. Verified by re-scanning `fix-loop/**/*.md` for path-shaped
  tokens after the edit: no remaining reference to `verify.sh`, and the diff is a
  single-line removal (`git diff --stat` confirms).

## Noticed, left out of scope

- `fix-loop/README.md` ("Prove the checker isn't soft" section) and
  `fix-loop/.claude/skills/fix-loop/SKILL.md` (step 4) refer to `test_intervals.py`
  by bare filename in prose (the real file is `fix-loop/buggy-app/test_intervals.py`).
  Not a table/link path claim, just informal in-sentence naming -- wording, not a
  broken reference, so left alone per the skill's prose-is-out-of-scope rule.
- `fix-loop/.claude/skills/fix-loop/SKILL.md` step 1 says to run
  `python3 check.py buggy-app` "from the repo root," but `check.py` only exists at
  `fix-loop/check.py`, not the top-level repo root. This reads ambiguously (likely
  means "repo root" loosely / assumes cwd is already `fix-loop/`), but I didn't
  touch it -- it's a phrasing/cwd-assumption question, not a provably broken path
  the way `scripts/verify.sh` was, and a prior commit (171e4b8) already fixed the
  actual broken invocations in this same file (the worktree-verification steps)
  without touching this line, suggesting it was left as-is deliberately. Flagging
  for a human to confirm intent rather than guessing.

## Repo-wide checks (always run)

- **Top-level README project table** (`README.md`): compared against
  `find . -maxdepth 1 -type d` -- all 8 project folders (`docs-freshness`,
  `doorbell`, `fix-loop`, `fix-loop-workflow`, `iss-loop`, `paper-watch`,
  `portfolio-starter`, `sky-watch`) are listed, none stale, none missing. No drift.
- **`.gitignore` consistency**: every project's docs that mention runtime-state
  files (`progress.md`, `run.log`) -- `docs-freshness`, `fix-loop-workflow`,
  `paper-watch` -- are covered by the top-level `.gitignore`'s unanchored
  `progress.md` / `run.log` patterns, plus `docs-freshness`'s own scoped debug-file
  entries. `fix-loop` itself writes no runtime state. No drift.

## Not fixed (false positives from my own survey script, verified and dismissed)

- `../portfolio-starter/` in `fix-loop/README.md` -- resolves to the real top-level
  `portfolio-starter/` folder; my first-pass script wrongly joined it under
  `fix-loop/`.
- `` `.claude/agents/reviewer.md` `` in `fix-loop/README.md` -- the real file
  `fix-loop/.claude/agents/reviewer.md` exists; my script's `lstrip("./")` call
  stripped the leading dot along with the slash, producing a false `claude/...`
  path.
