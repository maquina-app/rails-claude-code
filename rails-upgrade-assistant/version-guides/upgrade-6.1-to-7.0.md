---
title: "Rails 6.1 → 7.0.0 Upgrade Guide"
description: "Complete upgrade guide from Rails 6.1.x to 7.0.0 with breaking changes, migration steps, and testing procedures"
type: "version-guide"
rails_from: "6.1.x"
rails_to: "7.0.0"
difficulty: "hard"
breaking_changes: 17
priority_high: 5
priority_medium: 8
priority_low: 4
critical_warning: "Zeitwerk autoloader becomes mandatory — classic autoloader removed"
major_changes:
  - Zeitwerk mandatory (classic removed)
  - Key generator SHA1 to SHA256
  - button_to defaults to PATCH
  - Sprockets optional
  - Autoloading during initialization errors
tags:
  - rails-7.0
  - upgrade-guide
  - breaking-changes
  - zeitwerk
  - key-generator
  - button_to
  - sprockets
  - autoloading
category: "rails-upgrade"
version_family: "rails-7.x"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails 6.1 → 7.0 Upgrade Guide

## Supported Upgrade Path

**From:** Rails 6.1.x
**To:** Rails 7.0.0

This is a **HARD complexity** upgrade.

**CRITICAL WARNING:** This upgrade makes the Zeitwerk autoloader mandatory. The classic autoloader has been completely removed. If your application has not yet migrated to Zeitwerk, this must be done BEFORE upgrading to Rails 7.0.

---

## Breaking Changes - Rails 6.1 to 7.0.0

### HIGH IMPACT Changes (Breaking)

#### 1. **Zeitwerk Autoloader Mandatory (Classic Removed)**

**Component:** Railties, ActiveSupport
**Impact:** High - Classic autoloader completely removed
**Type:** Breaking - application will not boot without Zeitwerk

**OLD (Rails 6.1):**
```ruby
# config/application.rb
# Classic autoloader was still available
config.autoloader = :classic

# Or with require_dependency
require_dependency "some_class"
```

**NEW (Rails 7.0):**
```ruby
# config/application.rb
# Zeitwerk is the ONLY autoloader
# No config.autoloader setting needed (Zeitwerk is the only option)

# require_dependency is no longer needed (and is a no-op)
# Just use the constant directly:
SomeClass
```

**What Changed:**
- The classic autoloader has been completely removed
- `config.autoloader = :classic` will raise an error
- `require_dependency` is now a no-op (does nothing)
- `ActiveSupport::Dependencies.autoloaded_constants` removed
- `ActiveSupport::Dependencies.autoload_paths` removed
- All code must follow Zeitwerk naming conventions

**Migration Steps:**
1. **BEFORE upgrading:** Run `bin/rails zeitwerk:check` on Rails 6.1
2. Fix all Zeitwerk violations:
   - File names must match constant names (`user_role.rb` → `UserRole`)
   - One constant per file
   - Nested directories match module nesting
3. Remove `config.autoloader = :classic` from `config/application.rb`
4. Remove all `require_dependency` calls
5. Remove any code that relies on `ActiveSupport::Dependencies` private API
6. Run `bin/rails zeitwerk:check` again to verify

**Zeitwerk Naming Rules:**
```
app/models/user.rb            → User
app/models/user_role.rb       → UserRole
app/models/admin/user.rb      → Admin::User
app/services/pdf_generator.rb → PdfGenerator (not PDFGenerator!)
lib/html_parser.rb            → HtmlParser (not HTMLParser!)
```

---

#### 2. **Key Generator Changes from SHA1 to SHA256**

**Component:** ActiveSupport
**Impact:** High - Changes encryption/signing behavior
**Type:** Breaking - invalidates existing signed/encrypted data

**OLD (Rails 6.1):**
```ruby
# Key generator used SHA1 by default
# config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
```

**NEW (Rails 7.0):**
```ruby
# Key generator uses SHA256 by default
config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA256

# To keep SHA1 temporarily during migration:
config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
```

**What Changed:**
- Default hash digest for key generation changed from SHA1 to SHA256
- This affects cookies, sessions, encrypted attributes, and message verifiers
- Existing signed cookies and encrypted data become invalid
- Users may be logged out

