# The Vanilla Rails Philosophy (the *why*)

The rationale behind every refinement this skill applies. Distilled from Jorge Manrubia's writing (world.hey.com/jorge, dev.37signals.com), DHH's One Person Framework, and the Rails Doctrine. This is the design reasoning; for copy-paste implementations see `patterns.md`, and for the actionable rules see `../SKILL.md`.

---

## The One Person Framework

DHH introduced this in December 2021 with Rails 7:

> "A toolkit so powerful that it allows a single individual to create modern applications upon which they might build a competitive business. The way it used to be."

**The problem:** Web development fragmented into narrow specializations. The conventional path (React + Node + Redis + Kubernetes) demands learning so many tools that "you might well die of dysentery before you ever get to your destination."

**The solution:** Rails as "the wormhole that folds the time-learning-shipping-continuum… giving the individual rebel a fighting chance against The Empire." Rails 8 delivers it through:

- **Solid Queue** — background jobs without Redis
- **Solid Cache** — caching without Redis/Memcached
- **Solid Cable** — WebSockets without Redis
- **Built-in authentication** — ~150 lines, no Devise
- **Kamal 2 + Thruster** — deployment without Kubernetes/PaaS
- **Hotwire** — rich UIs without React/Vue build pipelines

**The test:** Can one person understand this codebase in an afternoon? If not, simplify.

---

## Conceptual Compression

From DHH's RailsConf 2018 keynote — the engine powering the One Person Framework:

> "Like a video codec that throws away irrelevant details such that you might download the film in real-time rather than buffer for an hour."

**Definition:** simplify a concept so a developer gets 80% of the value with 20% of the effort. Basecamp 3 has 42,000 lines of code with zero raw SQL statements — ActiveRecord compresses SQL so developers focus on the domain, not query optimization.

What gets compressed in Rails: ActiveRecord → SQL; Hotwire → frontend complexity; Solid Queue/Cache/Cable → infrastructure; Kamal → deployment; concerns → model organization; CRUD resources → controller actions.

**The warning:** "New concepts are being created rapidly, but in an absence of any corresponding surge in compression."

---

## Vanilla Rails is Plenty

> "If you have the luxury of starting a new Rails app today, here's our recommendation: go vanilla."

This rejects the common claim that "vanilla Rails can only get you so far." 37signals builds Basecamp and HEY without service objects, use-case interactors, repositories, data mappers, or command/action patterns.

### The recommended stack (Rails 8)

Hotwire (Turbo + Stimulus) · Hotwire Native for mobile · ERB templates and view helpers · import maps (no bundler) · Propshaft · solid_cache · solid_queue · solid_cable · Minitest with fixtures · PWA support · Kamal for deployment.

> "Your `importmap.rb` should import Turbo, Stimulus, your app controllers, and little else."

---

## Fight Hard Against Dependencies

Every dependency is future debt — upgrades, security patches, compatibility. Before reaching for a gem, ask: **"Can Rails do this already?"**

- **Ruby:** keep the Gemfile as close to what Rails generates as possible.
- **JavaScript:** fight *even harder*. You don't need React or any front-end framework; you don't need a JSON API to feed one. Hotwire is "fantastic, pragmatic, and ridiculously productive."
- **#nobuild:** use import maps instead of bundling; use Propshaft and serve CSS directly. "If you have 100 JavaScript files and 100 stylesheets, serve 200 standalone requests multiplexed over HTTP2. You will be delighted."

---

## Rich Domain Models, Not a Service Layer

Controllers access models directly. For simple cases, plain CRUD; for complex operations, controllers invoke domain methods on models:

```ruby
class Boxes::DesignationsController < ApplicationController
  def create
    @contact.designate_to(@box)
  end
end
```

The goal is **rich domain models** exposing natural, domain-oriented APIs (`recording.incinerate`, `recording.copy_to(bucket)`) rather than procedural service calls (`Recording::IncinerationService.execute(recording)`).

> "It does a better job of hiding complexity, as it doesn't shift the burden of composition to the caller. It feels more natural, like plain English. It feels more Ruby."

A rich model can have a large API while delegating the hard work to cohesive internal classes — this is a **facade**, not an SRP violation:

```ruby
module Recording::Incineratable
  def incinerate
    Incineration.new(self).run   # simple API, delegated implementation
  end
end
```

---

## Concerns: The Organization Tool

Concerns are not evil — 37signals has years of experience using them in large codebases. Two kinds:

- **Common concerns** shared across models — `app/models/concerns/timestampable.rb`
- **Model-specific concerns** organizing one model — `app/models/recording/completable.rb`

**The key principle is cohesion:** a concern must have *"has trait"* or *"acts as"* semantics.

```ruby
class User < ApplicationRecord
  include Examiner   # User "acts as" examiner of clearance petitions
end

module User::Examiner
  extend ActiveSupport::Concern
  included do
    has_many :clearances, foreign_key: "examiner_id"
  end
  def approve(contacts); end
end
```

**Concerns are NOT** arbitrary containers to split large models, a replacement for OO design, or an excuse to avoid creating a dedicated class when complexity warrants one. A good concern offers a simple API (`account.terminate`) while delegating complex operations to dedicated classes (`Purging`, `Incineration`).

---

## Active Record: Nice and Blended

