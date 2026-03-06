# Document Templates

Templates for all SDD documents. Keep them concise — they're read by AI agents and should be scannable.

---

## progress.yml

```yaml
project: [name]
updated: [ISO-8601]

product_planning:
  status: not_started  # not_started | in_progress | complete

current_spec:
  name: null               # e.g., 2025-03-06-appointment-booking
  status: null             # shaping | tasks | implementing | complete

completed_specs: []
```

---

## product/mission.md

```markdown
# [App Name] — Mission

## Problem
[One paragraph: what pain exists, who feels it, why current solutions fail]

## Users

**[Primary User]** — [brief description, demographics, context]
**[Secondary User]** — [brief description]

## Solution
[What we build and why it's different. One paragraph.]

## Differentiators
- [Differentiator 1]
- [Differentiator 2]
```

---

## product/roadmap.md

```markdown
# Roadmap

## v1 — MVP

| Feature | Effort | Priority |
|---------|--------|----------|
| [Feature 1] | S | Must |
| [Feature 2] | M | Must |
| [Feature 3] | S | Should |

Effort: XS (< 1 day) / S (1-2 days) / M (3-5 days) / L (1-2 weeks) / XL (2+ weeks)

## v2 — Post-Launch
- [Future feature 1]
- [Future feature 2]
```

---

## product/tech-stack.md

```markdown
# Tech Stack

Standard Rails 8 stack (see `standards/global/rails-stack.md`).

## Deviations / Additional Choices

- **Auth:** [Rails 8 built-in | phone OTP via WhatsApp]
- **Payments:** [Stripe | Conekta | MercadoPago]
- **Storage:** [Active Storage + S3 | local]
- **Email:** [Action Mailer + Postmark | Resend]
- **SMS/WhatsApp:** [Twilio | Meta Cloud API]

## i18n
- Default locale: [es | en]
- Supported: [es, en]
```

---

## specs/[date-name]/spec.md

```markdown
# [Feature Name]

## Goal
[One sentence: what this feature enables the user to do]

## User Stories

- As a [user], I want to [action] so that [outcome]
- As a [user], I want to [action] so that [outcome]

## Requirements

### Functional
- [Requirement 1]
- [Requirement 2]

### Business Rules
- [Rule: e.g., "A provider can have at most 1 appointment per 30-min slot"]

## Visual Design

[Link to mockup OR brief layout description]

Example:
- Page: list of [items] with [columns], filtered by [state]
- Empty state: "[message]"
- Actions: [button labels and what they do]
- On success: redirect to [path], notice "[message]"

## Out of Scope (v1)

- [Thing we're NOT building yet]
- [Another exclusion]
```

---

## specs/[date-name]/references.md

Documents existing code the implementer should follow or reuse. Written during Shape phase.

```markdown
# References: [Feature Name]

## Models to Extend or Follow

- `app/models/appointment.rb` — status pattern (string column + named methods)
- `app/models/concerns/publishable.rb` — concern structure to follow

## Controllers to Follow

- `app/controllers/appointments_controller.rb` — standard CRUD structure, authorization pattern
- `app/controllers/appointments/confirmations_controller.rb` — sub-resource pattern example

## Views / Partials to Reuse

- `app/views/shared/_empty_state.html.erb` — use for empty list states
- `app/views/shared/_status_badge.html.erb` — use for status display

## Stimulus Controllers to Reference

- `app/javascript/controllers/date_picker_controller.js` — value + target pattern to follow

## Notes

[Any other important context about existing code]
```

---

## specs/[date-name]/standards.md

Created during Shape phase by copying the content of each applicable standard. Makes the spec folder **self-contained** — Claude Code needs nothing outside this folder to implement correctly.

```markdown
# Standards: [Feature Name]

The following standards apply to this feature. Copied from `sdd/standards/` at shape time.

---

## global/rails-stack

[full content of sdd/standards/global/rails-stack.md]

---

## backend/rails-patterns

[full content of sdd/standards/backend/rails-patterns.md]

---

## frontend/hotwire

[full content of sdd/standards/frontend/hotwire.md]

---

## frontend/components

[full content of sdd/standards/frontend/components.md]

---

## testing/minitest

[full content of sdd/standards/testing/minitest.md]
```

---

## specs/[date-name]/tasks.md

Contains the full task breakdown. Each group has a **self-contained Claude Code prompt** — everything an agent needs to execute that group is embedded inline.