**Migration Steps:**
1. Add to `config/application.rb` to keep SHA1 temporarily:
   ```ruby
   config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
   ```
2. Deploy with SHA1 to verify everything else works
3. Plan a rotation strategy:
   - Set rotation for message verifiers/encryptors
   - Accept that users will need to re-authenticate
4. Switch to SHA256 when ready
5. Remove SHA1 configuration after rotation period

---

#### 3. **button_to Defaults to HTTP PATCH**

**Component:** ActionView
**Impact:** High - Changes form method for button_to
**Type:** Breaking - silently changes HTTP method

**OLD (Rails 6.1):**
```ruby
# button_to defaulted to POST
<%= button_to "Update", user_path(@user) %>
# Generated: <form method="post">
```

**NEW (Rails 7.0):**
```ruby
# button_to defaults to PATCH for existing records
<%= button_to "Update", user_path(@user) %>
# Generated: <form method="post"><input type="hidden" name="_method" value="patch">

# To keep POST behavior explicitly:
<%= button_to "Create", users_path, method: :post %>
```

**What Changed:**
- `button_to` now defaults to `method: :patch` when a persisted record is implied
- This matches the RESTful convention (update = PATCH)
- Existing `button_to` calls may hit wrong controller actions

**Migration Steps:**
1. Search for all `button_to` calls in views
2. Add explicit `method: :post` where POST is intended
3. Verify routes match the expected HTTP methods
4. Test all button_to forms thoroughly

---

#### 4. **Sprockets No Longer Required (Optional)**

**Component:** Railties, Asset Pipeline
**Impact:** High - Sprockets becomes optional
**Type:** Architecture change

**OLD (Rails 6.1):**
```ruby
# Gemfile - Sprockets was always included
gem "sprockets-rails"
# Sprockets was the only asset pipeline option
```

**NEW (Rails 7.0):**
```ruby
# Gemfile - Sprockets is optional
gem "sprockets-rails"  # Still works, but optional

# New option: import maps (no bundling)
gem "importmap-rails"

# Or: jsbundling-rails with esbuild/webpack/rollup
gem "jsbundling-rails"

# Or: cssbundling-rails for CSS
gem "cssbundling-rails"
```

**What Changed:**
- Sprockets is no longer included by default in new Rails apps
- Import maps are the new default for JavaScript
- `jsbundling-rails` and `cssbundling-rails` provide alternatives
- Existing apps with Sprockets continue to work

**Migration Steps:**
1. Keep `sprockets-rails` in Gemfile if you want to continue using it
2. No immediate action required for existing apps
3. Consider migrating to `importmap-rails` for simpler apps
4. Consider `jsbundling-rails` for apps needing bundling

---

#### 5. **Autoloading During Initialization Raises Error**

**Component:** Railties
**Impact:** High - Code that autoloads during boot will fail
**Type:** Breaking - boot-time errors

**OLD (Rails 6.1):**
```ruby
# config/initializers/my_init.rb
# Autoloading during initialization worked (with warnings)
MyModel.some_class_method
AdminUser.configure_something
```

**NEW (Rails 7.0):**
```ruby
# config/initializers/my_init.rb
# Autoloading during initialization raises an error!
# Use to_prepare or after_initialize callbacks instead:

Rails.application.config.after_initialize do
  MyModel.some_class_method
end

Rails.application.config.to_prepare do
  AdminUser.configure_something
end
```

**What Changed:**
- Autoloading application code during initialization is no longer allowed
- Initializers cannot reference application models, controllers, etc.
- Must use `to_prepare` or `after_initialize` callbacks
- This ensures consistent behavior with Zeitwerk

**Migration Steps:**
1. Check all files in `config/initializers/` for references to application code
2. Wrap references in `Rails.application.config.to_prepare` or `after_initialize`
3. Check `config/application.rb` for similar references
4. Test that the application boots correctly

---

### MEDIUM IMPACT Changes

#### 6. **ActiveSupport::Dependencies Private API Deleted**

