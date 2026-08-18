# Dreaming Loop — the improvement loop

**Loop Engineering, Project 12 — Concept 12 (spine), Concept 11 (maker-checker), Concept 6 (schedule), Part 5 (human gate).**

A weekly loop that reads your other loops' logs, finds repeated failures,
and proposes the smallest rules-file change that would prevent them — as a PR,
never a direct commit.

## The three things that must be true

1. **The PR's proposed change traces to real, cited log entries.** Not a
   plausible-sounding guess — actual runs, actual frequency, actual evidence.
2. **A deliberately planted repeated failure gets caught and turned into a proposal.**
   If the loop can't catch a failure you put there on purpose, it can't catch
   real ones either.
3. **Nothing changed in your rules file without you merging it.** The loop proposes.
   You decide. That's the human gate.

## What's here

| Path | What it is |
| --- | --- |
| `dream.sh` | The dreaming loop — reads logs, drafts PR, proposes changes |
| `dreaming-state.md` | The spine — tracks what's been analyzed, prevents re-analysis |
| `rules.md` | The rules file — target for proposed changes |
| `REPOS.md` | List of repos/projects to watch |
| `.claude/skills/dreaming-loop/SKILL.md` | The dreamer's playbook |
| `.claude/agents/dreaming-reviewer/agent.md` | Reviewer that grades the proposal |
| `progress.md` | This loop's own log |

## How it works

```
Weekly schedule (cron/Routine)
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Read dreaming-state.md           │
│    (last analysis date)             │
├─────────────────────────────────────┤
│ 2. For each repo in REPOS.md:       │
│    - Read progress.md entries       │
│      since last analysis date       │
│    - Find failures/corrections      │
│      that appear more than once     │
├─────────────────────────────────────┤
│ 3. Draft smallest rules.md change   │
│    that prevents the pattern        │
├─────────────────────────────────────┤
│ 4. Create PR on claude/ branch      │
│    - Cite evidence: runs, frequency │
│    - Propose one deletion           │
├─────────────────────────────────────┤
│ 5. Update dreaming-state.md         │
└─────────────────────────────────────┘
         │
         ▼
    Human gate (you)
         │
         ▼
    Merge or discard
```

## Build it — step by step

### 1. Create the repos list

Edit `REPOS.md` to list the projects you want the dreaming loop to watch:

```markdown
# Repos to Watch

- ./docs-freshness/progress.md
- ./two-routine-gate/progress.md
- ./paper-watch/progress.md
```

### 2. Create the initial rules file

The dreaming loop proposes changes to `rules.md`. Start with a simple one:

```markdown
# Rules

## Code Quality
- Never edit CLAUDE.md or AGENTS.md directly
- Always use claude/ branch prefix
- Never push to main without human approval

## Verification
- Always run tests before claiming success
- Always verify claims against actual state
```

### 3. Plant a repeated failure

To prove the loop works, add a repeated failure to one of the progress files:

```bash
echo "- 2026-08-18 status=FAIL reason='forgot to run tests before claiming success'" >> docs-freshness/progress.md
echo "- 2026-08-19 status=FAIL reason='forgot to run tests before claiming success'" >> docs-freshness/progress.md
echo "- 2026-08-20 status=FAIL reason='forgot to run tests before claiming success'" >> docs-freshness/progress.md
```

### 4. Run the dreamer

```bash
cd dreaming-loop
bash dream.sh
```

This will:
1. Read `dreaming-state.md` for last analysis date
2. Scan all progress files for repeated failures
3. Draft a rules.md change
4. Create a PR with evidence
5. Update `dreaming-state.md`

### 5. Review the PR

The loop created a PR on a `claude/` branch. Review it:

```bash
gh pr list --state open
gh pr view <PR-number>
```

Check:
- Does the proposed change trace to real log entries?
- Is the evidence cited (which runs, how often)?
- Is the change the smallest possible fix?

### 6. Merge or discard

If the proposal is good, merge it. If not, close the PR and tighten the prompt.

## A6 checklist

| Item | Status |
|------|--------|
| **Success condition** | PR cites real log entries with evidence |
| **Limit** | Weekly schedule, one PR at a time |
| **Isolated branch** | Uses `claude/` prefix |
| **Read-only checker** | Human reviews PR |
| **State file** | `dreaming-state.md` tracks analysis |
| **Human gate** | You merge or discard the PR |
| **Log** | `progress.md` tracks dream runs |

## The two rules

**Never propose changes without evidence.** An improvement loop that guesses
is worse than no improvement loop, because its guesses steer every future run.
If the evidence isn't there, don't propose the change.

**Never commit directly to rules.md.** Always a PR, always a branch, always
human review. The loop proposes. You decide.

## Why this matters

This is the capstone. Every concept comes together:
- **Spine** (`dreaming-state.md`) — remembers what's been analyzed
- **Maker-checker** — dreamer drafts, reviewer grades, you decide
- **Schedule** — runs weekly, unattended
- **Human gate** — you merge the PR

The dreaming loop is the loop that improves your other loops. It's the
meta-loop. And it needs the human gate more than any other, because a bad
improvement cascades into every future run.
