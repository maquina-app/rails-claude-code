#!/bin/bash

# Spec-Driven Development — Rails Project Initialization
# Usage: bash scripts/init_sdd.sh [project-name]
# Creates sdd/ structure with pre-built Rails standards

set -e

GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME="${1:-$(basename $(pwd))}"
SDD_DIR="sdd"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${BLUE}Initializing SDD for: ${PROJECT_NAME}${NC}"
echo ""

# Create directory structure
mkdir -p "$SDD_DIR/product"
mkdir -p "$SDD_DIR/standards/global"
mkdir -p "$SDD_DIR/standards/backend"
mkdir -p "$SDD_DIR/standards/frontend"
mkdir -p "$SDD_DIR/standards/testing"
mkdir -p "$SDD_DIR/specs"

echo -e "${YELLOW}Creating progress tracker...${NC}"

cat > "$SDD_DIR/progress.yml" << EOF
project: $PROJECT_NAME
updated: $DATE

product_planning:
  status: not_started

current_spec:
  name: null
  status: null

completed_specs: []
EOF

echo "  ✓ progress.yml"

# ─── Bootstrap Rails Standards ───────────────────────────────────────────────

echo -e "${YELLOW}Writing Rails standards...${NC}"

# global/rails-stack.md
cat > "$SDD_DIR/standards/global/rails-stack.md" << 'EOF'
# Rails Stack

**Framework:** Rails 8.x — vanilla, no gems duplicating built-in behavior
**Frontend:** Hotwire (Turbo + Stimulus) — no React, Vue, or JS frameworks
**CSS:** Tailwind CSS 4 — CSS-first config via `@theme` in application.css
**Components:** maquina_components — ERB partials with Tailwind
**Database:** SQLite (development) → PostgreSQL (production)
**Background jobs:** Solid Queue — no Redis
**Caching:** Solid Cache — no Redis/Memcached
**WebSockets:** Solid Cable — no Redis
**Auth:** Rails 8 built-in generator — not Devise
**Testing:** Minitest + Fixtures — not RSpec, not FactoryBot
**Deployment:** Kamal 2 with Docker

Run bin/rails commands with: `source ~/.zshrc && bin/rails [command]`
EOF
echo "  ✓ standards/global/rails-stack.md"

# backend/rails-patterns.md
cat > "$SDD_DIR/standards/backend/rails-patterns.md" << 'EOF'
# Rails Patterns

## Rich Domain Models (No Service Objects)

Logic belongs in models via methods and concerns.

```ruby
# ✅ Good
appointment.confirm!
booking.transfer_to(provider)

# ❌ Bad
AppointmentConfirmationService.call(appointment)
```

## CRUD Resources Only

For state changes, create a sub-resource — never custom actions.

```ruby
# ✅ Good
resources :appointments do
  resource :confirmation, only: [:create, :destroy]
end

# ❌ Bad
resources :appointments do
  post :confirm
end
```

## State as String Column

```ruby
# ✅ Good — appointment.status: "pending" | "confirmed" | "cancelled"
appointment.confirmed?  # status == "confirmed"
# ❌ Bad — is_confirmed, is_cancelled booleans
```

## Money as Integer Cents

```ruby
price_cents: integer  # 1500 = $15.00
def price = price_cents / 100.0
```

## Thin Controllers

Find/build → call one model method → redirect or render.

```ruby
def create
  @appointment = current_user.appointments.build(appointment_params)
  if @appointment.save
    redirect_to @appointment, notice: t(".created")
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Anti-Patterns

- No service objects or interactors
- No custom controller action names (use CRUD + sub-resources)
- No `respond_to` blocks for HTML-only actions
- No presenters or decorators — use helpers or model methods
EOF
echo "  ✓ standards/backend/rails-patterns.md"

# frontend/hotwire.md
cat > "$SDD_DIR/standards/frontend/hotwire.md" << 'EOF'
# Hotwire Patterns

## Turbo Drive (Default for Everything)

Layout enables morph mode:
```erb
<%= turbo_refresh_method_tag :morph %>
<%= turbo_refresh_scroll_tag :preserve %>
```

## Standard Form Response Pattern

```ruby
# Success → 303 redirect → Turbo morphs
redirect_to @resource, notice: t(".updated")

