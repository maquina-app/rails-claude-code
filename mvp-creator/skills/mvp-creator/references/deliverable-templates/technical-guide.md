# Technical Guide Template

Use this structure when generating the technical architecture guide deliverable.

---

# [APP_NAME] Technical Guide

## Overview

Brief description of the application and its technical approach.

**Philosophy:** [Core technical philosophy - e.g., "Vanilla Rails is plenty"]

---

## Tech Stack

### Core

| Component | Technology | Notes |
|-----------|------------|-------|
| Framework | Ruby on Rails 8.x | Latest stable |
| Frontend | Hotwire (Turbo + Stimulus) | No JS frameworks |
| CSS | Tailwind CSS 4 | CSS-first config |
| Database | SQLite / PostgreSQL | [Choice and why] |
| Background Jobs | Solid Queue | Database-backed |
| Caching | Solid Cache | Database-backed |
| WebSockets | Solid Cable | Database-backed |
| Authentication | Rails 8 built-in | Not Devise |

### Additional

| Component | Technology | Notes |
|-----------|------------|-------|
| Charts | Chart.js | [If needed] |
| Icons | Lucide | Via lucide-rails or CDN |
| Components | maquina_components | [If using] |

### What We Don't Use

| Technology | Why Not |
|------------|---------|
| Devise | Auth is ~150 lines of custom code |
| React/Vue | Hotwire is sufficient |
| Redis | Database-backed alternatives |
| RSpec | Minitest is simpler |
| Service objects | Rich domain models instead |

---

## File Organization

```
app/
├── controllers/
│   ├── concerns/           # Shared controller behavior
│   └── [resource]/         # Nested controllers for sub-resources
├── models/
│   ├── concerns/           # Shared model behavior
│   ├── [model]/            # Model-specific concerns
│   └── current.rb          # CurrentAttributes
├── views/
│   ├── components/         # Reusable view components
│   ├── layouts/
│   └── shared/             # Partials used across views
├── helpers/                # View helpers
├── jobs/                   # Background jobs
├── mailers/                # Email mailers
└── javascript/
    └── controllers/        # Stimulus controllers

config/
├── locales/
│   ├── [lang]/
│   │   ├── views.yml       # View strings
│   │   ├── models.yml      # Model names, attributes
│   │   ├── errors.yml      # Friendly error messages
│   │   ├── flash.yml       # Toast messages
│   │   └── enums.yml       # Enum translations
```

### When to Create New Files

| Scenario | Location |
|----------|----------|
| Shared model behavior | `app/models/concerns/` |
| Single model organization | `app/models/[model]/` |
| Complex operation | PORO under `app/models/[model]/` |
| Presentation logic | PORO with `include ActionView::Helpers` |
| External API client | `app/services/` (rare) |

---

## Data Models

### Core Entities

```ruby
# User
class User < ApplicationRecord
  has_many :[resources]
  
  # Preferences stored in user record
  # - timezone (for display)
  # - locale (for i18n)
end

# [Resource 1]
class [Resource1] < ApplicationRecord
  belongs_to :user
  has_many :[related_resources]
  
  # Key fields:
  # - [field]: [type] - [purpose]
end

# [Resource 2]
class [Resource2] < ApplicationRecord
  belongs_to :user
  belongs_to :[parent]
  
  # Key fields:
  # - [field]: [type] - [purpose]
end
```

### Key Enums

```ruby
class [Model] < ApplicationRecord
  enum :[enum_name], {
    value_1: 0,
    value_2: 1,
    value_3: 2
  }, prefix: true
end
```

### Money Handling

**Always store money as integer cents:**

```ruby
# Migration
add_column :transactions, :amount_cents, :integer, default: 0, null: false

# Model
class Transaction < ApplicationRecord
  def amount
    amount_cents / 100.0
  end
  
  def amount=(value)
    self.amount_cents = (value.to_f * 100).round
  end
end

# View helper
def format_money(cents)
  number_to_currency(cents / 100.0)
end
```

