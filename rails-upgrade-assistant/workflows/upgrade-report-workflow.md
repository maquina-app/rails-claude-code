# Upgrade Report Workflow

**Purpose:** Generate comprehensive upgrade reports with breaking changes, custom warnings, and migration steps

**When to use:** Every upgrade request (or when user specifically asks for upgrade report)

---

## Prerequisites

Before starting, ensure you have:
- Current Rails version (from `railsMcpServer:project_info`)
- Target Rails version (from user request)
- Project type (API-only or Full stack)

---

## Step-by-Step Workflow

### Step 1: Load Template

Read the upgrade report template:

```
railsMcpServer:get_file("templates/upgrade-report-template.md")
```

Note all `{PLACEHOLDER}` variables that need replacement.

---

### Step 2: Gather Project Data

**Use MCP tools to collect:**

```
1. railsMcpServer:project_info
   → Rails version, structure, type

2. railsMcpServer:get_file("Gemfile")
   → Gem dependencies

3. railsMcpServer:get_file("config/application.rb")
   → Application configuration

4. railsMcpServer:get_file("config/environments/production.rb")
   → Production settings

5. railsMcpServer:list_files("config/initializers")
   → Custom initializers
```

---

### Step 3: Load Version Guide

Determine upgrade path and load appropriate guide:

```
From 7.0 → 7.1: version-guides/upgrade-7.0-to-7.1.md
From 7.1 → 7.2: version-guides/upgrade-7.1-to-7.2.md
From 7.2 → 8.0: version-guides/upgrade-7.2-to-8.0.md
From 8.0 → 8.1: version-guides/upgrade-8.0-to-8.1.md
```

Extract:
- Breaking changes (HIGH/MEDIUM/LOW priority)
- New features
- Deprecations
- Configuration changes

---

### Step 4: Detect Custom Code

Search for custom configurations that may conflict:

**Common Custom Code Patterns:**

1. **Custom Middleware:**
   ```
   Search pattern: "use " in config files
   Flag: ⚠️ Custom middleware detected
   ```

2. **Manual Redis Configuration:**
   ```
   Search pattern: "Redis.new" in codebase
   Flag: ⚠️ Manual Redis configuration found
   ```

3. **Custom Asset Pipeline:**
   ```
   Search paths: config/initializers/assets.rb
   Flag: ⚠️ Custom asset configuration detected
   ```

4. **API-Specific Patterns:**
   ```
   Check: config.api_only in application.rb
   Flag: ⚠️ API-only application detected
   ```

---

### Step 5: Populate Template Variables

Replace all placeholders with actual values:

**Basic Info:**
- `{FROM_VERSION}` → "8.0.4"
- `{TO_VERSION}` → "8.1.1"
- `{GENERATION_DATE}` → Current date
- `{PROJECT_NAME}` → Detected project name
- `{UPGRADE_TYPE}` → "Single-hop" or "Multi-hop (hop X of Y)"

**Metrics:**
- `{COMPLEXITY_STARS}` → ⭐ to ⭐⭐⭐⭐⭐ (based on breaking changes count)
- `{TIME_ESTIMATE}` → "2-4 hours" (based on complexity)
- `{RISK_LEVEL}` → "Low", "Medium", "High", "Very High"
- `{BREAKING_CHANGES_COUNT}` → Count from version guide
- `{CUSTOM_WARNINGS_COUNT}` → Count of detected customizations
- `{HIGH_COUNT}`, `{MEDIUM_COUNT}`, `{LOW_COUNT}` → By priority

**Project Info:**
- `{PROJECT_ROOT}` → Full path
- `{CURRENT_RAILS_VERSION}` → From Gemfile
- `{RUBY_VERSION}` → From .ruby-version or Gemfile
- `{APP_TYPE}` → "Full Stack" or "API-only"
- `{DATABASE_TYPE}` → From database.yml

---

### Step 6: Populate Content Sections

**Breaking Changes Section:**

For each breaking change from version guide, create:

```markdown
### [Breaking Change Name]

**Priority:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW
**Component:** ActionCable / ActiveRecord / etc.

#### What Changed
- Clear explanation of the breaking change

#### Your Code (OLD)
\```ruby
# User's actual code from their project
config.force_ssl = true
\```

#### Updated Code (NEW)
\```ruby
# How it should look after upgrade
config.assume_ssl = true
config.force_ssl = true
\```

#### Why This Matters
- Impact on your application
- What breaks if not fixed

#### Action Required
1. Step-by-step fix instructions
2. Testing recommendations
```

**Custom Warnings Section:**

For each detected customization:

```markdown
⚠️ **Custom [Component] Detected**

**Location:** `path/to/file.rb`

**What We Found:**
\```ruby
# Actual code from user's project
\```

**Recommendation:**
- Review this customization carefully
- May conflict with new Rails defaults
- Test thoroughly after upgrade
```