**Component:** ActiveSupport
**Impact:** Medium - Affects code using internal autoloader APIs
**Type:** Removal

**OLD (Rails 6.1):**
```ruby
# Private API that some gems/apps used
ActiveSupport::Dependencies.autoloaded_constants
ActiveSupport::Dependencies.autoload_paths
ActiveSupport::Dependencies.mechanism
ActiveSupport::Dependencies.loaded
```

**NEW (Rails 7.0):**
```ruby
# These methods are removed
# Use Zeitwerk API instead:
Rails.autoloaders.main.loaded
Rails.autoloaders.main.dirs
```

**What Changed:**
- `ActiveSupport::Dependencies` private API methods removed
- Applications and gems using these APIs will break
- Zeitwerk provides equivalent functionality

**Migration Steps:**
1. Search for `ActiveSupport::Dependencies` usage
2. Replace with Zeitwerk equivalents:
   - `autoloaded_constants` → check Zeitwerk docs
   - `autoload_paths` → `Rails.autoloaders.main.dirs`
3. Update gems that depend on these APIs

---

#### 7. **Autoloaded Paths Removed from $LOAD_PATH**

**Component:** Railties
**Impact:** Medium - Bare `require` for app code breaks
**Type:** Breaking

**OLD (Rails 6.1):**
```ruby
# Autoload paths were in $LOAD_PATH
require "user"  # Worked because app/models was in $LOAD_PATH
```

**NEW (Rails 7.0):**
```ruby
# Autoload paths no longer in $LOAD_PATH
require "user"  # LoadError!

# Use the constant directly (Zeitwerk handles loading):
User  # This works

# Or use full path for explicit require:
require_relative "../app/models/user"
```

**What Changed:**
- Autoloaded directories (app/models, app/controllers, etc.) removed from `$LOAD_PATH`
- Bare `require "model_name"` no longer works
- Zeitwerk handles autoloading; explicit `require` is unnecessary

**Migration Steps:**
1. Search for `require` statements that load application code
2. Remove unnecessary `require` calls (Zeitwerk autoloads)
3. If explicit loading is needed, use `require_relative` with full path

---

#### 8. **request.content_type Returns Full Header**

**Component:** ActionPack
**Impact:** Medium - Content-Type comparison changes
**Type:** Behavior change (continued from 6.1)

**OLD (Rails 6.1):**
```ruby
request.content_type
# => "text/html" (some cases still returned MIME only)
```

**NEW (Rails 7.0):**
```ruby
request.content_type
# => "text/html; charset=utf-8" (always full header)

# Use media_type for MIME only:
request.media_type
# => "text/html"
```

**What Changed:**
- `request.content_type` consistently returns the full Content-Type header
- Use `request.media_type` for the MIME type portion only

**Migration Steps:**
1. Search for `request.content_type` string comparisons
2. Replace with `request.media_type` where comparing MIME types
3. Update API tests that assert on Content-Type

---

#### 9. **Cache Serialization Format Changes**

**Component:** ActiveSupport
**Impact:** Medium - Cache compatibility during transition
**Type:** Behavior change

**OLD (Rails 6.1):**
```ruby
# Cache used Marshal format by default
config.active_support.cache_format_version = 6.1
```

**NEW (Rails 7.0):**
```ruby
# New cache format version available
config.active_support.cache_format_version = 7.0

# To keep old format during migration:
config.active_support.cache_format_version = 6.1
```

**What Changed:**
- New cache serialization format (version 7.0)
- Can read old format entries
- New entries written in new format when enabled
- Transition period needed for rolling deploys

**Migration Steps:**
1. Keep `cache_format_version = 6.1` initially
2. Deploy and verify everything works
3. Switch to `cache_format_version = 7.0` after all servers upgraded
4. Optionally clear cache after full rollout

---

#### 10. **ActiveStorage Variant Processor Defaults to :vips**

**Component:** ActiveStorage
**Impact:** Medium - Changes default image processor
**Type:** Default change

**OLD (Rails 6.1):**
```ruby
# mini_magick was the default variant processor
config.active_storage.variant_processor = :mini_magick
```

