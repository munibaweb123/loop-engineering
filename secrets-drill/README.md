# The Secrets Drill

**Loop Engineering, Project 10 — A4 (secrets), A2 (the environment).**

Fail the `.env` way once, on purpose, so you never do it by accident.
Cloud Routines don't see your `.env` file — secrets must go in environment variables.

## What you learn

- Why `.env` files don't work in cloud Routines
- How to set secrets in the environment-variables panel
- How to tell your prompt to look for env vars, not `.env`

## The drill

1. **Create a Routine that reads `.env`**
   - Write a prompt that expects an API key from `.env`
   - Set it up with a schedule

2. **Watch it fail**
   - The Routine runs in a fresh clone
   - No `.env` file exists there
   - It either errors or uses wrong defaults

3. **Fix it with environment variables**
   - Go to the Routine's settings
   - Add the secret to the environment-variables panel
   - Update the prompt to say: "credentials are available as environment variables; do not look for a `.env` file"

4. **Verify it works**
   - Fire a one-off
   - Check the transcript — it should find the secret

## The key insight

A cloud Routine runs on Anthropic's servers, not your machine. Your `.env` file
lives on your machine. The Routine never sees it. Secrets must be set in the
Routine's environment-variables panel, and the prompt must say so explicitly.

## What you check

- [ ] Did the Routine fail when reading `.env`?
- [ ] Did you add the secret to the environment-variables panel?
- [ ] Did you update the prompt to mention env vars?
- [ ] Does the Routine now find the secret?

## Example

**Before (broken):**
```markdown
Read the API key from .env and use it to call the service.
```

**After (working):**
```markdown
Credentials are available as environment variables; do not look for a `.env` file.
Read the API key from $API_KEY and use it to call the service.
```

## Why this matters

Every cloud Routine starts from a fresh clone. No cookies, no `.env`, no local
state. If your prompt assumes local files exist, it will fail. The secrets drill
teaches you to think in terms of what the Routine can actually see.

## Files

| Path | What it is |
| --- | --- |
| `.claude/skills/secrets-drill/SKILL.md` | The drill's playbook |
| `README.md` | This file |
