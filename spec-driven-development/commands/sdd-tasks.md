Create the task breakdown for the current feature spec using the spec-driven-development skill.

## Setup
Read:
- `sdd/progress.yml` to find the current spec folder
- `sdd/specs/[folder]/spec.md` for requirements
- `sdd/specs/[folder]/references.md` for existing code to follow
- `sdd/specs/[folder]/standards.md` for applicable standards

## Task Groups

Break the spec into 4 groups following this order: Database → Backend → Frontend → Integration

Each group must have:
- A clear goal statement
- Specific, actionable tasks with checkboxes
- 2–5 tests to write first (before implementing)
- A verify command: `source ~/.zshrc && bin/rails test [path]`

## Self-Contained Claude Code Prompts

After the task checklist for each group, write a `## PROMPT — Group N` section that a Claude Code agent can execute independently with zero additional context. Each prompt must embed:
1. The task checklist for that group
2. The full content of `standards.md` (copy it inline — not a reference)
3. The relevant sections from `references.md`
4. The "done when" verify command

This design means each group's prompt can be handed off to a separate Claude Code session or subagent.

## Test counts
- 2–5 tests per group, 10–20 total
- Never more than 8 per group — if needed, split the feature

Write everything to `sdd/specs/[folder]/tasks.md`.
Update `sdd/progress.yml` when complete.
