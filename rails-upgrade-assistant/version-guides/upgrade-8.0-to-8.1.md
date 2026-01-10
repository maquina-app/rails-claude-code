---
title: "Rails 8.0.4 → 8.1.1 Upgrade Guide"
description: "Complete upgrade guide from Rails 8.0.4 to 8.1.1 with SSL configuration changes, bundler-audit requirement, and database pool updates"
type: "version-guide"
rails_from: "8.0.4"
rails_to: "8.1.1"
difficulty: "easy"
estimated_time: "2-4 hours"
breaking_changes: 8
priority_high: 3
priority_medium: 3
priority_low: 2
major_changes:
  - SSL settings commented (for Kamal)
  - pool to max_connections
  - bundler-audit required
  - Semicolon separator removed
  - ActiveJob adapters moved to gems
tags:
  - rails-8.1
  - upgrade-guide
  - breaking-changes
  - ssl-configuration
  - bundler-audit
  - max_connections
  - database-pool
  - kamal
category: "rails-upgrade"
version_family: "rails-8.x"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails Upgrade Assistant Skill: 8.0.4 → 8.1.1

**Version:** 1.0 
**Created:** November 1, 2025
**Source:** Official Rails CHANGELOGs from GitHub

---

## Overview

This skill helps upgrade Ruby on Rails applications from version 8.0.4 to 8.1.1, using official CHANGELOG data and the Rails MCP server to analyze your project intelligently.

### Key Features
- ✅ Uses Rails MCP tools to analyze your actual project
- ✅ Detects custom configurations automatically
- ✅ Based on official Rails CHANGELOGs from GitHub
- ✅ Neovim integration for live file updates
- ✅ Preserves your custom code with warnings
- ✅ Component-by-component change tracking

---

## How to Use This Skill

### Mode 1: Report-Only (Default - Safest)
```
"Analyze my Rails 8.0.4 app for upgrade to 8.1.1"
```
I'll generate a comprehensive report with all changes needed. You review and apply manually.

### Mode 2: Interactive with Neovim (Advanced)
```
"Upgrade my Rails app to 8.1.1 in interactive mode"
```
I'll:
1. Get your project's open buffers from Neovim
2. Show you each change before applying
3. Update files in Neovim when you approve
4. Preserve all custom configurations

**Prerequisites for Interactive Mode:**
- Neovim running with socket at `/tmp/nvim-{project_name}.sock`
- Files open in Neovim buffers
- Rails MCP server connected

---

## Upgrade Path: 8.0.4 → 8.1.1

**Complexity:** ⭐⭐ Medium
**Estimated Time:** 3-5 hours
**Risk Level:** Medium (config changes, some deprecations)

### What Changed
- **Breaking Changes:** 8 major items
- **Deprecations:** 15 items
- **New Features:** 50+ enhancements
- **Configuration Changes:** 10 required
- **Security:** bundler-audit added

---

## Critical Breaking Changes

### 🚨 HIGH PRIORITY - Action Required

#### 1. SSL Configuration Changes (Railties 8.1.1)
**Impact:** Production deployment configuration
**Status:** Changed default behavior

**OLD (Rails 8.0.4):**
```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

**NEW (Rails 8.1.1):**
```ruby
# config/environments/production.rb
# Now commented out to support Kamal deployments out of the box
# config.assume_ssl = true
# config.force_ssl = true
```

**⚠️ Custom Code Warning:**
If you have custom SSL middleware or manual SSL enforcement, review this change carefully.

**Migration Steps:**
1. Check if you're using Kamal: `grep -r "kamal" config/`
2. If NOT using Kamal, uncomment these lines in production.rb
3. If using Kamal, keep them commented and configure SSL in your reverse proxy
4. Test SSL redirect behavior in staging

**Testing:**
```ruby
# test/integration/ssl_test.rb
test "force SSL redirect" do
  get root_url(protocol: 'http')
  assert_redirected_to root_url(protocol: 'https')
end
```

---

#### 2. Database Connection Pool Renamed (ActiveRecord 8.1.0)
**Impact:** Database configuration
**Status:** Required change

**OLD (Rails 8.0.4):**
```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

