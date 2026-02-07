# Rails Claude Code Plugins

A collection of Claude Code plugins for Ruby on Rails development.

## Installation

```bash
# Add the marketplace
/plugin marketplace add maquina-app/rails-claude-code

# Install individual plugins
/plugin install rails-simplifier@maquina
/plugin install rails-upgrade-assistant@maquina
/plugin install maquina-ui-standards@maquina
/plugin install recuerd0@maquina
```

---

## Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [rails-simplifier](#1-rails-simplifier) | Code quality following 37signals patterns | 1.0.0 |
| [rails-upgrade-assistant](#2-rails-upgrade-assistant) | Rails 7.0→8.1 upgrade planning | 1.0.0 |
| [maquina-ui-standards](#3-maquina-ui-standards) | UI components with maquina_components | 0.3.1.0 |
| [recuerd0](#4-recuerd0) | Knowledge management from AI conversations | 1.0.0 |

---

## 1. rails-simplifier

A code simplification agent that refines Ruby on Rails code following **37signals patterns** and the **One Person Framework** philosophy.

### Philosophy

**The One Person Framework** (DHH, December 2021):
> "A toolkit so powerful that it allows a single individual to create modern applications upon which they might build a competitive business."

**Conceptual Compression** (RailsConf 2018):
> "Like a video codec that throws away irrelevant details such that you might download the film in real-time."

**Vanilla Rails is Plenty** (Jorge Manrubia, 37signals):
> "If you have the luxury of starting a new Rails app today, go vanilla."

### What It Does

| Pattern | Simplification |
|---------|---------------|
| Service objects | Rich model methods + concerns |
| Custom controller actions | CRUD resources |
| Boolean state columns | State records (`has_one :closure`) |
| Fat controllers | Thin controllers, model methods |
| `Time.now` | `Time.current` |
| Hardcoded strings | I18n keys |
| N+1 queries | `includes` / `preload` |
| Date tests without `travel_to` | Freeze time to fixture |

### Usage

```
> Review recent changes using the rails-simplifier agent
> Use rails-simplifier to review the bookings controller
```

### Resources

- [37signals Rails Patterns](https://gist.github.com/marckohlbrugge/d363fb90c89f71bd0c816d24d7642aca)
- [Jorge Manrubia's Blog](https://world.hey.com/jorge)
- [Rails Doctrine](https://rubyonrails.org/doctrine)

---

## 2. rails-upgrade-assistant

A **unified, intelligent Rails upgrade skill** that helps you upgrade Ruby on Rails applications through any version from **7.0 to 8.1.1**. Built on official Rails CHANGELOGs and integrated with MCP tools for automatic project analysis.

### What It Does

- **Analyzes** your Rails project automatically using Rails MCP tools
- **Detects** your current version and target version
- **Plans** single-hop or multi-hop upgrade paths
- **Identifies** breaking changes specific to YOUR code
- **Preserves** your custom configurations with warnings
- **Generates** comprehensive upgrade reports (50+ pages)
- **Based on** official Rails CHANGELOGs from GitHub

### Supported Upgrade Paths

| From | To | Breaking Changes | Difficulty |
|------|-----|-----------------|------------|
| 8.0.x | 8.1.1 | 8 changes | Easy |
| 7.2.x | 8.0.4 | 13 changes | Hard |
| 7.1.x | 7.2.3 | 38 changes | Medium |
| 7.0.x | 7.1.6 | 12 changes | Medium |
| 7.0.x | 8.1.1 | All 71 changes | Very Hard |

** Important:** Rails upgrades MUST be sequential. No version skipping!

### Usage

```
> Upgrade my Rails app to 8.1
> Help me upgrade from Rails 7.2 to 8.0
> Generate a detection script for Rails 8.0 upgrade
> What breaking changes are in Rails 8.1?
> Assess upgrade impact from 7.0 to 8.1
```

### Workflow

1. **Claude generates detection script** tailored to your specific upgrade
2. **You run the script** in your project directory
3. **Script outputs findings** with file:line references
4. **Share findings with Claude**
5. **Claude generates comprehensive report** with OLD→NEW code examples

### Benefits

- Accuracy in finding breaking changes
- Clear file:line references for every issue
- Faster upgrades overall

### Package Contents

```
rails-upgrade-assistant/
├── agents/rails-upgrade-assistant.md    # Main skill
├── version-guides/                       # Rails version details
│   ├── upgrade-7.0-to-7.1.md
│   ├── upgrade-7.1-to-7.2.md
│   ├── upgrade-7.2-to-8.0.md
│   └── upgrade-8.0-to-8.1.md
├── workflows/                            # How to generate deliverables
├── examples/                             # Real usage scenarios
├── reference/                            # Breaking changes, deprecations
├── templates/                            # Report templates
└── detection-scripts/                    # Pattern definitions
```

### Requirements

- **Required:** [Rails MCP Server](https://github.com/maquina-app/rails-mcp-server)
- **Optional:** [Neovim MCP Server](https://github.com/maquina-app/nvim-mcp-server) (for interactive file updates)

### Resources

- [Original Skill Repository](https://github.com/maquina-app/rails-upgrade-skill)
- [Rails Upgrading Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)

---

## 3. maquina-ui-standards

Build consistent, accessible UIs in Rails using **maquina_components** — ERB partials styled with Tailwind CSS 4 and data attributes, inspired by shadcn/ui.

### What It Provides

| Reference | Purpose |
|-----------|---------|
| Component catalog | All 15+ components with ERB examples |
| Form patterns | Validation, error handling, inline layouts |
| Layout patterns | Sidebar navigation, page structure |
| Turbo integration | Frames, Streams, component updates |
| Spec checklist | Review criteria for UI quality |

### Usage

```
> Create the users index view with a table showing name, email, and status
> Implement the project form with name, description, and a framework combobox
> Review this view against the maquina UI standards and suggest improvements
> Build a dashboard layout with sidebar navigation
```

### Component Example

```erb
<%# Partial components %>
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: "Appointments" %>
    <%= render "components/card/description", text: "Manage your schedule" %>
  <% end %>
  <%= render "components/card/content" do %>
    <!-- Content here -->
  <% end %>
<% end %>

<%# Data-attribute components (forms) %>
<%= form.text_field :name, data: { field: true } %>
```

### Package Contents

```
maquina-ui-standards/
├── agents/maquina-ui-standards.md    # Main skill
├── QUICKSTART.md                      # Quick reference
└── references/
    ├── component-catalog.md           # All available components
    ├── form-patterns.md               # Validation, error handling
    ├── layout-patterns.md             # Pages, dashboards
    ├── turbo-integration.md           # Frames, streams
    └── spec-checklist.md              # Accessibility, consistency
```

### Requirements

- [maquina_components gem](https://github.com/maquina-app/maquina_components) installed in your Rails app

### Resources

- [Original Maquina Components Announcement](https://maquina.app/blog/2025/12/announcing-maquina-components-opinionated-ul-for-rails-applications/)
- [Maquina Components Documentation](https://maquina.app/documentation/)
- [Original Skill Announcement](https://maquina.app/blog/2026/01/claude-skill-for-maquina-components/)

---

## 4. recuerd0

A CLI skill for **Recuerd0** — a command-line tool for preserving, versioning, and organizing knowledge from AI conversations.

### What It Does

| Feature | Description |
|---------|-------------|
| Save session | Generate a transcript from the current conversation, infer title/tags/workspace, and save as a memory |
| Workspace management | Create, list, archive workspaces |
| Memory CRUD | Create, read, update, delete memories |
| Versioning | Create versions of existing memories |
| Full-text search | FTS5-backed search with AND/OR/NOT operators |
| Piped content | Read memory content from stdin |

### Usage

```
> Remember this session
> Save this conversation to my "Rails Patterns" workspace
> Search my memories for "error handling"
> Create a new workspace called "Rails Patterns"
> Version memory 42 with updated content
```

### Save Session Workflow

When asked to save a session, the skill will:

1. Generate a structured transcript from the conversation context
2. Infer a title, tags, and workspace
3. Ask you to confirm or adjust before saving
4. Save via `recuerd0 memory create` piping content through stdin

If you provide a workspace name instead of an ID, it resolves the name automatically. If the workspace doesn't exist, it offers to create one.

### Package Contents

```
recuerd0/
├── agents/recuerd0.md              # Main skill
└── .claude-plugin/plugin.json      # Plugin metadata
```

### Requirements

- [Recuerd0 CLI](https://recuerd0.ai) installed and configured with an account

---

## Team Installation

Add to your project's `.claude/settings.json` for automatic installation:

```json
{
  "extraKnownMarketplaces": {
    "maquina": {
      "source": {
        "source": "github",
        "repo": "maquina-app/rails-claude-code"
      }
    }
  },
  "enabledPlugins": [
    "rails-simplifier@maquina",
    "rails-upgrade-assistant@maquina",
    "maquina-ui-standards@maquina",
    "recuerd0@maquina"
  ]
}
```

---

## License

[MIT](./LICENCE.txt)

---

## Author

[**Mario Alberto Chávez Cárdenas**](https://mariochavez.io/)

[Maquina](https://maquina.app) · [GitHub](https://github.com/maquina-app) · [X](https://x.com/mario_chavez)
