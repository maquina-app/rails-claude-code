---
title: "Rails Upgrade Assistant - Getting Started Guide"
description: "User documentation for the Rails Upgrade Assistant: installation, how it works, supported paths, and upgrade guidance for Rails 6.0 through 8.1.1"
type: "user-documentation"
audience: "users"
purpose: "getting-started"
rails_versions: "6.0.x to 8.1.1"
tags:
  - documentation
  - getting-started
  - user-guide
category: "documentation"
last_updated: "2026-02-23"
copyright: Copyright (c) 2026 Mario Alberto Chávez Cárdenas
---

# 📚 Rails Upgrade Assistant

**Rails support:** 6.0.x through 8.1.1 · **Upgrades:** sequential only

An intelligent Rails upgrade assistant that helps you move a Ruby on Rails app through any version from **6.0 to 8.1.1**, grounded in the official Rails CHANGELOGs. It reads, runs, and edits project files with Claude Code's built-in tools — **no external MCP servers or editor integration required**.

---

## What It Does

Given a Rails project, the assistant runs the whole loop itself:

1. **Detects** the current version from `Gemfile.lock` and confirms the target.
2. **Generates** a breaking-changes detection script tailored to the specific hop.
3. **Runs** the script and reads the findings (`file:line` references for each issue).
4. **Evaluates** the findings against the version guide and your actual files.
5. **Produces** a comprehensive upgrade report — breaking changes with OLD→NEW code, `app:update` config preview, migration checklist, and rollback plan — all from your real code, never generic examples.
6. **Offers to apply** the fixes, editing the files directly.

Custom configurations are flagged with ⚠️ so nothing of yours is changed silently.

---

## Quick Start

Install the plugin:

```bash
/plugin marketplace add maquina-app/rails-claude-code
/plugin install rails-upgrade-assistant@maquina
```

Then, from your Rails project, ask Claude:

```
Upgrade my Rails app to 8.1
```

That's it — no MCP setup, no editor configuration. Claude detects your version, generates and runs the detection script, and produces the report.

---

## Supported Upgrade Paths

| From | To | Hops | Breaking Changes | Difficulty | Key Changes |
|------|----|----|-----------------|------------|-------------|
| 8.0.x | 8.1.1 | 1 | 8 | ⭐ Easy | SSL config, bundler-audit |
| 7.2.x | 8.0.4 | 1 | 13 | ⭐⭐⭐ Hard | Propshaft, Solid gems |
| 7.1.x | 7.2.3 | 1 | 38 | ⭐⭐ Medium | Transaction jobs, PWA |
| 7.0.x | 7.1.6 | 1 | 12 | ⭐⭐ Medium | cache_classes, SSL |
| 6.1.x | 7.0.0 | 1 | 17 | ⭐⭐⭐ Hard | Webpacker, framework defaults |
| 6.0.x | 6.1.0 | 1 | 18 | ⭐⭐ Medium | Active Storage, per-db connections |
| 6.0.x | 8.1.1 | 6 | All 106 | ⭐⭐⭐⭐ Very Hard | Multi-hop required |

### Sequential upgrades only

Upgrade one minor version at a time, in order:

```
6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1
```

For a multi-version request (e.g. 7.0 → 8.1), Claude explains the sequence, then runs the full detect → report → fix loop for the first hop and completes it before starting the next.

---

## How to Use

**Full upgrade** — the default. Runs the whole loop and offers to apply fixes:

```
Upgrade my Rails app from 7.2 to 8.0
```

**Detection only** — generate and run the script, see the findings, stop before the report:

```
Find the breaking changes for a Rails 8.0 upgrade
```

**Config preview only** — just the `app:update` configuration section:

```
Show me the app:update changes for Rails 7.2
```

**Version query** — a quick answer, no script:

```
What breaking changes are in Rails 8.1?
What ActiveRecord changes are in Rails 8.0?
```

---

## What the Report Contains

Every full upgrade produces a report with:

1. **Executive summary** — versions, breaking-change count, risk, custom-code warning count.
2. **Project analysis** — your version and structure, files needing updates, detected customizations.
3. **Breaking changes**, prioritized HIGH / MEDIUM / LOW.
4. **OLD → NEW code**, using your actual affected-file code:

   ```ruby
   # OLD (Rails 7.2)
   config.action_dispatch.show_exceptions = true
   # NEW (Rails 7.2 — old boolean errors)
   config.action_dispatch.show_exceptions = :all
   # WHY: symbol format provides finer control
   ```

5. **Custom-code warnings** (⚠️) — each detected customization with file, line, and guidance.
6. **Step-by-step migration guide** — phased, with testing checkpoints.
7. **Testing checklist** and **rollback plan**.

---

## Custom-Code Detection

The assistant flags common customizations so you can review them before they break — for example:

```
⚠️ Custom SQLite path in config/database.yml
   Rails 7.1+ moves the database to storage/ — review and update the path.

⚠️ Custom autoload_paths in config/application.rb
   Rails 7.1+ autoloads lib/ by default (config.autoload_lib) — the manual path may conflict.

⚠️ Custom Sprockets processors detected
   Rails 8.0 Propshaft doesn't support processors — migrate the approach or keep Sprockets.
```

Every breaking change carries ⚠️ warnings for the customizations it commonly interacts with.

---

## Pre-Upgrade Checklist

Before starting any upgrade:

- [ ] All tests currently passing (unit + integration + system)
- [ ] Database backed up (and restore tested)
- [ ] Clean git working directory on a branch
- [ ] Staging environment available for testing
- [ ] Rollback plan documented and fast (< 5 minutes)
- [ ] Team notified; error tracking configured
- [ ] Current version confirmed (`bin/rails -v`)
- [ ] Custom code noted (know what you've changed)

---

## Common Issues

**"Can't detect my Rails version"** — confirm you're at the project root and `Gemfile.lock` exists; otherwise tell Claude your version explicitly.

**"Too many custom-code warnings"** — that's the assistant being thorough. Address HIGH-priority warnings first, focus on files you actually use.

**"Tests failing after upgrade"** — share the error with Claude; check `reference/reference-files-package.md` §3 (Troubleshooting) and re-verify you applied every required change.

**"Assets not loading after 7.2 → 8.0"** — that's the Sprockets → Propshaft migration; see `version-guides/upgrade-7.2-to-8.0.md` (Asset Pipeline) and confirm your asset paths.

---

## Documentation Map

- **`QUICK-REFERENCE.md`** — command cheat sheet, breaking-changes summary, quick troubleshooting.
- **`USAGE-GUIDE.md`** — detailed how-to, example prompts, workflows, best practices.
- **`version-guides/upgrade-X-to-Y.md`** — full CHANGELOG analysis and migration steps per hop.
- **`reference/`** — `breaking-changes-by-version.md` (quick lookup), `multi-hop-strategy.md`, `deprecations-timeline.md`, `testing-checklist.md`, `reference-files-package.md` (pattern guide §1, quality checklist §2, troubleshooting §3).
- **`examples/`** — walkthroughs: `simple-upgrade.md`, `multi-hop-upgrade.md`, `detection-script-only.md`, `preview-only.md`.

---

## Resources

- [Rails Upgrading Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails Guides](https://guides.rubyonrails.org) · [Rails GitHub](https://github.com/rails/rails)

---

## License & Attribution

Copyright (c) 2026 Mario Alberto Chávez Cárdenas. All Rails upgrade information is based on official Rails CHANGELOGs from the Rails GitHub repository. **Rails** is a trademark of the Rails Core Team; **Claude** is a product of Anthropic.
