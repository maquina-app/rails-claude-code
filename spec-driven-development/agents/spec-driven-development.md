---
name: spec-driven-development
description: A Rails-focused spec-driven development workflow for building features with AI agents. Use this skill when users want to plan features, write specs, create task breakdowns, or generate implementation prompts for Rails apps. Triggers on "sdd", "spec-driven", "shape spec", "create tasks", "initialize SDD", "feature planning", "implementation prompts", or any request to systematically plan and implement a Rails feature. Also triggers when moving from MVP documentation to implementation planning.
---

# Spec-Driven Development

A lightweight workflow for building production-quality Rails features with AI agents through systematic planning and self-contained specs.

Each spec is designed to be **picked up and executed independently** by Claude Code or a subagent — no extra context needed beyond the spec folder itself.

## Quick Start

**New Rails Project (from MVP docs):**
1. `bash scripts/init_sdd.sh` — creates `sdd/` with pre-built Rails standards + index
2. Convert MVP docs → product planning files
3. For each feature: Shape → Tasks → Hand off to Claude Code

**Adding Features to Existing App:**
1. `bash scripts/init_sdd.sh` (if no `sdd/` yet)
2. Discover additional standards from the codebase
3. Shape the spec → Tasks → Hand off to Claude Code

---

## Directory Structure

```
sdd/
├── product/
│   ├── mission.md            # Product vision, users, problems
│   ├── roadmap.md            # Feature priorities with effort estimates
│   └── tech-stack.md         # Technology decisions and deviations
├── standards/
│   ├── index.yml             # ← Catalog of all standards (auto-maintained)
│   ├── global/
│   │   └── rails-stack.md
│   ├── backend/
│   │   └── rails-patterns.md
│   ├── frontend/
│   │   ├── hotwire.md
│   │   └── components.md
│   └── testing/
│       └── minitest.md
└── specs/
    └── YYYY-MM-DD-feature-name/
        ├── spec.md           # Requirements, user stories, scope
        ├── references.md     # Existing code to reuse/follow
        ├── standards.md      # Standards that apply to THIS feature (injected from index)
        └── tasks.md          # Task groups with self-contained Claude Code prompts
```

---

## Standards System

Standards are short `.md` files. Every word costs tokens — keep them **concise and scannable**.

### index.yml — The Standards Catalog

`sdd/standards/index.yml` is the master catalog. Always read it before shaping a spec to know what's available. Always update it when adding new standards.

```yaml
# sdd/standards/index.yml
global:
  rails-stack:
    description: "Rails 8 stack: Hotwire, Tailwind 4, maquina_components, Solid trifecta, Kamal"
    applies_to: all

backend:
  rails-patterns:
    description: "Rich models, CRUD resources, no service objects, money as cents, state as records"
    applies_to: [models, controllers, routes]

frontend:
  hotwire:
    description: "Turbo Drive/Frames/Streams, morph pattern, Stimulus teardown, common pitfalls"
    applies_to: [views, javascript, turbo, stimulus]
  components:
    description: "maquina_components usage, Tailwind CSS 4 @theme config"
    applies_to: [views, partials, forms]

testing:
  minitest:
    description: "No mocks/stubs, test outcomes, happy path, WebMock for APIs, fixtures"
    applies_to: all
```

### Rails Standards (Auto-Bootstrapped on Init)

`bash scripts/init_sdd.sh` writes all standards files and `index.yml` automatically.

Read [references/rails-standards.md](references/rails-standards.md) for the full content of each file.

| File | Summary |
|------|---------|
| `standards/global/rails-stack.md` | Rails 8, Hotwire, Tailwind 4, maquina_components, SQLite/Postgres, Solid trifecta, Kamal |
| `standards/backend/rails-patterns.md` | Rich models, CRUD resources, no service objects, money as cents, state as records |
| `standards/frontend/hotwire.md` | Turbo Drive/Frames/Streams, morph, Stimulus patterns and teardown |
| `standards/frontend/components.md` | maquina_components, Tailwind 4 CSS-first config |
| `standards/testing/minitest.md` | No mocks/stubs, test outcomes, happy path, WebMock |

### Discovering Additional Standards (Existing Apps)

When adding SDD to an existing app, analyze the codebase for tribal knowledge to supplement the bootstrapped standards:

