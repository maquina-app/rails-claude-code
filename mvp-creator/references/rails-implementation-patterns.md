# Rails Implementation Patterns

> *Practical patterns from the 37signals Fizzy codebase*

**Related:** [rails-philosophy.md](rails-philosophy.md) for the "why"

---

## 1. The Stack

### What to Use

```ruby
# Gemfile
gem "rails", "~> 8.0"

# Hotwire stack
gem "turbo-rails"
gem "stimulus-rails"
gem "importmap-rails"
gem "propshaft"

# Database-backed infrastructure (NO Redis!)
gem "solid_queue"    # Jobs
gem "solid_cache"    # Caching
gem "solid_cable"    # WebSockets

# Minimal, focused gems
gem "bcrypt"         # Password hashing
```

### What NOT to Use

| Gem | Why to Avoid |
|-----|--------------|
| `devise` | Auth is ~150 lines of custom code |
| `pundit`/`cancancan` | Authorization belongs in models |
| `dry-rb` gems | Over-engineered |
| `interactor`/`command` | Service objects rarely needed |
| `sidekiq` | Solid Queue (no Redis) |
| `rspec` | Minitest is simpler |

---

## 2. Routing: Everything is CRUD

### The Core Principle

Every action maps to a CRUD verb. When something doesn't fit, **create a new resource**.

```ruby
# ❌ BAD: Custom actions
resources :cards do
  post :close
  post :reopen
  post :archive
end

# ✅ GOOD: New resources for state changes
resources :cards do
  resource :closure      # POST to close, DELETE to reopen
  resource :pin          # POST to pin, DELETE to unpin
  resource :watch        # POST to watch, DELETE to unwatch
end
```

### Real Example

```ruby
resources :cards do
  scope module: :cards do
    resource :closure         # Closing/reopening
    resource :column          # Assigning to workflow column
    resource :pin             # Pinning to sidebar
    resources :assignments    # Managing assignees
    resources :comments do
      resources :reactions    # Emoji reactions
    end
  end
end
```

---

## 3. Controller Patterns

### Thin Controllers, Rich Models

```ruby
# ✅ GOOD: Controller just orchestrates
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close  # All logic in model

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.reopen  # All logic in model

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

### Authorization: Controller Checks, Model Defines

```ruby
# Controller checks permission
class CardsController < ApplicationController
  before_action :ensure_can_administer, only: [:destroy]

  private
    def ensure_can_administer
      head :forbidden unless Current.user.can_administer?(@card)
    end
end

# Model defines what permission means
class User < ApplicationRecord
  def can_administer?(card)
    admin? || card.creator == self
  end
end
```

---

## 4. Controller Concerns

### Resource Scoping

```ruby
# app/controllers/concerns/card_scoped.rb
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find(params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        dom_id(@card, :container),
        partial: "cards/container",
        locals: { card: @card.reload }
      )
    end
end
```

### Timezone Concern

```ruby
# app/controllers/concerns/current_timezone.rb
module CurrentTimezone
  extend ActiveSupport::Concern

  included do
    around_action :set_current_timezone
    helper_method :timezone_from_cookie
    etag { timezone_from_cookie }
  end

  private
    def set_current_timezone(&)
      Time.use_zone(timezone_from_cookie, &)
    end

    def timezone_from_cookie
      @timezone_from_cookie ||= begin
        tz = cookies[:timezone]
        ActiveSupport::TimeZone[tz] if tz.present?
      end
    end
end
```

### Turbo Flash Concern

```ruby
# app/controllers/concerns/turbo_flash.rb
module TurboFlash
  extend ActiveSupport::Concern

  included do
    helper_method :turbo_stream_flash
  end

  private
    def turbo_stream_flash(**flash_options)
      turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash_options })
    end
end
```

---

## 5. Model Concerns

### Self-Contained Behavior

Each concern is self-contained with associations, scopes, and methods:

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
      events.create!(action: :closed)
    end
  end

  def reopen
    transaction do
      closure.destroy!
      events.create!(action: :reopened)
    end
  end

  def closed?
    closure.present?
  end

  def open?
    !closed?
  end
end
```

### Watchable Concern

```ruby
# app/models/concerns/watchable.rb
module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy
  end

  def watched_by?(user)
    watches.exists?(user: user)
  end

  def watch_for(user)
    watches.find_by(user: user)
  end

  def watchers
    User.where(id: watches.select(:user_id))
  end
end
```

---

## 6. State as Records, Not Booleans

```ruby
# ❌ BAD: Boolean columns
class Card < ApplicationRecord
  # closed: boolean
  # pinned: boolean
  # golden: boolean
end

# ✅ GOOD: State records
class Card < ApplicationRecord
  has_one :closure
  has_one :pin
  has_one :goldness

  def closed?
    closure.present?
  end

  def pinned?
    pin.present?
  end
end
```

Benefits:
- Track who made the change
- Track when the change happened
- Add metadata (reason, notes)
- Easy to query (joins vs. where)

---

## 7. Authentication Without Devise

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :signed_in?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def signed_in?
      Current.user.present?
    end

    def current_user
      Current.user
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      if session_record = find_session_by_cookie
        Current.user = session_record.user
      end
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def start_new_session_for(user)
      session_record = user.sessions.create!
      cookies.signed.permanent[:session_id] = { value: session_record.id, httponly: true }
      Current.user = user
    end

    def terminate_session
      Current.user.sessions.find_by(id: cookies.signed[:session_id])&.destroy
      cookies.delete(:session_id)
    end
end
```

---

## 8. CurrentAttributes Pattern

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account, :request_id, :user_agent, :ip_address

  resets { Time.zone = nil }

  def user=(user)
    super
    self.account = user&.account
    Time.zone = user&.time_zone
  end
end
```