> "Active Record restates the traditional question of how to separate persistence from domain logic: what if you don't have to?"

It works because it looks and feels like Ruby, answers real ORM needs, and enables encapsulation without ceremony. Use all of it:

- **Associations**, extensively (`has_many … through`, scoped associations)
- **Single Table Inheritance** — `class Box::Imbox < Box`
- **Delegated Types** — `delegated_type :contactable, types: %w[User Person Service]`
- **Serialized Attributes** — `serialize :schedule, RecurrenceSchedule`
- **Scopes** for complex queries — `scope :accessible_to, ->(contact) { … }`

---

## Sharp Knives: Globals, Callbacks, CurrentAttributes

> "Sacrificing purity for convenience is one of the Rails pillars."

**Callbacks** hook secondary/orthogonal concerns into the object lifecycle declaratively:

```ruby
included do
  after_create { create_bucket! account: account unless bucket.present? }
end
```

Use callbacks for simple, declarative, secondary concerns; use a **factory** instead when creation is a complex, multi-step operation the caller should be aware of.

**CurrentAttributes** capture request context declaratively:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :account, :person
end

class Project < ApplicationRecord
  belongs_to :creator, class_name: "Person", default: -> { Current.person }
end
```

Combined, callbacks + CurrentAttributes give automatic auditing (an `Event` created on `after_create`). For the exceptional case, `Event.suppress { … }` — "The key to using `.suppress` is exceptionality. You normally want the default behavior; exceptionally, you want to suppress it."

---

## Testing Philosophy

- **Write tests at the end.** "Most of the time, I write tests at the end… I don't practice TDD." The exception is when a test is the shortest feedback loop (common in infrastructure work).
- **Test the real thing.** Treat the subject as a black box: exercise the interface, check results — same approach for a class, a method, a web screen, or an API.
- **Avoid mock-heavy tests.** Building tiny fast tests by mocking slow dependencies has a bad cost/benefit.
- **System tests sparingly.** Their cost is huge (poor feedback loop, brittle, slow deploys) and they don't save you from manual testing. Reserve them for critical paths; don't write them systematically.
- **Minitest + fixtures.** The default — use it. Build a realistic fixture set as you cook the app.

---

## Domain-Driven Boldness

Don't be aseptic — give the domain personality. A key 37signals lesson: model with boldness.

> "I would have expected something like 'replacing a person with a placeholder when removing it', but 'erecting a tombstone' when 'deceasing a person' was so much better. It was more eloquent, clear, and concise… it had a boldness component, like personality or soul."

HEY's screening models this: users **examine** clearance **petitions**; contacts are **petitioners**, not requesters; users are **examiners**, not reviewers. "A petition is different from a request because it implies formality." **Start with plain text** — writing a plain-text description of a non-trivial model (with a dictionary as companion) is the favorite tool for finding this language.

---

## Fractal Code: Same Qualities at Every Level

> "Good code is a fractal: you observe the same qualities repeated at different levels of abstraction."

Four qualities to preserve at every level — model, concern, orchestration, delegation, implementation:

1. **Domain-Driven** — speak the domain of the problem
2. **Encapsulation** — expose clear interfaces, hide details
3. **Cohesiveness** — do one thing from the caller's point of view
4. **Symmetry** — operate at one level of abstraction, with sibling operations balanced (record/broadcast, relay/revoke)

> "The ability to make these journeys with ease on non-trivial systems is the number one quality in the code I like."

---

## Design Principles

**No Silver Buckets.** Separating code into specific "buckets" (services, actions, repositories) doesn't automatically produce better software. "If you struggle to write good controller actions, you will struggle to create good action objects. The pattern itself doesn't get you closer to the finish line." What you need is harder: "a well-designed system exposing a clear API to be exercised from the controller."

**No One Paradigm** (Rails Doctrine). Don't be dogmatic. Use inheritance, composition, callbacks, factories, concerns, or additional classes — each when appropriate.

**Compared to What?** Always ask it. A callback approach may have drawbacks — but the "pure" alternative often has worse tradeoffs.

**Difficult vs. Complex, and Erase-and-Rewind.** Software is both difficult and complex — a wicked problem you often can't fully understand until you've built something. Be willing to throw away code and rewrite. Sparks "find you with your hands dirty," not through pure contemplation.

---

## Sources

- Jorge Manrubia — [Blog](https://world.hey.com/jorge) · [Posts archive](https://www.jorgemanrubia.com/posts/)
- 37signals Dev — [Code I Like series](https://dev.37signals.com/series/code-i-like/), including [Good Concerns](https://dev.37signals.com/good-concerns/), [Vanilla Rails is Plenty](https://dev.37signals.com/vanilla-rails-is-plenty/), [Active Record, Nice and Blended](https://dev.37signals.com/active-record-nice-and-blended/), [Globals, Callbacks and Other Sacrileges](https://dev.37signals.com/globals-callbacks-and-other-sacrileges/)
- [No Silver Buckets](https://world.hey.com/jorge/no-silver-buckets-84d249d5) · [Compared to What?](https://dev.37signals.com/compared-to-what/) · [Systematic System Tests Considered Harmful](https://world.hey.com/jorge/systematic-system-tests-considered-harmful-867f22c8)
- [Rails Doctrine](https://rubyonrails.org/doctrine)
