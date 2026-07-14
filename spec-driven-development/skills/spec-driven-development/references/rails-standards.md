# Rails Standards — Bootstrap Content

When initializing SDD for a new Rails project, create these standard files verbatim. They encode the non-negotiable stack and patterns for all projects.

---

## `standards/global/rails-stack.md`

```markdown
# Rails Stack

**Framework:** Rails 8.x — vanilla, no gems that duplicate built-in behavior  
**Frontend:** Hotwire (Turbo + Stimulus) — no React, Vue, or JS frameworks  
**CSS:** Tailwind CSS 4 — CSS-first config via `@theme` in `app/assets/stylesheets/application.css`  
**Components:** maquina_components — ERB partials with Tailwind, inspired by shadcn/ui  
**Database:** SQLite (development) → PostgreSQL (production)  
**Background jobs:** Solid Queue — no Redis  
**Caching:** Solid Cache — no Redis/Memcached  
**WebSockets:** Solid Cable — no Redis  
**Auth:** Rails 8 built-in generator — not Devise  
**Testing:** Minitest + Fixtures — not RSpec, not FactoryBot  
**Deployment:** Kamal 2 with Docker  
**I18n:** Spanish first (`es`), English second (`en`) for LATAM apps  

Run `bin/rails` commands with: `source ~/.zshrc && bin/rails [command]`
```

---

## `standards/backend/rails-patterns.md`

```markdown
# Rails Patterns

## Rich Domain Models (No Service Objects)

Logic belongs in models via methods and concerns. Never extract to service objects.

```ruby
# ✅ Good — natural domain API
appointment.confirm!
appointment.cancel!(reason:)
booking.transfer_to(provider)

# ❌ Bad — service object pattern
AppointmentConfirmationService.call(appointment)
BookingTransferService.new(booking, provider).execute
```

## CRUD Resources Only

Every action maps to a CRUD verb. For state changes, create a sub-resource.

```ruby
# ✅ Good — new resource for state change
resources :appointments do
  resource :confirmation, only: [:create, :destroy]
  resource :cancellation, only: [:create]
end

# ❌ Bad — custom actions
resources :appointments do
  post :confirm
  post :cancel
end
```

## State as Records, Not Booleans

```ruby
# ✅ Good — state as a string column with defined transitions
# appointment.status: "pending" | "confirmed" | "cancelled"
appointment.confirmed?  # status == "confirmed"

# ❌ Bad — boolean proliferation
# is_confirmed, is_cancelled, is_pending, is_active...
```

## Money as Integer Cents

```ruby
# ✅ Good
price_cents: integer  # 1500 = $15.00
def price = price_cents / 100.0

# ❌ Bad
price: decimal  # floating point errors
```

## Concerns for Cross-Cutting Logic

```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern
  included do
    scope :published, -> { where(published_at: ..Time.current) }
  end
  def publish! = update!(published_at: Time.current)
end
```

## Thin Controllers

Controllers find/assign, call one model method, redirect or render.

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

- No `before_action` for complex logic — put it in the model
- No `respond_to` blocks for HTML-only actions
- No custom action names — use CRUD + sub-resources
- No `rescue_from` for business logic — let it fail visibly in development
- No presenters or decorators — use helpers or model methods
```

---

## `standards/frontend/hotwire.md`

```markdown
# Hotwire Patterns

## Turbo Drive (Default)

All navigation and form submissions go through Turbo Drive automatically.

**Morph mode** (configured in layout):
```erb
<%= turbo_refresh_method_tag :morph %>
<%= turbo_refresh_scroll_tag :preserve %>
```

## Form Response Pattern (Critical)

```ruby
# Success → redirect (Turbo follows with 303, then morphs)
redirect_to resource_path, notice: t(".updated")

# Validation failure → render with 422
render :edit, status: :unprocessable_entity
```

**Never** return `turbo_stream.refresh` as a direct form response — it's silently ignored due to request_id deduplication. Use `redirect_to` instead.

## Turbo Frames

Use sparingly. Best for scoped navigation (tabs, inline editing, preview panes).

```erb
<%= turbo_frame_tag "preview" do %>
  <%# Only this region updates %>
<% end %>
```

Ensure all frame responses include the matching `<turbo-frame>` tag.

## Turbo Streams

Use for broadcasting updates to multiple clients via Action Cable.

```ruby
# Controller: direct response (rare, for complex multi-element updates)
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.replace("el", partial: "...") }
end
```

## Stimulus: Key Patterns

```javascript
// Always implement teardown() for stateful controllers
teardown() {
  clearTimeout(this.timer)
  this.element.classList.remove("active")
}