1. Read 5–10 representative files per area (models, controllers, views, tests)
2. Look for patterns that are **opinionated, tribal, or non-obvious** — not standard Rails behavior
3. For each pattern: ask the user *why* it exists, then draft a concise standard
4. Write to `standards/[area]/[name].md` and add an entry to `index.yml`

**Only document what a new developer wouldn't know without being told.** Rails defaults don't need documenting.

---

## Phase 1: Product Planning (Once per project)

> Skip for existing apps — go to Phase 2.

### From MVP Creator Docs

If MVP docs exist (`docs/MVP_BUSINESS_PLAN.md`, `docs/TECHNICAL_GUIDE.md`):

1. Extract `sdd/product/mission.md` — vision, personas, problems
2. Extract `sdd/product/roadmap.md` — feature list, effort estimates (XS/S/M/L/XL)
3. Extract `sdd/product/tech-stack.md` — stack decisions + any deviations from default

### From Scratch

Ask one at a time:
1. What problem does this solve?
2. Who is the primary user? Geographic/language focus?
3. What are the must-have features for launch?
4. Any deviations from the standard Rails stack?

→ See [references/document-templates.md](references/document-templates.md) for file templates.

---

## Phase 2: Shape Spec (Per feature)

**This is the most important phase.** Shape well and the Claude Code handoff is seamless.

### Step 1: Create spec folder

```
sdd/specs/YYYY-MM-DD-feature-name/
```

### Step 2: Ask focused questions (4–6 max)

- What is the user trying to accomplish? What's the happy path?
- Any edge cases needed in v1?
- What does success look like? (redirect, message, UI change?)
- Any existing models/controllers/views to reuse?

### Step 3: Search the codebase for reference code

**Always search before speccing new code:**

```bash
grep -r "class.*ApplicationRecord" app/models/ | grep -i [domain]
ls app/controllers/ | grep -i [domain]
find app/views -name "*[domain]*"
```

Write findings to `specs/[name]/references.md`:

```markdown
# References: [Feature Name]

## Existing Models
- `app/models/appointment.rb` — has status pattern to follow

## Existing Controllers
- `app/controllers/appointments_controller.rb` — follow this CRUD structure

## Reusable Partials
- `app/views/shared/_status_badge.html.erb` — reuse for status display
```

### Step 4: Check for visuals

Ask if mockups exist. If none and the feature has meaningful UI:
- Use the `frontend-design` skill to create an HTML mockup
- Or describe the expected layout in spec.md

### Step 5: Inject relevant standards

Read `sdd/standards/index.yml`. Based on what the feature touches, select the applicable standards.

Present selection to the user:
```
Based on this feature, these standards apply:
- global/rails-stack (always)
- backend/rails-patterns (models + controller)
- frontend/hotwire (Turbo + Stimulus)
- frontend/components (maquina_components views)
- testing/minitest (always)

Any additions or removals?
```

Write `specs/[name]/standards.md` by copying the **full file content** of each confirmed standard. This makes the spec folder **self-contained** — a Claude Code agent or subagent can implement with zero dependencies outside this folder.

### Step 6: Write spec.md

→ See [references/document-templates.md](references/document-templates.md) for template.

Structure:
- **Goal** — one sentence
- **User Stories** — As a [user], I want [action] so that [outcome]
- **Requirements** — functional only, no implementation details
- **Visual Design** — mockup link or layout description
- **Out of Scope** — explicitly what's NOT in v1

---

## Phase 3: Create Tasks (Per feature)

Break the spec into task groups: **Database → Backend → Frontend → Testing**

Each group is **self-contained** and designed to be executed by Claude Code or a subagent independently.

### Task Group Structure

Each group:
- Lists specific, actionable tasks
- Writes tests first (2–5 tests per group)
- Ends with a verify command

### Standard Rails Task Groups

```markdown
## Group 1: Database
- [ ] Migration: `bin/rails g migration [name]`
- [ ] Model validations and associations
- [ ] Fixtures: `test/fixtures/[model].yml`

Tests: `bin/rails test test/models/[model]_test.rb`

## Group 2: Backend
- [ ] Routes (CRUD + sub-resources only)
- [ ] Controller with CRUD actions
- [ ] Model business logic methods/scopes
- [ ] Authorization if needed

Tests: `bin/rails test test/controllers/[name]_test.rb`

## Group 3: Frontend
- [ ] Views/partials using maquina_components
- [ ] Turbo/Hotwire behavior
- [ ] Stimulus controller if needed
- [ ] i18n translations (es/en)

Tests: `bin/rails test test/system/[name]_test.rb`

## Group 4: Integration
- [ ] End-to-end happy path test
- [ ] Critical edge case if any

Tests: `bin/rails test`
```

