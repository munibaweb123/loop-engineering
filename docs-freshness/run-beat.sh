#!/usr/bin/env bash
# The daily loop's heartbeat command. Point /schedule at this script.
#
# One firing does the whole body: read the spine, isolate the work in a
# worktree, have an implementer draft a docs-freshness fix, have a separate
# reviewer grade it, ship the result through the connector (a tracking
# GitHub issue, and a PR when there's a verified fix), and write the spine
# last. Nothing here trusts a claim it can re-check itself, and nothing here
# fails without leaving a line behind (Project 7's lesson, reused).
set -uo pipefail   # not -e: a failing step is data to log, not a reason to die silently

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERE="$REPO_ROOT/docs-freshness"
cd "$REPO_ROOT"

SPINE="$HERE/progress.md"
TRACKING_ISSUE_FILE="$HERE/TRACKING_ISSUE"
TODAY="$(date -u +%Y-%m-%d)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

MAKER_BUDGET_USD="1.20"   # one project folder + the two repo-wide checks; larger folders cost more
REVIEWER_BUDGET_USD="0.30"
WEEKLY_CAP_USD="5.00"

mkdir -p "$HERE"
touch "$SPINE"
ISSUE_NUM="$(cat "$TRACKING_ISSUE_FILE" 2>/dev/null || true)"

# ---- rotation: one project folder a day, round-robin, tracked in the spine ----
mapfile -t FOLDER_LIST < <(find "$REPO_ROOT" -maxdepth 1 -mindepth 1 -type d \
  ! -name .git ! -name .claude ! -name docs-freshness -printf '%f\n' | sort)
CURRENT_NEXT="$(grep '^next-folder:' "$SPINE" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')"
TARGET_FOLDER="$CURRENT_NEXT"
target_idx=-1
for i in "${!FOLDER_LIST[@]}"; do
  [[ "${FOLDER_LIST[$i]}" == "$CURRENT_NEXT" ]] && target_idx=$i && break
done
if [[ $target_idx -lt 0 ]]; then target_idx=0; TARGET_FOLDER="${FOLDER_LIST[0]}"; fi
NEW_NEXT_FOLDER="${FOLDER_LIST[$(( (target_idx + 1) % ${#FOLDER_LIST[@]} ))]}"
EXISTING_DAY_LINES="$(grep '^- ' "$SPINE" 2>/dev/null || true)"

spine_write() {   # spine_write status cost pr findings
  {
    echo "next-folder: $NEW_NEXT_FOLDER"
    echo
    [[ -n "$EXISTING_DAY_LINES" ]] && printf '%s\n' "$EXISTING_DAY_LINES"
    echo "- $TODAY status=$1 cost=$2 pr=$3 folder=$TARGET_FOLDER findings=\"$4\""
  } > "$SPINE"
}

connector_post() {   # connector_post body
  if [[ -n "$ISSUE_NUM" ]]; then
    gh issue comment "$ISSUE_NUM" --body "$1" >/dev/null 2>&1 || true
  fi
}

# ---- idempotency guard: never double-fire the same day ----
if grep -q "^- $TODAY status=" "$SPINE" 2>/dev/null; then
  echo "already ran today ($TODAY) -- see $SPINE"
  exit 0
fi

# ---- budget guard: trailing-7-day spend cap ----
trailing_spend="$(printf '%s\n' "$EXISTING_DAY_LINES" | tail -7 | \
  awk -F'cost=' '/^- /{split($2,a," "); sum+=a[1]} END{printf "%.4f", sum+0}')"
if awk -v s="$trailing_spend" -v cap="$WEEKLY_CAP_USD" 'BEGIN{exit !(s>=cap)}'; then
  spine_write "NEEDS_HUMAN" "0.0000" "none" "weekly budget cap reached (\$${WEEKLY_CAP_USD}, trailing spend \$${trailing_spend}) -- maker skipped"
  connector_post "🛑 **$TODAY**: weekly budget cap (\$$WEEKLY_CAP_USD) reached — trailing 7-day spend is \$$trailing_spend. Skipped today's run. Clear this by reviewing \`$SPINE\` and, if it's fine, waiting for the window to roll forward."
  exit 0
