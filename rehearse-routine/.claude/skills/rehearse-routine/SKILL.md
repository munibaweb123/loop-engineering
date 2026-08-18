# Rehearse a Routine Skill

The free rehearsal: test a prompt with one-offs before scheduling it.

## Purpose

This skill teaches you to iterate on a Routine prompt without spending daily
run limits. One-offs are free — use them to prove your prompt works.

## Steps

1. **Write your prompt**
   - Be specific about what you want
   - Include the skill or action to run
   - Specify the output format

2. **Fire a one-off**
   ```
   /schedule in 2 minutes, [your prompt here]
   ```

3. **Wait for it to run**
   - Don't干预 — let it complete
   - Check the run status at claude.ai/code/routines

4. **Read the transcript**
   - Click the run in the Routines list
   - Read what it actually did
   - Check for errors or unexpected behavior

5. **Iterate**
   - If the output is wrong, fix the prompt
   - Fire another one-off
   - Repeat until it's right

6. **Schedule for real**
   - Only when you trust the prompt
   ```
   /schedule every day at 9am, [your refined prompt]
   ```

## What to look for in transcripts

- **Tool usage**: Did it use the right tools?
- **Output format**: Did it produce what you expected?
- **Errors**: Did any commands fail?
- **Scope creep**: Did it do things you didn't ask for?

## Rules

- **One-offs are free** — use them generously
- **Read every transcript** — don't assume it worked
- **Iterate quickly** — fix, fire, check, repeat
- **Schedule only when trusted** — never schedule an untested prompt

## Common mistakes

- **Scheduling without testing** — the 3am surprise
- **Not reading transcripts** — assuming it worked
- **Overly complex prompts** — start simple, iterate
- **Forgetting connectors** — a Routine can only use tools it has access to
