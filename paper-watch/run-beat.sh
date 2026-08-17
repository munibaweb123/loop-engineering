#!/usr/bin/env bash
# The heartbeat's actual command. Point /schedule at THIS script, not at
# paperwatch.py directly.
#
# Why: paperwatch.py can only log its own errors -- it can't log a failure
# that happens before it ever starts (a typo'd path, a missing interpreter,
# a moved script). This wrapper can, because it doesn't depend on the thing
# it's watching: it runs paperwatch.py, captures whatever happens -- clean
# exit, "nothing new," or an outright crash -- and appends exactly one line
# to run.log every single time. No run fires without leaving a trace.
set -uo pipefail   # not -e: a failing exit code is data we want to capture, not die on

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SCRIPT="${PAPERWATCH_SCRIPT:-.claude/skills/paper-watch/scripts/paperwatch.py}"
TOPIC="${1:-LLM agents and agentic ai}"
LOG="run.log"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

output="$(python3 "$SCRIPT" --topic "$TOPIC" 2>&1)"
exit_code=$?

# last non-empty line -- enough to name a failure without replaying the run
last_line="$(printf '%s\n' "$output" | sed '/^[[:space:]]*$/d' | tail -1 | tr -d '\r' | tr '"' "'")"

if [[ $exit_code -eq 0 ]]; then
  new_count="$(printf '%s\n' "$output" | grep -oE '^\s*[0-9]+ new since last run' | grep -oE '[0-9]+' || true)"
  # the status subtitle ("nothing new..." / "N new..." / "first look...") is
  # more useful here than the last line, which is often a decorative footer
  status_line="$(printf '%s\n' "$output" | grep -m1 -E 'first look|new since last run|no papers found' \
                  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\"/'/g")"
  echo "$TS status=OK topic=\"$TOPIC\" new=${new_count:-0} note=\"${status_line:-$last_line}\"" >> "$LOG"
else
  echo "$TS status=FAIL topic=\"$TOPIC\" exit=$exit_code action=NEEDS_HUMAN reason=\"$last_line\"" >> "$LOG"
fi

printf '%s\n' "$output"
exit $exit_code
