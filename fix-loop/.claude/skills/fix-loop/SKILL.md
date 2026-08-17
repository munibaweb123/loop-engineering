---
name: fix-loop
description: Fix steps for taking one real, reproducible bug from a failing test to a verified patch, in an isolated git worktree, without ever touching the test that proves the bug. Use when asked to fix the bug in buggy-app, draft a fix for the fix-loop project, or implement a patch that a separate reviewer will grade PASS/FAIL.
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Fix loop — implementer steps

You are the **maker** half of a maker-checker split. You draft a fix. You do not
grade it, you do not merge it, and you do not open the PR — a separate reviewer
agent does that, from a context you cannot see or influence. Your job ends at a
verified diff, handed off honestly.

1. **Reproduce first.** Run `python3 check.py buggy-app` from the repo root. Read
   the failing test's name and assertion — that failure *is* the bug's spec, not
   a hint toward it.

2. **Isolate the work in a worktree.** Never edit the checkout you're standing in.
   ```bash
   git worktree add ../fix-loop-impl -b fix/<short-name>
   ```
   Make every change inside `../fix-loop-impl`.

3. **Fix the cause, not the symptom.** Read the buggy function before touching
   it. A patch that special-cases the failing test's exact input (an
   `if x == (1, 3): ...`, a hardcoded return) is not a fix — the reviewer reads
   the diff for exactly this trick, and a hidden case would still be broken.

4. **Never edit the test file.** `test_intervals.py` is the spec. Loosening or
   deleting an assertion to turn the suite green makes the checker lie instead
   of fixing the bug — the reviewer treats any change to it as an automatic FAIL.

5. **Verify locally before handing off.** `python3 check.py ../fix-loop-impl`
   must print all tests passing, including the ones that already passed before
   your change. If it doesn't, you are not done — a reviewer that has to find
   your bug for you is a wasted round.

6. **Hand off the diff, not a claim.** Report the worktree path and branch name,
   plus one or two sentences on what changed and why. The reviewer verifies it
   independently; it will not take your word for the result.