```markdown
# Tasks: [Feature Name]

**Spec:** `sdd/specs/[folder]/spec.md`
**Total tests:** ~[N]

---

## Group 1: Database

### Tasks
- [ ] `bin/rails g migration Create[Model] [columns]`
- [ ] Add model validations and associations to `app/models/[model].rb`
- [ ] Add `[method]` business logic to model
- [ ] Create fixtures: `test/fixtures/[models].yml`

### Tests to write first
- [ ] `[Model]Test#test_[scenario]`
- [ ] `[Model]Test#test_[scenario]`

### Verify
`source ~/.zshrc && bin/rails test test/models/[model]_test.rb`

---
<!-- CLAUDE CODE PROMPT: GROUP 1 -->
<!-- Copy everything below this line into a Claude Code session -->

## PROMPT — Group 1: Database

You are implementing **[Feature Name]** for a Rails 8 application.

### Your tasks

- [ ] `bin/rails g migration Create[Model] [columns]`
- [ ] Add model validations and associations
- [ ] Add `[method]` business logic method
- [ ] Create test fixtures

### Tests to write first (write these before implementing)

```ruby
# test/models/[model]_test.rb
class [Model]Test < ActiveSupport::TestCase
  test "[scenario description]" do
    # ...
  end
end
```

### Reference code to follow

[Copy relevant sections from references.md]

### Standards

[Copy full content of standards.md here — all applicable standards embedded]

### Done when

`source ~/.zshrc && bin/rails test test/models/[model]_test.rb` passes
<!-- END PROMPT -->

---

## Group 2: Backend

### Tasks
- [ ] Add routes: `resources :[resource]` (CRUD only, sub-resources for state changes)
- [ ] Create `app/controllers/[resource]_controller.rb`
- [ ] Implement [actions]

### Tests to write first
- [ ] `[Controller]Test#test_[action]_[scenario]`
- [ ] `[Controller]Test#test_[action]_[scenario]`

### Verify
`source ~/.zshrc && bin/rails test test/controllers/[name]_controller_test.rb`

---
<!-- CLAUDE CODE PROMPT: GROUP 2 -->

## PROMPT — Group 2: Backend

You are implementing **[Feature Name]** for a Rails 8 application.
Group 1 (Database) is already complete.

### Your tasks

[task list]

### Tests to write first

[test stubs]

### Reference code to follow

[relevant reference sections]

### Standards

[Copy full content of standards.md — backend/rails-patterns + testing/minitest at minimum]

### Done when

`source ~/.zshrc && bin/rails test test/controllers/[name]_test.rb` passes
<!-- END PROMPT -->

---

## Group 3: Frontend

### Tasks
- [ ] Create views using maquina_components (use `maquina-ui-standards` skill)
- [ ] Turbo/Hotwire behavior (morph, frames, or streams as appropriate)
- [ ] Stimulus controller if needed (use `better-stimulus` skill)
- [ ] i18n: `config/locales/es.yml` + `config/locales/en.yml`

### Tests to write first
- [ ] System test: happy path end-to-end

### Verify
`source ~/.zshrc && bin/rails test test/system/[name]_test.rb`

---
<!-- CLAUDE CODE PROMPT: GROUP 3 -->

## PROMPT — Group 3: Frontend

You are implementing **[Feature Name]** for a Rails 8 application.
Groups 1 and 2 are already complete.

### Your tasks

[task list]

### Required skills
- Use the `maquina-ui-standards` skill for all component work
- Use the `better-stimulus` skill before writing any Stimulus controller

### Visual design

[Description or mockup reference from spec.md]

### Reference code to follow

[relevant reference sections]

### Standards

[Copy full content of standards.md — frontend/hotwire + frontend/components + testing/minitest]

### Done when

`source ~/.zshrc && bin/rails test test/system/[name]_test.rb` passes
<!-- END PROMPT -->

---

## Group 4: Integration

### Tasks
- [ ] Full happy path integration test
- [ ] [Any critical edge case]

### Verify
`source ~/.zshrc && bin/rails test`

---
<!-- CLAUDE CODE PROMPT: GROUP 4 -->

## PROMPT — Group 4: Integration

You are finalizing **[Feature Name]** for a Rails 8 application.
Groups 1–3 are complete.

### Your tasks

Write integration tests for the full happy path.

### What "done" looks like (from spec.md)

[Copy goal + user stories from spec.md]

### Standards

[Copy testing/minitest from standards.md]

### Done when

`source ~/.zshrc && bin/rails test` passes with all [N] new tests
<!-- END PROMPT -->

---

## Progress

| Group | Status | Tests |
|-------|--------|-------|
| 1. Database | ⬜ | 0/[n] |
| 2. Backend | ⬜ | 0/[n] |
| 3. Frontend | ⬜ | 0/[n] |
| 4. Integration | ⬜ | 0/[n] |

Legend: ⬜ Not started · 🔄 In progress · ✅ Complete
```
