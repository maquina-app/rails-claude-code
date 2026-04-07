Show the current Spec-Driven Development status for this Rails project.

Read `sdd/progress.yml` and display a summary:

```
Project: [name]
Updated: [date]

Product Planning: [status]

Current Spec: [name]
  Status: [shaping | tasks | implementing | complete]

Completed Specs:
  - [spec-name]
  - [spec-name]
```

Then check the current spec folder (if any) and report:
- Which files exist (spec.md, references.md, standards.md, tasks.md)
- How many tasks are checked off vs total in tasks.md
- Which task group is currently in progress

Suggest the logical next command based on current state.
