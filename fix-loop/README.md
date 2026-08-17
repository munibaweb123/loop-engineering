# Fix Loop — a maker-checker with a real checker

**Loop Engineering, Concepts 8 (worktree), 9 (skill), 11 (maker-checker).**

A smaller version of the [Build your portfolio](../portfolio-starter/) loop, aimed at
one real bug instead of a whole page. Same split: an **implementer** drafts a fix, a
**separate reviewer** grades it, and only a PASS opens a PR. The reviewer is not the
implementer in a different mood — it runs in its own agent, re-runs the real checker
itself, and reads the diff for the specific ways a fix can cheat.

## What's here

| Path | What it is |
| --- | --- |
| `buggy-app/intervals.py` | A `merge_intervals` function with one real, planted bug. |
| `buggy-app/test_intervals.py` | The spec. 8 tests; 2 fail against the bug. **Never edit this to make it pass.** |
| `check.py` | The mechanical checker. `python3 check.py buggy-app` |
| `.claude/skills/fix-loop/` | The implementer's fix steps (Concept 9). |
| `.claude/agents/reviewer.md` | The checker agent (Concept 11) — read-mostly, runs the real checker itself, replies PASS/FAIL with reasons. |

## The bug

`merge_intervals` should merge intervals that overlap *or touch* — `(1, 3)` and
`(3, 5)` share the point 3, so there's no gap, and they should collapse into
`(1, 5)`. The code uses `start < last[1]` instead of `start <= last[1]`, so touching
intervals are left separate. Two of the eight tests catch it.

## Run it

```sh
python3 check.py buggy-app     # confirm it's red first: 6/8 pass, 2 fail
```

Then, in Claude Code, at the repo root:

```
Fix the bug in fix-loop/buggy-app using the fix-loop skill, in its own worktree.
Then have the fix-loop-reviewer agent grade the diff. Open a PR only if it says PASS.
```

What should happen:

1. **Implementer** (this session, following `.claude/skills/fix-loop/`): reproduces
   the failure, creates `git worktree add ../fix-loop-impl -b fix/<name>`, fixes the
   `<` to `<=` (the actual general fix — not a special case), and confirms
   `python3 check.py ../fix-loop-impl/fix-loop/buggy-app` is green — note the full
   path: `check.py` needs `buggy-app` itself, not the worktree root.
2. **Reviewer** (a *separate* agent — `Task`/`Agent` with `fix-loop-reviewer`, not the
   same conversation): re-runs `check.py` itself, reads `git diff main`, confirms the
   test file is untouched and the fix is general, and replies `VERDICT: PASS` or
   `VERDICT: FAIL` with reasons.
3. **Only on PASS**: push the branch and `gh pr create` from the worktree. On FAIL:
   report the reviewer's reasons and stop — no PR.

## Prove the checker isn't soft

A reviewer that passes everything isn't a reviewer. Before trusting this one, plant a
deliberately bad "fix" in a second worktree — e.g. edit `test_intervals.py` to delete
the two failing assertions, or hardcode
`if intervals == [(1, 3), (3, 5)]: return [(1, 5)]` instead of fixing the condition —
and run the same reviewer against it. It must reply `VERDICT: FAIL` and name the
specific problem (touched the spec file / hardcoded the test's own input). If it
passes the bad fix instead, the reviewer's checklist is too soft — tighten
`.claude/agents/reviewer.md`, don't ignore the result.

## Done means both of these are true

- A good fix gets `VERDICT: PASS` from the reviewer **and** a PR is opened.
- A deliberately bad fix gets `VERDICT: FAIL`, with the reviewer naming the reason.

## The two rules

**Never edit `check.py` or `test_intervals.py` to make the suite pass.** That's the
one unforgivable move, for the implementer and the reviewer alike — if the checker
disagrees with the fix, distrust the fix.

**The reviewer must run the checker itself.** A reviewer that reads the implementer's
"tests pass" claim and believes it isn't a checker, it's a rubber stamp.
