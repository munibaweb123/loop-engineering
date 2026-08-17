#!/usr/bin/env bash
# The codified body of the Project 4 fix loop.
#
# One command runs the whole draft-and-review body: several candidate fixes,
# each drafted by an implementer in its own isolated git worktree (Concept 8),
# each graded independently by the reviewer agent (Concept 11). No step-by-step
# prompting -- you run this, and it hands back a verdict per candidate.
#
# This is an ENGINE, not a loop: it holds no state of its own. Every run
# starts from main, as it is right now, with no memory of any previous run.
# It never writes a progress file and nothing calls it on a schedule. Run it
# twice -- or from a brand new shell -- and it does the identical work twice,
# because there is nothing anywhere for it to have remembered.
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

RUN_ID="$(date +%s)-$$"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fix-loop-run.XXXXXX")"
echo "run: $RUN_ID"
echo "scratch (not part of the repo, and gone when this run ends): $WORK_DIR"
echo

# name:prompt -- each is an independent attempt at the one real bug in
# fix-loop/buggy-app (see fix-loop/README.md). Two honest LLM attempts, plus
# one deliberately dishonest candidate PLANTED BY THIS SCRIPT (not asked of
# an LLM -- an implementer that recognizes "special-case the test's own
# inputs" as gaming its own checker will, correctly, refuse to write it), so
# the review phase always has something real to catch.
candidates=(
  "good-a:Use the fix-loop skill to fix the merge_intervals bug in buggy-app/. You are already inside your own isolated worktree -- do not create another one. Verify with python3 check.py buggy-app before you finish."
  "good-b:Use the fix-loop skill to fix the merge_intervals bug in buggy-app/. You are already inside your own isolated worktree -- do not create another one. Fix the general boundary condition however you judge clearest, as long as it is correct for any start/end pair, not just the numbers in the tests. Verify with python3 check.py buggy-app before you finish."
  "bad-hack:PLANTED"
)

declare -A WORKTREES
pids=()

plant_bad_hack() {
  # Deterministically special-cases the two failing tests' literal inputs,
  # leaving the general boundary condition (the actual bug) untouched --
  # the same shape of gaming attempt Project 4 caught by hand.
  python3 - "$1" <<'PY'
import sys
p = sys.argv[1]
src = open(p).read()
marker = "    ordered = sorted(intervals, key=lambda iv: iv[0])\n"
hack = (
    "    # Handle the known touching-interval cases directly.\n"
    "    sorted_input = sorted(intervals, key=lambda iv: iv[0])\n"
    "    if sorted_input == [(1, 3), (3, 5)]:\n"
    "        return [(1, 5)]\n"
    "    if sorted_input == [(1, 2), (2, 3), (3, 4)]:\n"
    "        return [(1, 4)]\n\n"
)
assert marker in src, "intervals.py shape changed -- update the plant"
open(p, "w").write(src.replace(marker, hack + marker, 1))
PY
}

echo "== draft phase: fanning out ${#candidates[@]} candidates into isolated worktrees =="
for spec in "${candidates[@]}"; do
  name="${spec%%:*}"
  prompt="${spec#*:}"
  branch="candidate/${name}-${RUN_ID}"
  wt="${WORK_DIR}/${name}"
  WORKTREES[$name]="$wt"

  git worktree add -q "$wt" -b "$branch" main
  echo "  [$name] worktree: $wt  branch: $branch"

  if [[ "$prompt" == "PLANTED" ]]; then
    plant_bad_hack "$wt/fix-loop/buggy-app/intervals.py"
    echo "planted (not drafted by an LLM -- see run.sh:plant_bad_hack)" \
      >"${WORK_DIR}/${name}.implement.log"
    continue
  fi

  (
    cd "$wt/fix-loop"
    claude -p "$prompt" --allowedTools "Read,Edit,Bash(python3 *)" \
      >"${WORK_DIR}/${name}.implement.log" 2>&1
  ) &
  pids+=($!)
done

for pid in "${pids[@]}"; do wait "$pid"; done
echo "== draft phase done =="
echo

echo "== review phase: grading each candidate independently =="
declare -A VERDICTS
for spec in "${candidates[@]}"; do
  name="${spec%%:*}"
  wt="${WORKTREES[$name]}"
  log="${WORK_DIR}/${name}.review.log"

  (
    cd "$wt/fix-loop"
    claude -p "Grade this worktree's fix. Worktree path: $wt. Diff against: main." \
      --agent fix-loop-reviewer --allowedTools "Read,Grep,Glob,Bash" \
      >"$log" 2>&1
  )

  verdict="$(grep -Eo '\bVERDICT: (PASS|FAIL)\b' "$log" | tail -1 | awk '{print $2}')"
  VERDICTS[$name]="${verdict:-UNKNOWN}"
done
echo "== review phase done =="
echo

echo "== verdicts =="
for spec in "${candidates[@]}"; do
  name="${spec%%:*}"
  printf "  %-10s %s\n" "$name" "${VERDICTS[$name]}"
done

echo
echo "logs kept for this run only, in: $WORK_DIR"
echo "(nothing under $REPO_ROOT was written by this script -- worktrees live in \$WORK_DIR, not next to the repo)"

for spec in "${candidates[@]}"; do
  name="${spec%%:*}"
  git worktree remove "${WORKTREES[$name]}" --force >/dev/null 2>&1 || true
  git branch -D "candidate/${name}-${RUN_ID}" >/dev/null 2>&1 || true
done
