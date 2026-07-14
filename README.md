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
/plugin install mvp-creator@maquina
/plugin install better-stimulus@maquina
/plugin install spec-driven-development@maquina
/plugin install rails-security-auditor@maquina
/plugin install rails-hotwire-driver@maquina
```

---

## Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [rails-simplifier](#1-rails-simplifier) | Code quality following 37signals patterns | 1.1.0 |
| [rails-upgrade-assistant](#2-rails-upgrade-assistant) | Rails 6.0→8.1 upgrade planning | 1.2.0 |
| [maquina-ui-standards](#3-maquina-ui-standards) | UI components with maquina_components | 0.4.4 |
| [recuerd0](#4-recuerd0) | Knowledge management from AI conversations | 1.4.0 |
| [mvp-creator](#5-mvp-creator) | MVP documentation for Rails applications | 1.1.0 |
| [better-stimulus](#6-better-stimulus) | StimulusJS best practices from betterstimulus.com | 1.1.0 |
| [spec-driven-development](#7-spec-driven-development) | Spec-driven development workflow for Rails | 1.3.0 |
| [rails-security-auditor](#8-rails-security-auditor) | Security audit for Rails 8.0–8.2 configuration | 1.0.1 |
| [rails-hotwire-driver](#9-rails-hotwire-driver) | Drive a running Rails dev server from the terminal, optional screenshots/browser layer | 0.3.0 |

---

## 1. rails-simplifier

A code simplification skill that refines Ruby on Rails code following **37signals patterns** and the **One Person Framework** philosophy.

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
> Simplify the recent changes to the bookings controller
> Refactor this to vanilla Rails / 37signals patterns
> Review this model against the rails-simplifier standards
```

### Package Contents

```
rails-simplifier/
└── skills/simplify/
    ├── SKILL.md                # Main skill: rules, patterns, process
    └── references/
        ├── philosophy.md       # The "why" — 37signals / Jorge Manrubia philosophy
        └── patterns.md         # The "how" — implementation catalog from Fizzy
```

### Resources

