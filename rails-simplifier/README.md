# Rails Claude Code Plugins

A collection of Claude Code plugins for Ruby on Rails development, following 37signals patterns and the One Person Framework philosophy.

## Philosophy

### The One Person Framework

DHH introduced this concept in December 2021:

> "A toolkit so powerful that it allows a single individual to create modern applications upon which they might build a competitive business."

Rails 8 delivers this through: Solid Queue/Cache/Cable (no Redis), built-in auth (no Devise), Kamal (no Kubernetes), and Hotwire (no React).

### Conceptual Compression

From DHH's RailsConf 2018 keynote:

> "Like a video codec that throws away irrelevant details such that you might download the film in real-time rather than buffer for an hour."

**Definition:** 80% of the value with 20% of the effort.

### Vanilla Rails is Plenty

> "If you have the luxury of starting a new Rails app today, go vanilla." — Jorge Manrubia, 37signals

---

## Installation

```bash
# Add the marketplace
/plugin marketplace add maquina/rails-claude-code

# Install individual plugins
/plugin install rails-simplifier@rails
/plugin install rails-upgrade-assistant@rails
/plugin install maquina-ui-standards@rails
```

---

## Plugins

### 1. rails-simplifier

**Category:** Productivity

A code simplification agent that refines Ruby on Rails code for clarity, consistency, and maintainability while preserving functionality.

**Features:**
- Applies 37signals conventions and patterns
- Converts custom controller actions to CRUD resources
- Identifies service objects that should be model methods
- Suggests concerns for horizontal behavior extraction
- Converts boolean columns to state records
- Enforces `Time.current` over `Time.now`
- Identifies N+1 queries and missing `includes`
- Flags hardcoded strings that should be I18n

**Usage:**
```
> Review recent changes using the rails-simplifier agent
> Use rails-simplifier to review the bookings controller
```

**What it looks for:**

| Pattern | Simplification |
|---------|---------------|
| Service objects | Rich model methods + concerns |
| Custom controller actions | CRUD resources |
| Boolean state columns | State records (`has_one :closure`) |
| `Time.now` | `Time.current` |
| Date tests without `travel_to` | Freeze time to fixture |

---

### 2. rails-upgrade-assistant

**Category:** Development

Analyzes Rails applications and generates comprehensive upgrade reports for Rails 7.0 through 8.1.1.

**Features:**
- Sequential upgrade planning (no version skipping)
- Breaking changes detection scripts
- Deprecation timeline tracking
- Multi-hop upgrade strategy
- `app:update` preview reports
- Testing checklists

**Supported Upgrade Paths:**
- 7.0 → 7.1
- 7.1 → 7.2
- 7.2 → 8.0
- 8.0 → 8.1

**Usage:**
```
> Help me upgrade from Rails 7.2 to 8.0
> Generate a detection script for Rails 8.0 upgrade
> What breaking changes are in Rails 8.1?
```

**Workflow:**
1. Claude generates detection script for your specific upgrade
2. You run the script in your project (`./detect_rails_X_issues.sh`)
3. Share findings with Claude
4. Claude generates comprehensive upgrade report with OLD→NEW code examples

**Benefits:**
- ⏱️ Saves 2-3 hours per upgrade
- 🎯 90%+ accuracy in finding breaking changes
- 📋 File:line references for every issue
- 📊 50% faster upgrades overall

---

### 3. maquina-ui-standards

**Category:** Development

Build consistent, accessible UIs in Rails using maquina_components — ERB partials styled with Tailwind CSS 4, inspired by shadcn/ui.

**Features:**
- Component catalog (Button, Card, Input, Select, Dialog, etc.)
- Form patterns with validation
- Layout patterns (Dashboard, Sidebar, Page headers)
- Turbo integration patterns
- Spec checklist for UI review

**Usage:**
```
> Create a booking form using maquina components
> Build a dashboard layout with sidebar navigation
> Review this view for UI consistency
```

**Component Example:**
```erb
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: "Appointments" %>
    <%= render "components/card/description", text: "Manage your schedule" %>
  <% end %>
  <%= render "components/card/content" do %>
    <!-- Content here -->
  <% end %>
<% end %>
```

**References included:**
- Component catalog (all available components)
- Form patterns (validation, error handling)
- Layout patterns (pages, dashboards)
- Turbo integration (frames, streams)
- Spec checklist (accessibility, consistency)

---

## Quick Reference

| Plugin | Use When |
|--------|----------|
| `rails-simplifier` | After coding session, reviewing code quality |
| `rails-upgrade-assistant` | Planning or executing Rails version upgrades |
| `maquina-ui-standards` | Building views, forms, or UI components |

---

## Team Installation

Add to your project's `.claude/settings.json` for automatic installation:

```json
{
  "extraKnownMarketplaces": {
    "rails": {
      "source": {
        "source": "github",
        "repo": "maquina/rails-claude-code"
      }
    }
  },
  "enabledPlugins": [
    "rails-simplifier@rails",
    "rails-upgrade-assistant@rails",
    "maquina-ui-standards@rails"
  ]
}
```

---

## Resources

- [37signals Rails Patterns](https://gist.github.com/marckohlbrugge/d363fb90c89f71bd0c816d24d7642aca)
- [Jorge Manrubia's Blog](https://world.hey.com/jorge)
- [Rails Doctrine](https://rubyonrails.org/doctrine)
- [37signals Dev Blog](https://dev.37signals.com)
- [Maquina Components](https://github.com/maquina/maquina_components)
- [DHH's RailsConf 2018 Keynote](https://www.youtube.com/watch?v=zKyv-IGvgGE)

---

## License

MIT

---

## Author

**Mario Alberto Chávez**  
[Maquina](https://maquina.io) · [@mac](https://x.com/mac)