**NEW (Rails 7.0):**
```ruby
# vips is now the default variant processor
config.active_storage.variant_processor = :vips

# To keep mini_magick:
config.active_storage.variant_processor = :mini_magick
```

**What Changed:**
- Default variant processor changed from `:mini_magick` to `:vips`
- libvips is faster and uses less memory than ImageMagick
- Transformation method names may differ

**Migration Steps:**
1. Install libvips on your system: `brew install vips` (macOS)
2. OR keep mini_magick: `config.active_storage.variant_processor = :mini_magick`
3. If switching to vips, update transformation calls
4. Test all image variant generation

---

#### 11. **Transaction Rollback on return/break/throw**

**Component:** ActiveRecord
**Impact:** Medium - Early return inside transaction now rolls back
**Type:** Behavior change

**OLD (Rails 6.1):**
```ruby
# Early return inside transaction committed the transaction
ActiveRecord::Base.transaction do
  user.save!
  return if some_condition  # Transaction was COMMITTED
end
```

**NEW (Rails 7.0):**
```ruby
# Early return inside transaction now ROLLS BACK
ActiveRecord::Base.transaction do
  user.save!
  return if some_condition  # Transaction is ROLLED BACK!
end

# To commit on early return, use .transaction(requires_new: false):
# Or restructure code to avoid early return in transactions
```

**What Changed:**
- `return`, `break`, and `throw` inside a transaction block now trigger a rollback
- Previously, these would commit the transaction
- This is safer but may break existing logic that relies on commit-on-return

**Migration Steps:**
1. Search for `return`, `break`, or `throw` inside `transaction` blocks
2. Restructure code to avoid early exit:
   ```ruby
   ActiveRecord::Base.transaction do
     user.save!
     next if some_condition  # Use next instead of return
     other_operation
   end
   ```
3. Or assign result and check after transaction
4. Test all transaction flows carefully

---

#### 12. **show_exceptions Configuration Values Changed**

**Component:** ActionPack
**Impact:** Medium - New valid values for show_exceptions
**Type:** Configuration change

**OLD (Rails 6.1):**
```ruby
# Boolean values
config.action_dispatch.show_exceptions = true
config.action_dispatch.show_exceptions = false
```

**NEW (Rails 7.0):**
```ruby
# Boolean still works but deprecated
# New symbol values preferred:
config.action_dispatch.show_exceptions = :all        # was true
config.action_dispatch.show_exceptions = :rescuable   # new option
config.action_dispatch.show_exceptions = :none        # was false
```

**What Changed:**
- New symbol values introduced: `:all`, `:rescuable`, `:none`
- Boolean values still work but are deprecated
- `:rescuable` is a new option that only shows exceptions for rescuable errors

**Migration Steps:**
1. Search for `show_exceptions` in environment files
2. Replace `true` with `:all`
3. Replace `false` with `:none`
4. Consider `:rescuable` for test environments

---

#### 13. **#to_s with Format Argument Deprecated**

**Component:** ActiveSupport
**Impact:** Medium - Date/Time formatting syntax deprecated
**Type:** Deprecation

**OLD (Rails 6.1):**
```ruby
Time.current.to_s(:db)
Date.today.to_s(:short)
DateTime.now.to_s(:long)
```

**NEW (Rails 7.0):**
```ruby
# Use to_formatted_s or to_fs instead
Time.current.to_fs(:db)
Date.today.to_fs(:short)
DateTime.now.to_fs(:long)

# Or use I18n.l:
I18n.l(Time.current, format: :db)
```

**What Changed:**
- `to_s(:format)` is deprecated for Date, Time, DateTime, and other types
- New method `to_fs(:format)` (alias: `to_formatted_s`) is the replacement
- This avoids overriding Ruby's core `to_s` method

**Migration Steps:**
1. Search for `.to_s(:` pattern in codebase
2. Replace with `.to_fs(:`
3. Update any custom format helpers
4. Fix deprecation warnings in tests

---

### LOW IMPACT Changes

#### 14. **ActiveSupport::Digest Uses SHA256**

**Component:** ActiveSupport
**Impact:** Low - Changes internal digest algorithm
**Type:** Default change