- [37signals Rails Patterns](https://gist.github.com/marckohlbrugge/d363fb90c89f71bd0c816d24d7642aca)
- [Jorge Manrubia's Blog](https://world.hey.com/jorge)
- [Rails Doctrine](https://rubyonrails.org/doctrine)

---

## 2. rails-upgrade-assistant

A **unified, intelligent Rails upgrade assistant** that helps you upgrade Ruby on Rails applications through any version from **6.0 to 8.1.1**. Built on official Rails CHANGELOGs, it analyzes your project with the standard file tools — no external services required.

### What It Does

- **Analyzes** your Rails project automatically by reading its files
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
| 6.1.x | 7.0.0 | 17 changes | Hard |
| 6.0.x | 6.1.0 | 18 changes | Medium |
| 6.0.x | 8.1.1 | All 106 changes | Very Hard |

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

1. **Detects** your current and target versions from `Gemfile.lock`
2. **Generates a detection script** tailored to the specific hop
3. **Runs the script** and reads the findings (`file:line` references)
4. **Generates a comprehensive report** with OLD→NEW code from your actual files
5. **Offers to apply the fixes** directly

### Benefits

- Accuracy in finding breaking changes
- Clear file:line references for every issue
- Faster upgrades overall

### Package Contents

```
rails-upgrade-assistant/
├── agents/rails-upgrade-assistant.md    # Main agent
├── version-guides/                       # Rails version details
│   ├── upgrade-6.0-to-6.1.md
│   ├── upgrade-6.1-to-7.0.md
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

- None beyond Claude Code — the assistant reads, runs, and edits project files with its built-in tools.

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
├── skills/ui/SKILL.md                 # Model-invoked skill (loads standards into the working context)
├── QUICKSTART.md                      # Quick reference for humans
└── references/
    ├── component-catalog.md           # All available components
    ├── helpers-reference.md           # Ruby helper builders and _simple methods
    ├── stimulus-controllers.md        # Component JavaScript reference
    ├── installation-guide.md          # Setup, theme, icons
    ├── form-patterns.md               # Validation, error handling
    ├── layout-patterns.md             # Pages, dashboards
    ├── turbo-integration.md           # Frames, streams
    └── spec-checklist.md              # Accessibility, consistency
```

As of 0.5.0 this ships as a **skill** rather than a subagent: Claude loads the standards into the same conversation where the feature is being built, keeping full context of your models, controllers, and spec while writing views.

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

### Workspace Routing

Drop a `.recuerd0.yaml` file at the root of each project to pin its memories to a workspace:

```yaml
workspace: "12"
```

The CLI walks parent directories, so nested subfolders inherit the config. When no config is present, the skill resolves the workspace by matching the project/repo name, and offers to create one if there's no match.

### Package Contents

```
recuerd0/
└── skills/remember/
    ├── SKILL.md                    # Main skill: capture gate, dedup, routing, save
    └── references/
        ├── cli-reference.md        # Command catalog, flags, output format
        ├── import-context.md       # Importing CLAUDE.md / context files
        └── memory-templates.md     # Feature/decision/API memory templates
```

### Requirements

- [Recuerd0 CLI](https://recuerd0.ai) installed and configured with an account
- Optionally, a workspace pinned via `.recuerd0.yaml`, `RECUERD0_WORKSPACE`, or the CLI's global config — the skill resolves or creates one when it's not set

---

## 5. mvp-creator

Create comprehensive **MVP documentation** for Rails applications through guided research and discovery.

### What It Does

Produces 5 deliverables for a new Rails application:

| Deliverable | Purpose |
|-------------|---------|
| Research Report | Competitor analysis, market overview, feature comparison |
| MVP Business Plan | Vision, features, user flows, success metrics |
| Brand Guide | Logo, colors, typography, components, voice |
| Technical Guide | Architecture, patterns, data models, code style |
| Claude Setup | CLAUDE.md, .mcp.json, commands for Claude Desktop/Code |

### Usage

```
> I have an idea for a project management app
> Help me plan a SaaS for freelancers
> Research competitors for a booking system
> Create a business plan for my app idea
> Design a brand for my Rails project
```

### Workflow

```
Topic/Idea → Research → Discovery Questions → Generate Deliverables → Handoff to SDD
```

### Package Contents

```
mvp-creator/
├── QUICKSTART.md                                 # Quick reference
└── skills/mvp-creator/
    ├── SKILL.md                                  # Main skill
    ├── scripts/init.sh                           # Project initialization
    └── references/
        ├── rails-philosophy.md                   # 37signals patterns
        ├── rails-ui-patterns.md                  # UI conventions
        ├── rails-api-patterns.md                 # API patterns
        ├── rails-implementation-patterns.md      # Implementation guide
        └── deliverable-templates/                # Output templates
            ├── research-report.md
            ├── mvp-business-plan.md
            ├── brand-guide.md
            ├── technical-guide.md
            └── claude-setup.md
```

---

## 6. better-stimulus

Apply opinionated **StimulusJS best practices** sourced from [betterstimulus.com](https://www.betterstimulus.com). Use when writing, reviewing, or refactoring Stimulus controllers.

### What It Covers

| Topic | Description |
|-------|-------------|
| Architecture | Application controller, configurable controllers, late binding |
| State management | Values API, targets, outlets, avoiding global state |
| Lifecycle | Connect/disconnect patterns, lazy loading, cleanup |
| Composition | Mixins, use-hooks, controller communication |
| SOLID principles | Applied to Stimulus controllers |
| Cookbook | Common patterns for modals, forms, validation, etc. |

### Usage

```
> Write a Stimulus controller for a dropdown menu
> Review this Stimulus controller against best practices
> Refactor this controller to use the Values API
> How should I handle state in Stimulus?
```

### Package Contents

```
better-stimulus/
└── skills/better-stimulus/
    ├── SKILL.md                        # Main skill
    └── references/
        ├── cookbook.md                 # Common patterns
        ├── inter-controller.md         # Outlets, callbacks, custom events
        ├── error-handling.md           # Global error handler
        └── solid.md                    # SOLID principles for Stimulus
```

### Resources

- [Better Stimulus](https://www.betterstimulus.com)
- [julianrubisch/better-stimulus](https://github.com/julianrubisch/better-stimulus)

---

## 7. spec-driven-development

A lightweight workflow for building production-quality **Rails features with AI agents** through systematic planning and self-contained specs.

### What It Does

| Feature | Description |
|---------|-------------|
| Feature shaping | Convert ideas into structured specs |
| Task breakdown | Split specs into implementable tasks |
| Standards discovery | Extract patterns from existing codebases |
| Progress tracking | YAML-based status for specs and tasks |
| Agent handoff | Self-contained specs ready for Claude Code |

### Usage

```
> Initialize SDD for this project
> Shape a spec for the notifications feature
> Create tasks from the authentication spec
> Show SDD status
> Add a new spec for the billing module
```

### Workflow

```
Initialize → Shape Spec → Create Tasks → Hand off to Claude Code → Track Progress
```

### Package Contents

```
spec-driven-development/
├── agents/spec-driven-development.md    # Main skill
├── README.md                             # Full documentation
├── QUICKSTART.md                         # Quick reference
├── scripts/
│   ├── init_sdd.sh                       # Initialize SDD structure
│   ├── new_spec.sh                       # Create new spec
│   └── status.sh                         # Show progress
├── references/
│   ├── rails-standards.md                # Rails conventions
│   ├── hotwire-patterns.md               # Turbo/Stimulus patterns
│   └── document-templates.md             # Spec templates
└── templates/
    ├── standard-template.md              # Spec template
    └── progress.yml                      # Progress tracking
```

---

## 8. rails-security-auditor

A security auditor that scans a Rails application's configuration and produces a structured, actionable report grouped by severity. Grounded in **Rails 8.0–8.2 security defaults** and covers the framework, application, and infrastructure layers.

### What It Does

- **Scans** production environment, initializers, controllers, Gemfile, and CI config
- **Detects** the Rails version from `Gemfile.lock` and adjusts expectations accordingly
- **Checks** CSRF, security headers, CSP, session cookies, rate limiting, authorization, dependency CVEs, and Rails 8.2 framework defaults
- **Reports** each finding with severity, evidence, plain-language risk explanation, and exact fix
- **Offers** to apply fixes — one, all critical, or all — with minimal diffs

### Check Categories

| Category | Covers |
|----------|--------|
| PROD | `force_ssl`, `assume_ssl`, log level, `filter_parameters`, trusted proxies |
| CSRF | `protect_from_forgery`, strategy, per-form tokens |
| HDR | X-Frame-Options, X-Content-Type-Options, Referrer-Policy |
| CSP | Content Security Policy initializer and directives |
| SESS | Session cookie `SameSite`, `expire_after`, `httponly` |
| RATE | `rate_limit` macro, Rack::Attack throttles and safelists |
| AUTH | Authorization gem, tenant scoping, `allow_unauthenticated_access` |
| GEM | Brakeman, bundler-audit, Rails CVEs |
| CI | Security scanning in CI |
| DATA | Column-level encryption, hardcoded secrets |
| FWKD | Rails 8.2 framework defaults (CSRF header strategy, transaction-aware jobs) |

### Usage

```
> Audit security
> Run a security audit on this Rails app
> Is my CSRF configured correctly?
> Am I missing any security headers?
> Check my Rack::Attack config
```

### Package Contents

```
rails-security-auditor/
├── agents/rails-security-auditor.md    # Main agent
├── references/
│   └── checks.md                       # Full catalog of checks with fixes
└── .claude-plugin/plugin.json          # Plugin metadata
```

---

## 9. rails-hotwire-driver

Drive a **running local Rails dev server from the terminal** — no browser required for the core workflow. The runtime complement to static code tools: it exercises the server-rendered Hotwire contract directly, so you can verify what the app actually does at request time. An **optional** layer adds a real (headless) browser via [agent-browser](https://github.com/vercel-labs/agent-browser) for the JS-dependent residual — screenshots, visual regression, Turbo-event waits, Stimulus introspection.

### What It Does

Core (curl + Ruby, no browser):
- **Submits ERB forms with the correct CSRF token** — GETs the page, reads the hidden `authenticity_token`, merges your fields, and posts (the #1 hand-driving failure, eliminated)
- **Logs in via OTP/magic-link** by reading the code straight from the development log, scoped to the login's request id
- **Inspects Turbo Stream responses** — parses the returned `action #target` pairs
- **Correlates by request id** — pulls the exact log slice (params, SQL, partial renders) for any request
- **Bridges sessions to/from a real browser** (`storageState`) so you log in once and share the session between curl and agent-browser/Playwright

Optional (requires agent-browser):
- **Screenshots** — full page, scoped to an element, device emulation, dark/light mode
- **Visual regression** — pixel diff against a saved baseline, fixed viewport
- **Turbo-aware waits** — poll a DOM condition or listen for a named Turbo event, instead of a fixed sleep or `networkidle` (which hangs on apps with an open ActionCable connection)
- **Stimulus introspection** — connected controllers, their targets, and their values
- **Structural diffs** — accessibility-tree diff scoped to a selector, to confirm a Turbo action changed exactly what it should
- **Console/error capture** — paired with the request id of the action that triggered it

### Guardrails

- **Local only** — refuses any non-localhost host (`localhost`, loopback, `*.localhost` for kamal-proxy); the browser scripts enforce this independently
- **No production logs** — the log reader refuses any path containing `production`
- **Cookie hygiene** — `Set-Cookie` is redacted; the session value never enters the transcript

### Usage

```
> Log into the app from the terminal and read the OTP from the log
> Submit the new post form and show me the turbo-stream targets
> Trace what request <id> did in the dev log
> Screenshot the cart page after adding an item
> Wait for the turbo-stream broadcast to actually update #cart_summary
> Inspect the Stimulus controller on this element
```

### Package Contents

```
rails-hotwire-driver/
├── skills/rails-hotwire-driver/
│   ├── SKILL.md                        # Skill instructions and workflows
│   ├── references/
│   │   └── config.md                   # Full env-var reference
│   └── scripts/
│       ├── req.sh                      # One HTTP request, cookies persisted
│       ├── submit_form.rb              # Submit a form with the right CSRF token
│       ├── readlog.sh                  # Read the dev log (request-id correlation)
│       ├── flow.sh                     # Full login → OTP → action in one command
│       ├── jar_to_storage.rb           # curl session → browser storageState
│       ├── storage_to_jar.rb           # Browser storageState → curl jar
│       ├── screenshot.sh               # Full-page/scoped/device/dark-light screenshots (agent-browser)
│       ├── screenshot-diff.sh          # Visual regression against a baseline (agent-browser)
│       ├── turbo-wait.sh               # Wait for a Turbo event or DOM condition (agent-browser)
│       ├── stimulus.sh                 # Stimulus controller introspection (agent-browser)
│       ├── dom-diff.sh                 # Scoped structural (a11y-tree) diff (agent-browser)
│       └── browser-errors.sh           # Console/error capture (agent-browser)
└── .claude-plugin/plugin.json          # Plugin metadata
```

### Requirements

- A Rails app **running locally** in development; set `BASE_URL` (default `http://localhost:3000`)
- `Nokogiri` on the load path — run the Ruby scripts via the app's bundle (`bundle exec ruby ...`)
- Recommended: `config.log_tags = [ :request_id ]` for exact log correlation
- **Optional**, only for the browser scripts: [agent-browser](https://github.com/vercel-labs/agent-browser)
  ```
  npm install -g agent-browser
  agent-browser install            # downloads its own Chrome for Testing, first run only
  agent-browser install --with-deps  # Linux: also installs system libs
  ```
  Detects and reuses an existing Chrome/Brave/Playwright/Puppeteer install instead of downloading a second copy.

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
    "recuerd0@maquina",
    "mvp-creator@maquina",
    "better-stimulus@maquina",
    "spec-driven-development@maquina",
    "rails-security-auditor@maquina",
    "rails-hotwire-driver@maquina"
  ]
}
```

---

## License

[MIT](./LICENSE.txt)

---

## Author

[**Mario Alberto Chávez Cárdenas**](https://mariochavez.io/)

[Maquina](https://maquina.app) · [GitHub](https://github.com/maquina-app) · [X](https://x.com/mario_chavez)