**NEW (Rails 8.1.1):**
```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

**⚠️ Custom Code Warning:**
If you have database initializers or custom connection pool logic, update them.

**Migration Steps:**
1. Open config/database.yml
2. Find all instances of `pool:`
3. Rename to `max_connections:`
4. Keep the same value
5. Check for `pool` references in initializers

**New Options Available:**
```yaml
default: &default
  max_connections: 5      # Renamed from 'pool'
  min_connections: 0      # NEW: minimum connections
  keepalive: 60          # NEW: connection keepalive
  max_age: 3600          # NEW: max connection age in seconds
```

---

#### 3. Query String Parsing Changes (ActionPack 8.1.0)
**Impact:** URL parameter parsing
**Status:** Breaking change

**REMOVED:** Semicolon as query string separator
```ruby
# OLD behavior (8.0.4) - NO LONGER WORKS
ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
# => [["foo", "bar"], ["baz", "quux"]]

# NEW behavior (8.1.1)
ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
# => [["foo", "bar;baz=quux"]]
```

**REMOVED:** Leading bracket skipping
```ruby
# OLD behavior (8.0.4) - NO LONGER WORKS
ActionDispatch::ParamBuilder.from_query_string("[foo]=bar")
# => { "foo" => "bar" }

# NEW behavior (8.1.1)
ActionDispatch::ParamBuilder.from_query_string("[foo]=bar")
# => { "[foo]" => "bar" }
```

**⚠️ Custom Code Warning:**
Check your codebase for:
- Manual URL parsing with semicolons
- Parameter parsing that expects bracket stripping
- API integrations that might send semicolon-separated params

**Migration Steps:**
1. Search codebase: `grep -r ";" app/ | grep "params\|query"`
2. Replace semicolon separators with `&`
3. Update API documentation if you have one
4. Notify API consumers of the change

---

#### 4. Routes to Missing Controllers (ActionPack 8.1.0)
**Impact:** Error handling
**Status:** Behavior change (404 → 500)

**Before:** Missing controller returned 404 Not Found
**After:** Missing controller returns 500 Internal Server Error

**Reason:** Non-existent controllers are programming errors, not routing errors.

**⚠️ Custom Code Warning:**
If you have error handling that specifically catches 404s for missing controllers, update it.

**Migration Steps:**
1. Audit routes: `bin/rails routes | grep "#"`
2. Ensure all referenced controllers exist
3. Update error monitoring to expect 500s for missing controllers
4. Review custom error handling in ApplicationController

---

#### 5. ActiveJob Adapter Changes (ActiveJob 8.1.0)
**Impact:** Background job processing
**Status:** Adapters removed

**REMOVED:**
- Built-in `sidekiq` adapter (use sidekiq gem's adapter)
- Built-in `sucker_punch` adapter (use gem's adapter)

**Migration Steps:**

If using **Sidekiq:**
```ruby
# Gemfile - ensure you have sidekiq 7.3.3+
gem 'sidekiq', '>= 7.3.3'

# config/application.rb - adapter now comes from gem
config.active_job.queue_adapter = :sidekiq
```

If using **SuckerPunch:**
```ruby
# Gemfile
gem 'sucker_punch'

# config/application.rb - adapter now comes from gem
config.active_job.queue_adapter = :sucker_punch
```

---

#### 6. ActiveStorage Azure Service Removed (ActiveStorage 8.1.0)
**Impact:** Cloud storage
**Status:** Removed

**REMOVED:** `:azure` storage service support

**Migration Path:**
If you're using Azure storage, you need to:
1. Switch to a different storage service (S3, GCS, or Disk)
2. Or use the `azure-storage-blob` gem directly with a custom service

**⚠️ Custom Code Warning:**
Check your storage.yml for azure configuration.

---

#### 7. MySQL Unsigned Types Removed (ActiveRecord 8.1.0)
**Impact:** Database migrations
**Status:** Removed

**REMOVED:**
- `:unsigned_float`
- `:unsigned_decimal`

**Migration Steps:**
```ruby
# OLD - NO LONGER WORKS
add_column :products, :price, :unsigned_decimal, precision: 10, scale: 2

