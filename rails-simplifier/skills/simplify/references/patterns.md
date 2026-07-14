# 37signals Implementation Patterns (the *how*)

Concrete patterns for applying the vanilla-Rails philosophy, distilled from the open-source **Fizzy** codebase. This is the implementation companion to `philosophy.md` (the *why*) and the rule summaries in `../SKILL.md`. Reach for a section here when a refinement needs a fuller, real-world pattern than the SKILL.md summary.

> **Attribution & licensing.** Distilled from Marc Kohlbrugge's "37signals Rails Patterns" analysis and the community [37signals-skills](https://github.com/marckohlbrugge/37signals-skills) project — analysis and commentary under **MIT**. Code examples originate from 37signals' open-source [Fizzy](https://github.com/basecamp/fizzy) codebase, licensed under the [**O'Saasy License**](https://osaasy.dev) — review it before reusing snippets in a project. This is LLM-assisted analysis of public code; verify against the real source before relying on it.
>
> Out of scope here (covered elsewhere): **Stimulus controllers** → use the `better-stimulus` skill; **CSS architecture** → not a concern of this simplifier. **Naming conventions** and the **Turbo Stream response** shape live in `../SKILL.md`.

---

## The Stack: What to Avoid

The most simplify-relevant part of the stack is what 37signals *doesn't* reach for. When you find one of these in recently-changed code, that's a signal to compress toward vanilla Rails:

| Gem in the code | Vanilla-Rails replacement |
|-----------------|---------------------------|
| `devise` | ~150 lines of custom auth (see below) |
| `pundit` / `cancancan` | Authorization methods on models |
| `dry-rb` gems | Plain Ruby / Active Record |
| `interactor` / `command` | Rich model methods + concerns |
| `view_component` | ERB partials |
| `sidekiq` + `redis` | Solid Queue / Solid Cache / Solid Cable |
| `elasticsearch` | Custom scopes / SQL search |
| `graphql` | REST + Turbo |
| `rspec` + factories | Minitest + fixtures |

Their baseline is small: the Hotwire stack (`turbo-rails`, `stimulus-rails`, `importmap-rails`, `propshaft`), the Solid trio, and a few focused gems (`bcrypt`, `rqrcode`, `redcarpet`).

---

## Routing: Everything is CRUD

Every action maps to a CRUD verb. When something doesn't fit, **create a new resource** instead of a custom action.

```ruby
# ❌ BAD: custom actions on an existing resource
resources :cards do
  post :close
  post :reopen
  post :archive
end

# ✅ GOOD: a singular resource per state change (POST creates, DELETE reverses)
resources :cards do
  scope module: :cards do
    resource :closure         # close / reopen
    resource :goldness        # gild / ungild
    resource :not_now         # postpone / resume
    resource :pin             # pin / unpin
    resource :watch           # subscribe / unsubscribe

    resources :assignments
    resources :comments do
      resources :reactions
    end
  end
end
```

Use `resolve` so `polymorphic_url` works for nested/anchored records:

```ruby
resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end
```

---

## Controllers: Thin, With a Minimal Base

Controllers orchestrate; models hold the logic. Each state-change controller is a CRUD pair over one resource:

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close            # all logic in the model
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.reopen
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

Keep `ApplicationController` small — compose behavior from concerns:

```ruby
class ApplicationController < ActionController::Base
  include Authentication, Authorization
  include CurrentRequest, CurrentTimezone, SetPlatform
  include TurboFlash

  etag { "v1" }          # bump to bust all caches on deploy
  allow_browser versions: :modern
end
```

**Authorization: the controller checks, the model defines.** No Pundit/CanCanCan.

```ruby
class CardsController < ApplicationController
  before_action :ensure_permission_to_administer_card, only: :destroy

  private
    def ensure_permission_to_administer_card
      head :forbidden unless Current.user.can_administer_card?(@card)
    end
end

class User < ApplicationRecord
  def can_administer_card?(card)
    admin? || card.creator == self
  end
end
```

---

## Controller Concerns Catalog

Shared controller behavior lives in small, focused concerns. Common ones from Fizzy:

**Resource scoping** — set the tenant-scoped record and share a render helper:

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        [@card, :card_container],
        partial: "cards/container", method: :morph,
        locals: { card: @card.reload }
      )
    end