---

## Timezone Strategy

### Storage

- Store all times in UTC in the database
- Never store local times

### Display

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  
  resets { Time.zone = nil }
  
  def user=(user)
    super
    Time.zone = user&.timezone || "UTC"
  end
end
```

### Date Boundaries

"Today's records" must respect user's timezone:

```ruby
scope :today, -> {
  where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
}
```

---

## Turbo 8 Patterns

### Decision Framework

| Scenario | Pattern | Why |
|----------|---------|-----|
| **Default** | Morph + Broadcasts | Simplest, works everywhere |
| Inline editing | Turbo Frame | Scoped replacement |
| Modal dialogs | Turbo Frame | Isolated content |
| Quick-add forms | Turbo Frame | Preserve page state |
| Multi-element update | Turbo Stream | Targeted updates |
| Navigation | Turbo Drive | Fast page loads |

### Morph (Default)

```ruby
# Model
class [Resource] < ApplicationRecord
  after_commit :broadcast_refresh
  
  private
  
  def broadcast_refresh
    broadcast_refresh_to user, :[resources]
  end
end
```

```erb
<%# View %>
<%= turbo_stream_from current_user, :[resources] %>
```

### Turbo Frames (When Needed)

```erb
<%= turbo_frame_tag dom_id(@resource) do %>
  <%# Content that can be replaced in isolation %>
<% end %>
```

### Turbo Streams (Multi-Element)

```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace(dom_id(@resource), @resource),
      turbo_stream.replace(:stats, partial: "stats"),
      turbo_stream_flash(notice: "Updated!")
    ]
  end
end
```

---

## Stimulus Controller Patterns

### Naming Convention

One controller per behavior:
- `toggle_controller.js` — Show/hide elements
- `auto_submit_controller.js` — Form auto-submission
- `clipboard_controller.js` — Copy to clipboard

### Standard Structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { delay: { type: Number, default: 300 } }
  static classes = ["hidden"]

  connect() {
    // Setup
  }

  disconnect() {
    // Cleanup
  }

  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass)
  }
}
```

### Common Controllers

```javascript
// Auto-submit for filters
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    this.element.requestSubmit()
  }

  debounceSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }
}
```

---

## I18n Strategy

### File Organization

```
config/locales/
├── es/
│   ├── views.es.yml      # All view strings
│   ├── models.es.yml     # Model names, attributes
│   ├── errors.es.yml     # Friendly error messages
│   ├── flash.es.yml      # Toast messages
│   └── enums.es.yml      # Enum translations
└── en/
    └── [same structure]
```

### Configuration

```ruby
# config/application.rb
config.i18n.default_locale = :[default_locale]
config.i18n.available_locales = [:[locale1], :[locale2]]
config.i18n.fallbacks = true
config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
```

### Friendly Error Messages

```yaml
# config/locales/es/errors.es.yml
es:
  activerecord:
    errors:
      models:
        [model]:
          attributes:
            [attribute]:
              blank: "Por favor ingresa [field name]"
              invalid: "[Field] no es válido"
              taken: "Este [field] ya está en uso"
```

```yaml
# config/locales/en/errors.en.yml
en:
  activerecord:
    errors:
      models:
        [model]:
          attributes:
            [attribute]:
              blank: "Please enter [field name]"
              invalid: "[Field] is not valid"
              taken: "This [field] is already in use"
```

### View Usage

```erb
<%# Always use I18n %>
<h1><%= t(".title") %></h1>
<p><%= t(".description") %></p>

<%# With interpolation %>
<p><%= t(".welcome", name: current_user.name) %></p>
```

---

## Authentication

### Rails 8 Built-in Auth

```bash
bin/rails generate authentication
bin/rails db:migrate
```

### Key Files Generated

