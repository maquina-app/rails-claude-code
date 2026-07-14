---
name: simplify
description: >
  Simplifies and refines Ruby on Rails code following 37signals patterns and the
  One Person Framework philosophy, while preserving exact functionality. Focuses
  on recently modified code unless instructed otherwise. Use this skill when
  simplifying or refactoring Rails code, reviewing recently written Rails code
  for 37signals/vanilla-Rails conformance, or when asked to make Rails code more
  vanilla. Triggers on "simplify this", "refactor to 37signals", "make this more
  vanilla Rails", removing service objects, thinning fat controllers, converting
  boolean state columns to records, or CRUD-ifying custom controller actions.
---

# Rails Simplifier

Simplify and refine Ruby on Rails code to enhance clarity, consistency, and maintainability **while preserving exact functionality**. Apply 37signals patterns and the One Person Framework philosophy to make Rails code more vanilla without altering its behavior.

Deeper material lives in two references, read them when a refinement needs more than the summaries below:
- `references/philosophy.md` — the *why*, distilled from the 37signals / Jorge Manrubia writing.
- `references/patterns.md` — the *how*, an implementation catalog of concrete patterns from the Fizzy codebase (routing, controllers, concerns, state records, auth, jobs, testing, caching, POROs).

---

## Guiding Philosophy

Three ideas drive every refinement. For the full treatment — quotes, examples, and the design principles behind them — read `references/philosophy.md`.

- **One Person Framework** (DHH, 2021) — a toolkit powerful enough that one developer can build and maintain a whole competitive app. Rails 8 delivers it via Solid Queue/Cache/Cable, built-in auth, Kamal, and Hotwire. **The test:** can one person understand this codebase in an afternoon? If not, simplify.
- **Conceptual Compression** (DHH, RailsConf 2018) — simplify a concept so a developer gets 80% of the value with 20% of the effort (ActiveRecord compresses SQL; Hotwire compresses the frontend; concerns compress model organization). **Your job:** when code expands cognitive load without proportional value, compress it.
- **Vanilla Rails is Plenty** (Jorge Manrubia, 37signals) — build even complex apps without service objects, interactors, repositories, or command patterns. Rich domain models expose natural, domain-oriented APIs:

```ruby
# ✅ GOOD: Natural, domain-oriented API (conceptual compression)
recording.incinerate
card.close

# ❌ BAD: Service/procedural style (expands complexity)
Recording::IncinerationService.execute(recording)
CardClosureService.new(card, user).call
```

> "We strongly prefer the first form. It does a better job of hiding complexity, as it doesn't shift the burden of composition to the caller. It feels more natural, like plain English. It feels more Ruby." — Jorge Manrubia

---

## Refinement Rules

You will analyze recently modified code and apply refinements that:

### 1. Preserve Functionality

Never change what the code does — only how it does it. All original features, outputs, and behaviors must remain intact.

### 2. Apply CRUD Everything

Every action should map to a CRUD verb. When something doesn't fit, create a new resource:

```ruby
# ❌ BAD: Custom actions (expands controller complexity)
resources :cards do
  post :close
  post :reopen
  post :archive
end

# ✅ GOOD: New resources for state changes (compresses to CRUD pattern)
resources :cards do
  resource :closure      # POST to close, DELETE to reopen
  resource :archive      # POST to archive, DELETE to unarchive
  resource :goldness     # POST to gild, DELETE to ungild
end
```

### 3. Apply Thin Controllers, Rich Models

Controllers orchestrate; models contain business logic:

```ruby
# ✅ GOOD: Controller just orchestrates
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close  # All logic in model — conceptual compression

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.html { redirect_to @card, notice: t(".created") }
    end
  end

  def destroy
    @card.reopen

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.html { redirect_to @card, notice: t(".destroyed") }
    end
  end
end

# ❌ BAD: Business logic in controller (complexity leak)
def create
  @card.transaction do
    @card.create_closure!(user: Current.user)
    @card.events.create!(action: :closed)
    NotificationMailer.card_closed(@card).deliver_later
  end
end
```

### 4. Apply Concerns for Organization

Concerns must have "has trait" or "acts as" semantics. Self-contained with associations, scopes, callbacks, and methods:

```ruby
# app/models/card/closeable.rb
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }
  end

  def close
    transaction do
      create_closure!(user: Current.user)
      events.create!(action: :closed, creator: Current.user)
    end
    notify_watchers_of_closure
  end

  def reopen
    closure&.destroy
    events.create!(action: :reopened, creator: Current.user)
  end

  def closed?
    closure.present?
  end

  def open?
    !closed?
  end

  private
    def notify_watchers_of_closure
      watchers.each { |w| CardNotificationJob.perform_later(w, self, :closed) }
    end
end
```

**What concerns are NOT:**
- Arbitrary containers to split large models
- A replacement for proper object-oriented design
- An excuse to avoid creating additional classes when complexity warrants it

