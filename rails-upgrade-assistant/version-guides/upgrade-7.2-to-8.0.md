---
title: "Rails 7.2.3 → 8.0.4 Upgrade Guide"
description: "Complete upgrade guide from Rails 7.2.3 to 8.0.4 with major architectural changes including Propshaft, multi-database, and Solid gems"
type: "version-guide"
rails_from: "7.2.3"
rails_to: "8.0.4"
difficulty: "very-hard"
breaking_changes: 13
priority_high: 5
priority_medium: 4
priority_low: 4
major_changes:
  - Sprockets to Propshaft (asset pipeline)
  - Multi-database configuration required
  - Solid gems as defaults (cache/queue/cable)
  - SSL configuration changes
  - Docker/Kamal integration
tags:
  - rails-8.0
  - upgrade-guide
  - breaking-changes
  - propshaft
  - sprockets
  - asset-pipeline
  - multi-database
  - solid-cache
  - solid-queue
  - solid-cable
  - kamal
category: "rails-upgrade"
version_family: "rails-8.x"
critical_warning: "Asset pipeline changed from Sprockets to Propshaft - complete migration required"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails 7.2 → 8.0 Upgrade Guide

## Supported Upgrade Path

**Rails 7.2.3 → 8.0.4**
**Difficulty:** Very Hard
**Risk Level:** HIGH - Major version upgrade with breaking changes

**Critical Warning:** The asset pipeline changed from Sprockets to Propshaft. This requires a complete migration of your asset pipeline configuration, custom processors, and asset references.

---

## Breaking Changes

### 1. Asset Pipeline: Sprockets → Propshaft (HIGH IMPACT)

Rails 8.0 replaces Sprockets with Propshaft as the default asset pipeline.

**OLD (Rails 7.2):**
```ruby
# Gemfile
gem "sprockets-rails"

# app/assets/config/manifest.js
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_tree ../../javascript .js

# Asset helpers with digest paths
asset_path("application.css")
```

**NEW (Rails 8.0):**
```ruby
# Gemfile
gem "propshaft"

# No manifest.js needed - Propshaft serves all files in app/assets automatically
# Asset helpers work the same but pipeline behavior differs:
# - No compilation/concatenation
# - No Sprockets directives (//= require, //= link)
# - Static file serving with digest stamping
```

**Migration Steps:**
1. Replace `sprockets-rails` with `propshaft` in Gemfile
2. Remove `app/assets/config/manifest.js`
3. Remove all Sprockets directives (`//= require`, `//= link`) from asset files
4. Move any assets that relied on Sprockets compilation to use importmap or bundled JS
5. Test all asset loading (CSS, JS, images, fonts)

**Warning:** If you have custom Sprockets processors or heavy Sprockets directive usage, this migration is the most time-consuming part of the upgrade. You can keep Sprockets by explicitly adding `gem "sprockets-rails"` to your Gemfile, but Propshaft is now the supported default.

---

### 2. Multi-Database Configuration for Solid Gems (HIGH IMPACT)

Rails 8.0 introduces Solid Cache, Solid Queue, and Solid Cable as defaults, each requiring their own database configuration.

**OLD (Rails 7.2):**
```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: db/development.sqlite3
```

**NEW (Rails 8.0):**
```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  cache:
    <<: *default
    database: storage/development_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/development_cable.sqlite3
    migrations_paths: db/cable_migrate
```

**Migration Steps:**
1. Update `config/database.yml` for multi-database layout
2. Run migrations for each new database: `bin/rails db:migrate`
3. Update any direct database configuration references in initializers

---

### 3. Solid Gems as Defaults (HIGH IMPACT)

Rails 8.0 uses Solid Cache, Solid Queue, and Solid Cable instead of Redis-based solutions.

**OLD (Rails 7.2):**
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
config.active_job.queue_adapter = :sidekiq
```

**NEW (Rails 8.0):**
```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.action_cable.adapter = :solid_cable
```

**Note:** You can keep Redis/Sidekiq by keeping your existing configuration. Solid gems are the new defaults but are optional.

---

### 4. SSL Configuration Changes (MEDIUM IMPACT)

**OLD (Rails 7.2):**
```ruby
# config/environments/production.rb
# SSL not configured by default
```

**NEW (Rails 8.0):**
```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

**Migration Steps:**
1. Review your SSL termination setup (reverse proxy, load balancer)
2. If SSL terminates before Rails, `assume_ssl = true` is correct
3. If Rails handles SSL directly, `force_ssl = true` handles redirects
4. Test SSL redirect behavior in staging

---

### 5. Removed Deprecated APIs (MEDIUM IMPACT)

Rails 8.0 removes methods and configurations deprecated in 7.x:

- Deprecated Active Record methods and callbacks
- Deprecated controller and routing helpers
- Deprecated configuration options from earlier versions

**Migration Steps:**
1. Run your app on Rails 7.2 with deprecation warnings enabled
2. Fix all deprecation warnings before upgrading
3. Search your codebase for methods listed in the Rails 8.0 release notes as removed

---

## Migration Checklist

### Pre-Upgrade

- [ ] Back up your database
- [ ] Create a git branch for the upgrade
- [ ] Rails 7.2.3 currently running and all tests passing
- [ ] Staging environment available for testing
- [ ] Rollback plan prepared
- [ ] Time allocated (6-12 hours + testing)

### During Upgrade

- [ ] Update Gemfile to Rails 8.0.4
- [ ] Run `bundle update rails`
- [ ] Run `bin/rails app:update` and review changes
- [ ] Migrate asset pipeline (Sprockets → Propshaft) or keep Sprockets explicitly
- [ ] Update `config/database.yml` for multi-database if using Solid gems
- [ ] Configure Solid Cache, Solid Queue, Solid Cable (or keep existing stack)
- [ ] Review and update SSL configuration
- [ ] Fix all removed deprecated API calls
- [ ] Run full test suite

### Post-Upgrade

- [ ] All tests passing
- [ ] No deprecation warnings
- [ ] Assets load correctly (CSS, JS, images)
- [ ] Background jobs processing
- [ ] Caching works as expected
- [ ] WebSockets/ActionCable functional
- [ ] Deploy to staging and verify
- [ ] Deploy to production and monitor

---

## Official Resources

- **Rails Guides:** https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- **Rails 8.0 Release Notes:** https://guides.rubyonrails.org/8_0_release_notes.html
- **Rails GitHub:** https://github.com/rails/rails
- **Railsdiff:** https://railsdiff.org/7.2.3/8.0.4
