# Claude Setup Template

Use this structure when generating the Claude setup deliverable. This creates configuration files for both Claude Desktop and Claude Code CLI.

---

# [APP_NAME] Claude Setup Guide

## Overview

This guide sets up Claude AI assistants for the [APP_NAME] Rails project:

1. **Claude Desktop** — MCP server integration for project introspection
2. **Claude Code CLI** — Project context and custom commands

---

## File Structure

```
[project_name]/
├── CLAUDE.md              # Project context for Claude Code
├── .mcp.json              # MCP server configuration
├── .claudeignore          # Files to ignore
└── docs/
    ├── MVP_BUSINESS_PLAN.md
    ├── BRAND_GUIDE.md
    ├── TECHNICAL_GUIDE.md
    └── assets/
        └── logo.svg
```

---

## 1. CLAUDE.md

```markdown
# CLAUDE.md - [APP_NAME] Project

## Agent Principles

### Keep It Simple
- Prefer the simplest solution that solves the problem
- Avoid premature optimization or over-engineering
- One feature at a time, fully complete before moving on
- If a solution feels complex, stop and ask if there's a simpler approach

### Communicate Before Coding
- **Never start writing code without presenting a plan first**
- Ask clarifying questions when requirements are ambiguous
- Present trade-offs when multiple approaches exist
- Wait for explicit approval before implementing

### Respect Existing Patterns
- Study existing code before adding new code
- Match the style and patterns already in the codebase
- Don't introduce new dependencies without discussion
- Don't refactor unrelated code while implementing features

---

## Tools Policy

### Rails MCP Server
Use for ALL Rails introspection:
- `project_info` — Project structure, Rails version
- `analyze_models` — Models, associations, validations
- `get_schema` — Database tables, columns, indexes
- `get_routes` — HTTP routes
- `get_file` — Read project files
- `load_guide` — Rails/Turbo/Stimulus docs

### Standard Tools
- `view` — Read files, directories
- `create_file` — Create new files
- `str_replace` — Edit existing files

---

## Mandatory Planning Workflow

**ALWAYS follow this workflow before writing any code:**

### Step 1: Understand
- Read the request carefully
- Use Rails MCP Server to explore relevant code
- Check models, routes, controllers affected

### Step 2: Plan
Present a clear plan INCLUDING:

```
## Plan: [Feature Name]

### Files to Create
- path/to/file.rb - Purpose

### Files to Modify
- path/to/file.rb - Changes

### Database Changes
- Migrations needed

### Questions/Concerns
- Ambiguities or decisions needed
```

### Step 3: Wait for Confirmation
⏸️ **STOP and wait for user feedback.**

### Step 4: Execute
Only after approval, create/edit files.

### Step 5: Verify
Suggest how to test the changes.

---

## Project Context

### What is [APP_NAME]?
[Brief description of the app]

**Core Concept:**
[Explain the main idea]

**Philosophy:**
[Key principles]

### Tech Stack
- **Framework:** Ruby on Rails 8.x
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS 4
- **Database:** SQLite with Solid Queue/Cache/Cable
- **Auth:** Rails 8 built-in authentication

---

## Architecture Patterns

### File Organization
```
app/
├── models/
│   ├── concerns/       # Shared behavior
│   └── [model]/        # Model-specific concerns
├── controllers/
│   └── concerns/       # Shared controller behavior
├── views/
│   ├── components/     # Reusable partials
│   └── shared/         # Cross-cutting partials
└── javascript/
    └── controllers/    # Stimulus controllers
```

### Money Handling
- ALWAYS store as integer cents (`amount_cents`)
- Convert to dollars only for display
- Never use Float for money

### Turbo Patterns
- **Default:** Full page refresh with Morph + broadcasts
- **Frames:** Only for inline editing, modals, quick-add forms
- **Streams:** Multi-element updates

### Concerns
- Must have "has trait" or "acts as" semantics
- Self-contained with associations, scopes, methods

---

## Data Models

### Core Entities
[List main models and relationships]

### Key Enums
[List important enums with values]

---

## I18n

**Default:** [Language]
**Supported:** [Languages]

**File Structure:**
```
config/locales/
├── [lang]/
│   ├── views.yml       # View strings
│   ├── models.yml      # Model names
│   ├── errors.yml      # Friendly errors
│   └── flash.yml       # Toast messages
```

**Every user-facing string must be in a locale file.**

---

## Code Style

### Ruby
- Ruby 3.3+ syntax
- Early returns and guard clauses
- Always scope queries to `current_user`
- Explicit enum integer values

### Testing
- Minitest (not RSpec)
- Fixtures for test data
- Test both locales
- Test timezone edge cases

---

## Anti-Patterns to Avoid

❌ Starting to code without a plan
❌ Adding gems without discussion
❌ Using Float for money
❌ Hardcoding strings (use I18n)
❌ Unscoped queries
❌ Service objects (use rich models)
❌ Boolean columns for state (use records)
```