# Validation failure → 422 → Turbo replaces
render :edit, status: :unprocessable_entity
```

**Never use `turbo_stream.refresh` as a direct form response** — it's silently ignored.
**Never render 200 on POST** — Turbo won't update the URL.

## Turbo Frames

Use for scoped page regions (tabs, inline edit, preview). Every frame response must include the matching `<turbo-frame id="...">` tag.

## Stimulus: Required Patterns

```javascript
// Implement teardown() for any controller that changes visual state
teardown() {
  clearTimeout(this.timer)
  this.element.classList.remove("active")
}

// Use values for reactive state
static values = { mode: { type: String, default: "write" } }
modeValueChanged() { this.syncUI() }
```

Global teardown in application.js:
```javascript
document.addEventListener("turbo:before-cache", () => {
  application.controllers.forEach(c => c.teardown?.())
})
```

**Always use `better-stimulus` skill** before writing Stimulus controllers.

## Common Pitfalls

- `data-turbo-temporary` has NO effect with morph mode — use teardown()
- Nested `<form>` tags are invalid HTML — use sibling forms + data-turbo-frame
- Missing frame in response → Turbo error — ensure all frame responses include the frame tag
- Lazy i18n in gem partials: use full key paths inside do...end blocks
EOF
echo "  ✓ standards/frontend/hotwire.md"

# frontend/components.md
cat > "$SDD_DIR/standards/frontend/components.md" << 'EOF'
# maquina_components

## Tailwind CSS 4

CSS-first config in application.css:
```css
@import "tailwindcss";
@theme {
  --color-primary: oklch(55% 0.2 250);
  --font-sans: "Plus Jakarta Sans", sans-serif;
}
```
No tailwind.config.js. Define all design tokens in @theme.

## Components

Use maquina_components for all UI elements. Never write custom button/card/form HTML.

Key components: Button, Card, Form, Badge, Dialog, Table, Alert
See: https://maquina.app/documentation/components/

**Use `maquina-ui-standards` skill** for implementation guidance.

## Anti-Patterns

- Don't mix Bootstrap or other CSS frameworks
- Don't use arbitrary Tailwind values — extend @theme instead
- Don't write custom form fields — use FormComponent
EOF
echo "  ✓ standards/frontend/components.md"

# testing/minitest.md
cat > "$SDD_DIR/standards/testing/minitest.md" << 'EOF'
# Minitest Standards

## Non-Negotiable Rules

- **No mocks or stubs** — test real objects against the real database
- **Test outcomes, not implementation** — assert what changed, not how
- **Happy path focus** — complete coverage of the main flow; edge cases only for critical validations
- **WebMock for external HTTP** — stub all outbound HTTP; never hit real APIs
- **Fixtures, not factories** — use Rails fixtures in test/fixtures/
- **Simple tests** — one clear assertion per test when possible

## Test Examples

```ruby
# ✅ Good — tests outcome, no stubs
test "confirms appointment and notifies client" do
  appointment = appointments(:pending)
  appointment.confirm!
  assert appointment.confirmed?
  assert_enqueued_emails 1
end

# ❌ Bad — tests implementation, uses stubs
test "appointment calls NotificationService" do
  mock = Minitest::Mock.new
  mock.expect(:notify, true)
  NotificationService.stub(:new, mock) { appointment.confirm! }
  mock.verify
end
```

## WebMock

```ruby
# test_helper.rb
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

# In test
stub_request(:post, "https://api.example.com/messages")
  .to_return(status: 200, body: { id: "123" }.to_json)