Usage in models:

```ruby
class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { Current.account }
end
```

---

## 9. Background Jobs

### Simple Job Pattern

```ruby
# app/jobs/card/notification_job.rb
class Card::NotificationJob < ApplicationJob
  queue_as :default

  def perform(card)
    card.watchers.each do |watcher|
      CardMailer.updated(watcher, card).deliver_later
    end
  end
end
```

### Triggered by Callbacks

```ruby
module Card::Notifiable
  extend ActiveSupport::Concern

  included do
    after_commit :notify_watchers, on: :update, if: :saved_change_to_title?
  end

  private
    def notify_watchers
      Card::NotificationJob.perform_later(self)
    end
end
```

---

## 10. Testing Patterns

### Fixtures Over Factories

```yaml
# test/fixtures/users.yml
admin:
  name: Admin User
  email: admin@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
  admin: true

regular:
  name: Regular User
  email: user@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
```

### Integration Test Pattern

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @card = cards(:one)
    sign_in_as @user
  end

  test "closes card" do
    post card_closure_path(@card)

    assert_response :success
    assert @card.reload.closed?
  end

  test "reopens card" do
    @card.close
    delete card_closure_path(@card)

    assert_response :success
    assert @card.reload.open?
  end

  private
    def sign_in_as(user)
      post sessions_path, params: { email: user.email, password: "password" }
    end
end
```

### System Test Pattern

```ruby
class CardFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:regular)
    sign_in_as @user
  end

  test "creating and closing a card" do
    visit board_path(boards(:one))

    click_on "New Card"
    fill_in "Title", with: "Test Card"
    click_on "Create"

    assert_text "Test Card"

    click_on "Close"
    assert_text "Closed"
  end
end
```

---

## 11. Turbo/Hotwire Patterns

### Morph for Full Page Updates

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  after_commit :broadcast_refresh, on: [:create, :update, :destroy]

  private
    def broadcast_refresh
      broadcast_refresh_to board
    end
end
```

```erb
<%# app/views/boards/show.html.erb %>
<%= turbo_stream_from @board %>
```

### Turbo Streams for Multi-Element Updates

```ruby
def create
  @comment = @card.comments.create!(comment_params)

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.append(:comments, @comment),
        turbo_stream_flash(notice: "Comment added!")
      ]
    end
  end
end
```

### Turbo Frames for Inline Editing

```erb
<%# app/views/cards/_card.html.erb %>
<%= turbo_frame_tag dom_id(card) do %>
  <div class="card">
    <h3><%= card.title %></h3>
    <%= link_to "Edit", edit_card_path(card) %>
  </div>
<% end %>

<%# app/views/cards/edit.html.erb %>
<%= turbo_frame_tag dom_id(@card) do %>
  <%= form_with model: @card do |f| %>
    <%= f.text_field :title %>
    <%= f.submit "Save" %>
  <% end %>
<% end %>
```

---

## 12. Stimulus Controllers

### Toggle Controller

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static classes = ["hidden"]

  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass)
  }

  show() {
    this.contentTarget.classList.remove(this.hiddenClass)
  }

  hide() {
    this.contentTarget.classList.add(this.hiddenClass)
  }
}
```

### Auto-Submit Controller

```javascript
// app/javascript/controllers/auto_submit_controller.js
import { Controller } from "@hotwired/stimulus"

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

### Dialog Controller

```javascript
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
```

---

## 13. Database Patterns

### Default Values via Lambdas

```ruby
class Card < ApplicationRecord
  belongs_to :account, default: -> { board.account }
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

### Touch for Cache Invalidation

```ruby
class Comment < ApplicationRecord
  belongs_to :card, touch: true
end

class Closure < ApplicationRecord
  belongs_to :card, touch: true
end
```

### Counter Caches

```ruby
class Comment < ApplicationRecord
  belongs_to :card, counter_cache: true
end

# Migration
add_column :cards, :comments_count, :integer, default: 0, null: false
```

---

## 14. Naming Conventions

### Verb Methods for Actions

```ruby
# ✅ GOOD
card.close
card.reopen
card.gild
board.publish

# ❌ BAD
card.set_closed(true)
card.update_status(:closed)
```

### Predicate Methods for State

```ruby
card.closed?
card.open?
card.golden?

def closed?
  closure.present?
end
```

### Concern Naming (Adjectives)

- `Closeable` — can be closed
- `Publishable` — can be published
- `Watchable` — can be watched
- `Assignable` — can be assigned

### Scope Naming

```ruby
scope :chronologically,         -> { order(created_at: :asc) }
scope :reverse_chronologically, -> { order(created_at: :desc) }
scope :alphabetically,          -> { order(name: :asc) }
scope :preloaded,               -> { includes(:creator, :tags) }
```

---

## Quick Reference

### Do This

- ✅ New resource over new action
- ✅ Model methods over service objects
- ✅ Concerns for horizontal behavior
- ✅ State records over booleans
- ✅ `fresh_when` for HTTP caching
- ✅ Minitest + fixtures
- ✅ Database-backed everything
- ✅ Turbo Morph for full page updates

### Not This

- ❌ Custom controller actions
- ❌ Service/interactor objects
- ❌ Boolean columns for state
- ❌ RSpec + factories
- ❌ Redis for jobs/cache/cable
- ❌ Devise for auth

---

## Resources

- [Fizzy Source Code](https://github.com/basecamp/fizzy)
- [37signals Dev Blog](https://dev.37signals.com)
- [Rails Doctrine](https://rubyonrails.org/doctrine)