fi

# ---- draft phase: one isolated worktree for today's run ----
BRANCH="docs-freshness/$TODAY"
WT="$(mktemp -d "${TMPDIR:-/tmp}/docs-freshness-run.XXXXXX")"
if ! git worktree add -q "$WT" -b "$BRANCH" main 2>"$HERE/.last-error.log"; then
  reason="$(tail -1 "$HERE/.last-error.log" | tr '"' "'")"
  spine_write "FAIL" "0.0000" "none" "worktree setup failed: $reason"
  connector_post "🛑 **$TODAY**: could not even set up the worktree — needs a human. Reason: $reason"
  exit 1
fi

maker_prompt="Use the docs-freshness skill. You are already in your own isolated worktree, standing at the repo root -- do not create another one. Today's assigned project folder is '$TARGET_FOLDER' -- check only that folder's docs, plus the two repo-wide checks (top-level README table, .gitignore consistency) the skill says to always run. Write FINDINGS.md at the repo root before you finish, even if there was nothing to fix."
maker_json="$HERE/.maker-$TODAY.json"
(cd "$WT" && claude -p "$maker_prompt" --allowedTools "Read,Edit,Grep,Glob,Bash" \
  --max-budget-usd "$MAKER_BUDGET_USD" --output-format json) >"$maker_json" 2>&1
maker_ok=$?

