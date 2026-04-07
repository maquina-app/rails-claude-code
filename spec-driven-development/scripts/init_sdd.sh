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
echo "Slash commands are provided by the spec-driven-development plugin:"
echo "  /sdd-plan      — create product docs"
echo "  /sdd-shape     — shape a feature spec"
echo "  /sdd-tasks     — create task breakdown"
echo "  /sdd-status    — show progress"
echo "  /sdd-discover-standards — extract tribal knowledge from codebase"