// Values for reactive state
static values = { mode: { type: String, default: "write" } }
modeValueChanged() { this.syncUI() }

// Targets for DOM references
static targets = ["input", "preview"]
```

**Use `better-stimulus` skill** before writing any Stimulus controller.

## Turbo Cache Cleanup

Global teardown in `application.js`:
```javascript
document.addEventListener("turbo:before-cache", () => {
  application.controllers.forEach(c => c.teardown?.())
})
```

Controllers with visual state (hidden/shown elements, timers) MUST implement `teardown()`.

## Common Pitfalls

- `data-turbo-temporary` does NOT work with morph mode — use `teardown()` instead
- Never return 200 on POST — Turbo won't update the URL
- Nested `<form>` elements are invalid HTML — use sibling forms with `data-turbo-frame`
- Frames in responses must match the requesting frame ID exactly
```

---

## `standards/frontend/components.md`

```markdown
# maquina_components

UI built with maquina_components ERB partials + Tailwind CSS 4.

## Tailwind CSS 4 Configuration

CSS-first config in `app/assets/stylesheets/application.css`:
```css
@import "tailwindcss";
@theme {
  --color-primary: oklch(55% 0.2 250);
  --font-sans: "Plus Jakarta Sans", sans-serif;
}
```

No `tailwind.config.js`. Use `@theme` for design tokens.

## Component Usage

```erb
<%# Use render for all maquina components %>
<%= render Maquina::ButtonComponent.new(variant: :primary) do %>
  Save
<% end %>

<%# Or use the tag helpers %>
<%= maquina_button(variant: :outline) { "Cancel" } %>
```

## Key Components

- `ButtonComponent` — variants: primary, secondary, outline, ghost, destructive
- `CardComponent` — with header, content, footer slots
- `FormComponent` — wraps form fields with labels and error states
- `BadgeComponent` — status indicators
- `DialogComponent` — modal dialogs (uses `<dialog>` element)

See [maquina.app/documentation/components](https://maquina.app/documentation/components/) for full catalog.

**Use `maquina-ui-standards` skill** for implementation guidance on complex components.

## Anti-Patterns

- Don't write custom button/card/form HTML — use the component library
- Don't use Bootstrap or other CSS frameworks alongside Tailwind
- Don't use arbitrary Tailwind values — define design tokens in `@theme`
```

---

## `standards/testing/minitest.md`

```markdown
# Minitest Standards

## Non-Negotiable Rules

- **No mocks or stubs** — test against real objects and the real database
- **Test outcomes, not implementation** — assert what changed, not how
- **Happy path focus** — cover the main flow completely; edge cases only for critical validations
- **WebMock for external HTTP** — stub all outbound HTTP calls; never hit real APIs
- **Fixtures, not factories** — use Rails fixtures in `test/fixtures/`
- **Keep tests simple** — one clear assertion per test when possible

## Test Structure

```ruby
# Model test — tests business logic
class AppointmentTest < ActiveSupport::TestCase
  test "confirms appointment and sends notification" do
    appointment = appointments(:pending)
    appointment.confirm!
    assert appointment.confirmed?
    assert_enqueued_emails 1
  end
end

# Controller/Integration test — tests the HTTP layer
class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  test "creates appointment and redirects" do
    sign_in users(:provider)
    post appointments_path, params: { appointment: { ... } }
    assert_redirected_to appointment_path(Appointment.last)
    assert_equal "Cita creada", flash[:notice]
  end
end

# System test — tests the critical UI happy path
class AppointmentBookingTest < ApplicationSystemTestCase
  test "client books appointment successfully" do
    visit new_appointment_path
    fill_in "Nombre", with: "María López"
    click_button "Confirmar"
    assert_text "Tu cita está confirmada"
  end
end
```

## WebMock Usage

```ruby
# In test_helper.rb
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

# In individual tests
stub_request(:post, "https://api.whatsapp.com/messages")
  .to_return(status: 200, body: { id: "msg_123" }.to_json)
```

## Fixtures

```yaml
# test/fixtures/appointments.yml
pending:
  id: 1
  client: maria
  provider: juan
  status: pending
  scheduled_at: <%= 1.week.from_now %>

confirmed:
  id: 2
  client: carlos
  provider: juan
  status: confirmed
```

## Anti-Patterns

- No `Minitest::Mock` or `stub` unless absolutely necessary (external lib with no seam)
- No `let` or `subject` — use plain methods or `setup`
- No shared examples — each test file is self-contained
- No `before(:each)` — use `setup` method
```
