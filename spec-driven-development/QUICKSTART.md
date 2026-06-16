# Quick Start: spec-driven-development

## When to Use

Building Rails features systematically with self-contained specs that Claude Code can pick up and execute independently.

## Two Paths

### New Project (from MVP docs or scratch)
```bash
bash scripts/init_sdd.sh my-project   # bootstraps sdd/ + Rails standards + index.yml
# /sdd-plan  — create mission.md, roadmap.md, tech-stack.md
# /sdd-shape — shape the first feature
```

### Existing App (Adding Features)
```bash
bash scripts/init_sdd.sh              # only if no sdd/ folder yet
bash scripts/new_spec.sh feature-name # create a dated spec folder
# Skip product planning — go straight to /sdd-shape
```

## Feature Workflow

```
Shape → Tasks → Hand off to Claude Code
```

| Phase | Command | Output |
|-------|---------|--------|
| Product Planning (once) | `/sdd-plan` | `product/mission.md`, `roadmap.md`, `tech-stack.md` |
| Shape Spec | `/sdd-shape` | `spec.md`, `references.md`, `standards.md` |
| Create Tasks | `/sdd-tasks` | `tasks.md` (self-contained Claude Code prompts) |
| Implement | hand off to Claude Code | Working code |

## Directory Structure

```
sdd/
├── progress.yml              # Track current state
├── product/                  # mission, roadmap, tech-stack (new projects)
├── standards/
│   ├── index.yml             # Catalog of all standards
│   ├── global/  backend/  frontend/  testing/
└── specs/
    └── 2024-12-28-user-auth/
        ├── spec.md           # Requirements, user stories, scope
        ├── references.md     # Existing code to reuse/follow
        ├── standards.md      # Standards injected for THIS feature
        └── tasks.md          # Task groups + self-contained prompts
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `/sdd-init` | Initialize sdd/ with Rails standards + index.yml + progress tracker |
| `/sdd-plan` | Create product mission, roadmap, tech stack |
| `/sdd-shape` | Gather requirements → search codebase → inject standards → write spec |
| `/sdd-tasks` | Create task breakdown with self-contained Claude Code prompts |
| `/sdd-status` | Show progress and next suggested action |
| `/sdd-discover-standards` | Extract tribal knowledge from an existing codebase into standards |

Helper scripts (used by the commands, runnable directly):

| Script | Purpose |
|--------|---------|
| `bash scripts/init_sdd.sh` | Initialize project |
| `bash scripts/new_spec.sh name` | Create a new dated spec folder |
| `bash scripts/status.sh` | Show progress |

## Shape Phase Questions

Ask about:
1. Core functionality needed (the happy path)
2. User interactions and what success looks like
3. Data to store
4. Similar existing code to reuse
5. Edge cases needed in v1

## Spec Structure

```markdown
# Spec: Feature Name

## Goal
[One sentence]

## User Stories
- As a [user], I want [action] so that [benefit]

## Requirements
[Functional only — no implementation details]

## Visual Design
[Mockup link or layout description]

## Out of Scope
[What we're NOT building in v1]
```

## Tasks Structure

```markdown
## Group 1: Database
- [ ] Write 2–5 focused tests first
- [ ] Migration, model validations, fixtures

## Group 2: Backend
...

## Group 3: Frontend
...

## Group 4: Integration
...
```

## Tips

1. **Always check `progress.yml`** before starting
2. **Provide visuals** — add mockups, or use `frontend-design` to create one
3. **Search for reuse** before specifying new code
4. **2–5 tests per group** (10–20 total, never more than 8) — don't over-test
5. **Use concrete folder names** — never `{{...}}`

## Related Skills

- `frontend-design` — Create mockups during Shape
- `maquina-ui-standards` — Implement UI tasks
- `better-stimulus` — Before any Stimulus controller
- `rails-simplifier` — After implementing models/controllers
