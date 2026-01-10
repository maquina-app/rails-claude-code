---
title: "Rails Upgrade Quick Reference - All Versions"
description: "Fast lookup reference for Rails upgrades covering commands, breaking changes, troubleshooting, and multi-hop strategies for versions 7.0 through 8.1"
type: "quick-reference"
audience: "users"
purpose: "fast-lookup"
rails_versions: "7.0.x to 8.1.1"
read_time: "10-15 minutes"
breaking_changes_total: 71
tags:
  - quick-reference
  - commands
  - breaking-changes
  - troubleshooting
  - cheat-sheet
category: "reference"
priority: "high"
read_order: 3
print_friendly: true
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# ⚡ Rails Upgrade Quick Reference

**Quick Reference for Rails 7.0 → 8.1**  
**Version:** 1.0 | **Last Updated:** November 1, 2025

---

## 📖 How to Use This Guide

This quick reference contains commands, checklists, and breaking changes for all supported Rails upgrades. Jump directly to your target version section:

- **[Common Commands](#-common-commands-all-versions)** - Works for any version
- **[Rails 7.1](#-upgrading-to-rails-71-from-70)** - 7.0 → 7.1 Quick Ref
- **[Rails 7.2](#-upgrading-to-rails-72-from-71)** - 7.1 → 7.2 Quick Ref
- **[Rails 8.0](#-upgrading-to-rails-80-from-72)** - 7.2 → 8.0 Quick Ref
- **[Rails 8.1](#-upgrading-to-rails-81-from-80)** - 8.0 → 8.1 Quick Ref
- **[Multi-Hop](#-multi-hop-upgrades)** - Upgrading across multiple versions
- **[Troubleshooting](#-general-troubleshooting)** - Common issues & fixes

**For detailed guidance:** See `version-guides/upgrade-X-to-Y.md` for your specific path

---

## 🚀 Common Commands (All Versions)

### Quick Start Any Upgrade

```bash
# 1. Create backup & branch
git checkout -b rails-upgrade
git add -A && git commit -m "Pre-upgrade checkpoint"

# 2. Backup database
pg_dump myapp_production > backup.sql  # PostgreSQL
# or your backup method

# 3. Verify tests pass
bin/rails test

# 4. Update Gemfile
vim Gemfile  # Update Rails version

# 5. Install
bundle update rails
bundle install

# 6. Update Rails config
bin/rails app:update

# 7. Run migrations (if any)
bin/rails db:migrate

# 8. Test everything
bin/rails test
bin/rails test:system

# 9. Check for deprecations
grep -r "DEPRECATION" log/test.log

# 10. Deploy to staging
git push staging main
```

### Universal Testing Commands

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test by line
bin/rails test test/models/user_test.rb:42

# Run system tests
bin/rails test:system

# Run with verbose output
bin/rails test -v

# Check for slow tests
bin/rails test --profile

# Parallel testing
bin/rails test --parallel
```

### Universal Detection Commands

```bash
# Check current Rails version
bin/rails -v

# List all gems
bundle list

# Check for outdated gems
bundle outdated rails

# Check migration status
bin/rails db:migrate:status

# Check for pending migrations
bin/rails db:migrate:status | grep down

# Find deprecation warnings
grep -r "DEPRECATION" log/

# Check routes
bin/rails routes

# Check for unused routes
bin/rails routes --unused
```

### Quick Rollback (Any Version)

```bash
# Rollback to previous version
git reset --hard HEAD^
bundle install

# Rollback migrations (if needed)
bin/rails db:rollback STEP=N

# Restore database (if needed)
psql myapp_development < backup.sql
```

---

## 🎯 Upgrading to Rails 7.1 (from 7.0)

**Difficulty:** ⭐⭐ Medium | **Time:** 2-4 hours | **Breaking Changes:** 12

### Top 5 Breaking Changes

#### 1. cache_classes → enable_reloading ⚠️ INVERTED LOGIC

```ruby
# config/environments/*.rb

# OLD ❌
config.cache_classes = false  # Development/test
config.cache_classes = true   # Production

# NEW ✅
config.enable_reloading = true   # Development/test (inverted!)
config.enable_reloading = false  # Production (inverted!)
```

**Action:** Replace in ALL environment files. Boolean is inverted!

---

#### 2. Force SSL Now Default in Production

```ruby
# config/environments/production.rb

# OLD ❌
# (nothing, or commented out)

# NEW ✅
config.force_ssl = true        # Now default ON
config.assume_ssl = true       # Add if behind load balancer
```

**Action:** Explicitly disable if not using SSL: `config.force_ssl = false`

---

#### 3. ActionMailer Preview Path → Plural

```ruby
# config/application.rb or config/environments/*.rb

# OLD ❌
config.action_mailer.preview_path = "test/mailers/previews"

# NEW ✅
config.action_mailer.preview_paths = ["test/mailers/previews"]
```

**Action:** Change singular to plural, wrap in array

---

#### 4. SQLite Database Location Moved

```yaml
# config/database.yml

# OLD ❌
development:
  database: db/development.sqlite3

# NEW ✅
development:
  database: storage/development.sqlite3
```

**Action:** Update paths, move files: `mv db/*.sqlite3 storage/`

---

#### 5. lib/ Autoloaded by Default

```ruby
# config/application.rb

# NEW ✅ (add this)
config.autoload_lib(ignore: %w[assets tasks])
```

**Action:** Add this line. Review `lib/` for naming conflicts.

---

### Quick Migration Checklist (7.0 → 7.1)

**Core Updates (30 min):**

- [ ] Update Gemfile: `gem "rails", "~> 7.1.6"`
- [ ] Update `config/application.rb`: `config.load_defaults 7.1`
- [ ] Replace `cache_classes` with `enable_reloading` (ALL env files)
- [ ] Review production SSL config
- [ ] Update `preview_path` → `preview_paths`
- [ ] Update `database.yml` if using SQLite
- [ ] Add `config.autoload_lib(ignore: %w[assets tasks])`

**Testing (1-2 hours):**

- [ ] Run full test suite
- [ ] Check for deprecation warnings
- [ ] Test in browser
- [ ] Deploy to staging

**Optional Improvements:**

- [ ] Enable cache format 7.1: `config.active_support.cache_format_version = 7.1`
- [ ] Add health check: `get "up" => "rails/health#show"`
- [ ] Add verbose job logs (development)

### Detection Commands (7.0 → 7.1)

```bash
# Find cache_classes usage
grep -r "cache_classes" config/

# Find singular preview_path
grep -r "preview_path[^s]" config/

# Find old database paths
grep -r "database: db/" config/

# Find manual autoload_paths for lib/
grep -r "autoload_paths.*lib" config/

# Find custom SSL middleware
grep -r "force_ssl\|SSL" config/
```

### Key Takeaways (7.0 → 7.1)

1. **cache_classes → enable_reloading** (INVERTED boolean!)
2. **force_ssl ON by default** in production
3. **SQLite moved** from db/ to storage/
4. **lib/ autoloaded** (watch for conflicts)
5. **preview_path → preview_paths** (plural)

---

## 🎯 Upgrading to Rails 7.2 (from 7.1)

**Difficulty:** ⭐⭐⭐ Hard | **Time:** 4-6 hours | **Breaking Changes:** 38

### Top 5 Breaking Changes

#### 1. Transaction-Aware Job Enqueuing ⚠️ BIGGEST BEHAVIOR CHANGE

**What:** Jobs in transactions now wait for commit before enqueuing

```ruby
# Rails 7.2 NEW behavior:
Topic.transaction do
  topic = Topic.create(name: "Rails")
  NotificationJob.perform_later(topic)  # Waits for commit!
end

# To restore old behavior (enqueue immediately):
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end
```

**Detection:**

```bash
grep -r "\.transaction do" app/models/
grep -r "perform_later\|perform_now" app/models/
```

---

#### 2. ActiveRecord::Base.connection Deprecated

```ruby
# OLD ❌ (deprecated)
ActiveRecord::Base.connection.execute("SELECT 1")

# NEW ✅ (Option 1 - recommended)
ActiveRecord::Base.with_connection do |conn|
  conn.execute("SELECT 1")
end

# NEW ✅ (Option 2)
ActiveRecord::Base.lease_connection.execute("SELECT 1")
```

**Detection:**

```bash
grep -rn "\.connection[^_]" app/ lib/ | \
  grep -v "with_connection\|lease_connection"
```

---

#### 3. show_exceptions: true/false Removed

```ruby
# config/environments/*.rb

# OLD ❌ (removed - will error)
config.action_dispatch.show_exceptions = true
config.action_dispatch.show_exceptions = false

# NEW ✅
config.action_dispatch.show_exceptions = :all       # like true
config.action_dispatch.show_exceptions = :rescuable # only rescuable errors
config.action_dispatch.show_exceptions = :none      # like false
```

**Detection:**

```bash
grep -r "show_exceptions.*true\|show_exceptions.*false" config/
```

---

#### 4. params == Hash Comparison Removed

```ruby
# OLD ❌ (removed - will error)
if params == { name: "John" }

# NEW ✅
if params.to_h == { name: "John" }
```

**Detection:**

```bash
grep -rn "params.*==" app/controllers/
```

---

#### 5. Rails.application.secrets Removed

```ruby
# OLD ❌ (completely removed)
Rails.application.secrets.api_key

# NEW ✅
Rails.application.credentials.api_key
```

**Detection:**

```bash
grep -r "Rails\.application\.secrets" app/ lib/ config/
```

---

### Quick Migration Checklist (7.1 → 7.2)

**Core Updates (45 min):**

- [ ] Update Gemfile: `gem "rails", "~> 7.2.3"`
- [ ] Update `config/application.rb`: `config.load_defaults 7.2`
- [ ] Fix `show_exceptions` in all environment files (symbol syntax)
- [ ] Replace `params == hash` with `params.to_h == hash`
- [ ] Migrate `.connection` to `.with_connection`
- [ ] Replace `secrets` with `credentials`
- [ ] Fix `serialize` to use `type:` or `coder:` parameter

**Environment Config Updates:**

```ruby
# config/environments/development.rb - ADD
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
config.action_view.annotate_rendered_view_with_filenames = true

# config/environments/test.rb - ADD
config.action_mailer.default_url_options = { host: "www.example.com" }

# config/environments/production.rb - UPDATE
config.action_dispatch.show_exceptions = :all  # was true
config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
```

**Code Fixes:**

- [ ] Review jobs enqueued in transactions (test timing!)
- [ ] Update model `serialize` syntax
- [ ] Fix mailer test assertions (args → params)
- [ ] Remove deprecated ActiveSupport methods

### Complete Detection Command Suite (7.1 → 7.2)

```bash
# Run all detection commands:

# 1. Old show_exceptions
grep -r "show_exceptions.*true\|show_exceptions.*false" config/

# 2. Params comparison  
grep -rn "params.*==" app/controllers/

# 3. Deprecated .connection
grep -rn "\.connection[^_]" app/ lib/ | grep -v "with_connection\|lease_connection"

# 4. Old serialize syntax
grep -r "serialize\s*:" app/models/ | grep -v "type:\|coder:"

# 5. query_constraints (deprecated)
grep -r "query_constraints" app/models/

# 6. Removed secrets
grep -r "Rails\.application\.secrets" app/ lib/ config/

# 7. Old mailer config
grep -r "preview_path[^s]" config/

# 8. Old mailer test syntax
grep -r "assert_enqueued_email_with.*:args" spec/ test/

# 9. Deprecated ActiveSupport
grep -r "to_default_s\|clone_empty" app/ lib/

# 10. Old fixture_path
grep -r "fixture_path[^s]" spec/ test/
```

### Key Takeaways (7.1 → 7.2)

1. **Transaction-aware jobs** - BIGGEST behavior change, test carefully!
2. **show_exceptions** - Must use symbols now (:all/:rescuable/:none)
3. **ActiveRecord.connection** - Use with_connection or lease_connection
4. **params comparison** - Must convert to hash first
5. **secrets removed** - Use credentials instead

---

## 🎯 Upgrading to Rails 8.0 (from 7.2)

**Difficulty:** ⭐⭐⭐⭐ Very Hard | **Time:** 6-8 hours | **Breaking Changes:** 13

### Top 5 Breaking Changes

#### 1. Asset Pipeline: Sprockets → Propshaft ⚠️ MAJOR CHANGE

```ruby
# Gemfile

# OLD ❌ REMOVE
gem "sprockets-rails"

# NEW ✅ ADD
gem "propshaft"
```

```bash
# Remove Sprockets manifest (no longer needed)
rm app/assets/config/manifest.js
```

```css
/* app/assets/stylesheets/application.css */

/* OLD - Sprockets directives (REMOVE) */
/*
 *= require_tree .
 *= require_self
 */

/* NEW - Propshaft (no preprocessing directives needed) */
/* Just import your stylesheets normally */
```

```erb
<!-- app/views/layouts/application.html.erb -->

<!-- OLD -->
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>

<!-- NEW -->
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
```

**Detection:**

```bash
grep -r "sprockets" Gemfile
ls app/assets/config/manifest.js
grep -r "require_tree\|require_self" app/assets/
```

---

#### 2. Multi-Database Configuration Required

```yaml
# config/database.yml

# OLD ❌ Single database
production:
  <<: *default
  database: storage/production.sqlite3

# NEW ✅ Multi-database (for Solid gems)
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/production_cable.sqlite3
    migrations_paths: db/cable_migrate
```

**Setup:**

```bash
# Create migration directories
mkdir -p db/cache_migrate db/queue_migrate db/cable_migrate
```

---

#### 3. Solid Gems: New Defaults for Cache/Queue/Cable

```ruby
# Gemfile - ADD (optional but recommended)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

```bash
# Install (creates migrations and config)
rails solid_cache:install
rails solid_queue:install
rails solid_cable:install

# Run migrations
rails db:migrate
```

**Note:** These are optional. You can keep Redis/Sidekiq/etc if preferred.

---

#### 4. SSL Configuration Changes

```ruby
# config/environments/production.rb

# NEW ✅ (add if not using Kamal)
config.assume_ssl = true   # NEW in Rails 8.0
config.force_ssl = true
```

---

#### 5. Removed Deprecations

```ruby
# ❌ REMOVED (will cause errors in Rails 8.0)
config.active_record.sqlite3_deprecated_warning
config.active_job.use_big_decimal_serializer
ActiveRecord::ConnectionPool#connection  # Use with_connection
ActiveSupport::ProxyObject              # Use BasicObject
```

---

### Quick Migration Checklist (7.2 → 8.0)

**Phase 1: Gemfile (15 min)**

- [ ] Update: `gem "rails", "~> 8.0.4"`
- [ ] Remove: `gem "sprockets-rails"`
- [ ] Add: `gem "propshaft"`
- [ ] Add: `gem "solid_cache"` (optional)
- [ ] Add: `gem "solid_queue"` (optional)
- [ ] Add: `gem "solid_cable"` (optional)
- [ ] Run: `bundle install`

**Phase 2: Asset Pipeline (30 min)**

- [ ] Remove: `app/assets/config/manifest.js`
- [ ] Update layout: `stylesheet_link_tag :app` (not "application")
- [ ] Remove Sprockets directives from CSS/JS
- [ ] Test assets load correctly

**Phase 3: Database (45 min)**

- [ ] Update `config/database.yml` (multi-database structure)
- [ ] Create migration directories: `mkdir -p db/{cache,queue,cable}_migrate`
- [ ] Run Solid gem install tasks (if using)
- [ ] Run: `rails db:migrate`

**Phase 4: Configuration (30 min)**

- [ ] Update `config/application.rb`: `config.load_defaults 8.0`
- [ ] Review SSL settings in `config/environments/production.rb`
- [ ] Remove deprecated config options
- [ ] Update environment-specific configs

**Phase 5: Testing (2-3 hours)**

- [ ] Run: `rails test`
- [ ] Run: `rails test:system`
- [ ] Manual asset testing
- [ ] Database connection testing
- [ ] Background job testing (if using Solid Queue)
- [ ] Cache testing (if using Solid Cache)

### Detection Commands (7.2 → 8.0)

```bash
# Find Sprockets usage
grep -r "sprockets" Gemfile
ls app/assets/config/manifest.js
grep -r "require_tree\|require_self" app/assets/

# Find single-database config
grep -A 5 "production:" config/database.yml | grep -v "primary:"

# Find old SSL config
grep -r "force_ssl" config/ | grep -v "assume_ssl"

# Find deprecated config
grep -r "sqlite3_deprecated_warning\|use_big_decimal_serializer" config/

# Find old connection usage
grep -r "ConnectionPool#connection" app/ lib/
```

### Common Issues & Quick Fixes (7.2 → 8.0)

| Issue                     | Cause                 | Fix                                         |
| ------------------------- | --------------------- | ------------------------------------------- |
| Assets not loading        | Propshaft config      | Check stylesheet_link_tag :app              |
| DB connection errors      | database.yml wrong    | Use multi-database structure                |
| Jobs not processing       | Solid Queue not setup | Run solid_queue:install                     |
| SSL redirect loops        | Missing assume_ssl    | Add config.assume_ssl = true                |
| Sprockets errors          | Not removed properly  | Remove gem, remove manifest.js              |
| Migration directory error | Dirs not created      | mkdir -p db/{cache,queue,cable}\_migrate    |

### Key Takeaways (7.2 → 8.0)

1. **Propshaft** replaces Sprockets (no preprocessing)
2. **Multi-database** config required for Solid gems
3. **Solid gems** optional but recommended for cache/queue/cable
4. **SSL config** changed (assume_ssl added)
5. **Major version** means more breaking changes - test thoroughly!

---

## 🎯 Upgrading to Rails 8.1 (from 8.0)

**Difficulty:** ⭐ Easy | **Time:** 2-4 hours | **Breaking Changes:** 8

### Top 5 Breaking Changes

#### 1. SSL Configuration Now Commented Out

```ruby
# config/environments/production.rb

# CHANGED - Now commented by default (for Kamal)
# config.assume_ssl = true
# config.force_ssl = true

# ⚠️ Uncomment these if NOT using Kamal!
```

**Action:** Uncomment SSL lines if you're not using Kamal deployment

---

#### 2. Database pool: → max_connections:

```yaml
# config/database.yml

# OLD ❌
default: &default
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

# NEW ✅
default: &default
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

**Action:** Replace ALL occurrences of `pool:` with `max_connections:`

---

#### 3. Semicolon Query Separator Removed

```ruby
# URL parameter parsing

# OLD ❌ (no longer works)
"?foo=bar;baz=qux"

# NEW ✅
"?foo=bar&baz=qux"
```

**Detection:**

```bash
grep -r ";" app/ | grep -E "(params|query|url)"
```

---

#### 4. bundler-audit Required

```ruby
# Gemfile - ADD
group :development, :test do
  gem "bundler-audit", require: false
end
```

```bash
# Create script
cat > bin/bundler-audit << 'EOF'
#!/usr/bin/env ruby
require_relative "../config/boot"
require "bundler/audit/cli"

ARGV.concat %w[ --config config/bundler-audit.yml ] if ARGV.empty? || ARGV.include?("check")
Bundler::Audit::CLI.start
EOF

chmod +x bin/bundler-audit
```

```yaml
# config/bundler-audit.yml
ignore:
  - CVE-THAT-DOES-NOT-APPLY
```

---

#### 5. ActiveJob Adapters Removed

```ruby
# ❌ REMOVED from Rails
:sidekiq        # Now in sidekiq gem 7.3.3+
:sucker_punch   # Now in sucker_punch gem

# ✅ UPDATE Gemfile
gem "sidekiq", ">= 7.3.3"  # Includes adapter
```

---

### 5-Minute Migration Checklist (8.0 → 8.1)

**Minimal Upgrade (30 min):**

- [ ] Update Gemfile: `gem "rails", "~> 8.1.1"`
- [ ] Update `config/application.rb`: `config.load_defaults 8.1`
- [ ] Update `config/database.yml`: `pool:` → `max_connections:`
- [ ] Uncomment SSL in production.rb (if not using Kamal)
- [ ] Run: `bundle update rails`
- [ ] Run: `bin/rails test`

**Recommended Upgrade (2 hours):**

- [ ] All above +
- [ ] Add `bundler-audit` gem
- [ ] Create `bin/bundler-audit` script
- [ ] Create `config/bundler-audit.yml`
- [ ] Update ApplicationController: add `stale_when_importmap_changes`
- [ ] Add `image_processing` gem (uncommented)
- [ ] Run: `bin/bundler-audit`
- [ ] Test in staging

**Complete Upgrade (1 day):**

- [ ] All above +
- [ ] Create `bin/ci` and `config/ci.rb`
- [ ] Update GitHub Actions to @v5
- [ ] Update Dockerfile (if using)
- [ ] Update dependabot config
- [ ] Regenerate error pages
- [ ] Full documentation update

### Critical File Changes (8.0 → 8.1)

**Gemfile:**

```ruby
# Update Rails
gem "rails", "~> 8.1.1"                          # was 8.0.4

# Uncomment
gem "image_processing", "~> 1.2"                 # was commented

# Add
group :development, :test do
  gem "bundler-audit", require: false            # NEW
end
```

**config/application.rb:**

```ruby
config.load_defaults 8.1  # was 8.0
```

**config/database.yml:**

```yaml
# GLOBAL CHANGE
max_connections:  # was pool:
```

**config/environments/production.rb:**

```ruby
# These are NOW COMMENTED by default
# config.assume_ssl = true
# config.force_ssl = true

# Uncomment if NOT using Kamal!
```

**app/controllers/application_controller.rb:**

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes  # ADD this line
end
```

**.gitignore:**

```
/config/*.key  # was /config/master.key
```

### Detection Commands (8.0 → 8.1)

```bash
# Find pool: (should be max_connections:)
grep -r "pool:" config/database.yml

# Find semicolon separators
grep -r ";" app/ | grep -E "(params|query)"

# Find SSL config
grep -r "force_ssl\|assume_ssl" config/environments/production.rb

# Find Azure storage (removed)
grep -r "azure" config/storage.yml

# Find unsigned MySQL types (deprecated)
grep -r "unsigned_" db/migrate/

# Check if bundler-audit exists
ls bin/bundler-audit
```

### Quick Fixes (8.0 → 8.1)

**Fix: Database Pool Error**

```yaml
# config/database.yml
max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

**Fix: SSL Not Working**

```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

**Fix: Bundler Audit Missing**

```bash
bundle add bundler-audit --group "development,test"
chmod +x bin/bundler-audit
```

**Fix: Semicolon Parameters**

```ruby
# Replace in API clients
# OLD: "?foo=bar;baz=qux"
# NEW: "?foo=bar&baz=qux"
```

### Key Takeaways (8.0 → 8.1)

1. **SSL defaults changed** (commented for Kamal)
2. **pool: → max_connections:** (database.yml)
3. **bundler-audit** now part of Rails setup
4. **Semicolons removed** from query parsing
5. **Easy upgrade** (smallest breaking changes of all)

---

## 🔄 Multi-Hop Upgrades

### Understanding Multi-Hop Upgrades

**You CANNOT skip versions!** Rails upgrades must be sequential:

```
✅ Correct:  7.0 → 7.1 → 7.2 → 8.0 → 8.1
❌ Wrong:    7.0 → 8.0 (skips 7.1, 7.2)
❌ Wrong:    7.1 → 8.0 (skips 7.2)
❌ Wrong:    7.0 → 7.2 (skips 7.1)
```

### Recommended Multi-Hop Strategy

1. **Complete each hop fully** before moving to next
2. **Deploy to production** between hops
3. **Monitor for 24-48 hours** before next hop
4. **Test thoroughly** at each step

### Example: 7.0 → 8.1 (4 Hops)

**Timeline: 2-3 weeks**

```
Week 1:
  Day 1-2:   7.0 → 7.1 (implement + test)
  Day 3:     Deploy to staging
  Day 4-5:   Deploy to production + monitor

Week 2:
  Day 1-2:   7.1 → 7.2 (implement + test)
  Day 3:     Deploy to staging
  Day 4-5:   Deploy to production + monitor

Week 3:
  Day 1-3:   7.2 → 8.0 (implement + test, more complex)
  Day 4:     Deploy to staging
  Day 5:     Deploy to production + monitor

Week 4:
  Day 1:     8.0 → 8.1 (implement + test, easy)
  Day 2:     Deploy to staging
  Day 3:     Deploy to production + monitor
  Day 4-5:   Final verification + documentation
```

### Multi-Hop Checklist

**Before Starting:**

- [ ] Read all relevant version guides
- [ ] Understand cumulative breaking changes
- [ ] Plan timeline (2-4 weeks recommended)
- [ ] Get team buy-in
- [ ] Schedule deployment windows

**Between Each Hop:**

- [ ] Deploy to production
- [ ] Monitor for 24-48 hours
- [ ] Verify all features work
- [ ] Check performance metrics
- [ ] Review error logs
- [ ] Get team signoff

**After Final Hop:**

- [ ] Full system verification
- [ ] Update documentation
- [ ] Team training on changes
- [ ] Celebrate! 🎉

### Quick Commands for Multi-Hop

```bash
# Start each hop with clean slate
git checkout -b rails-7.X-upgrade
git pull origin main

# Complete hop
# [... do upgrade work ...]
bin/rails test
git commit -am "Upgrade to Rails 7.X"

# Deploy
git push staging
# [test in staging]
git push production

# Monitor
tail -f log/production.log
# [watch error tracking dashboard]

# After 24-48 hours, start next hop
```

---

## 🆘 General Troubleshooting

### Most Common Issues (All Versions)

#### Tests Failing After Upgrade

```bash
# Check for deprecation warnings
grep -r "DEPRECATION" log/test.log

# Run with verbose output
bin/rails test -v

# Check specific failing test
bin/rails test path/to/failing_test.rb:LINE

# Clear cache
rm -rf tmp/cache
bin/rails tmp:clear

# Regenerate schema
bin/rails db:schema:dump
```

#### Assets Not Loading

```bash
# Rails 7.x (Sprockets)
bin/rails assets:precompile
bin/rails assets:clobber

# Rails 8.x (Propshaft)
# Propshaft doesn't precompile - check:
ls public/assets/  # Should be empty
# Assets served directly from app/assets/

# Check layout file
grep stylesheet_link_tag app/views/layouts/application.html.erb
# Should be: stylesheet_link_tag :app (Rails 8)
```

#### Database Connection Errors

```bash
# Check database exists
bin/rails db:exists

# Check migrations
bin/rails db:migrate:status

# Reset if needed (development only!)
bin/rails db:reset

# Check config
cat config/database.yml

# Test connection
bin/rails runner "puts ActiveRecord::Base.connection.active?"
```

#### Background Jobs Not Processing

```bash
# Check job adapter
grep -r "active_job.queue_adapter" config/

# If using Solid Queue (Rails 8.x)
bin/rails solid_queue:start

# Check job queue
bin/rails runner "puts ActiveJob::Base.queue_adapter"

# Check for stuck jobs
bin/rails runner "puts SolidQueue::Job.count"
```

#### SSL Issues (Production)

```bash
# Check configuration
grep -r "force_ssl\|assume_ssl" config/environments/production.rb

# Test in browser
curl -I https://yourapp.com
# Should return 200, not redirect loop

# Check load balancer
# Ensure X-Forwarded-Proto header is set correctly

# Disable temporarily for testing
# config.force_ssl = false
```

#### Deprecation Warnings

```bash
# Find all deprecation warnings
grep -r "DEPRECATION" log/

# Check specific warning
bin/rails runner "
  ActiveSupport::Deprecation.behavior = :stderr
  # Your code here
"

# Update deprecated code
# See version-specific sections above
```

### Environment-Specific Issues

#### Development Environment

```bash
# Clear cache
rm -rf tmp/cache/*

# Reset development database
bin/rails db:reset

# Check logs
tail -f log/development.log

# Restart server
# (Ctrl+C and restart bin/rails server)
```

#### Test Environment

```bash
# Reset test database
bin/rails db:test:prepare

# Clear test cache
RAILS_ENV=test bin/rails tmp:clear

# Run with backtrace
bin/rails test --backtrace

# Check test logs
cat log/test.log
```

#### Production Environment

```bash
# Check for errors
tail -f log/production.log | grep ERROR

# Check background jobs
# (depends on your adapter)

# Verify assets
ls public/assets/  # Should exist and be populated (Rails 7)
# or served from app/assets/ (Rails 8 Propshaft)

# Test database connection
bin/rails runner "puts ActiveRecord::Base.connection.active?" RAILS_ENV=production
```

### Quick Health Check Commands

```bash
# Overall health check
bin/rails runner "puts 'OK'" && echo "✅ Rails works"

# Database
bin/rails runner "User.count" && echo "✅ Database works"

# Cache
bin/rails runner "Rails.cache.write('test', 'ok'); \
  Rails.cache.read('test')" && echo "✅ Cache works"

# Jobs (if using Active Job)
bin/rails runner "TestJob.perform_later" && echo "✅ Jobs work"

# All tests
bin/rails test && echo "✅ All tests pass"
```

---

## 📚 Quick Links

### Documentation in This Package

- **Main Skill File:** `SKILL.md` - Complete instructions for Claude
- **README:** `README.md` - Getting started guide
- **Usage Guide:** `USAGE-GUIDE.md` - Detailed how-to
- **Troubleshooting:** `TROUBLESHOOTING.md` - Common issues & solutions

### Version-Specific Guides

- **Rails 7.0 → 7.1:** `version-guides/upgrade-7.0-to-7.1.md`
- **Rails 7.1 → 7.2:** `version-guides/upgrade-7.1-to-7.2.md`
- **Rails 7.2 → 8.0:** `version-guides/upgrade-7.2-to-8.0.md`
- **Rails 8.0 → 8.1:** `version-guides/upgrade-8.0-to-8.1.md`

### Reference Materials

- **Breaking Changes:** `reference/breaking-changes-by-version.md`
- **Multi-Hop Strategy:** `reference/multi-hop-strategy.md`
- **Deprecations Timeline:** `reference/deprecations-timeline.md`
- **Testing Checklist:** `reference/testing-checklist.md`

### Official Rails Resources

- **Rails Guides:** https://guides.rubyonrails.org
- **Upgrading Guide:** https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- **Rails GitHub:** https://github.com/rails/rails
- **Rails Forum:** https://discuss.rubyonrails.org
- **Rails Discord:** https://discord.gg/rails

---

## 🎯 Using This Quick Reference

### During Active Upgrade

1. Jump to your target version section
2. Follow the quick migration checklist
3. Run detection commands
4. Apply fixes from examples
5. Use troubleshooting section as needed

### For Planning

1. Review breaking changes table
2. Estimate time using difficulty ratings
3. Read key takeaways
4. Plan multi-hop timeline if needed

### For Quick Lookup

1. Use Ctrl+F / Cmd+F to search
2. Check common commands section
3. Review troubleshooting for issues
4. Reference version-specific sections

---

## ⚡ Success Criteria Quick Check

After any upgrade, verify these items:

**Core Functionality:**

- [ ] Application boots without errors
- [ ] All routes work
- [ ] Assets load correctly
- [ ] Database queries execute
- [ ] Forms submit successfully

**Testing:**

- [ ] All tests pass (unit, integration, system)
- [ ] No deprecation warnings in logs
- [ ] Test coverage maintained
- [ ] Performance acceptable

**Deployment:**

- [ ] Staging deployment successful
- [ ] Production deployment successful
- [ ] No error spikes in monitoring
- [ ] User-reported issues minimal/none

**Quality:**

- [ ] Code review completed
- [ ] Documentation updated
- [ ] Team trained on changes
- [ ] Rollback plan tested

---

## 💡 Pro Tips for All Upgrades

1. **Read the full guide first** - Don't start coding until you understand all changes
2. **Use staging extensively** - Catch issues before production
3. **Test incrementally** - Apply one change, test, commit, repeat
4. **Monitor carefully** - Watch for 24-48 hours after deploy
5. **Keep rollback ready** - Should take < 5 minutes
6. **Document custom workarounds** - Help future upgrades
7. **Communicate with team** - Keep everyone informed
8. **Don't rush** - Better to be slow and safe than fast and broken

---

**Quick Reference Version:** 1.0  
**Rails Versions Covered:** 7.0.x → 8.1.1  
**Last Updated:** November 1, 2025  
**Created From:** 4 version-specific quick reference files

---

**📌 Keep this quick reference handy during your upgrade!**

For detailed explanations and complete upgrade workflows, see the version-specific guides in `version-guides/`.

For interactive upgrade assistance, upload `SKILL.md` to your Claude Project and say:  
`"Upgrade my Rails app to [version]"`