end
```

**Request context** — capture per-request globals into `Current`:

```ruby
module CurrentRequest
  extend ActiveSupport::Concern
  included do
    before_action do
      Current.http_method = request.method
      Current.request_id  = request.uuid
      Current.user_agent  = request.user_agent
      Current.ip_address  = request.ip
    end
  end
end
```

**Timezone** — set the zone per request and fold it into the ETag so cached pages vary by zone:

```ruby
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

**Turbo flash** — a helper to render a flash into a Turbo Stream:

```ruby
module TurboFlash
  extend ActiveSupport::Concern
  included do
    helper_method :turbo_stream_flash
  end

  private
    def turbo_stream_flash(**flash_options)
      turbo_stream.replace(:flash, partial: "layouts/shared/flash", locals: { flash: flash_options })
    end
end
```

---

## Model Concerns: Self-Contained Behavior

Each concern bundles its associations, scopes, and methods — everything the trait needs:

```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
    scope :closed, -> { joins(:closure) }
    scope :open,   -> { where.missing(:closure) }
  end

  def closed? = closure.present?
  def open?   = !closed?

  def close(user: Current.user)
    return if closed?
    transaction do
      create_closure! user: user
      track_event :closed, creator: user
    end
  end

  def reopen(user: Current.user)
    return unless closed?
    transaction do
      closure&.destroy
      track_event :reopened, creator: user
    end
  end
end
```

A rich model composes many such traits:

```ruby
class Card < ApplicationRecord
  include Assignable, Closeable, Eventable, Golden,
          Pinnable, Postponable, Readable, Searchable,
          Taggable, Watchable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :comments, dependent: :destroy
  has_one_attached :image
  has_rich_text :description
end
```

**File organization** — model-specific concerns, state records, and POROs nest under the model:

```
app/models/
├── card.rb
├── card/
│   ├── closeable.rb              # concern (behavior)
│   ├── goldness.rb               # ActiveRecord (state record)
│   ├── eventable.rb              # concern
│   └── eventable/
│       └── system_commenter.rb   # PORO
```

---

## State as Records, Not Booleans

Model state as a separate record so you capture *who*, *when*, and *why* for free. (Rule summary in `../SKILL.md`; the real Fizzy examples:)

```ruby
class Closure < ApplicationRecord            # when + who closed a card
  belongs_to :card, touch: true
  belongs_to :user, optional: true
end

class Card::Goldness < ApplicationRecord     # marked important
  belongs_to :card, touch: true
end

class Card::NotNow < ApplicationRecord        # postponed
  belongs_to :card, touch: true
  belongs_to :user, optional: true
end

class Board::Publication < ApplicationRecord  # published publicly
  belongs_to :board
  has_secure_token :key                       # the public URL key
end
```

Query with `joins(:closure)` / `where.missing(:closure)` instead of `where(closed: …)`, and render rich UI ("Closed 2 hours ago by David").

---

## Authentication Without Devise

Auth is ~150 lines of a plain concern — no gem. The shape:

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
    end
  end

  private
    def authenticated? = Current.identity.present?

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      if session = Session.find_signed(cookies.signed[:session_token])
        set_current_session session
      end
    end

    def set_current_session(session)
      Current.session = session
      cookies.signed.permanent[:session_token] = {
        value: session.signed_id, httponly: true, same_site: :lax
      }
    end
end
```

Passwordless entry is a short-lived, single-use `MagicLink` record — a numeric code with an expiry, consumed on use:

```ruby
class MagicLink < ApplicationRecord
  CODE_LENGTH = 6
  EXPIRATION_TIME = 15.minutes

  belongs_to :identity
  scope :active, -> { where(expires_at: Time.current...) }

  before_validation :generate_code, :set_expiration, on: :create

  def self.consume(code)
    active.find_by(code: Code.sanitize(code))&.consume
  end

  def consume
    destroy
    self
  end

  private
    def generate_code
      self.code = SecureRandom.random_number(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, "0")
    end

    def set_expiration
      self.expires_at = EXPIRATION_TIME.from_now
    end
end
```

---

## CurrentAttributes

`Current` holds request context, with cascading setters that derive related state:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
  attribute :http_method, :request_id, :user_agent, :ip_address, :referrer

  def session=(value)
    super
    self.identity = value.identity if value.present?
  end

  def identity=(identity)
    super
    self.user = identity.users.find_by(account: account) if identity.present?
  end
end
```

Then models default associations to it declaratively:

