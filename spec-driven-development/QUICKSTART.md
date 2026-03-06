# Quick Start: spec-driven-development

## When to Use

Building features systematically with specifications.

## Two Paths

### New Project
```bash
bash scripts/init_sdd.sh my-project
# Create mission.md, roadmap.md, tech-stack.md
# Then shape first feature
```

### Existing App (Adding Features)
```bash
bash scripts/init_sdd.sh          # Only if no sdd/ folder
bash scripts/new_spec.sh feature-name
# Skip product planning, go straight to Shape
```

## Feature Workflow

```
Shape → Spec → Verify → Tasks → Implement → Verify
```

| Phase | Output | Time |
|-------|--------|------|
| Shape | `planning/requirements.md` | 15-30 min |
| Spec | `spec.md` | 30-60 min |
| Verify | `verification/spec-verification.md` | 10 min |
| Tasks | `tasks.md` | 20-30 min |
| Implement | Working code | Varies |
| Verify | `verification/final-verification.md` | 15 min |

## Directory Structure

```
sdd/
├── progress.yml           # Track current state
├── product/               # Mission, roadmap (new projects)
├── standards/             # Coding standards (optional)
└── specs/
    └── 2024-12-28-user-auth/
        ├── planning/
        │   ├── requirements.md
        │   └── visuals/     # Mockups go here
        ├── spec.md
        ├── tasks.md
        └── verification/
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `bash scripts/init_sdd.sh` | Initialize project |
| `bash scripts/new_spec.sh name` | Create new spec folder |
| `bash scripts/status.sh` | Show progress |
| `bash scripts/export.sh` | Zip all documents |

## Shape Phase Questions

Ask about:
1. Core functionality needed
2. User interactions
3. Data to store
4. Similar existing code to reuse
5. Edge cases to handle

## Spec Structure

```markdown
# Spec: Feature Name

## Goal
[One sentence]

## User Stories
- As a [user], I want [action] so that [benefit]

## Requirements
### Functional
### Non-functional

## Visual Design
[Reference mockups in planning/visuals/]

## Existing Code
[What to reuse from codebase]

## Out of Scope
[What we're NOT building]
```

## Tasks Structure

```markdown
### Task Group 1: Database Layer
- [ ] 1.1 Write 2-8 tests
- [ ] 1.2 Create migration
- [ ] 1.3 Create model
- [ ] 1.4 Run tests

### Task Group 2: API Layer
...

### Task Group 3: Frontend
...

### Task Group 4: Test Review
```

## Tips

1. **Always check `progress.yml`** before starting
2. **Visuals are mandatory** — create mockups if none provided
3. **Search for reuse** before specifying new code
4. **2-8 tests per group** — don't over-test
5. **Use concrete folder names** — never `{{...}}`

## Related Skills

- `frontend-design` — Create mockups during Shape
- `maquina-ui-standards` — Implement UI tasks