### 5. Model State as Records

Model states as separate records to track who, when, and why — instead of boolean columns, which lose that context:

```ruby
# ❌ BAD: Boolean columns (loses context)
class Card < ApplicationRecord
  # closed: boolean
  # closed_at: datetime
  # closed_by_id: integer
end

# ✅ GOOD: State records (preserves full context)
class Card < ApplicationRecord
  has_one :closure, dependent: :destroy
  has_one :confirmation, dependent: :destroy

  def closed?
    closure.present?
  end

  def confirmed?
    confirmation.present?
  end
end

# app/models/closure.rb
class Closure < ApplicationRecord
  belongs_to :card, touch: true
  belongs_to :user, default: -> { Current.user }

  # Fields: closed_at, reason (optional)
end
```

**Benefits:**
- Track who made the change (user reference)
- Track when it happened (timestamps)
- Add metadata (reason, notes)
- Easy to query (`joins(:closure)` vs `where(closed: true)`)
- Reversible (delete record to reopen)

### 6. Extract Shared Controller Behavior into Concerns

Pull a resource-scoping `before_action` and its shared render helpers into a small controller concern (e.g. `CardScoped`), so each thin controller just includes it. See the full concerns catalog — scoping, request context, timezone, Turbo flash — in `references/patterns.md`.

---

## Naming Conventions

### Verb Methods for Actions

```ruby
# ✅ GOOD: Natural verbs
card.close
card.reopen
card.gild
card.postpone
board.publish
booking.confirm
booking.cancel

# ❌ BAD: Procedural/setter style
card.set_closed(true)
card.update_status(:closed)
CardCloser.call(card)
```

### Predicate Methods for State

```ruby
card.closed?
card.open?
card.golden?
card.postponed?
booking.confirmed?
booking.cancelled?

# Derived from presence
def closed?
  closure.present?
end
```

### Concern Naming (Adjectives with -able/-ible)

- `Closeable` — can be closed
- `Publishable` — can be published
- `Watchable` — can be watched
- `Confirmable` — can be confirmed
- `Cancellable` — can be cancelled
- `Schedulable` — can be scheduled (shared across models)

### Scope Naming (Adverbs/Adjectives)

```ruby
scope :chronologically,         -> { order(created_at: :asc) }
scope :reverse_chronologically, -> { order(created_at: :desc) }
scope :alphabetically,          -> { order(name: :asc) }
scope :active,                  -> { where(active: true) }
scope :upcoming,                -> { where(starts_at: Time.current..) }
scope :today,                   -> { where(starts_at: Time.current.all_day) }
scope :preloaded,               -> { includes(:creator, :tags) }
```

---

## Code Quality Patterns

### Time Handling

```ruby
# ✅ GOOD
Time.current                    # Respects Rails timezone
Date.current                    # Respects Rails timezone
booking.starts_at.in_time_zone(account.timezone)

# ❌ BAD
Time.now                        # System timezone, inconsistent
Date.today                      # System timezone
```

### Money Handling

```ruby
# ✅ GOOD: Integer cents
add_column :services, :price_cents, :integer, default: 0, null: false

def price
  price_cents / 100.0
end

def price=(value)
  self.price_cents = (value.to_f * 100).round
end

# ❌ BAD: Float/Decimal
add_column :services, :price, :decimal  # Precision issues
```

### Query Scoping

```ruby
# ✅ GOOD: Always scope to current tenant
@bookings = current_account.bookings.upcoming
@booking = current_account.bookings.find(params[:id])

# ❌ BAD: Unscoped queries (security risk)
@booking = Booking.find(params[:id])
```

### N+1 Prevention

```ruby
# ✅ GOOD: Eager load associations
@bookings = current_account.bookings
              .includes(:client, :service, :user)
              .upcoming

# ❌ BAD: N+1 queries
@bookings.each { |b| b.client.name }  # N+1!
```

### Error Handling

```ruby
# ✅ GOOD: Rescue specific errors, log context
class Whatsapp::ReminderJob < ApplicationJob
  retry_on Faraday::Error, wait: 5.minutes, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(booking)
    # Job logic
  rescue StandardError => e
    Rails.logger.error("Reminder failed", {
      booking_id: booking.id,
      error_class: e.class.name,
      error_message: e.message
    })
    raise # Re-raise to trigger retry
  end
end
```

### Logging Patterns

```ruby
# ✅ GOOD: Structured logging with context
Rails.logger.info("Booking created", {
  booking_id: booking.id,
  client_id: booking.client_id,
  service: booking.service.name
})

# What to log: Auth events, booking lifecycle, external API calls, job execution, errors

# ❌ BAD: Logging sensitive data
Rails.logger.info("OTP: #{otp_code}")           # Never log OTP
Rails.logger.info("Phone: #{user.phone}")        # Mask: +52***5678
Rails.logger.info("Token: #{api_token}")         # Never log tokens
```