**OLD (Rails 6.1):**
```ruby
# ActiveSupport::Digest used MD5
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::MD5
```

**NEW (Rails 7.0):**
```ruby
# ActiveSupport::Digest uses SHA256
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA256

# To keep MD5 temporarily:
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::MD5
```

**What Changed:**
- Default digest class changed from MD5 to SHA256
- Affects cache keys, ETags, and other internal digests
- May invalidate existing cache entries

**Migration Steps:**
1. Cache entries will be regenerated automatically
2. ETag values will change (may affect HTTP caching)
3. To keep MD5 temporarily, set in initializer

---

#### 15. **ActiveStorage Video Preview Requires FFmpeg**

**Component:** ActiveStorage
**Impact:** Low - FFmpeg requirement for video previews
**Type:** Dependency change

**NEW (Rails 7.0):**
```ruby
# Video previews now require FFmpeg
# Install: brew install ffmpeg (macOS)
#          apt-get install ffmpeg (Ubuntu)
```

**What Changed:**
- Video preview generation uses FFmpeg directly
- Must be installed on the system for video previews to work

**Migration Steps:**
1. Install FFmpeg if using video previews
2. No action needed if not using video previews

---

#### 16. **Schema Dump Includes Rails Version**

**Component:** ActiveRecord
**Impact:** Low - Schema file format change
**Type:** Enhancement

**OLD (Rails 6.1):**
```ruby
# db/schema.rb
ActiveRecord::Schema.define(version: 2024_01_01_000000) do
```

**NEW (Rails 7.0):**
```ruby
# db/schema.rb
ActiveRecord::Schema[7.0].define(version: 2024_01_01_000000) do
```

**What Changed:**
- Schema dump now includes the Rails version
- Ensures schema compatibility across Rails versions
- File is regenerated when running migrations

**Migration Steps:**
1. Run `rails db:schema:dump` to regenerate schema file
2. Commit the updated schema file
3. No functional changes needed

---

#### 17. **Spring 3.0.0+ Required**

**Component:** Railties
**Impact:** Low - Development dependency update
**Type:** Dependency change

**OLD (Rails 6.1):**
```ruby
# Gemfile
gem "spring", "~> 2.0"
```

**NEW (Rails 7.0):**
```ruby
# Gemfile
gem "spring", "~> 3.0"  # If using Spring

# Or remove Spring entirely (recommended for modern setups):
# Spring is no longer included by default
```

**What Changed:**
- Spring 2.x is not compatible with Rails 7.0
- Spring 3.0.0+ required if you use Spring
- Spring is no longer included in new Rails 7.0 apps

**Migration Steps:**
1. Update Spring: `gem "spring", "~> 3.0"` and `bundle update spring`
2. Or remove Spring entirely from Gemfile (recommended)
3. If removing, also remove `spring-watcher-listen`

---

## Custom Code Detection Patterns

The assistant will automatically scan for these patterns and flag them:

### 1. Classic Autoloader Configuration
```ruby
# PATTERN: Classic autoloader usage
config.autoloader = :classic

# WILL FLAG:
# Warning: Classic autoloader removed - must use Zeitwerk
```

### 2. require_dependency Calls
```ruby
# PATTERN: require_dependency usage
require_dependency "some_file"

# WILL FLAG:
# Warning: require_dependency is a no-op in Rails 7.0
```

### 3. ActiveSupport::Dependencies Usage
```ruby
# PATTERN: Private API usage
ActiveSupport::Dependencies.

# WILL FLAG:
# Warning: ActiveSupport::Dependencies private API removed
```

### 4. button_to Without Method
```ruby
# PATTERN: button_to without explicit method
button_to "Label", path

# WILL FLAG:
# Warning: button_to now defaults to PATCH - add explicit method: if needed
```

### 5. Autoloading in Initializers
```ruby
# PATTERN: Application code referenced in initializers
# config/initializers/*.rb referencing app/ classes

# WILL FLAG:
# Warning: Autoloading during initialization raises error - use to_prepare
```

### 6. Early Return in Transactions
```ruby
# PATTERN: return inside transaction block
transaction do
  return

# WILL FLAG:
# Warning: return in transaction now triggers rollback
```

