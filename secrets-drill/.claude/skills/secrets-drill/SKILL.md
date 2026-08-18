# Secrets Drill Skill

The secrets drill: fail the `.env` way once, so you never do it by accident.

## Purpose

This skill teaches you how cloud Routines handle secrets. A Routine runs on
Anthropic's servers, not your machine. Your `.env` file doesn't exist there.

## Steps

1. **Create a test Routine**
   - Write a prompt that expects an API key
   - Intentionally reference `.env` in the prompt
   - Schedule it or fire a one-off

2. **Watch it fail**
   - The Routine will either:
     - Error: "No such file: .env"
     - Use wrong defaults
     - Skip the secret entirely
   - This is expected — you're proving the failure

3. **Fix with environment variables**
   - Go to claude.ai/code/routines
   - Open your Routine's settings
   - Find the environment-variables panel
   - Add your secret:
     - Key: `API_KEY`
     - Value: `your-actual-key`

4. **Update the prompt**
   - Remove any reference to `.env`
   - Add this line:
     ```
     Credentials are available as environment variables; do not look for a `.env` file.
     ```
   - Reference the env var: `$API_KEY`

5. **Verify it works**
   - Fire a one-off
   - Check the transcript
   - The Routine should now find and use the secret

## What to look for

- **The error**: `.env` not found (proves the failure)
- **The fix**: env var in settings (proves the solution)
- **The prompt change**: explicit mention of env vars (proves the pattern)

## Rules

- **Fail on purpose first** — so you understand the failure
- **Never put secrets in prompts** — they're visible in transcripts
- **Always say env vars exist** — so the Routine doesn't look for files
- **Test after fixing** — prove the solution works

## Common patterns

**Wrong (assumes local file):**
```
Read the API key from .env
```

**Right (uses env var):**
```
Credentials are available as environment variables; do not look for a `.env` file.
Use $API_KEY for authentication.
```