**Test count:** 2–5 per group, 10–20 total per feature. Never more than 8 per group.

### Self-Contained Claude Code Prompts

For each task group, generate a prompt in `tasks.md` that a Claude Code agent can execute with **zero additional context** — everything it needs is embedded:

1. The task checklist
2. Full content of `standards.md` (already scoped to this feature)
3. File paths from `references.md`
4. Test verify command

This design means you can hand off each group to Claude Code independently, or run all groups sequentially in a single Claude Code session.

→ See [references/document-templates.md](references/document-templates.md) for the self-contained prompt format.

---

## Phase 4: Implement with Claude Code

### Hand-off pattern

The spec folder is the complete hand-off package:

```
sdd/specs/2025-03-06-appointment-booking/
├── spec.md         → What to build
├── references.md   → What code to follow
├── standards.md    → How to build it (Rails patterns, testing rules, Hotwire)
└── tasks.md        → Step-by-step with self-contained prompts
```

**Option A — Full session:** Feed Claude Code the spec folder, then work through task groups sequentially in one session.

**Option B — Group by group:** Copy each group's self-contained prompt into a fresh Claude Code session. Good for complex features or parallel work.

### Required skills during implementation

| When | Use skill |
|------|-----------|
| Before writing any Stimulus controller | `better-stimulus` — targets, values, connect/disconnect, teardown |
| For all view/component work | `maquina-ui-standards` — correct maquina_components usage |
| After implementing any model or controller | `rails-simplifier` — review for Rails idioms, CRUD patterns, rich model |
| Any Turbo/Hotwire behavior | Read [references/hotwire-patterns.md](references/hotwire-patterns.md) first |

### Implementation cycle (per group)

1. Run tests → fail (expected)
2. Implement
3. Run tests → pass
4. Run `rails-simplifier` on anything that feels complex
5. Mark tasks `[x]` → next group

---

## Testing Standards (Non-Negotiable)

These are also in `standards/testing/minitest.md` — repeated here because they're critical.

- **No mocks or stubs** — test real objects against the real database
- **Test outcomes, not implementation** — assert what changed, not how
- **Happy path focus** — full coverage of the main flow; edge cases only for critical validations
- **WebMock for external HTTP** — stub all outbound calls; never hit real APIs
- **Fixtures over factories** — Rails fixtures only
- **Simple tests** — one clear assertion per test

```ruby
# ✅ Tests outcome
test "appointment confirmed after payment" do
  appointment = appointments(:pending)
  appointment.confirm_payment!
  assert appointment.confirmed?
  assert_equal 1, appointment.payments.count
end

# ❌ Tests implementation
test "appointment calls PaymentService" do
  mock = Minitest::Mock.new
  mock.expect(:process, true)
  PaymentService.stub(:new, mock) { appointment.confirm_payment! }
  mock.verify
end
```

---

## Progress Tracking

```yaml
# sdd/progress.yml
project: [name]
updated: [ISO-8601]

product_planning:
  status: not_started  # not_started | in_progress | complete

current_spec:
  name: null
  status: null  # shaping | tasks | implementing | complete

completed_specs: []
```

---

## Commands

These slash commands are available in Claude Code after running `bash scripts/init_sdd.sh`, which writes `.claude/commands/sdd-*.md` into the project root.

| Command | Action |
|---------|--------|
| `/sdd-init` | Initialize sdd/ with Rails standards + index.yml + all commands |
| `/sdd-plan` | Create/update product planning docs |
| `/sdd-shape` | Shape spec: questions → codebase search → inject standards → write spec.md + references.md + standards.md |
| `/sdd-tasks` | Create task groups with self-contained Claude Code prompts |
| `/sdd-status` | Show progress.yml summary and next suggested action |
| `/sdd-discover-standards` | Extract tribal knowledge from existing codebase into new standards |

---

## Related Skills

| Skill | When |
|-------|------|
| `mvp-creator` | Before SDD — product vision, brand guide, technical architecture |
| `frontend-design` | During shaping — UI mockups when none exist |
| `rails-simplifier` | After implementing models/controllers — Rails idiom review |
| `better-stimulus` | Before any Stimulus controller |
| `maquina-ui-standards` | All UI work with maquina_components |