```ruby
class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

---

## Background Jobs: Shallow Jobs, Rich Models

Jobs are one-liners that delegate to the model — the logic stays testable and reusable:

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable)
    notifiable.notify_recipients
  end
end
```

Pair a `_later` (enqueue) with a `_now` (do it) so callers choose sync vs async:

```ruby
module Card::Readable
  def mark_as_read_later(user:)
    MarkCardAsReadJob.perform_later(self, user)
  end

  def mark_as_read_now(user:)
    readings.find_or_create_by!(user: user).touch
  end
end
```

Recurring work is declarative via Solid Queue's `config/recurring.yml`:

```yaml
production:
  deliver_bundled_notifications:
    command: "Notification::Bundle.deliver_all_later"
    schedule: every 30 minutes
  auto_postpone_all_due:
    command: "Card.auto_postpone_all_due"
    schedule: every hour at minute 50
```

---

## Testing: Minitest + Fixtures

Test the real thing as a black box. (Time-freezing guidance for date-sensitive tests is in `../SKILL.md`.)

```ruby
class CardTest < ActiveSupport::TestCase
  setup { Current.session = sessions(:david) }

  test "closed scope" do
    assert_equal [cards(:shipping)], Card.closed
  end
end
```

Integration tests exercise the controller through real HTTP, asserting the state change:

```ruby
class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as :kevin }

  test "create closes the card" do
    card = cards(:logo)
    assert_changes -> { card.reload.closed? }, from: false, to: true do
      post card_closure_path(card), as: :turbo_stream
    end
  end

  test "destroy reopens as JSON" do
    delete card_closure_path(cards(:shipping)), as: :json
    assert_response :no_content
  end
end
```

Fixtures — not factories — provide fast, realistic, referenced-by-name data:

```yaml
# test/fixtures/cards.yml
logo:
  account: 37s
  board: writebook
  creator: david
  title: "Logo Design"
  number: 1
```

---

## HTTP Caching

Lean on conditional GETs. `fresh_when` renders `304 Not Modified` when nothing changed:

```ruby
class Cards::AssignmentsController < ApplicationController
  def new
    @users = @board.users.active.alphabetically
    fresh_when etag: [@users, @card.assignees]
  end
end
```

Compose ETags globally (`etag { "v1" }` — bump to bust everything on deploy) and per-concern (`etag { timezone_from_cookie }`) so every dimension that affects output participates.

---

## Database Patterns

- **Defaults via lambdas** — derive belongs-to defaults instead of assigning in the controller:

  ```ruby
  belongs_to :account, default: -> { board.account }
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  ```

- **Carry `account_id` on every model** — each record derives its tenant, keeping queries scopeable end-to-end.
- **`touch: true`** on child `belongs_to` so parent `updated_at` (and its caches) invalidate automatically:

  ```ruby
  class Closure < ApplicationRecord
    belongs_to :card, touch: true
  end
  ```

---

## PORO Patterns

When a model's facade delegates real work, the collaborators are plain Ruby objects nested under the model. Two common shapes:

**Presentation logic** — build HTML/plain-text without leaking it into the model or view:

```ruby
class Event::Description
  include ActionView::Helpers::TagHelper

  def initialize(event, user)
    @event, @user = event, user
  end

  def to_html
    action_sentence(creator_tag, card_title_tag).html_safe
  end

  private
    def action_sentence(creator, card_title)
      case @event.action
      when "card_closed"   then %(#{creator} moved #{card_title} to "Done")
      when "card_reopened" then "#{creator} reopened #{card_title}"
      end
    end
end
```

**Complex operations** — a cohesive object that does one job the model delegates to:

```ruby
class Card::Eventable::SystemCommenter
  def initialize(card, event)
    @card, @event = card, event
  end

  def comment
    return unless comment_body.present?
    @card.comments.create!(creator: @card.account.system_user, body: comment_body)
  end
end
```

---

## Sources

- [Original "37signals Rails Patterns" gist](https://gist.github.com/marckohlbrugge/d363fb90c89f71bd0c816d24d7642aca) and the [37signals-skills](https://github.com/marckohlbrugge/37signals-skills) project — Marc Kohlbrugge (MIT)
- [Fizzy source](https://github.com/basecamp/fizzy) · [Campfire source](https://github.com/basecamp/once-campfire) — 37signals (code under the O'Saasy License)
- [Rails Doctrine](https://rubyonrails.org/doctrine)