---

## Step-by-Step Upgrade Process

### Before You Begin

**CRITICAL: Zeitwerk Preparation (Do This FIRST on Rails 6.1)**

```bash
# Run Zeitwerk compatibility check BEFORE upgrading
bin/rails zeitwerk:check

# Fix all issues reported
# Common fixes:
# - Rename files to match constants
# - Fix module nesting
# - Remove require_dependency calls
```

**Checklist:**
- [ ] `bin/rails zeitwerk:check` passes with no issues
- [ ] Application under version control (git)
- [ ] All tests currently passing
- [ ] Database backup created
- [ ] Staging environment available
- [ ] Team notified of upgrade
- [ ] Ruby version >= 2.7.0 (Rails 7.0 minimum)

### Step 1: Analysis

1. Say: `"Analyze my Rails app for upgrade to 7.0"`
2. Review the generated report
3. Note all warnings
4. Pay special attention to Zeitwerk and key generator changes

### Step 2: Gemfile Update

```ruby
# OLD
gem "rails", "~> 6.1.0"

# NEW
gem "rails", "~> 7.0.0"

# Also update Spring if using:
gem "spring", "~> 3.0"  # Or remove entirely
```

Run:
```bash
bundle update rails
```

### Step 3: Configuration Updates

**Priority Order:**

1. **config/application.rb**
   ```ruby
   # Remove classic autoloader config
   # config.autoloader = :classic  # REMOVE THIS

   # Update load defaults
   config.load_defaults 7.0

   # Keep SHA1 key generator initially
   config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
   ```

2. **Review new_framework_defaults_7_0.rb**
   ```bash
   rails app:update
   # Review config/initializers/new_framework_defaults_7_0.rb
   # Enable settings one at a time
   ```