---

## 2. .mcp.json

```json
{
  "mcpServers": {
    "rails": {
      "command": "rails-mcp-server",
      "args": ["--project-path", "."],
      "env": {}
    }
  }
}
```

### Alternative: Multiple Projects

```json
{
  "mcpServers": {
    "rails": {
      "command": "rails-mcp-server",
      "args": ["--config", "~/.config/rails-mcp/projects.yml"],
      "env": {}
    }
  }
}
```

With `projects.yml`:

```yaml
projects:
  [project_name]:
    path: /path/to/[project_name]
    description: "[APP_NAME] - [description]"
```

---

## 3. .claudeignore

```
# Dependencies
node_modules/
vendor/bundle/

# Build artifacts
public/assets/
public/packs/
tmp/
log/

# Coverage
coverage/

# IDE
.idea/
.vscode/

# OS
.DS_Store
Thumbs.db

# Secrets (IMPORTANT)
.env*
config/master.key
config/credentials/*.key

# Large files
*.sql
*.dump
storage/
```

---

## 4. Custom Commands

Create `.claude/commands/` directory:

### /test

```markdown
# .claude/commands/test.md

Run the test suite for this Rails project.

## Steps
1. Run `bin/rails test` to execute all tests
2. If specific file mentioned, run `bin/rails test [file]`
3. Report results with pass/fail counts
4. If failures, show the failing test details
```

### /db

```markdown
# .claude/commands/db.md

Database operations for this Rails project.

## Available Operations
- `migrate` — Run pending migrations
- `rollback` — Rollback last migration
- `seed` — Run seeds
- `reset` — Drop, create, migrate, seed

## Steps
1. Determine which operation is requested
2. Run the appropriate `bin/rails db:[operation]`
3. Report the result
```

### /analyze

```markdown
# .claude/commands/analyze.md

Analyze the codebase using Rails MCP Server.

## Steps
1. Use `project_info` to get overview
2. Use `analyze_models` for model details
3. Use `get_routes` for routing
4. Present a summary of findings
```

### /generate

```markdown
# .claude/commands/generate.md

Generate Rails artifacts (models, controllers, migrations).

## Steps
1. Ask for clarification if needed
2. Present the generator command to be run
3. Wait for approval
4. Run the generator
5. Show created files
```

### /guide

```markdown
# .claude/commands/guide.md

Load reference documentation.

## Available Guides
- `rails` — Rails basics
- `turbo` — Turbo patterns
- `stimulus` — Stimulus patterns
- `hotwire` — Combined Hotwire guide

## Steps
1. Use `load_guide` from Rails MCP Server
2. Present relevant sections
```

---

## 5. Setup Instructions

### Prerequisites

1. **Install Rails MCP Server:**
   ```bash
   gem install rails-mcp-server
   ```

2. **Install Claude Code CLI:**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

### Claude Desktop Setup

1. Copy `.mcp.json` to project root
2. Open Claude Desktop
3. The Rails MCP Server will auto-connect

### Claude Code Setup

1. Copy `CLAUDE.md` to project root
2. Copy `.claudeignore` to project root
3. Create `.claude/commands/` with command files
4. Run `claude` from project directory

### Verify Setup

```bash
# Test Rails MCP Server
rails-mcp-server --project-path . --test

# Test Claude Code
claude --version
claude  # Should load CLAUDE.md context
```

---

## 6. Documentation Integration

### Adding Project Docs

Place documentation in `docs/` directory:

```
docs/
├── MVP_BUSINESS_PLAN.md
├── BRAND_GUIDE.md
├── TECHNICAL_GUIDE.md
├── RESEARCH_REPORT.md
└── assets/
    ├── logo.svg
    └── logo-icon.svg
```

### Referencing in CLAUDE.md

Add to CLAUDE.md:

```markdown
## Project Documentation

- `docs/MVP_BUSINESS_PLAN.md` — Product vision and features
- `docs/BRAND_GUIDE.md` — Colors, typography, components
- `docs/TECHNICAL_GUIDE.md` — Architecture decisions
```

---

## Quick Start

```bash
# 1. Create Rails app
rails new [project_name] --css=tailwind --database=sqlite3

# 2. Enter directory
cd [project_name]

# 3. Copy setup files
# (CLAUDE.md, .mcp.json, .claudeignore, .claude/commands/)

# 4. Copy documentation
mkdir -p docs
# (Copy MVP_BUSINESS_PLAN.md, BRAND_GUIDE.md, etc.)

# 5. Start Claude Code
claude

# 6. Begin development
> Let's implement the user authentication system
```