- `app/models/user.rb` — User model with `has_secure_password`
- `app/models/session.rb` — Session model
- `app/controllers/sessions_controller.rb` — Login/logout
- `app/controllers/concerns/authentication.rb` — Auth concern

### Usage

```ruby
class ApplicationController < ActionController::Base
  include Authentication
end

class PublicController < ApplicationController
  allow_unauthenticated_access
end

class ProtectedController < ApplicationController
  # Requires authentication by default
end
```

---

## Testing Approach

### Framework

- **Minitest** (not RSpec)
- **Fixtures** (not factories)

### Test Types

| Type | Location | Focus |
|------|----------|-------|
| Unit | `test/models/` | Model validations, methods |
| Controller | `test/controllers/` | Request/response |
| Integration | `test/integration/` | Multi-step flows |
| System | `test/system/` | Critical user journeys |

### Fixture Example

```yaml
# test/fixtures/users.yml
default: &default
  timezone: "America/Mexico_City"
  locale: "es"

admin:
  <<: *default
  email: admin@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

regular:
  <<: *default
  email: user@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
```

### Test Patterns

```ruby
class [Model]Test < ActiveSupport::TestCase
  test "validates presence of [field]" do
    record = [Model].new([field]: nil)
    assert_not record.valid?
    assert_includes record.errors[:[field]], I18n.t("activerecord.errors...")
  end
end
```

### What to Test

- Model validations and business logic
- Controller responses (status codes, redirects)
- I18n in both locales
- Timezone edge cases (midnight, DST)
- Critical user flows (system tests)

---

## Code Style

### Ruby

```ruby
# Early returns
def process
  return unless valid?
  return if already_processed?
  
  do_work
end

# Scoped queries
def index
  @resources = current_user.resources.active.ordered
end

# Explicit enum values
enum status: { pending: 0, active: 1, archived: 2 }
```

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Model methods (actions) | Verbs | `close`, `reopen`, `archive` |
| Model methods (queries) | Predicates | `closed?`, `active?` |
| Scopes | Adverbs/adjectives | `chronologically`, `active` |
| Concerns | Adjectives (-able) | `Closeable`, `Watchable` |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|--------------|------------|
| Service objects | Rich domain models with concerns |
| Float/Decimal for money | Integer cents |
| Hardcoded strings | I18n everywhere |
| Unscoped queries | Always scope to `current_user` |
| Custom controller actions | New resources (CRUD) |
| Boolean columns for state | State records (has_one) |
| Complex JS frameworks | Stimulus + Turbo |
| Redis for everything | Solid Queue/Cache/Cable |

---

## Performance Considerations

### Database

- Add indexes for queried columns
- Use `counter_cache` for counts
- Use `includes` to avoid N+1

### Caching

```ruby
# Fragment caching
<% cache @resource do %>
  <%= render @resource %>
<% end %>

# Russian doll caching
<% cache [@resource, @resource.items] do %>
  <% @resource.items.each do |item| %>
    <% cache item do %>
      <%= render item %>
    <% end %>
  <% end %>
<% end %>
```

### HTTP Caching

```ruby
class ResourcesController < ApplicationController
  def show
    @resource = current_user.resources.find(params[:id])
    fresh_when @resource
  end
end
```

---

## Security Checklist

- [ ] All queries scoped to `current_user`
- [ ] Strong parameters in controllers
- [ ] CSRF protection enabled
- [ ] Sensitive data encrypted
- [ ] No secrets in version control
- [ ] Input validation on models
- [ ] Rate limiting on sensitive endpoints

---

## Deployment

### Kamal 2

```yaml
# config/deploy.yml
service: [app_name]
image: [username]/[app_name]

servers:
  web:
    - [server_ip]

registry:
  username: [username]
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
```

### Commands

```bash
# First deployment
bin/kamal setup

# Subsequent deployments
bin/kamal deploy

# Production console
bin/kamal console

# Logs
bin/kamal logs
```
