---
title: "Rails Upgrade Assistant - Usage Guide"
description: "How to drive the Rails Upgrade Assistant: prompts, the workflow, multi-hop upgrades, best practices, and troubleshooting"
type: "user-documentation"
audience: "users"
purpose: "how-to"
rails_versions: "6.0.x to 8.1.1"
category: "documentation"
last_updated: "2026-02-23"
copyright: Copyright (c) 2026 Mario Alberto Chávez Cárdenas
---

# 📚 Rails Upgrade Assistant — Usage Guide

How to drive the assistant through a real upgrade. For a fast command list see `QUICK-REFERENCE.md`; for install and overview see `README.md`.

The assistant reads, runs, and edits project files with Claude Code's built-in tools — no MCP servers or editor setup.

---

## The Workflow

Every full upgrade runs the same autonomous loop. You ask; Claude does all of it:

1. **Detect** — reads `Gemfile.lock` for your current Rails version and confirms the target; notes whether the app is API-only or full-stack from `config/application.rb`.
2. **Generate** — builds a breaking-changes detection script for the specific hop from the version's pattern file.
3. **Run** — executes the script from your project root; it writes `rails_{version}_upgrade_findings.txt` with a `file:line` for each issue.
4. **Evaluate** — reads the findings and your affected files, cross-referenced against the version guide.
5. **Report** — produces the upgrade report: breaking changes with OLD→NEW code from your real files, `app:update` config preview, migration checklist, and rollback plan. Customizations are flagged ⚠️.
6. **Apply** — offers to make the changes, editing the files directly.

You stay in control: review the report first, and choose which fixes to apply.

---

## Example Prompts

**Run a full upgrade:**
```
Upgrade my Rails app to 8.1
Upgrade my Rails app from 7.2 to 8.0
```

**Just find the breaking changes (script + findings, no report):**
```
Find the breaking changes for a Rails 8.0 upgrade
Create a detection script for Rails 8.0
```

**Just preview configuration changes:**
```
Show me the app:update changes for Rails 7.2
What config files will change for Rails 8.1?
```

**Ask about a version (quick answer, no script):**
```
What breaking changes are in Rails 8.1?
What ActiveRecord changes are in Rails 8.0?
Will my Redis cache still work after upgrading to 8.0?
```

**Apply fixes after reviewing:**
```
Apply the HIGH-priority fixes
Fix the SSL configuration change for me
```

---

## Multi-Hop Upgrades

Rails upgrades are **sequential** — one minor version at a time:

```
6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1
```

When you ask for a jump across several versions (e.g. `7.0 → 8.1`), the assistant:

1. Explains the required sequence (`7.0 → 7.1 → 7.2 → 8.0 → 8.1`).
2. Runs the full detect → report → apply loop for the **first** hop only.
3. Waits for you to finish that hop — apply, test, and ideally deploy — before starting the next.

Complete each hop fully (including a green test suite) before moving on. See `reference/multi-hop-strategy.md` for planning a large jump.

```
Help me upgrade from Rails 7.0 to 8.1
Plan the upgrade path from Rails 6.1 to 8.0
```

---

## Best Practices

**Start on a clean branch.** Commit or stash everything first; do the upgrade on its own branch.

**Work one change at a time.** Apply a change → run the suite → commit → repeat. Don't batch every breaking change into one commit:

```bash
git switch -c rails-8-1-upgrade
# apply a change
bin/rails test
git commit -am "Upgrade: assume_ssl for proxy setup"
```

**Address HIGH priority first.** Clear everything that will stop the app from booting before touching MEDIUM/LOW items.

**Respect the ⚠️ warnings.** Each one marks a customization the upgrade may interact with — review it rather than blindly accepting the default.

**Lean on staging.** For major jumps (e.g. 7.2 → 8.0, which moves Sprockets → Propshaft and introduces the Solid gems), test in staging before production.

**Keep a fast rollback.** Have a tested rollback that runs in a few minutes, and watch error rates for 24–48 hours after deploying.

---

## Pre-Upgrade Checklist

- [ ] All tests currently passing
- [ ] Database backed up (restore tested)
- [ ] Clean git working directory on a dedicated branch
- [ ] Staging environment available
- [ ] Rollback plan documented and fast
- [ ] Current version confirmed (`bin/rails -v`)
- [ ] Custom code noted

---

## Troubleshooting

**Can't detect the Rails version.** Confirm you're at the project root and `Gemfile.lock` exists; otherwise state your version directly ("My Rails version is 7.2.3").

**The report looks generic.** Ask Claude to read your config first ("Analyze my config, then generate the report") — the report should quote your actual affected-file code, never placeholders.

**Too many ⚠️ warnings.** That's thoroughness, not a problem. Prioritize HIGH-priority warnings and the files you actually use.

**Tests fail after applying changes.** Share the exact error; check `reference/reference-files-package.md` §3 (Troubleshooting) and confirm every required change was applied.

**Assets stop loading after 7.2 → 8.0.** That's the Sprockets → Propshaft migration — see `version-guides/upgrade-7.2-to-8.0.md` (Asset Pipeline) and verify your asset paths and manifest.

---

## Where to Go Next

- `QUICK-REFERENCE.md` — command and breaking-changes cheat sheet
- `version-guides/upgrade-{FROM}-to-{TO}.md` — full change list per hop
- `reference/testing-checklist.md` — comprehensive post-upgrade testing
- `reference/reference-files-package.md` — pattern guide (§1), quality checklist (§2), troubleshooting (§3)

---

**Rails support:** 6.0.x through 8.1.1 · Copyright (c) 2026 Mario Alberto Chávez Cárdenas
