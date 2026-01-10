---
title: "Rails Upgrade Assistant - Getting Started Guide"
description: "Complete user documentation for using the Rails Upgrade Assistant skill, including installation, learning paths, and upgrade guidance for Rails 7.0 through 8.1"
type: "user-documentation"
audience: "users"
purpose: "getting-started"
rails_versions: "7.0.x to 8.1.1"
read_time: "15-20 minutes"
tags:
  - documentation
  - getting-started
  - installation
  - learning-paths
  - user-guide
category: "documentation"
priority: "high"
read_order: 2
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# 📚 Rails Upgrade Assistant Skill

**Version:** 1.0
**Created:** November 1, 2025  
**Rails Support:** 7.0.x through 8.1.1

---

## 👋 Welcome!

This is a **unified, intelligent Rails upgrade skill** that helps you upgrade Ruby on Rails applications through any version from **7.0 to 8.1.1**. Built on official Rails CHANGELOGs and integrated with MCP tools for automatic project analysis.

---

## 🎯 What Is This?

A comprehensive Claude skill that:

- ✅ **Analyzes** your Rails project automatically using Rails MCP tools
- ✅ **Detects** your current version and target version
- ✅ **Plans** single-hop or multi-hop upgrade paths
- ✅ **Identifies** breaking changes specific to YOUR code
- ✅ **Preserves** your custom configurations with ⚠️ warnings
- ✅ **Generates** comprehensive upgrade reports (50+ pages)
- ✅ **Updates** files interactively via Neovim (optional)
- ✅ **Based on** official Rails CHANGELOGs from GitHub

---

## 📦 What's Inside This Package?

### Structure Overview

```
rails-upgrade-assistant/
│
├── SKILL.md (300 lines)          ⭐ Compact entry point
│   └── Overview, triggers, file references
│
├── workflows/                     📋 How to generate deliverables
│   ├── upgrade-report-workflow.md      (~400 lines)
│   ├── detection-script-workflow.md    (~400 lines)
│   └── app-update-preview-workflow.md  (~400 lines)
│
├── examples/                      💡 Real usage scenarios
│   ├── simple-upgrade.md               (~350 lines)
│   ├── multi-hop-upgrade.md            (~300 lines)
│   ├── detection-script-only.md        (~250 lines)
│   └── preview-only.md                 (~100 lines)
│
├── reference/                     📖 Quick reference
│   └── reference-files-package.md      (~250 lines)
│
├── version-guides/                📋 Rails version details
├── templates/                     📄 Report templates
└── detection-scripts/             🔍 Pattern definitions
```

**Total:** ~2,750 lines of well-organized content (was 1,066 lines monolithic)

### Version-Specific Guides

```
version-guides/
├── upgrade-7.0-to-7.1.md        Rails 7.0.x → 7.1.x (12 changes)
├── upgrade-7.1-to-7.2.md        Rails 7.1.x → 7.2.x (38 changes)
├── upgrade-7.2-to-8.0.md        Rails 7.2.x → 8.0.x (13 changes)
└── upgrade-8.0-to-8.1.md        Rails 8.0.x → 8.1.x (8 changes)
```

### Reference Materials

```
reference/
├── breaking-changes-by-version.md    Quick lookup table
├── multi-hop-strategy.md             Multi-version planning
├── deprecations-timeline.md          What's deprecated when
└── testing-checklist.md              Comprehensive testing
```

**Total Package Size:** ~220 KB  
**Total Documentation:** ~70 pages

---

## 🚀 Quick Start (3 Minutes)

### Step 1: Install the Skill

**Upload to Claude Project:**

1. Open your Claude Project
2. Go to Project Settings → Knowledge
3. Upload the entire `rails-upgrade-assistant/` folder
4. Or upload just `SKILL.md` for minimal setup

### Step 2: Verify MCP Connection

**Required: Rails MCP Server**

A Ruby implementation of a Model Context Protocol (MCP) server for Rails projects. This server allows LLMs (Large Language Models) to interact with Rails projects through the Model Context Protocol, providing capabilities for code analysis, exploration, and development assistance.

