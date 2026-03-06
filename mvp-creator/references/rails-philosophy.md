# Rails Philosophy

> *The Jorge Manrubia approach to building Rails applications the 37signals way*

**Related:** [rails-implementation-patterns.md](rails-implementation-patterns.md) for the "how"

---

## Core Philosophy: Embrace Vanilla Rails

> "If you have the luxury of starting a new Rails app today, here's our recommendation: go vanilla."

Rails, used as intended, provides everything needed to build and maintain large, complex applications.

---

## 1. The Dependency Philosophy

### Fight Hard Against Dependencies

**Ruby Dependencies:**
- Keep the Gemfile close to what Rails generates
- Every new dependency is future debt—upgrades, security patches, compatibility
- Ask: "Can Rails do this already?" before reaching for a gem

**JavaScript Dependencies:**
- Fight *even harder* before adding JavaScript dependencies
- You don't need React or any front-end framework
- You don't need a JSON API to feed front-end frameworks
- Hotwire is "fantastic, pragmatic, and ridiculously productive"

**The #nobuild Philosophy:**
- Use import maps instead of bundling JavaScript
- Use Propshaft and serve CSS directly

### The Recommended Stack (Rails 8)

```
✓ Hotwire (Turbo + Stimulus)
✓ Hotwire Native for mobile
✓ ERB templates and view helpers
✓ Import maps (no bundler)
✓ Propshaft for assets
✓ solid_cache for caching
✓ solid_queue for background jobs
✓ solid_cable for Action Cable
✓ Minitest with fixtures
✓ PWA support
✓ Kamal for deployment
```

---

## 2. Application Architecture: Rich Domain Models

### No Service Layer Needed

37signals builds complex applications (Basecamp, HEY) without:
- Service objects/classes
- Use case interactors
- Repositories
- Commands/Actions patterns

### Controllers Access Models Directly

For simple scenarios, plain CRUD:

```ruby
class BoostsController < ApplicationController
  def create
    @boost = @boostable.boosts.create!(content: params[:boost][:content])
  end
end
```

For complex operations, controllers invoke methods on domain models:

```ruby
class Boxes::DesignationsController < ApplicationController
  def create
    @contact.designate_to(@box)
  end
end
```

### Rich vs. Anemic Domain Models

```ruby
# Good: Natural, domain-oriented API
recording.incinerate
recording.copy_to(destination_bucket)

# Not preferred: Service/procedural style
Recording::IncinerationService.execute(recording)
RecordingService.new(recording).incinerate
```

### Hiding Complexity Behind Simple APIs

Rich models can have large APIs while delegating complex work internally:

```ruby
module Recording::Incineratable
  def incinerate
    Incineration.new(self).run  # Delegates to internal class
  end
end
```

This isn't a Single Responsibility violation—the model is a **facade** offering the API but delegating implementation.

---

## 3. Concerns: The Organization Tool

### Two Types of Concerns

**1. Common concerns** (shared across models):
```
app/models/concerns/timestampable.rb
```

**2. Model-specific concerns** (organize a single model):
```
app/models/recording/completable.rb
app/models/recording/copyable.rb
app/models/recording/incineratable.rb
```

### The Key Principle: Cohesion

Concerns must have **"has trait" or "acts as" semantics**:

```ruby
class User < ApplicationRecord
  include Examiner  # User "acts as" examiner
end

module User::Examiner
  extend ActiveSupport::Concern

  included do
    has_many :clearances, foreign_key: "examiner_id"
  end

  def approve(contacts)
    # ...
  end
end
```

### What Concerns Are NOT

- Arbitrary containers to split large models
- A replacement for proper object-oriented design
- An excuse to avoid creating additional classes when complexity warrants it

---

## 4. Active Record: Nice and Blended

### Embrace the Pattern

> "Active Record restates the traditional question of how to separate persistence from domain logic: what if you don't have to?"

### Use All the Features

**Associations** (extensively):
```ruby
module Topic::Entries
  included do
    has_many :entries, dependent: :destroy
    has_many :addressed_contacts, -> { distinct }, through: :entries
  end
end
```

**Single Table Inheritance:**
```ruby
class Box < ApplicationRecord; end
class Box::Imbox < Box; end
class Box::Trailbox < Box; end
```

**Delegated Types:**
```ruby
class Contact < ApplicationRecord
  delegated_type :contactable, types: %w[User Person Service]
end
```

---

