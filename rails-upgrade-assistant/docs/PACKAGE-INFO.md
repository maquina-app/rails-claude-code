---
title: "Rails Upgrade Assistant - Package Overview"
description: "Navigation and structure overview for the Rails Upgrade Assistant package"
type: "documentation-index"
audience: "users"
purpose: "navigation-overview"
rails_versions: "6.0.x to 8.1.1"
tags:
  - documentation
  - index
  - navigation
category: "documentation"
read_order: 1
last_updated: "2026-02-23"
copyright: Copyright (c) 2026 Mario Alberto Chávez Cárdenas
---

# 📚 Rails Upgrade Assistant — Package Overview

A modular agent that upgrades Ruby on Rails apps from **6.0 through 8.1.1**, grounded in the official Rails CHANGELOGs. It reads, runs, and edits project files with Claude Code's built-in tools — **no external MCP servers or editor integration**.

Start with `README.md` for the getting-started guide; this file is the map of what's in the package and when to load it.

---

## What It Does

Runs the whole upgrade loop autonomously: detect the current version from `Gemfile.lock` → generate a breaking-changes detection script → **run it** → evaluate the findings against the version guide and your actual files → produce a comprehensive upgrade report → offer to apply the fixes. Customizations are flagged with ⚠️ so nothing is changed silently.

---

## Package Structure

```
rails-upgrade-assistant/
├── agents/rails-upgrade-assistant.md   ⭐ Entry point — workflow + resource index
├── docs/                               📖 Human documentation
│   ├── PACKAGE-INFO.md                 This file — package map
│   ├── README.md                       Getting-started guide
│   ├── QUICK-REFERENCE.md              Command cheat sheet
│   └── USAGE-GUIDE.md                  Comprehensive how-to
├── workflows/                          📋 How to generate deliverables
│   ├── detection-script-workflow.md
│   ├── upgrade-report-workflow.md
│   └── app-update-preview-workflow.md
├── examples/                           💡 Walkthroughs (simple, multi-hop, script-only, preview-only)
├── reference/                          📖 Breaking-changes lookup, multi-hop strategy, deprecations, testing, pattern/quality/troubleshooting package
├── version-guides/                     📋 One per hop, 6.0→6.1 … 8.0→8.1
├── templates/                          📄 Upgrade-report template
└── detection-scripts/                  🔍 Per-version YAML patterns + bash template
```

The agent file stays compact and loads workflows, guides, examples, and references **only when the current step needs them** — see its **Resources** section for the load-timing map.

---

## Where to Look

| You want to… | Read |
|---|---|
| Get started / install | `docs/README.md` |
| Look up a command or breaking-change fast | `docs/QUICK-REFERENCE.md` |
| Learn the workflow in depth, with example prompts | `docs/USAGE-GUIDE.md` |
| See the full change list for a specific hop | `version-guides/upgrade-{FROM}-to-{TO}.md` |
| Plan a multi-version upgrade | `reference/multi-hop-strategy.md` |
| Understand how a deliverable is generated | `workflows/` |
| See a worked example | `examples/` |
| Troubleshoot an error | `reference/reference-files-package.md` §3 |

---

## Supported Paths

| From | To | Hops | Breaking Changes | Difficulty |
|------|----|----|-----------------|------------|
| 8.0.x | 8.1.1 | 1 | 8 | ⭐ Easy |
| 7.2.x | 8.0.4 | 1 | 13 | ⭐⭐⭐ Hard |
| 7.1.x | 7.2.3 | 1 | 38 | ⭐⭐ Medium |
| 7.0.x | 7.1.6 | 1 | 12 | ⭐⭐ Medium |
| 6.1.x | 7.0.0 | 1 | 17 | ⭐⭐⭐ Hard |
| 6.0.x | 6.1.0 | 1 | 18 | ⭐⭐ Medium |
| 6.0.x | 8.1.1 | 6 | All 106 | ⭐⭐⭐⭐ Very Hard |

Upgrades are **sequential** — one minor version at a time (`6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1`). For a multi-version request, the assistant runs the full loop for the first hop and finishes it before starting the next.

---

## Quick Start

```bash
/plugin marketplace add maquina-app/rails-claude-code
/plugin install rails-upgrade-assistant@maquina
```

Then, from your Rails project:

```
Upgrade my Rails app to 8.1
```

No setup beyond Claude Code.

---

**Rails support:** 6.0.x through 8.1.1 · Copyright (c) 2026 Mario Alberto Chávez Cárdenas
