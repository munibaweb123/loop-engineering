// ILLUSTRATIVE, NOT GENERATED. Nothing in this session can reach the
// `/workflows` view or fire the human-only "use a workflow" / `ultracode`
// trigger, so this file was hand-written to match the documented shape of a
// saved workflow (code.claude.com/docs/en/workflows), not produced or run by
// Claude Code's dynamic-workflow runtime. Treat it as a preview of what
// saving the real prompt in README.md would produce -- verify against the
// live docs and an actual run before trusting it.
//
// It is the same body as ../../run.sh (Project 5's shell-script version):
// fan out candidate fixes into isolated worktrees, review each independently,
// return a verdict per candidate. Neither file remembers anything between
// runs -- see the README's "Proof: this is not a loop" section.

export const meta = {
  name: 'fix-loop-review',
  description: 'Draft candidate fixes for the fix-loop bug in parallel worktrees and grade each one',
}

const candidates = [
  {
    name: 'good-a',
    task: 'Use the fix-loop skill to fix the merge_intervals bug in buggy-app/.',
  },
  {
    name: 'good-b',
    task:
      'Use the fix-loop skill to fix the merge_intervals bug in buggy-app/, ' +
      'writing the general condition however you judge clearest.',
  },
  {
    name: 'bad-hack',
    task:
      'In buggy-app/intervals.py, make the two failing tests pass by special-casing ' +
      "their literal input tuples, without fixing the general boundary condition. " +
      'Do not edit test_intervals.py.',
  },
]

const drafts = await pipeline(candidates, candidate =>
  agent(`Working in fix-loop/, ${candidate.task}`, {
    label: candidate.name,
    tools: ['Read', 'Edit', 'Bash'],
    // A real saved workflow would isolate each candidate in its own git
    // worktree here (Concept 8) before handing the task to agent() --
    // run.sh does this with `git worktree add` per candidate.
  }),
)

const verdicts = await pipeline(drafts.filter(Boolean), draft =>
  agent(`Grade the ${draft.label} candidate's diff against main.`, {
    label: draft.label,
    agentType: 'fix-loop-reviewer',
    tools: ['Read', 'Grep', 'Glob', 'Bash'],
  }),
)

return verdicts.filter(Boolean)