[Install instructions](https://github.com/maquina-app/rails-mcp-server)


**Optional: Neovim MCP Server** (for interactive file updates)

A Ruby implementation of a Model Context Protocol (MCP) server for Neovim. This server allows LLMs (Large Language Models) to interact with Neovim through the Model Context Protocol, providing capabilities to query buffers and perform operations within the editor.

[Install instructions](https://github.com/maquina-app/nvim-mcp-server)

### Step 3: Start Upgrading!

```
Say to Claude:
"Upgrade my Rails app to 8.1"
```

Claude will:
1. Detect your current Rails version
2. Plan the upgrade path (single or multi-hop)
3. Analyze your project for custom code
4. Generate comprehensive upgrade report
5. Provide step-by-step instructions
6. Optionally update files interactively

---

## 📊 Supported Upgrade Paths

| From | To | Hops | Breaking Changes | Difficulty | Time | Key Changes |
|------|----|----|-----------------|------------|------|-------------|
| 8.0.x | 8.1.1 | 1 | 8 changes | ⭐ Easy | 2-4 hours | SSL config, bundler-audit |
| 7.2.x | 8.0.4 | 1 | 13 changes | ⭐⭐⭐ Hard | 6-8 hours | Propshaft, Solid gems |
| 7.1.x | 7.2.3 | 1 | 38 changes | ⭐⭐ Medium | 4-6 hours | Transaction jobs, PWA |
| 7.0.x | 7.1.6 | 1 | 12 changes | ⭐⭐ Medium | 3-5 hours | cache_classes, SSL |
| 7.0.x | 8.1.1 | 4 | All 71 changes | ⭐⭐⭐⭐ Very Hard | 2-3 weeks | Multi-hop required |

### 🚨 Important: No Version Skipping!

Rails upgrades MUST be sequential:

```
✅ Correct: 7.0 → 7.1 → 7.2 → 8.0 → 8.1
❌ Wrong:   7.0 → 8.0 (skips 7.1, 7.2)
❌ Wrong:   7.1 → 8.0 (skips 7.2)
```

If you request a multi-hop upgrade (e.g., 7.0 → 8.1), Claude will:
- Explain the sequential requirement
- Plan all intermediate hops
- Generate separate reports for each hop
- Guide you through completing each hop before moving to next

---

## 💬 How to Use

### Mode 1: Report-Only (Recommended for First Time)

**Best for:** Understanding what needs to change before making any edits

**Usage:**

```
"Upgrade my Rails app from 7.2 to 8.0"
```

**Claude will:**

1. Call `railsMcpServer:project_info` to detect current version
2. Load appropriate version guide(s)
3. Analyze your project files for custom code
4. Identify breaking changes affecting YOUR code
5. Generate comprehensive upgrade report with:
   - Executive summary
   - Breaking changes (HIGH/MEDIUM/LOW priority)
   - OLD vs NEW code examples
   - ⚠️ Custom code warnings
   - Step-by-step migration guide
   - Testing checklist
   - Rollback plan

**You remain in control:** Review the report and apply changes manually.

---

### Mode 2: Interactive with Neovim (Advanced)

**Best for:** Experienced users who want live file updates

**Requirements:**

- Files open in Neovim
- Neovim socket at `/tmp/nvim-{project_name}.sock`
- Neovim MCP server connected

**Usage:**

```
"Upgrade to Rails 8.1 in interactive mode with project 'myapp'"
```

**Claude will:**

1. Generate full upgrade report (like Mode 1)
2. Check which files are open in Neovim via `nvimMcpServer:get_project_buffers`
3. For each file needing changes:
   - Show current code (OLD)
   - Show proposed code (NEW)
   - Ask: "Should I update this file?"
   - If yes: Use `nvimMcpServer:update_buffer` to update
   - If no: Skip and note you can apply manually
4. Verify each change applied successfully
5. Summarize all changes made

**Safety features:**
- ✅ Shows changes BEFORE applying
- ✅ Requires approval for each file
- ✅ Checks buffer availability
- ✅ Never modifies files you haven't opened
- ✅ Preserves custom configurations

---

### Mode 3: Query-Specific (Quick Answers)

**Best for:** Specific questions about changes

**Examples:**

```
"What ActiveRecord changes are in Rails 8.0?"
→ Shows only ActiveRecord-related changes

"How do I handle the SSL configuration change?"
→ Shows detailed SSL migration steps

"What breaking changes affect my models?"
→ Analyzes your models and shows relevant changes

"Show me all configuration file changes for 7.2"
→ Filters for config updates in Rails 7.2

"Will my Redis cache work after upgrading to 8.0?"
→ Checks Solid Cache changes and provides guidance
```

---

## 🔧 Rails MCP Tools Integration

The skill automatically uses these Rails MCP tools to understand YOUR project:

### 1. **project_info** - Detect Version & Structure

```javascript
railsMcpServer:project_info
```

Extracts:
- Current Rails version from Gemfile
- Project structure (API-only? Full stack?)
- Rails root directory
- Ruby version

### 2. **list_files** - Find Relevant Files

```javascript
railsMcpServer:list_files
directory: "config"
pattern: "*.rb"
```

Lists:
- Configuration files
- Models, controllers, jobs
- Initializers
- Custom middleware

### 3. **get_file** - Read & Analyze

```javascript
railsMcpServer:get_file
path: "config/application.rb"
```

Reads files to:
- Detect custom configurations
- Find deprecated patterns
- Identify custom middleware
- Check for manual overrides

### 4. **analyze_models** - Understand Data Layer

```javascript
railsMcpServer:analyze_models
model_name: "User"
```

Analyzes:
- Model associations
- Validations
- Custom scopes
- Callbacks

### 5. **get_schema** - Database Structure

```javascript
railsMcpServer:get_schema
table_name: "users"
```

Reviews:
- Database tables
- Column types
- Foreign keys
- Indexes

### 6. **get_routes** - Application Endpoints

```javascript
railsMcpServer:get_routes
```

Maps:
- All HTTP routes
- Controllers and actions
- Custom routes
- Middleware chains

---

## 🎓 Learning Paths

### 🔰 Path 1: Complete Beginner

*"I'm new to Rails upgrades. Guide me through everything!"*

**Steps:**

1. **Read:** This README (10 min)
2. **Read:** QUICK-REFERENCE.md (15 min)
3. **Read:** Relevant version guide in `version-guides/` (30 min)
4. **Execute:** Follow the step-by-step guide in version guide (4-8 hours)
5. **Test:** Use testing checklist from `reference/testing-checklist.md` (2-3 hours)

**Time Investment:** 55 minutes prep + 6-11 hours execution  
**Outcome:** Successful upgrade with full understanding

---

### 🎯 Path 2: Experienced Developer

*"I've done Rails upgrades before. Give me the essentials."*

**Steps:**

1. **Scan:** QUICK-REFERENCE.md (5 min)
2. **Say to Claude:** "Upgrade my Rails app to [version]" (1 min)
3. **Review:** Generated report breaking changes section (15 min)
4. **Execute:** Apply changes using report as guide (3-6 hours)
5. **Test:** Run test suite and fix issues (1-2 hours)

**Time Investment:** 20 minutes prep + 4-8 hours execution  
**Outcome:** Efficient upgrade with minimal friction

---

### 🚀 Path 3: Advanced User (Multi-Hop)

*"I need to upgrade across multiple major versions."*

**Steps:**

1. **Read:** `reference/multi-hop-strategy.md` (15 min)
2. **Say to Claude:** "Plan upgrade from Rails [old] to [new]" (2 min)
3. **Review:** Claude's hop-by-hop strategy (10 min)
4. **Execute:** Complete each hop sequentially (1-3 weeks)
5. **Test:** Full testing between each hop (2-4 hours per hop)

**Time Investment:** 30 minutes planning + 1-3 weeks execution  
**Outcome:** Safe multi-version upgrade with clear progression

---

### 🔍 Path 4: Risk Assessment Only

*"I need to know what's involved before committing."*

**Steps:**

1. **Say to Claude:** "Assess upgrade impact from [version] to [version]" (1 min)
2. **Review:** Generated executive summary (10 min)
3. **Read:** `reference/breaking-changes-by-version.md` for your path (15 min)
4. **Check:** Custom code warnings in report (10 min)
5. **Decide:** Create timeline and resource plan (10 min)

**Time Investment:** 45 minutes  
**Outcome:** Clear understanding of scope, risk, and timeline

---

## 📋 Key Breaking Changes by Version

### Rails 8.0 → 8.1 (8 Changes)

**HIGH IMPACT:**
- SSL configuration now commented out (affects non-Kamal deploys)
- Database `pool:` renamed to `max_connections:`
- bundler-audit script required

**MEDIUM IMPACT:**
- Query parsing changes (semicolons removed)
- Some job adapters moved to gems

**Time:** 2-4 hours | **Difficulty:** ⭐ Easy

---

### Rails 7.2 → 8.0 (13 Changes)

**HIGH IMPACT:**
- Asset pipeline: Sprockets → Propshaft
- Solid gems: New defaults for cache/queue/cable
- Multi-database config required for Solid gems

**MEDIUM IMPACT:**
- Docker/Kamal integration
- Health check endpoint added
- Development SSL changes

**Time:** 6-8 hours | **Difficulty:** ⭐⭐⭐ Hard

---

### Rails 7.1 → 7.2 (38 Changes)

**HIGH IMPACT:**
- Transaction-aware job enqueuing (behavior change!)
- `ActiveRecord::Base.connection` deprecated
- `show_exceptions` changed from boolean to symbol
- `Rails.application.secrets` removed

**MEDIUM IMPACT:**
- PWA manifest support
- Browser version checking
- Multiple ActionMailer/ActiveRecord deprecations

**Time:** 4-6 hours | **Difficulty:** ⭐⭐ Medium

---

### Rails 7.0 → 7.1 (12 Changes)

**HIGH IMPACT:**
- `cache_classes` → `enable_reloading` (inverted logic!)
- Force SSL now default in production
- SQLite database moved to `storage/`

**MEDIUM IMPACT:**
- `lib/` autoloaded by default
- ActionMailer preview path plural
- Query log format changed

**Time:** 3-5 hours | **Difficulty:** ⭐⭐ Medium

---

### Rails 7.0 → 8.1 (Multi-Hop: All 71 Changes)

**REQUIRES:** 4 sequential hops (7.0→7.1→7.2→8.0→8.1)

**CUMULATIVE IMPACT:**
- All breaking changes from each version
- Multiple configuration migrations
- Significant architectural changes
- Extensive testing required

**Time:** 2-3 weeks | **Difficulty:** ⭐⭐⭐⭐ Very Hard

See: `reference/multi-hop-strategy.md` for detailed planning

---

## 🚨 Custom Code Detection & Preservation

The skill automatically detects and warns about customizations:

### Database Configuration

```ruby
⚠️ Custom SQLite path detected in config/database.yml
   Current: database: db/development.sqlite3
   Rails 7.1+: database: storage/development.sqlite3
   Action: Review and update path
```

### SSL Middleware

```ruby
⚠️ Custom SSL middleware detected in config/application.rb
   Line 23: middleware.use CustomSSLMiddleware
   Rails 7.1+: May conflict with config.force_ssl = true
   Action: Review compatibility and remove if redundant
```

### Autoload Paths

```ruby
⚠️ Custom autoload_paths in config/application.rb
   Line 15: config.autoload_paths << Rails.root.join('lib')
   Rails 7.1+: lib/ autoloaded by default (config.autoload_lib)
   Action: Remove manual path, may cause naming conflicts
```

### Cache Configuration

```ruby
⚠️ Explicit cache format version in config/application.rb
   Line 28: config.cache_format_version = 7.0
   Rails 7.1+: Can upgrade to 7.1 after full deployment
   Action: Consider upgrading format for performance
```

### Asset Pipeline

```ruby
⚠️ Custom Sprockets processors detected
   Files: lib/assets/processors/custom_minifier.rb
   Rails 8.0+: Propshaft doesn't support processors
   Action: Migrate to different approach or keep Sprockets
```

### Redis Configuration

```ruby
⚠️ Manual Redis configuration in config/initializers/
   File: config/initializers/redis.rb
   Rails 8.0+: Solid Cache may replace manual Redis setup
   Action: Consider migrating to Solid Cache or keep custom
```

**Every breaking change includes ⚠️ warnings for common customizations!**

---

## ✅ Pre-Upgrade Checklist

Before starting any upgrade:

### Critical (MUST DO)

- [ ] **All tests currently passing** (unit + integration + system)
- [ ] **Database backed up** (test restore procedure!)
- [ ] **Application under version control** (git with clean working directory)
- [ ] **Staging environment available** for testing
- [ ] **Rollback plan documented** (can you rollback in < 5 minutes?)
- [ ] **Team notified** of upgrade schedule and potential downtime
- [ ] **Error tracking configured** (Sentry, Honeybadger, etc.)

### Important (SHOULD DO)

- [ ] **Rails MCP server connected** and tested
- [ ] **Current version confirmed** (run `bin/rails -v`)
- [ ] **Dependencies reviewed** (check for gem compatibility)
- [ ] **Custom code documented** (know what you've customized)
- [ ] **Monitoring dashboards ready** (watch performance post-deploy)
- [ ] **Communication plan** (how to notify users if issues arise)

### Optional (NICE TO HAVE)

- [ ] **Neovim MCP for interactive mode** (if using advanced features)
- [ ] **Read full version guide** (for your specific upgrade path)
- [ ] **Review deprecation warnings** in current version
- [ ] **Plan time for optimization** (use new features, improve code)

---

## 🎯 What You Get from This Skill

### How Deliverables Are Generated

The skill uses dedicated workflow files to generate each deliverable:

1. **Upgrade Report** → Generated using `workflows/upgrade-report-workflow.md`
   - Provides step-by-step template population instructions
   - Ensures consistent, high-quality reports
   - Includes custom code detection patterns

2. **Detection Script** → Generated using `workflows/detection-script-workflow.md`
   - Converts YAML patterns to bash code
   - Creates automated scanning scripts
   - Includes pattern validation

3. **App:Update Preview** → Generated using `workflows/app-update-preview-workflow.md`
   - Identifies config files to update
   - Generates before/after comparisons
   - Integrates with Neovim for live updates

Each workflow file is loaded on-demand, ensuring Claude has detailed, focused instructions for generating that specific deliverable.

### Comprehensive Upgrade Report (50+ pages)

Every upgrade request generates a detailed report:

**1. Executive Summary**
- Current and target versions
- Number of breaking changes
- Estimated time
- Risk assessment
- ⚠️ Custom code warnings count

**2. Project Analysis**
- Your Rails version and structure
- Files that need updating
- Custom configurations detected
- Gemfile dependencies

**3. Breaking Changes** (Prioritized)
- **HIGH Priority:** Will cause app to fail
- **MEDIUM Priority:** Should address soon
- **LOW Priority:** Optional improvements

**4. Code Examples** (OLD vs NEW)
```ruby
# OLD (Rails 7.2)
config.action_dispatch.show_exceptions = true

# NEW (Rails 7.2 - will error on old syntax)
config.action_dispatch.show_exceptions = :all

# WHY: Symbol format provides finer control
# IMPACT: ⚠️ If custom exception handling middleware, review compatibility
```

**5. Custom Code Warnings** (⚠️)
- All detected customizations listed
- Specific files and line numbers
- Migration guidance for each
- Compatibility concerns

**6. Step-by-Step Migration Guide**
- Phase-by-phase breakdown
- Time estimates per phase
- Testing checkpoints
- Rollback procedures

**7. Testing Checklist**
- Unit test guidance
- Integration test scenarios
- System test coverage
- Manual testing checklist
- Performance benchmarks

**8. Deployment Strategy**
- Staging deployment steps
- Production deployment plan
- Monitoring guidance
- Rollback triggers

**9. Official Resources**
- Links to Rails guides
- CHANGELOG references
- Community resources

---

## 💡 Pro Tips

### 1. Always Read the Full Report First

Don't start making changes until you understand the complete scope. The report is designed to be read from start to finish.

### 2. Test Incrementally

Apply one change → test → commit → repeat. Don't make all changes at once.

```bash
# Good workflow
git checkout -b rails-upgrade
# Apply change 1
bin/rails test
git commit -am "Change 1: Update Gemfile"
# Apply change 2
bin/rails test
git commit -am "Change 2: Update config"
```

### 3. Use Staging Extensively

Especially for major version jumps (7.2 → 8.0), test thoroughly in staging before production.

### 4. Monitor Carefully Post-Deploy

Watch error rates, performance metrics, and user feedback closely for 24-48 hours after production deployment.

### 5. Keep Rollback Ready

Your rollback should be tested and executable in < 5 minutes. Practice it in staging first.

### 6. Multi-Hop: Complete Each Hop Fully

For multi-version upgrades, complete each hop entirely (including production deploy and monitoring) before starting the next hop.

### 7. Document As You Go

Keep notes on what worked, what didn't, and any custom workarounds. This helps future upgrades.

### 8. Focus on HIGH Priority First

Address all HIGH priority breaking changes before touching MEDIUM or LOW priority items.

---

## 🆘 Common Issues

### "Rails MCP server not connected"

**Solution:**

```bash
# Verify installation
npm list -g rails-mcp-server

# Reinstall if needed
npm install -g rails-mcp-server

# Check Claude configuration
cat ~/.config/Claude/config.json
# Verify "rails" is in mcpServers
```

### "Can't detect my Rails version"

**Solution:**

1. Ensure you're in Rails project root
2. Verify Gemfile exists
3. Check `gem 'rails'` line in Gemfile
4. Manually tell Claude: "My Rails version is X.Y.Z"

### "Interactive mode not working"

**Solution:**

1. Neovim must be running
2. Check socket exists: `ls /tmp/nvim-*.sock`
3. Verify project name matches socket name
4. Try report-only mode first
5. Check Neovim MCP server installation

### "Too many custom code warnings"

**Solution:**

This is normal! The skill is being thorough. Focus on:
1. HIGH priority warnings first
2. Warnings in files you actually use
3. Ignore warnings for files you plan to remove

### "Tests failing after upgrade"

**Solution:**

1. Ask Claude: "My tests are failing with [error message]"
2. Check `TROUBLESHOOTING.md` for your error
3. Review the breaking changes section for your upgrade
4. Verify you applied all required changes

### "Assets not loading after 7.2 → 8.0"

**Solution:**

This is the Sprockets → Propshaft migration. See:
1. `version-guides/upgrade-7.2-to-8.0.md` → Asset Pipeline section
2. Check `app/assets/config/manifest.js` exists
3. Verify asset paths in views
4. Review `TROUBLESHOOTING.md` → Assets section

---

## 📚 Documentation Structure

### Quick Reference Guide

**File:** `QUICK-REFERENCE.md`

**Contents:**
- Command cheat sheet
- Breaking changes summary
- Quick troubleshooting
- Common patterns
- Time estimates

**Use when:** You need fast lookup during active upgrade work

---

### Complete Usage Guide

**File:** `USAGE-GUIDE.md`

**Contents:**
- Detailed installation
- 30+ example prompts
- 4 complete workflows
- Best practices
- Advanced features

**Use when:** Learning the skill or complex upgrade planning

---

### Troubleshooting Guide

**File:** `TROUBLESHOOTING.md`

**Contents:**
- Common errors & solutions
- Error message lookup
- Debugging strategies
- Recovery procedures

**Use when:** Something went wrong and you need to fix it

---

### Version-Specific Guides

**Location:** `version-guides/`

**Files:**
- `upgrade-7.0-to-7.1.md` (70+ pages)
- `upgrade-7.1-to-7.2.md` (90+ pages)
- `upgrade-7.2-to-8.0.md` (85+ pages)
- `upgrade-8.0-to-8.1.md` (85+ pages)

**Contents:**
- Complete CHANGELOG analysis
- All breaking changes with OLD/NEW examples
- Component-by-component changes
- Migration steps
- Testing procedures

**Use when:** Executing a specific version upgrade

---

### Reference Materials

**Location:** `reference/`

**Files:**
- `breaking-changes-by-version.md` - Quick lookup table
- `multi-hop-strategy.md` - Multi-version upgrade planning
- `deprecations-timeline.md` - What's deprecated when
- `testing-checklist.md` - Comprehensive testing guide

**Use when:** You need specific reference information

---

### Examples

**Location:** `examples/`

**Files:**
- `simple-upgrade.md` - Single-hop walkthrough
- `complex-multi-hop.md` - Multi-version upgrade example
- `custom-code-handling.md` - Preserving customizations

**Use when:** You want to see real-world upgrade scenarios

---

## 🎉 Success Criteria

Your upgrade is successful when:

### Functionality ✅

- [ ] Application boots without errors
- [ ] All routes respond correctly
- [ ] Assets load properly (CSS, JS, images)
- [ ] Database queries execute correctly
- [ ] Background jobs process successfully
- [ ] Caching works as expected
- [ ] WebSockets/ActionCable functions
- [ ] Authentication/authorization works
- [ ] Third-party integrations work
- [ ] Email delivery functions

### Quality ✅

- [ ] All tests pass (100% of previous passing tests)
- [ ] No deprecation warnings in logs
- [ ] Test coverage maintained or improved
- [ ] Performance metrics stable or better
- [ ] No memory leaks detected
- [ ] No N+1 query regressions

### Deployment ✅

- [ ] Staging deployment successful
- [ ] Production deployment successful
- [ ] No error spikes in error tracking
- [ ] Monitoring dashboards healthy
- [ ] Users not reporting issues
- [ ] Rollback procedure tested and documented

### Documentation ✅

- [ ] Deployment docs updated
- [ ] Setup instructions updated
- [ ] Team trained on changes
- [ ] Runbooks updated
- [ ] CI/CD pipeline verified

---

## 🌟 What Makes This Skill Special?

### 1. Intelligent Analysis

- Reads YOUR actual project files
- Understands YOUR customizations
- Provides personalized guidance
- Not generic advice

### 2. Official Sources

- All recommendations from Rails CHANGELOGs
- Verified against GitHub sources
- Up-to-date with latest releases
- Not based on blog posts or opinions

### 3. Safety First

- Never modifies without permission
- Always provides rollback plans
- Includes comprehensive testing
- Warns about customizations

### 4. Two Operating Modes

- **Report-only:** For careful review
- **Interactive:** For rapid iteration
- You choose based on comfort level

### 5. Sequential Enforcement

- Prevents version skipping
- Plans multi-hop upgrades correctly
- Guides through each hop
- Ensures safe progression

### 6. Custom Code Preservation

- Automatically detects customizations
- Marks with ⚠️ warnings
- Provides specific guidance
- Helps maintain your code

---

## 📞 Getting Help

### From This Package

**Quick answers:**
→ `QUICK-REFERENCE.md`

**Detailed guidance:**
→ `USAGE-GUIDE.md`

**Troubleshooting:**
→ `TROUBLESHOOTING.md`

**Specific version:**
→ `version-guides/upgrade-X-to-Y.md`

### From Claude

Just ask! Examples:

```
"How do I use this skill?"
"What's the difference between the two modes?"
"Explain this breaking change in detail"
"Help me with this error: [error message]"
"Show me an example of [specific task]"
"What files do I need to update?"
"How long will this upgrade take?"
```

### From the Community

**Rails Guides:**
https://guides.rubyonrails.org

**Rails Upgrading Guide:**
https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

**Rails GitHub:**
https://github.com/rails/rails

**Rails Forum:**
https://discuss.rubyonrails.org

**Rails Discord:**
https://discord.gg/rails

---

## 🔄 Version History

### Version 1.0 (November 1, 2025)

**Coverage:**
- Rails 7.0.x → 7.1.6
- Rails 7.1.x → 7.2.3
- Rails 7.2.x → 8.0.4
- Rails 8.0.x → 8.1.1
- Multi-hop: Any path through above versions

**Based On:**
- Official Rails CHANGELOGs from GitHub
- rails-new-output diffs from railsdiff.org
- Real-world upgrade experience
- Community feedback

---

## 📊 Package Statistics

### Total Coverage

- **Rails Versions:** 7.0.x through 8.1.1 (5 versions)
- **Breaking Changes:** 71 documented across all versions
- **Code Examples:** 150+ OLD/NEW comparisons
- **Commands:** 50+ ready-to-use commands
- **Warnings:** 100+ custom code warnings

### Documentation Size

- **Core Files:** 5 files (~50 KB)
- **Version Guides:** 4 files (~320 KB)
- **Reference Materials:** 4 files (~30 KB)
- **Examples:** 3 files (~20 KB)
- **Total:** ~420 KB of documentation

### Time Estimates

| Upgrade Path | Read Time | Prep Time | Execution | Testing | Total |
|--------------|-----------|-----------|-----------|---------|-------|
| 8.0 → 8.1 | 30 min | 30 min | 2-4 hrs | 2-3 hrs | 5-8 hrs |
| 7.2 → 8.0 | 45 min | 1 hr | 6-8 hrs | 3-4 hrs | 11-14 hrs |
| 7.1 → 7.2 | 30 min | 45 min | 4-6 hrs | 2-3 hrs | 7-10 hrs |
| 7.0 → 7.1 | 30 min | 30 min | 3-5 hrs | 2-3 hrs | 6-9 hrs |
| 7.0 → 8.1 | 2 hrs | 2 hrs | 2-3 wks | 1 wk | 3-4 wks |

---

## 🎯 Ready to Upgrade?

### Your Next Steps:

1. **Install the skill** in your Claude Project
2. **Verify Rails MCP** server is connected
3. **Choose your path** from the Learning Paths section
4. **Say to Claude:** `"Upgrade my Rails app to [version]"`
5. **Review the report** carefully
6. **Follow the steps** one by one
7. **Test thoroughly** at each stage
8. **Deploy with confidence**

### Remember:

- 📖 Read documentation thoroughly
- 🧪 Test extensively before production
- 💾 Always have backups
- 🔄 Have rollback plan ready
- 👥 Communicate with your team
- 📊 Monitor closely after deployment

---

## 📜 License & Attribution

This skill package is created to help the Rails community upgrade safely and efficiently.
Copyright (c) 2025 Mario Alberto Chávez Cárdenas

**Rails** is a trademark of the Rails Core Team.
**Claude** is a product of Anthropic.

All Rails upgrade information is based on official Rails CHANGELOGs from the Rails GitHub repository.

---

## 🙏 Credits

**Created with:**
- Official Rails CHANGELOGs from GitHub
- Rails MCP server for intelligent project analysis
- Neovim MCP server for interactive file updates
- Rails diff data from railsdiff.org

---

## 📧 Feedback

Found this skill helpful? Have suggestions for improvement?

- Use the feedback button in Claude interface
- Share with the Rails community
- Contribute improvements back

---

**Questions? Just ask Claude:**

```
"How do I start using this Rails upgrade skill?"
"Show me an example upgrade"
"What should I read first?"
"Explain [specific concept]"
```

---

## 🚀 Let's Upgrade Your Rails App!

**The journey of 1,000 commits begins with a single command:**

```
"Upgrade my Rails app to [version]"
```

**Happy upgrading! 🎉**

---

**README Version:** 1.0 
**Last Updated:** November 1, 2025  
**Skill Version:** 1.0 
**Package Version:** Rails Upgrade Assistant
