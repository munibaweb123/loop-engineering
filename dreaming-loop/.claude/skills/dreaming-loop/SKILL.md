# Dreaming Loop Skill

The dreaming loop reads other loops' logs, finds repeated failures,
and proposes the smallest rules-file change that would prevent them.

## Purpose

This skill is used by the dreaming loop (Project 12) to analyze
progress.md files from other loops and propose improvements.

## Steps

1. **Read the spine** (`dreaming-state.md`)
   - Get the last analysis date
   - Don't re-analyze entries already processed

2. **Scan progress files** (from `REPOS.md`)
   - Read entries since last analysis date
   - Look for lines containing: FAIL, error, forgot, missed, failed
   - Count occurrences of each failure pattern

3. **Find repeated patterns**
   - A pattern that appears 2+ times is worth proposing
   - Extract the exact reason text
   - Count how many times it appeared

4. **Draft the smallest change**
   - Add one rule to `rules.md` that prevents this pattern
   - Keep it minimal — smallest possible fix
   - Cite the evidence in the PR

5. **Create PR on claude/ branch**
   - Branch name: `claude/dreaming-loop-YYYYMMDD`
   - Never commit directly to main
   - PR body must include:
     - Which runs had the failure
     - How many times it appeared
     - Why this line stops it

6. **Propose one deletion**
   - Check if any rule in `rules.md` hasn't been needed recently
   - If found, propose removing it
   - Cite that no recent logs needed it

7. **Update the spine**
   - Write new `last_analysis` date
   - Log what was analyzed and proposed

## Rules

- **Never propose without evidence.** Every proposal must cite actual log entries.
- **Never commit directly.** Always a PR, always a branch, always human review.
- **Keep changes minimal.** Smallest possible fix, not a rewrite.
- **One PR at a time.** Don't stack proposals — wait for review.

## What the human checks

The human gate reviews:
- Does the proposed change trace to real log entries?
- Is the evidence cited (which runs, how often)?
- Is the change the smallest possible fix?
- Is the deletion justified (no recent use)?

If all check out, merge. If not, close and tighten the prompt.