---

### Step 7: Generate Migration Guide

Create 8-phase step-by-step plan:

```markdown
## Phase 1: Preparation
- [ ] Read this complete report
- [ ] Create backup
- [ ] Run all tests (verify 100% pass)

## Phase 2: Update Dependencies
- [ ] Update Gemfile
- [ ] Run bundle update rails
- [ ] Review bundler output

## Phase 3: Update Configuration
- [ ] Update config/application.rb
- [ ] Update config/environments/*.rb
- [ ] Run detection script

## Phase 4: Run rails app:update
- [ ] Run rails app:update
- [ ] Review each conflict
- [ ] Keep custom configurations

## Phase 5: Fix Breaking Changes
- [ ] Fix HIGH priority issues
- [ ] Fix MEDIUM priority issues
- [ ] Address deprecation warnings

## Phase 6: Update Tests
- [ ] Fix test failures
- [ ] Update test configurations
- [ ] Verify 100% pass rate

## Phase 7: Staging Deployment
- [ ] Deploy to staging
- [ ] Run smoke tests
- [ ] Monitor for errors

## Phase 8: Production Deployment
- [ ] Deploy to production
- [ ] Monitor closely
- [ ] Be ready to rollback
```

---

### Step 8: Add Testing Checklist

Include comprehensive testing checklist from:
```
reference/testing-checklist.md
```

---

### Step 9: Add Rollback Plan

```markdown
## When to Rollback

Rollback immediately if:
- Critical functionality broken
- Database errors
- Performance degradation > 50%
- Memory leaks detected

## How to Rollback

1. Git revert: git revert HEAD
2. Redeploy previous version
3. Verify all systems operational
4. Review what went wrong
```

---

### Step 10: Add Resources

```markdown
## Official Resources

- [Rails {VERSION} Release Notes](URL)
- [Upgrade Guide](URL)
- [CHANGELOG](URL)
- [API Documentation](URL)
```

---

### Step 11: Quality Check

Before delivering, verify:

- [ ] All {PLACEHOLDERS} replaced
- [ ] Every breaking change has OLD vs NEW code
- [ ] Custom code warnings included
- [ ] Used user's actual code (not generic)
- [ ] Testing checklist included
- [ ] Rollback plan included
- [ ] Resources section completed

**Full Checklist:** See `reference/quality-checklist.md`

---

### Step 12: Deliver Report

Present the complete report as markdown with:

1. Executive summary at top
2. Breaking changes prominently displayed
3. Custom warnings clearly flagged
4. Step-by-step migration guide
5. Testing checklist
6. Rollback plan

**Format:**
```markdown
# Rails Upgrade Report: {FROM_VERSION} → {TO_VERSION}

[Complete 50-page report here]
```

---

## Template Variable Reference

### Required Variables

| Variable | Example | Source |
|----------|---------|--------|
| `{FROM_VERSION}` | "8.0.4" | project_info |
| `{TO_VERSION}` | "8.1.1" | User request |
| `{PROJECT_NAME}` | "my-rails-app" | Gemfile or dir name |
| `{GENERATION_DATE}` | "November 2, 2025" | Current date |
| `{BREAKING_CHANGES_COUNT}` | "2" | Version guide |
| `{CUSTOM_WARNINGS_COUNT}` | "3" | Detected customs |

### Optional Variables

| Variable | Example | When to Use |
|----------|---------|-------------|
| `{UPGRADE_TYPE}` | "Multi-hop (hop 2 of 4)" | Multi-hop only |
| `{TESTS_COUNT}` | "1,247" | If detectable |
| `{FILES_COUNT}` | "8" | From analysis |

---

## Common Pitfalls

❌ **Don't:**
- Use generic code examples
- Skip custom code detection
- Leave {PLACEHOLDERS} unreplaced
- Copy/paste from version guide verbatim

✅ **Do:**
- Use user's actual code
- Flag all customizations
- Provide clear OLD→NEW examples
- Explain WHY changes matter

---

## Example Output Structure

```markdown
# Rails Upgrade Report: 8.0.4 → 8.1.1

## Executive Summary
[TL;DR with key findings]

## Project Analysis
[User's specific project details]

## Breaking Changes (2)
### 🔴 HIGH: SSL Configuration Changes
[OLD code] → [NEW code]

## Custom Code Warnings (3)
⚠️ Custom middleware detected
⚠️ Manual Redis configuration

## Migration Guide
[8 phases with checkboxes]

## Testing Checklist
[Comprehensive testing plan]

## Rollback Plan
[When and how to rollback]

## Resources
[Official Rails documentation]
```

---

**Related Files:**
- Template: `templates/upgrade-report-template.md`
- Examples: `examples/simple-upgrade.md`
- Quality Check: `reference/quality-checklist.md`
