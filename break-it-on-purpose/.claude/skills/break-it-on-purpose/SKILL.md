# Break It on Purpose Skill

The observability drill: sabotage your own loop, then diagnose it from the spine alone.

## Purpose

This skill teaches you to read spines, understand failure patterns, and build
loops that fail loudly instead of silently.

## Steps

1. **Choose a loop to break**
   - Pick any project that has run at least once
   - Make sure it has a progress.md spine

2. **Plant a break**
   - Option A: Corrupt the spine (add false entries)
   - Option B: Disable a checker (comment out a test)
   - Option C: Introduce a cost spike (run an expensive command)
   - Option D: Make it fail silently (return wrong output without error)

3. **Wait for the next run**
   - Let the loop fire with the break in place
   - Don't干预 — let it run naturally

4. **Diagnose from the spine**
   - Read progress.md only (no code, no logs)
   - Answer these questions:
     - What failed?
     - When did it start?
     - How many runs were affected?
     - What would you change to catch this earlier?

5. **Document your findings**
   - Write what you learned
   - Identify what the spine did and didn't tell you
   - Propose improvements to observability

## What makes a good diagnosis

- You can tell the exact run that failed
- You can tell what changed from the previous run
- You can tell the impact (how many runs affected)
- You can propose a specific fix

## Rules

- **Don't break production loops** — use a test or throwaway loop
- **Document the break** — so you can undo it later
- **Time-box the drill** — 30 minutes max, then fix it
- **Learn from it** — the goal is observability, not destruction
