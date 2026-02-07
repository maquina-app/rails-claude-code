# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code Plugin Marketplace** (`maquina-app/rails-claude-code`) containing three plugins for Ruby on Rails development. All plugins follow 37signals patterns and the One Person Framework philosophy.

**This is a documentation-only project** — no build system, test suite, linter, or CI pipeline. All content is Markdown, JSON, and YAML. Validation happens through manual testing via Claude Code.

## Plugins

| Plugin | Version | Purpose |
|--------|---------|---------|
| `rails-simplifier` | 1.0.0 | Refines Rails code following 37signals patterns (rich models, concerns, CRUD resources) |
| `rails-upgrade-assistant` | 1.0.0 | Plans and executes Rails upgrades from 7.0 → 8.1.1 with detection scripts and reports |
| `maquina-ui-standards` | 0.3.1.1 | Builds UIs using maquina_components (ERB partials + Tailwind CSS 4, inspired by shadcn/ui) |
| `recuerd0` | 1.0.0 | Manages workspaces and memories via the Recuerd0 CLI for preserving knowledge from AI conversations |

## Architecture

### Marketplace Structure

```
.claude-plugin/marketplace.json    ← Marketplace definition (lists all plugins)
<plugin-name>/
├── .claude-plugin/plugin.json     ← Plugin metadata (name, version, description)
├── agents/<plugin-name>.md        ← Main skill definition (Markdown with YAML frontmatter)
├── references/                    ← Quick lookup guides
├── workflows/                     ← Step-by-step procedures
├── examples/                      ← Real usage scenarios
└── templates/                     ← Output format templates
```

Each plugin's **agent file** (`agents/*.md`) is the entry point — it contains the full skill instructions for Claude, with selective references to supporting files. Agent files use YAML frontmatter to define skill name, description, and model preference.

### Key Design Decisions

- **Modular loading**: Agent files are compact (300–600 lines) and reference detailed docs on demand rather than inlining everything
- **Workflows explain HOW**, examples show WHAT, references provide quick lookups — each has a distinct role
- **Detection scripts** (upgrade-assistant only) use YAML pattern definitions + shell script templates for automated codebase scanning

## Version Management

Versions are tracked in two places that must stay in sync:
1. `.claude-plugin/marketplace.json` — the `version` field in each plugin entry
2. `<plugin-name>/.claude-plugin/plugin.json` — the plugin's own `version` field

## Installation (for users of these plugins)

```bash
# Add marketplace
/plugin marketplace add maquina-app/rails-claude-code

# Install plugins
/plugin install rails-simplifier@maquina
/plugin install rails-upgrade-assistant@maquina
/plugin install maquina-ui-standards@maquina
/plugin install recuerd0@maquina
```

Team-wide installation goes in `.claude/settings.json` with `extraKnownMarketplaces` and `enabledPlugins` keys (see README.md for full example).

## Editing Guidelines

- When modifying agent files (`agents/*.md`), preserve the YAML frontmatter structure
- When adding breaking changes to version guides, update both the version guide and `reference/breaking-changes-by-version.md`
- Detection script patterns (`detection-scripts/patterns/*.yml`) follow a consistent YAML schema — match existing pattern structure
- Component additions to maquina-ui-standards go in `references/component-catalog.md` and should include ERB examples with all variant options