```

## Anti-Patterns

- No Minitest::Mock or stub unless there's absolutely no seam
- No let/subject — use plain methods or setup
- No FactoryBot — use fixtures
EOF
echo "  ✓ standards/testing/minitest.md"

# ─── Standards Index ─────────────────────────────────────────────────────────

echo -e "${YELLOW}Creating standards index...${NC}"

cat > "$SDD_DIR/standards/index.yml" << 'EOF'
# Standards Index
# Read this before shaping a spec to know which standards to inject.
# Update when adding new standards files.

global:
  rails-stack:
    file: global/rails-stack.md
    description: "Rails 8 stack: Hotwire, Tailwind 4, maquina_components, Solid trifecta, Kamal"
    applies_to: all

backend:
  rails-patterns:
    file: backend/rails-patterns.md
    description: "Rich models, CRUD resources, no service objects, money as cents, state as records"
    applies_to: [models, controllers, routes]

frontend:
  hotwire:
    file: frontend/hotwire.md
    description: "Turbo Drive/Frames/Streams, morph pattern, Stimulus teardown, common pitfalls"
    applies_to: [views, javascript, turbo, stimulus]
  components:
    file: frontend/components.md
    description: "maquina_components usage, Tailwind CSS 4 @theme config, anti-patterns"
    applies_to: [views, partials, forms]

testing:
  minitest:
    file: testing/minitest.md
    description: "No mocks/stubs, test outcomes, happy path, WebMock for APIs, fixtures"
    applies_to: all
EOF

echo "  ✓ standards/index.yml"

# ─── Claude Code Slash Commands ──────────────────────────────────────────────

echo -e "${YELLOW}Creating Claude Code slash commands...${NC}"

mkdir -p ".claude/commands"

cat > ".claude/commands/sdd-init.md" << 'EOF'
Initialize Spec-Driven Development for this Rails project.

Run `bash scripts/init_sdd.sh` (or `bash sdd/scripts/init_sdd.sh` if the script lives there).

This creates the `sdd/` directory structure with:
- Pre-built Rails standards files (global, backend, frontend, testing)
- `sdd/standards/index.yml` catalog
- `sdd/progress.yml` tracker
- All `.claude/commands/sdd-*.md` slash commands

After running, confirm the structure was created and suggest running /sdd-plan next.
EOF
echo "  ✓ .claude/commands/sdd-init.md"

cat > ".claude/commands/sdd-plan.md" << 'EOF'
Create or update the product planning documents for this Rails project using the spec-driven-development skill.

## If MVP Creator docs exist (docs/MVP_BUSINESS_PLAN.md, docs/TECHNICAL_GUIDE.md):
Extract and convert them into:
- `sdd/product/mission.md` — product vision, user personas, problems solved
- `sdd/product/roadmap.md` — feature list with XS/S/M/L/XL effort estimates
- `sdd/product/tech-stack.md` — stack decisions and any deviations from the Rails 8 default

## If starting from scratch:
Ask these questions one at a time:
1. What problem does this solve?
2. Who is the primary user? Any geographic or language focus?
3. What are the must-have features for launch?
4. Any deviations from the standard Rails 8 stack?

Then create the three files in `sdd/product/`.

Update `sdd/progress.yml` when complete.
EOF
echo "  ✓ .claude/commands/sdd-plan.md"

cat > ".claude/commands/sdd-shape.md" << 'EOF'
Shape a feature spec for this Rails project using the spec-driven-development skill.

## Process

### 1. Create the spec folder
Create `sdd/specs/YYYY-MM-DD-[feature-name]/` using today's date and a descriptive kebab-case name.

### 2. Ask focused discovery questions (4–6 max)
- What is the user trying to accomplish? What is the happy path?
- Are there edge cases that need handling in v1?
- What does success look like? (redirect destination, flash message, UI change)
- Are there existing models, controllers, or views to reuse or extend?

### 3. Search the codebase for existing patterns
Before writing anything, search for related code:
```
grep -r "class.*ApplicationRecord" app/models/
ls app/controllers/
find app/views -name "*.html.erb" | head -30
```
Write findings to `sdd/specs/[folder]/references.md`.

### 4. Check for visuals
Ask if mockups or wireframes exist. If none and the feature has meaningful UI, use the `frontend-design` skill to create an HTML mockup.

### 5. Inject relevant standards
Read `sdd/standards/index.yml`. Based on what the feature touches, present the applicable standards to the user for confirmation. Then write the **full file content** of each confirmed standard into `sdd/specs/[folder]/standards.md`.

### 6. Write spec.md
Create `sdd/specs/[folder]/spec.md` with:
- **Goal** — one sentence
- **User Stories** — As a [user], I want [action] so that [outcome]
- **Requirements** — functional only, no implementation details
- **Visual Design** — mockup link or layout description
- **Out of Scope** — explicitly what is NOT in v1

Update `sdd/progress.yml` when complete. Suggest running /sdd-tasks next.
EOF
echo "  ✓ .claude/commands/sdd-shape.md"

cat > ".claude/commands/sdd-tasks.md" << 'EOF'
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
EOF
echo "  ✓ .claude/commands/sdd-tasks.md"

cat > ".claude/commands/sdd-status.md" << 'EOF'
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
EOF
echo "  ✓ .claude/commands/sdd-status.md"

cat > ".claude/commands/sdd-discover-standards.md" << 'EOF'
Discover and document tribal knowledge from this Rails codebase as new SDD standards.

Use this when adding SDD to an existing Rails app to capture patterns beyond the bootstrapped defaults.

## Process

### 1. Identify focus area
If the user specified an area, use it. Otherwise, analyze the codebase and suggest 3–5 areas:
- Models (naming, scopes, concerns, validations)
- Controllers (authorization, response patterns, filters)
- Views (component usage, partial conventions, i18n)
- Jobs / mailers / concerns (shared patterns)
- Tests (fixture conventions, helper patterns)

Present options and ask which to focus on first.

### 2. Analyze files in that area
Read 5–10 representative files. Look for patterns that are:
- **Opinionated** — a deliberate choice that could have gone differently
- **Tribal** — something a new developer wouldn't know without being told
- **Consistent** — repeated across multiple files

### 3. For each pattern found
Ask the user 1–2 questions:
- "What problem does this solve?"
- "Are there exceptions?"

Then draft a concise standard and confirm before writing the file.

### 4. Write the standard file
Save to `sdd/standards/[area]/[name].md` — concise, scannable, leads with the rule.

### 5. Update index.yml
Add the new entry to `sdd/standards/index.yml` with file path, description, and applies_to.

Only document what's non-obvious. Rails defaults don't need documenting.
EOF
echo "  ✓ .claude/commands/sdd-discover-standards.md"

echo ""
echo -e "${GREEN}✓ SDD initialized for ${PROJECT_NAME}${NC}"
echo ""
echo "Structure created:"
echo "  sdd/"
echo "  ├── progress.yml"
echo "  ├── product/               ← add mission.md, roadmap.md, tech-stack.md"
echo "  ├── standards/index.yml    ← catalog of all standards"
echo "  └── standards/             ← pre-built Rails standards"
echo ""
echo "  .claude/commands/"
echo "  ├── sdd-init.md"
echo "  ├── sdd-plan.md"
echo "  ├── sdd-shape.md"
echo "  ├── sdd-tasks.md"
echo "  ├── sdd-status.md"
echo "  └── sdd-discover-standards.md"
echo ""
echo "Slash commands are now available in Claude Code:"
echo "  /sdd-plan      — create product docs"
echo "  /sdd-shape     — shape a feature spec"
echo "  /sdd-tasks     — create task breakdown"
echo "  /sdd-status    — show progress"
echo "  /sdd-discover-standards — extract tribal knowledge from codebase"