## 5. Sharp Knives: Callbacks and Globals

### Callbacks Are Fine

```ruby
class Recording < ApplicationRecord
  after_create_commit :process_later

  private
    def process_later
      Recording::ProcessingJob.perform_later(self)
    end
end
```

### CurrentAttributes Pattern

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account, :request_id
end

# In controller concern
Current.user = authenticate_user
Current.account = Current.user.account

# In model
belongs_to :creator, default: -> { Current.user }
```

---

## 6. Testing Philosophy

### Test at the End, Not First

> "Writing tests first works great when you know exactly what you're building. But when you're still exploring, writing tests first can slow you down."

### Integration Over Unit Tests

- Focus on system tests for critical user flows
- Unit tests for complex business logic
- Fixtures over factories (faster, simpler)
- Minitest over RSpec (less magic)

### Pending Tests

Don't delete failing tests—mark them pending:

```ruby
test "complex feature" do
  skip "Pending: needs refactoring"
end
```

---

## 7. Fixed Time, Variable Scope

### The Basecamp Approach

> "Stop thinking about what features you could add... Start thinking about what features you could cut."

- Time is fixed (the deadline)
- Scope is variable (features can be cut)
- Ship something working, then iterate

### The Gift of Constraints

Constraints force good decisions:
- Limited time → focus on essentials
- Limited budget → creative solutions
- Limited team → simpler architecture

---

## 8. Fractal Code

### Good Code is Fractal

> "Good code is a fractal: you observe the same qualities repeated at different levels of abstraction."

Four essential qualities at every level:

1. **Domain-Driven** — speak the domain language
2. **Encapsulation** — expose clear interfaces, hide details
3. **Cohesiveness** — do one thing from the caller's view
4. **Symmetry** — operate at the same level of abstraction

### Example: Layered Abstraction

```ruby
# Level 1 - Model
class Event < ApplicationRecord
  include Relaying
end

# Level 2 - Concern
module Event::Relaying
  def relay_now
    relay_to_timeline
    relay_to_webhooks
    relay_to_readers
  end
end

# Level 3 - Delegation
def relay_to_timeline
  Timeline::Relayer.new(self).relay
end

# Level 4 - Implementation
class Timeline::Relayer
  def relay
    record
    broadcast
  end
end
```

At each level: clear names, one responsibility, details hidden, symmetry between siblings.

---

## 9. Domain-Driven Boldness

### Naming Matters

> "Erecting a tombstone when deceasing a person was so much better than replacing a person with a placeholder when removing it."

Don't be aseptic—code can have personality:

```ruby
# Users "examine" clearance "petitions"
# Contacts are "petitioners", not requesters
# Users are "examiners", not reviewers

class Contact < ApplicationRecord
  include Petitioner
end

module Contact::Petitioner
  included do
    has_many :clearance_petitions, foreign_key: "petitioner_id"
  end
end
```

---

## 10. Design Principles Summary

### No Silver Buckets

> "The suggestion that mixing buckets is the root of all your software quality problems is common in our industry."

Separating code into specific "buckets" (services, actions, repositories) doesn't automatically produce better software:

> "If you struggle to write good controller actions, you will struggle to create good action objects."

### No One Paradigm

Don't be dogmatic. Use:
- Inheritance when appropriate
- Composition when appropriate
- Callbacks when appropriate
- Concerns when appropriate
- Additional classes when appropriate

### Always Ask: "Compared to What?"

The callback approach might have drawbacks, but what's the alternative? Often, the "pure" solution has worse tradeoffs.

---

## Key Takeaways

1. **Go vanilla** — Rails provides everything you need
2. **Fight dependencies** — Each one is future debt
3. **Rich domain models** — Not service layers
4. **Concerns for organization** — With proper cohesion
5. **Embrace Active Record** — Blending persistence and domain logic is a feature
6. **Use sharp knives** — Callbacks, CurrentAttributes, globals—when appropriate
7. **Test the real thing** — At the end, not first
8. **Fixed time, variable scope** — The key to shipping
9. **Domain-driven boldness** — Don't be aseptic
10. **Fractal code** — Same qualities at every level

---

## Resources

- [Jorge Manrubia's Blog](https://world.hey.com/jorge)
- [37signals Dev Blog](https://dev.37signals.com)
- [Rails Doctrine](https://rubyonrails.org/doctrine)
- [Shape Up](https://basecamp.com/shapeup)