3. **config/initializers/** (wrap autoloading)
   ```ruby
   # Wrap all app code references in to_prepare
   Rails.application.config.to_prepare do
     MyModel.configure_something
   end
   ```

4. **ActiveStorage** (variant processor)
   ```ruby
   # config/application.rb
   config.active_storage.variant_processor = :mini_magick  # Keep existing
   ```

5. **config/environments/*.rb**
   ```ruby
   # Update show_exceptions to symbols
   config.action_dispatch.show_exceptions = :all    # was true
   config.action_dispatch.show_exceptions = :none   # was false
   ```

### Step 4: Code Updates

```bash
# Remove require_dependency calls
grep -rn "require_dependency" app/ lib/ config/

# Find button_to without explicit method
grep -rn "button_to" app/views/

# Find early return in transactions
grep -rn "\.transaction" app/ lib/ | xargs grep -l "return"

# Find to_s with format argument
grep -rn "\.to_s(:" app/ lib/

# Find ActiveSupport::Dependencies usage
grep -rn "ActiveSupport::Dependencies" app/ lib/ config/

# Find bare require for app code
grep -rn "^require ['\"]" app/ lib/ config/
```

### Step 5: Testing

```bash
# Run Zeitwerk check first
bin/rails zeitwerk:check

# Run test suite
bin/rails test

# Check for deprecation warnings
RAILS_ENABLE_TEST_LOG=true bin/rails test

# Test in browser (development)
bin/rails server

# Run system tests
bin/rails test:system
```

### Step 6: Staging Deployment

1. Deploy to staging
2. Run smoke tests
3. Monitor logs for autoloading issues
4. Test critical user paths
5. Verify session/cookie behavior (key generator!)

### Step 7: Production Deployment

**Rolling Deploy Strategy:**

1. **First deploy:**
   - Keep SHA1 key generator
   - Monitor for autoloading errors
   - Watch for button_to behavior changes

2. **After 24-48 hours:**
   - Plan SHA256 key generator migration
   - Enable new framework defaults one at a time

3. **Key generator rotation (plan separately):**
   - Announce session reset to users
   - Switch to SHA256
   - Monitor login issues

---

## Rollback Plan

### If Issues Arise

1. **Gemfile Rollback:**
   ```ruby
   gem "rails", "~> 6.1.7"  # Latest 6.1
   ```

2. **Bundle:**
   ```bash
   bundle update rails
   ```

3. **Revert Configuration:**
   ```bash
   git checkout HEAD^ config/
   ```

4. **Database (if needed):**
   ```bash
   rails db:rollback STEP=X
   ```

5. **Redeploy Previous Version**

---

## Testing Checklist

### Functional Tests

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All system tests pass
- [ ] Manual smoke tests pass

### Environment Tests

- [ ] `bin/rails zeitwerk:check` passes
- [ ] Development boots correctly
- [ ] Test suite runs
- [ ] Production boots correctly
- [ ] Staging works as expected

### Feature Tests

- [ ] User authentication (key generator change!)
- [ ] Session persistence (key generator change!)
- [ ] Database operations (transaction rollback behavior!)
- [ ] Form submissions (button_to method change!)
- [ ] Background jobs
- [ ] Email delivery
- [ ] File uploads and image variants
- [ ] API endpoints
- [ ] Encrypted credentials
- [ ] Cache operations

### Performance Tests

- [ ] Page load times acceptable
- [ ] Database query performance
- [ ] Autoloading speed
- [ ] Background job processing

---

## Common Issues & Solutions

### Issue 1: Application Won't Boot

**Symptom:** `Zeitwerk::NameError` on boot
**Cause:** File/constant naming mismatch
**Solution:**
```bash
# Run Zeitwerk check
bin/rails zeitwerk:check

# Rename files to match constants:
# PDFGenerator → pdf_generator.rb
# HTMLParser → html_parser.rb
```

### Issue 2: Autoloading Error in Initializer

**Symptom:** `NameError: uninitialized constant` during boot
**Cause:** Autoloading during initialization not allowed
**Solution:**
```ruby
# config/initializers/my_init.rb
# Wrap in to_prepare:
Rails.application.config.to_prepare do
  MyModel.configure_something
end
```

### Issue 3: Users Logged Out

**Symptom:** All users forced to re-login
**Cause:** Key generator changed from SHA1 to SHA256
**Solution:**
```ruby
# Keep SHA1 temporarily:
config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
```

### Issue 4: button_to Hitting Wrong Route

**Symptom:** "No route matches [PATCH]" errors
**Cause:** `button_to` now defaults to PATCH
**Solution:**
```ruby
# Add explicit method:
<%= button_to "Action", path, method: :post %>
```

### Issue 5: Transaction Not Committing

**Symptom:** Database changes disappearing
**Cause:** `return` in transaction now rolls back
**Solution:**
```ruby
# Restructure to avoid early return:
result = ActiveRecord::Base.transaction do
  user.save!
  some_condition ? :skip : :done
end
```

---

## Official Resources

### Rails Guides
- https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- https://guides.rubyonrails.org/7_0_release_notes.html

### GitHub CHANGELOGs
- ActionCable: https://github.com/rails/rails/blob/v7.0.0/actioncable/CHANGELOG.md
- ActionMailbox: https://github.com/rails/rails/blob/v7.0.0/actionmailbox/CHANGELOG.md
- ActionMailer: https://github.com/rails/rails/blob/v7.0.0/actionmailer/CHANGELOG.md
- ActionPack: https://github.com/rails/rails/blob/v7.0.0/actionpack/CHANGELOG.md
- ActionText: https://github.com/rails/rails/blob/v7.0.0/actiontext/CHANGELOG.md
- ActionView: https://github.com/rails/rails/blob/v7.0.0/actionview/CHANGELOG.md
- ActiveJob: https://github.com/rails/rails/blob/v7.0.0/activejob/CHANGELOG.md
- ActiveModel: https://github.com/rails/rails/blob/v7.0.0/activemodel/CHANGELOG.md
- ActiveRecord: https://github.com/rails/rails/blob/v7.0.0/activerecord/CHANGELOG.md
- ActiveStorage: https://github.com/rails/rails/blob/v7.0.0/activestorage/CHANGELOG.md
- ActiveSupport: https://github.com/rails/rails/blob/v7.0.0/activesupport/CHANGELOG.md
- Railties: https://github.com/rails/rails/blob/v7.0.0/railties/CHANGELOG.md