# NEW
add_column :products, :price, :decimal, precision: 10, scale: 2
# Add check constraint if needed
add_check_constraint :products, "price >= 0", name: "price_positive"
```

---

#### 8. Time Zone Behavior (ActiveSupport 8.1.0)
**Impact:** Time handling
**Status:** Deprecated config

**REMOVED:**
- `config.active_support.to_time_preserves_timezone` (deprecated)
- Time always preserves receiver timezone now

**Migration Steps:**
1. Remove the config option from application.rb
2. Review time conversion code
3. Test timezone-dependent features

---

## Configuration Changes Required

### 1. Application Configuration (config/application.rb)

**Update load_defaults:**
```ruby
# OLD
config.load_defaults 8.0

# NEW
config.load_defaults 8.1
```

### 2. ApplicationController (app/controllers/application_controller.rb)

**Add new method:**
```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  # NEW in 8.1.1 - invalidates etag when importmap changes
  stale_when_importmap_changes
end
```

### 3. Gemfile Updates

**Required changes:**
```ruby
# Update Rails version
gem "rails", "~> 8.1.1"

# NEW - Add image_processing (uncommented)
gem "image_processing", "~> 1.2"

# NEW - Add bundler-audit for security scanning
group :development, :test do
  gem "bundler-audit", require: false
end
```

### 4. .gitignore Update

**Change:**
```
# OLD
/config/master.key