maker_cost="$(python3 -c "import json,sys
try:
    print(f\"{json.load(open('$maker_json')).get('total_cost_usd',0):.4f}\")
except Exception:
    print('0.0000')" 2>/dev/null)"

if [[ $maker_ok -ne 0 ]] || [[ -z "$maker_cost" ]]; then
  subtype="$(python3 -c "import json
try:
    print(json.load(open('$maker_json')).get('subtype',''))
except Exception:
    print('')" 2>/dev/null)"
  api_status="$(python3 -c "import json
try:
    print(json.load(open('$maker_json')).get('api_error_status',''))
except Exception:
    print('')" 2>/dev/null)"
  if [[ "$subtype" == "error_max_budget_usd" ]]; then
    spine_write "FAIL" "${maker_cost:-$MAKER_BUDGET_USD}" "none" "hit the \$$MAKER_BUDGET_USD per-run budget before finishing -- scope is too big for the cap, not a crash"
    connector_post "🛑 **$TODAY**: implementer hit its \$$MAKER_BUDGET_USD budget cap before finishing — needs a human to widen the cap or narrow the survey scope. Not a crash, just too big for the ceiling."
  elif [[ "$api_status" == "429" ]]; then
    # transient and self-resolving -- the account's rate/usage limit, not a bug in
    # this loop. Distinct status on purpose: this does NOT need a human to act,
    # only to know it happened -- UNLESS it repeats two beats running, which stops
    # looking transient and starts looking like something actually wrong.
    last_status="$(printf '%s\n' "$EXISTING_DAY_LINES" | tail -1 | grep -oE 'status=[A-Z_]+' | cut -d= -f2)"
    if [[ "$last_status" == "RATE_LIMITED" ]]; then
      spine_write "NEEDS_HUMAN" "${maker_cost:-0.0000}" "none" "rate-limited two beats in a row -- no longer looks transient"
      connector_post "🛑 **$TODAY**: rate-limited again, same as last beat — two in a row stops looking transient. Needs a human look."
    else
      spine_write "RATE_LIMITED" "${maker_cost:-0.0000}" "none" "hit account rate limit (429) -- transient, expected to clear by the next scheduled beat"
      connector_post "⏳ **$TODAY**: hit the account's rate limit mid-run (transient, not a bug). No action needed unless this repeats on the next scheduled beat too."
    fi
  else
    reason="$(tail -c 300 "$maker_json" | tr '\n' ' ' | tr '"' "'")"
    spine_write "FAIL" "${maker_cost:-0.0000}" "none" "implementer crashed (exit $maker_ok): $reason"
    connector_post "🛑 **$TODAY**: the implementer step crashed (exit $maker_ok) — needs a human. See $HERE/.maker-$TODAY.json"
  fi
  git worktree remove "$WT" --force >/dev/null 2>&1 || true
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  exit 1
fi

diff_stat="$(git -C "$WT" diff main --stat)"
findings="$(cat "$WT/FINDINGS.md" 2>/dev/null | tr '\n' ' ' | tr '"' "'" | cut -c1-300)"

if [[ -z "$diff_stat" ]]; then
  # clean day: nothing to review, nothing to ship -- still a real, logged outcome
  spine_write "OK" "$maker_cost" "none" "clean day: ${findings:-no drift found}"
  connector_post "✅ **$TODAY**: docs-freshness check ran, found nothing to fix. Cost: \$$maker_cost."
  git worktree remove "$WT" --force >/dev/null 2>&1 || true
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  exit 0
fi

# ---- review phase: a verdict, independent of the maker's own claim ----
review_json="$HERE/.review-$TODAY.json"
(cd "$WT/docs-freshness" && claude -p "Grade this worktree's docs-freshness fix. The repo root is one level up (..)." \
  --agent docs-freshness-reviewer --allowedTools "Read,Grep,Glob,Bash" \
  --max-budget-usd "$REVIEWER_BUDGET_USD" --output-format json) >"$review_json" 2>&1
review_ok=$?

review_cost="$(python3 -c "import json,sys
try:
    print(f\"{json.load(open('$review_json')).get('total_cost_usd',0):.4f}\")
except Exception:
    print('0.0000')" 2>/dev/null)"
review_text="$(python3 -c "import json
try:
    print(json.load(open('$review_json')).get('result',''))
except Exception:
    print('')" 2>/dev/null)"
total_cost="$(awk -v a="$maker_cost" -v b="${review_cost:-0}" 'BEGIN{printf "%.4f", a+b}')"

if [[ $review_ok -ne 0 ]]; then
  spine_write "FAIL" "$total_cost" "none" "reviewer crashed (exit $review_ok)"
  connector_post "🛑 **$TODAY**: the reviewer step crashed — needs a human. Maker's diff was left unshipped."
  git worktree remove "$WT" --force >/dev/null 2>&1 || true
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  exit 1
fi

verdict="$(printf '%s' "$review_text" | grep -Eo 'VERDICT: (PASS|FAIL)' | tail -1 | awk '{print $2}')"

if [[ "$verdict" != "PASS" ]]; then
  reason="$(printf '%s' "$review_text" | tr '\n' ' ' | tr '"' "'" | cut -c1-400)"
  spine_write "REJECTED" "$total_cost" "none" "reviewer FAIL: $reason"
  connector_post "⚠️ **$TODAY**: found something worth fixing, but the reviewer rejected the fix: $reason"
  git worktree remove "$WT" --force >/dev/null 2>&1 || true
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  exit 0
fi

# ---- connector: ship, but never stack a second PR on an unreviewed first one ----
existing_pr="$(gh pr list --state open --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("docs-freshness/")) | .number' 2>/dev/null | head -1)"

if [[ -n "$existing_pr" ]]; then
  spine_write "OK" "$total_cost" "held" "fix verified, but PR #$existing_pr is still open from an earlier run -- not stacking another"
  connector_post "✅ **$TODAY**: found and verified another fix, but PR #$existing_pr from an earlier run is still open — holding this one rather than stacking. Findings: $findings"
  git worktree remove "$WT" --force >/dev/null 2>&1 || true
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  exit 0
fi

(cd "$WT" && git add -A && git commit -q -m "docs-freshness: $TODAY

$findings" && git push -q -u origin "$BRANCH")
pr_url="$(cd "$WT" && gh pr create --title "docs-freshness: $TODAY" --body "$findings

---
Drafted by the docs-freshness implementer, verified independently by the docs-freshness-reviewer agent. Verdict: PASS. Cost: \$$total_cost." 2>/dev/null)"
pr_num="$(basename "$pr_url" 2>/dev/null)"

spine_write "OK" "$total_cost" "#${pr_num:-?}" "$findings"
connector_post "✅ **$TODAY**: opened $pr_url — $findings"

git worktree remove "$WT" --force >/dev/null 2>&1 || true