### Testing: Time Helpers for Date-Sensitive Tests

Fixtures are loaded once, but `Date.current` is evaluated at test runtime. In parallel tests, this causes drift:

```ruby
# ❌ BAD: Flaky test (date drift in parallel tests)
test "today scope" do
  assert_includes Booking.today, bookings(:today_booking)  # May fail near midnight!
end

# ✅ GOOD: Freeze time to match fixture
test "today scope" do
  booking = bookings(:today_booking)
  travel_to booking.date.to_time  # Freeze to fixture's date
  assert_includes Booking.today, booking
end

# ✅ GOOD: Freeze time when creating records
test "creates booking for today" do
  freeze_time
  post bookings_path, params: { booking: { date: Date.current } }
  assert_equal Date.current, Booking.last.date
end
```

### I18n: Localize All User-Facing Strings

```ruby
# ✅ GOOD: I18n everywhere
redirect_to @booking, notice: t(".created")
validates :starts_at, presence: { message: :blank }  # Uses locale file

# ❌ BAD: Hardcoded strings
redirect_to @booking, notice: "Booking created!"
validates :starts_at, presence: { message: "can't be blank" }
```

---

## Turbo/Hotwire Patterns

### Decision Framework

| Scenario | Pattern |
|----------|---------|
| **Default** | Turbo Drive + Morph |
| List updates | Turbo Stream |
| Inline editing | Turbo Frame |
| Modals/dialogs | Turbo Frame |
| Multi-element updates | Turbo Stream |

### Turbo Stream Response Pattern

```ruby
def create
  @booking = current_account.bookings.create!(booking_params)

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.prepend(:bookings, @booking),
        turbo_stream.replace(:today_count, partial: "dashboard/today_count"),
        turbo_stream_flash(notice: t(".created"))
      ]
    end
    format.html { redirect_to bookings_path, notice: t(".created") }
  end
end
```

The `turbo_stream_flash` helper above comes from a small `TurboFlash` controller concern — see `references/patterns.md` for its definition alongside the rest of the concerns catalog.

---

## Anti-Patterns to Identify and Refactor

| Anti-Pattern | Simplification | Why |
|--------------|----------------|-----|
| Service objects (`*Service`, `*Interactor`) | Rich model methods + concerns | Conceptual compression |
| Custom controller actions (`post :close`) | CRUD resources (`resource :closure`) | Rails conventions |
| Boolean state columns (`closed: boolean`) | State records (`has_one :closure`) | Track who/when/why |
| Fat controllers with business logic | Thin controllers, model methods | Single responsibility |
| Devise authentication | Rails 8 built-in auth | ~150 lines vs gem |
| Sidekiq/Redis | Solid Queue | One less service |
| React/Vue/JSON APIs | Hotwire (Turbo + Stimulus) | No build pipeline |
| RSpec + FactoryBot | Minitest + fixtures | Built-in, simpler |
| Procedural naming (`set_closed`) | Verb methods (`close`) | Natural Ruby |
| `Time.now` | `Time.current` | Timezone consistency |
| Float for money | Integer cents | Precision |
| Unscoped queries | Always scope to tenant | Security |
| N+1 queries | `includes` / `preload` | Performance |
| Hardcoded strings | I18n keys | Localization |
| Date scope tests without `travel_to` | Freeze time to fixture date | Parallel test stability |

---

## Your Refinement Process

1. **Identify** recently modified code sections
2. **Analyze** for opportunities to compress complexity
3. **Check** for service objects → convert to model methods
4. **Check** for custom controller actions → convert to CRUD resources
5. **Check** for boolean columns → convert to state records
6. **Check** for fat controllers → move logic to models
7. **Check** for `Time.now` → replace with `Time.current`
8. **Check** for hardcoded strings → convert to I18n
9. **Check** for N+1 queries → add `includes`
10. **Check** for date tests without time freezing → add `travel_to`
11. **Apply** domain-driven naming conventions
12. **Ensure** all functionality remains unchanged
13. **Verify** the refined code is simpler and more maintainable

---

## Maintain Balance

Avoid over-simplification that could:

- Reduce code clarity or maintainability
- Create overly clever solutions that are hard to understand
- Combine too many concerns into single methods or classes
- Remove helpful abstractions that improve code organization
- Make the code harder to debug or extend

**Remember:** The goal is conceptual compression — hiding complexity behind simple APIs, not eliminating necessary complexity.

---

## Focus Scope

Refine only code that has been recently modified or touched in the current session, unless explicitly instructed to review a broader scope. Apply refinements proactively right after Rails code is written or modified, without waiting for an explicit request. The goal is Rails code that follows the One Person Framework philosophy — simple enough that one developer can understand and maintain the entire system.

> "The best code is the code you don't write. The second best is the code that's obviously correct."

> "Vanilla Rails is plenty." — Jorge Manrubia, 37signals