# NEW (supports multiple key files)
/config/*.key
```

### 5. Dockerfile Improvements

**Key changes:**
```dockerfile
# Jemalloc symlink added for easier configuration
RUN ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so

# LD_PRELOAD now set in ENV instead of entrypoint
ENV LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# File ownership set during copy instead of after
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# Bootsnap parallel compilation disabled (QEMU bug workaround)
RUN bundle exec bootsnap precompile -j 1 --gemfile
```

### 6. GitHub Actions Workflow (.github/workflows/ci.yml)

**Major changes:**
```yaml
# Checkout action updated
- uses: actions/checkout@v5  # was v4

# NEW - Bundler audit job
scan_gems:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v5
    - name: Scan for known security vulnerabilities in gems
      run: bin/bundler-audit

# NEW - RuboCop caching
lint:
  env:
    RUBOCOP_CACHE_ROOT: tmp/rubocop
  steps:
    - name: Prepare RuboCop cache
      uses: actions/cache@v4
      with:
        path: ${{ env.RUBOCOP_CACHE_ROOT }}
        key: rubocop-${{ runner.os }}-${{ hashFiles('...') }}

# System tests now separate
system-test:
  runs-on: ubuntu-latest
  steps:
    - name: Run System Tests
      run: bin/rails db:test:prepare test:system

# Redis image updated
services:
  redis:
    image: valkey/valkey:8  # was redis
```

### 7. Dependabot Configuration

**Update frequency:**
```yaml
# .github/dependabot.yml
updates:
  - package-ecosystem: bundler
    schedule:
      interval: weekly  # was daily
```

---

## New Files to Create

### 1. bin/bundler-audit
```bash
#!/usr/bin/env ruby
require_relative "../config/boot"
require "bundler/audit/cli"

ARGV.concat %w[ --config config/bundler-audit.yml ] if ARGV.empty? || ARGV.include?("check")
Bundler::Audit::CLI.start
```

Make executable: `chmod +x bin/bundler-audit`

### 2. config/bundler-audit.yml
```yaml
# Audit all gems listed in the Gemfile for known security problems
# CVEs that are not relevant can be enumerated on the ignore list

ignore:
  - CVE-THAT-DOES-NOT-APPLY
```

### 3. bin/ci
```bash
#!/usr/bin/env ruby
require_relative "../config/boot"
require "active_support/continuous_integration"

CI = ActiveSupport::ContinuousIntegration
require_relative "../config/ci.rb"
```

Make executable: `chmod +x bin/ci`

### 4. config/ci.rb
```ruby
# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  
  step "Style: Ruby", "bin/rubocop"
  
  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager"
  
  step "Tests: Rails", "bin/rails test"
  step "Tests: System", "bin/rails test:system"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end
```

---

## Development Environment Changes

### 1. config/environments/development.rb

**New logging options:**
```ruby
# Highlight code that triggered redirect in logs
config.action_dispatch.verbose_redirect_logs = true

# Suppress logger output for asset requests
config.assets.quiet = true
```

### 2. Content Security Policy

**New automatic nonce option:**
```ruby
# config/initializers/content_security_policy.rb

# Automatically add nonce to javascript_tag, javascript_include_tag, 
# and stylesheet_link_tag if corresponding directives are specified
# config.content_security_policy_nonce_auto = true
```

### 3. Puma Configuration

**Documentation update:**
```ruby
# config/puma.rb

# You can set WEB_CONCURRENCY to 'auto' to automatically start 
# a worker for each available processor
```

---

## Production Environment Changes

### config/environments/production.rb

**SSL Configuration (CHANGED):**
```ruby
# Assume all access through SSL-terminating reverse proxy
# config.assume_ssl = true  # NOW COMMENTED

# Force all access over SSL
# config.force_ssl = true   # NOW COMMENTED

# Reason: Support Kamal deployments out of the box
# Uncomment if NOT using Kamal
```

**Logging improvements:**
```ruby
# Change to "debug" to log everything (including PII!).
config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
```

---

## Error Pages - Dark Mode Support

All error pages now support dark mode:
- public/400.html
- public/404.html
- public/406-unsupported-browser.html
- public/422.html
- public/500.html

**Changes:**
- Uses `100dvh` instead of `100vh` (mobile viewport)
- Dark mode CSS added with `@media (prefers-color-scheme: dark)`
- SVG elements styled separately for light/dark themes

**No action required** - files regenerated automatically with `rails app:update`

---

## Application Layout Changes

### app/views/layouts/application.html.erb

**New meta tag:**
```html
<meta name="application-name" content="Railsdiff">
```

This helps Progressive Web Apps identify the application name.

---

## New Features in Rails 8.1

### 1. Structured Events (All Components)
Rails 8.1 adds comprehensive structured event reporting via `Rails.event`:

**Usage:**
```ruby
# Emit custom events
Rails.event.notify("user.signup", user_id: 123, email: "user@example.com")

# With tags
Rails.event.tagged("graphql") do
  Rails.event.notify("query.executed", duration: 45)
end

# Set context (for all events in block)
Rails.event.set_context(request_id: request.id, shop_id: current_shop.id)
```

**Available events include:**
- `action_mailer.delivered`, `action_mailer.processed`
- `action_controller.*` (request_started, completed, redirect, etc.)
- `action_view.render_*` (template, partial, layout, collection)
- `active_job.*` (enqueued, started, completed, etc.)
- `active_record.sql`, `active_record.strict_loading_violation`
- `active_storage.service_*` (upload, download, delete, etc.)

### 2. ActionMailer.deliver_all_later

**Batch email delivery:**
```ruby
user_emails = User.all.map { |user| Notifier.welcome(user) }

# Enqueue all at once (reduces queue round-trips)
ActionMailer.deliver_all_later(user_emails)

# With custom queue
ActionMailer.deliver_all_later(user_emails, queue: :my_queue)
```

### 3. ActiveJob Continuations

**For long-running jobs:**
```ruby
class ProcessImportJob
  include ActiveJob::Continuable

  def perform(import_id)
    @import = Import.find(import_id)

    step :initialize do
      @import.initialize
    end

    # With cursor tracking
    step :process do |step|
      @import.records.find_each(start: step.cursor) do |record|
        record.process
        step.advance! from: record.id
      end
    end

    step :finalize
  end

  private
    def finalize
      @import.finalize
    end
end
```

### 4. ActiveRecord.only_columns

**Whitelist columns instead of blacklisting:**
```ruby
class User < ApplicationRecord
  # Only consider these columns, ignore all others
  self.only_columns = [:id, :email, :created_at, :updated_at]
end
```

Useful for:
- Legacy databases with too many columns
- Safe schema changes (deploy-then-migrate)
- Performance optimization

### 5. ActiveRecord Connection Options

**More granular control:**
```yaml
production:
  adapter: postgresql
  max_connections: 10      # renamed from 'pool'
  min_connections: 2       # NEW
  keepalive: 60           # NEW (seconds)
  max_age: 3600           # NEW (seconds)
```

### 6. Rate Limiting Enhancements

**New scope option:**
```ruby
class APIController < ActionController::API
  # Share rate limit across multiple controllers
  rate_limit to: 100, within: 1.hour, scope: "api"
end

class API::PostsController < APIController
  # Inherits rate limit from APIController
end
```

### 7. Markdown Rendering Support

**Native markdown rendering:**
```ruby
class PagesController < ActionController::Base
  def show
    @page = Page.find(params[:id])
    
    respond_to do |format|
      format.html
      format.md { render markdown: @page }
    end
  end
end
```

### 8. JSON Renderer Improvements

**No longer escapes HTML/Unicode by default:**
```ruby
# Old behavior (8.0): escapes <, >, &, U+2028, U+2029
# New behavior (8.1): no escaping (faster, cleaner)

# To restore old behavior:
config.action_controller.escape_json_responses = true

# Or per-request:
render json: @posts, escape: true
```

### 9. ActiveRecord Deprecation Support

**Deprecate associations:**
```ruby
class Post < ApplicationRecord
  has_many :comments, deprecated: true
end

# Will now warn when used:
post.comments  # => DEPRECATION WARNING: comments association is deprecated
```

### 10. Request Cache Control Directives

**Full RFC 9111 support:**
```ruby
def show
  if request.cache_control_directives.only_if_cached?
    @article = Article.find_cached(params[:id])
    return head(:gateway_timeout) if @article.nil?
  else
    @article = Article.find(params[:id])
  end
  
  render :show
end
```

---

## Deprecations to Address

### High Priority

1. **ActiveSupport::Configurable** - Deprecated
   - Plan migration away from this module

2. **String#mb_chars** - Deprecated
   - Ruby strings are encoding-aware now
   - Use native string methods instead

3. **Semicolon query separators** - Removed
   - Update any URL parsing code

4. **ActiveJob sidekiq adapter** - Removed
   - Use sidekiq gem's adapter (7.3.3+)

### Medium Priority

5. **ActiveRecord signed_id_verifier_secret** - Deprecated
   - Migrate to `signed_id_verifier` or `Rails.application.message_verifiers`

6. **ActionDispatch bracket parameter parsing** - Changed
   - Leading brackets no longer stripped

7. **Azure storage service** - Removed
   - Migrate to S3, GCS, or disk storage

### Low Priority

8. **config.active_support.to_time_preserves_timezone** - Deprecated
   - Remove from configs (behavior is now default)

9. **Time arithmetic deprecations** - Removed
   - Various deprecated time calculations

---

## Testing Changes

### New bin/setup Option

```bash
# Reset database during setup
bin/setup --reset
```

### New Assertion Helpers

```ruby
# Simple body content checks
assert_in_body "Welcome"
assert_not_in_body "Error"

# Notification assertions with payload matching
assert_events_reported([
  { name: "user.created", payload: { id: 123 } },
  { name: "email.sent" }
]) do
  User.create!(email: "test@example.com")
end
```

---

## Security Improvements

### 1. Bundler Audit Integration

**Automatic security scanning:**
```bash
# Check for vulnerabilities
bin/bundler-audit

# In CI
bin/ci  # includes bundler-audit step
```

### 2. Continuous Integration Helper

**New bin/ci command:**
```bash
# Run all checks locally
bin/ci

# Defines checks in config/ci.rb
```

---

## Performance Improvements

### 1. RuboCop Caching

**GitHub Actions now caches RuboCop:**
- Faster linting in CI
- Cached based on dependencies hash

### 2. Bootsnap Optimization

**Parallel compilation disabled for QEMU compatibility:**
```bash
# Prevents QEMU bug during Docker builds
bundle exec bootsnap precompile -j 1
```

### 3. URL Helper Optimization

**~10% faster when host includes protocol:**
```ruby
# Optimized case
url_for(host: "https://example.com", ...)
```

### 4. ActiveRecord Batching

**Massive improvements:**
- 4.8x faster batch generation
- 900x less bandwidth usage
- 45x less memory allocation

---

## Migration Checklist

### Pre-Upgrade

- [ ] Backup database
- [ ] Ensure all tests pass on 8.0.4
- [ ] Review custom gems for compatibility
- [ ] Check for deprecated features in use
- [ ] Read this entire guide

### During Upgrade

- [ ] Update Gemfile to Rails 8.1.1
- [ ] Run `bundle update rails`
- [ ] Update config/application.rb (load_defaults 8.1)
- [ ] Update database.yml (pool → max_connections)
- [ ] Add image_processing gem
- [ ] Add bundler-audit gem
- [ ] Create bin/bundler-audit script
- [ ] Create config/bundler-audit.yml
- [ ] Create bin/ci script
- [ ] Create config/ci.rb
- [ ] Update .gitignore (master.key → *.key)
- [ ] Update ApplicationController (add stale_when_importmap_changes)
- [ ] Review SSL config in production.rb
- [ ] Update GitHub Actions workflow
- [ ] Update Dockerfile
- [ ] Run `bin/rails app:update`

### Post-Upgrade

- [ ] Run full test suite
- [ ] Run bin/bundler-audit
- [ ] Check for deprecation warnings
- [ ] Test in staging environment
- [ ] Review error pages in browser
- [ ] Verify SSL behavior
- [ ] Check database connections
- [ ] Monitor performance metrics
- [ ] Update deployment documentation
- [ ] Deploy to production
- [ ] Monitor error tracking

---

## Rollback Plan

If issues arise:

1. **Immediate Rollback:**
```bash
git revert <upgrade-commit>
bundle install
bin/rails db:migrate
```

2. **Gemfile.lock Restore:**
```bash
git checkout HEAD^ -- Gemfile.lock
bundle install
```

3. **Database Rollback:**
```bash
# If migrations were run
bin/rails db:rollback STEP=<number>
```

4. **Configuration Restore:**
```bash
git checkout HEAD^ -- config/
```

---

## Common Issues & Solutions

### Issue 1: SSL Redirects Not Working

**Symptom:** HTTP requests not redirecting to HTTPS in production

**Cause:** force_ssl commented out by default in 8.1.1

**Solution:**
```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

### Issue 2: Database Connection Errors

**Symptom:** `unknown keyword: pool`

**Cause:** database.yml still uses old `pool:` key

**Solution:**
```yaml
# Change in config/database.yml
max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Issue 3: Bundler Audit Failing

**Symptom:** `bundler-audit` command not found

**Cause:** Gem not installed

**Solution:**
```ruby
# Add to Gemfile
gem "bundler-audit", require: false, group: [:development, :test]
```

Then: `bundle install && chmod +x bin/bundler-audit`

### Issue 4: GitHub Actions Failing

**Symptom:** checkout action version error

**Cause:** Using old actions/checkout@v4

**Solution:**
Update .github/workflows/ci.yml:
```yaml
- uses: actions/checkout@v5
```

### Issue 5: Semicolon Parameters Breaking

**Symptom:** API parameters parsed incorrectly

**Cause:** Semicolon separator removed

**Solution:**
Update API clients to use `&` instead of `;`:
```
# OLD: ?foo=bar;baz=qux
# NEW: ?foo=bar&baz=qux
```

---

## Component-Specific Changes Summary

### ActionCable
- Allow composite channels in `stream_for`
- Allow nil connection identifiers for Redis

### ActionMailbox
- New `reply_to_address` extension method

### ActionMailer
- New structured events (delivered, processed)
- New `deliver_all_later` for batch delivery

### ActionPack
- Removed semicolon query separator support
- Removed leading bracket parameter skipping
- Missing controllers now return 500, not 404
- Added verbose_redirect_logs setting
- JSON rendering no longer escapes by default
- Rate limiting improvements
- Markdown rendering support
- Request cache control directive support
- Many new structured events

### ActionText
- Trix now comes from gem, not vendored
- Rich textarea improvements
- Attachment upload progress enhancements

### ActionView
- New structured events
- relative_time_in_words helper
- Improved error highlighting
- Template dependency tracking improvements
- Layouts have access to render local variables
- content_security_policy_nonce_auto setting

### ActiveJob
- Continuations support for long-running jobs
- Removed deprecated adapters
- New structured events
- New UnknownJobClassError for deserialization

### ActiveModel
- reset_token expiry configuration
- except_on: option for validations
- Normalization support backported

### ActiveRecord
- pool renamed to max_connections
- only_columns for column whitelisting
- Deprecated association support
- Virtual generated columns (PostgreSQL 18+)
- Integer shard key support
- Many query and performance improvements
- New structured events
- Schema dumping optimizations

### ActiveStorage
- Removed :azure service
- Configurable analyzers and transformers
- Direct upload progress improvements
- New structured events

### ActiveSupport
- Removed deprecated time methods
- Structured Event Reporter (Rails.event)
- escape_js_separators_in_json config
- Cache key size configuration
- Many deprecations and cleanups

### Railties
- SSL defaults changed for Kamal
- bin/ci for continuous integration
- bin/bundler-audit added
- System tests not generated by default
- RuboCop caching in CI
- No more bin/bundle binstub

---

## Official Resources

- **Rails Guides:** https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- **Rails 8.1 Release Notes:** https://guides.rubyonrails.org/8_1_release_notes.html
- **Rails GitHub:** https://github.com/rails/rails
- **CHANGELOGs:** https://github.com/rails/rails/tree/v8.1.1

---

## Using This Skill with Rails MCP & Neovim

### Step 1: Analyze Your Project

```
"Analyze my Rails project for upgrade to 8.1.1"
```

I will:
1. Use `railsMcpServer:project_info` to understand your setup
2. Use `railsMcpServer:get_file` to read your configs
3. Use `railsMcpServer:analyze_models` to check your models
4. Detect custom configurations automatically
5. Generate a report with ⚠️ warnings for your custom code

### Step 2: Review Changes

I'll show you:
- What files need to be changed
- What your current configuration is
- What the new configuration should be
- Where you have custom code that needs attention

### Step 3: Apply Changes (Interactive Mode)

```
"Update my files with the changes"
```

I will:
1. Use `nvimMcpServer:get_project_buffers` to see your open files
2. Show you each change before applying
3. Use `nvimMcpServer:update_buffer` to update files in Neovim
4. Verify changes with you

### Step 4: Verify

```
"Check my upgrade status"
```

I'll verify:
- All required files updated
- No syntax errors
- All custom code preserved
- Tests still pass

---

## Custom Code Detection

I automatically detect and warn about:

### Configuration Customizations
- ⚠️ Custom SSL middleware
- ⚠️ Manual database pool configuration  
- ⚠️ Custom query parameter parsing
- ⚠️ ActiveJob adapter customizations
- ⚠️ Custom storage services

### Code Patterns
- ⚠️ Semicolon URL separators
- ⚠️ Leading bracket parameter assumptions
- ⚠️ Error handling for missing controllers
- ⚠️ Time zone conversion code
- ⚠️ Unsigned type usage

### Integration Points
- ⚠️ Custom Sidekiq configuration
- ⚠️ Azure storage integration
- ⚠️ Custom serialization logic
- ⚠️ Rate limiting customizations

---

## Success Criteria

Your upgrade is successful when:

✅ All tests pass
✅ No deprecation warnings
✅ All custom code warnings addressed
✅ Staging deployment successful
✅ Production deployment successful
✅ No unexpected errors in error tracking
✅ Performance metrics stable or improved

---

## Support & Troubleshooting

### If You Get Stuck

1. **Check this guide** for your specific error
2. **Search CHANGELOGs** for component-specific issues
3. **Review diff** between 8.0.4 and 8.1.1
4. **Check Rails guides** for detailed explanations
5. **Ask me** for help interpreting errors

### Getting More Help

```
"I'm seeing this error after upgrade: [error message]"
"How do I handle custom [feature] during upgrade?"
"What does this deprecation warning mean?"
```

---

## Appendix: Full File Diff Reference

See the attached diff document for complete file-by-file changes between Rails 8.0.4 and 8.1.1 generated by railsdiff.org.

---

**End of Skill**

This skill is based on official Rails CHANGELOGs and the railsdiff.org diff output.
All recommendations follow Rails core team guidance and best practices.

**Version:** 1.0 
**Last Updated:** November 1, 2025
**Rails Versions:** 8.0.4 → 8.1.1

