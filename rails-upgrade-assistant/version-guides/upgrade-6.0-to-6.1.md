---
title: "Rails 6.0 → 6.1.0 Upgrade Guide"
description: "Complete upgrade guide from Rails 6.0.x to 6.1.0 with breaking changes, migration steps, and testing procedures"
type: "version-guide"
rails_from: "6.0.x"
rails_to: "6.1.0"
difficulty: "medium"
breaking_changes: 18
priority_high: 6
priority_medium: 8
priority_low: 4
major_changes:
  - where.not NAND semantics
  - form_with generates non-remote forms
  - config_for Symbol-only keys
  - ActiveModel::Error new API
  - SameSite=Lax cookie default
  - Content-Type includes charset
tags:
  - rails-6.1
  - upgrade-guide
  - breaking-changes
  - where-not
  - form_with
  - config_for
  - activemodel-errors
  - samesite-cookies
category: "rails-upgrade"
version_family: "rails-6.x"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails 6.0 → 6.1 Upgrade Guide

## Supported Upgrade Path

**From:** Rails 6.0.x
**To:** Rails 6.1.0

This is a **MEDIUM complexity** upgrade.

---

## Breaking Changes - Rails 6.0 to 6.1.0

### HIGH IMPACT Changes (Breaking)

#### 1. **where.not Now Uses NAND (NOT AND) Semantics**

**Component:** ActiveRecord
**Impact:** High - Changes query behavior for multi-condition where.not
**Type:** Breaking - silently changes query results

**OLD (Rails 6.0):**
```ruby
# Generated NOR: WHERE NOT (role = 'admin') AND NOT (status = 'active')
User.where.not(role: "admin", status: "active")
# SQL: WHERE (role != 'admin' AND status != 'active')
```

**NEW (Rails 6.1):**
```ruby
# Generates NAND: WHERE NOT (role = 'admin' AND status = 'active')
User.where.not(role: "admin", status: "active")
# SQL: WHERE NOT (role = 'admin' AND status = 'active')
# Equivalent to: WHERE (role != 'admin' OR status != 'active')
```

**What Changed:**
- `where.not` with multiple conditions now uses NAND instead of NOR
- This changes query results silently — no error, different data
- Single-condition `where.not` is unaffected

**Migration Steps:**
1. Search for `where.not` with hash arguments containing multiple keys
2. If NOR behavior is needed, chain separate `where.not` calls:
   ```ruby
   User.where.not(role: "admin").where.not(status: "active")
   ```
3. Test all queries that use multi-key `where.not`
4. Review results carefully — this is a silent behavior change

---

#### 2. **form_with Generates Non-Remote Forms by Default**

**Component:** ActionView
**Impact:** High - Changes form submission behavior
**Type:** Breaking - forms now submit as standard HTTP instead of XHR

**OLD (Rails 6.0):**
```ruby
# form_with generated remote: true by default (AJAX submission)
<%= form_with(model: @user) do |f| %>
  # Generated: <form data-remote="true" ...>
<% end %>
```

**NEW (Rails 6.1):**
```ruby
# form_with generates local forms by default (standard HTTP submission)
<%= form_with(model: @user) do |f| %>
  # Generated: <form ...> (no data-remote)
<% end %>

# To keep old behavior explicitly:
<%= form_with(model: @user, local: false) do |f| %>
```

**What Changed:**
- `config.action_view.form_with_generates_remote_forms` now defaults to `false`
- Forms created with `form_with` no longer submit via AJAX by default
- `form_for` was already non-remote, only `form_with` changes

**Migration Steps:**
1. Search for all `form_with` calls in views
2. If AJAX submission is needed, add `local: false` to each form
3. OR set `config.action_view.form_with_generates_remote_forms = true` in application config
4. Test all form submissions thoroughly

---

#### 3. **config_for Requires Symbol Keys**

**Component:** Railties
**Impact:** High - Changes configuration access pattern
**Type:** Breaking - string keys raise error

**OLD (Rails 6.0):**
```ruby
# config/my_config.yml
# development:
#   api_key: "abc123"

config = Rails.application.config_for(:my_config)
config["api_key"]   # Worked with string keys
config[:api_key]    # Also worked with symbol keys
```

**NEW (Rails 6.1):**
```ruby
config = Rails.application.config_for(:my_config)
config[:api_key]    # Works - symbol keys only
config["api_key"]   # NoMethodError or nil - string keys no longer work
```

**What Changed:**
- `config_for` now returns an `ActiveSupport::OrderedOptions` object
- Only Symbol key access is supported
- String key access no longer works
- Supports nested method-style access: `config.api_key`

**Migration Steps:**
1. Search for `config_for` usage throughout your codebase
2. Replace all string key access (`config["key"]`) with symbol keys (`config[:key]`)
3. Consider using method-style access: `config.api_key`
4. Update any code that iterates over config keys

---

#### 4. **ActiveModel::Errors New API**

**Component:** ActiveModel
**Impact:** High - Changes error handling interface
**Type:** Breaking - old hash-like methods removed or changed

**OLD (Rails 6.0):**
```ruby
# Hash-like interface
user.errors[:name]           # Returns array of messages
user.errors.keys             # Returns attribute names with errors
user.errors[:name] << "custom error"  # Direct array manipulation
user.errors.details[:name]   # Returns error details

# Adding errors
user.errors.add(:name, :blank)
user.errors[:name]           # ["can't be blank"]
```

**NEW (Rails 6.1):**
```ruby
# New Error objects API
user.errors[:name]           # Still returns array of messages (backward compat)
user.errors.where(:name)     # Returns array of Error objects (new!)

# Error objects have attributes
error = user.errors.where(:name).first
error.attribute              # :name
error.type                   # :blank
error.message                # "can't be blank"
error.full_message           # "Name can't be blank"
error.details                # { error: :blank }

# Adding errors (same)
user.errors.add(:name, :blank)

# Deprecated: direct hash manipulation
user.errors[:name] << "msg"  # Deprecated, use errors.add instead
```

**What Changed:**
- `errors` now contains `ActiveModel::Error` objects internally
- `errors.keys`, `errors.values`, `errors.to_xml` behavior changed
- Direct array manipulation (`errors[:attr] << msg`) is deprecated
- New `errors.where` method for querying errors
- `errors#add` now returns an `Error` object

**Migration Steps:**
1. Replace `errors[:attr] << "msg"` with `errors.add(:attr, :invalid, message: "msg")`
2. Replace `errors.keys` if relying on duplicates — use `errors.attribute_names` for unique list
3. Update any code that treats `errors` as a plain Hash
4. Test custom validators and error handling thoroughly

---

#### 5. **SameSite=Lax Cookie Default**

**Component:** ActionPack
**Impact:** High - Changes cookie security behavior
**Type:** Breaking - affects cross-site requests and OAuth flows

**OLD (Rails 6.0):**
```ruby
# Cookies had no SameSite attribute by default
# Browsers treated them as SameSite=None (sent on all requests)
cookies[:session_id] = { value: "abc", httponly: true }
# Set-Cookie: session_id=abc; HttpOnly
```

**NEW (Rails 6.1):**
```ruby
# Cookies default to SameSite=Lax
cookies[:session_id] = { value: "abc", httponly: true }
# Set-Cookie: session_id=abc; HttpOnly; SameSite=Lax

# To keep old behavior:
cookies[:session_id] = { value: "abc", same_site: :none, secure: true }
```

**What Changed:**
- `config.action_dispatch.cookies_same_site_protection` defaults to `:lax`
- All cookies get `SameSite=Lax` unless explicitly set otherwise
- Cross-site POST requests will not include cookies by default
- OAuth and payment gateway callbacks may break

**Migration Steps:**
1. Review OAuth/SSO integrations that rely on cross-site cookies
2. Review payment gateway callbacks (Stripe, PayPal)
3. For cross-site cookies, explicitly set `same_site: :none, secure: true`
4. Test all third-party integrations thoroughly
5. OR set `config.action_dispatch.cookies_same_site_protection = :none` (not recommended)

---

#### 6. **Content-Type Now Includes Charset in Full Header**

**Component:** ActionPack
**Impact:** High - Changes Content-Type comparison behavior
**Type:** Breaking - string comparisons against Content-Type may fail

**OLD (Rails 6.0):**
```ruby
# request.content_type returned just the MIME type
request.content_type
# => "text/html"
```

**NEW (Rails 6.1):**
```ruby
# request.content_type now returns the full Content-Type header
request.content_type
# => "text/html; charset=utf-8"

# Use request.media_type for just the MIME type
request.media_type
# => "text/html"
```

**What Changed:**
- `request.content_type` returns the full header including charset
- String comparisons like `request.content_type == "text/html"` may fail
- New `request.media_type` method returns just the MIME type

**Migration Steps:**
1. Search for `request.content_type` comparisons in controllers and middleware
2. Replace `request.content_type == "type"` with `request.media_type == "type"`
3. Review middleware that inspects Content-Type headers
4. Test API endpoints that check content types

---

### MEDIUM IMPACT Changes

#### 7. **halted_callback_hook Signature Changed**

**Component:** ActiveSupport
**Impact:** Medium - Affects custom callback handling
**Type:** Breaking for apps overriding halted_callback_hook

**OLD (Rails 6.0):**
```ruby
class MyModel < ApplicationRecord
  def halted_callback_hook(filter)
    # Only received the filter name
    Rails.logger.warn "Callback halted by #{filter}"
  end
end
```

**NEW (Rails 6.1):**
```ruby
class MyModel < ApplicationRecord
  def halted_callback_hook(filter, name)
    # Now receives filter AND callback chain name
    Rails.logger.warn "Callback #{name} halted by #{filter}"
  end
end
```

**What Changed:**
- `halted_callback_hook` now receives a second argument: the callback chain name
- Existing overrides with single argument still work but miss the name

**Migration Steps:**
1. Search for `halted_callback_hook` overrides
2. Add second parameter `name` to method signature
3. Update logging or handling to use the new parameter

---

#### 8. **HTTPS Redirect Uses 308 Status Code**

**Component:** ActionPack
**Impact:** Medium - Changes redirect behavior for POST/PUT/DELETE
**Type:** Behavior change

**OLD (Rails 6.0):**
```ruby
# force_ssl used 301 redirect (changes POST to GET)
config.force_ssl = true
# HTTP POST → 301 → GET (method changed!)
```

**NEW (Rails 6.1):**
```ruby
# force_ssl now uses 308 redirect (preserves HTTP method)
config.force_ssl = true
# HTTP POST → 308 → POST (method preserved!)
```

**What Changed:**
- HTTP to HTTPS redirects now use 308 Permanent Redirect
- POST, PUT, DELETE methods are preserved during redirect
- Some older HTTP clients may not support 308

**Migration Steps:**
1. Check if any clients rely on POST-to-GET conversion during SSL redirect
2. Test with older HTTP clients that may not support 308
3. If needed, configure custom redirect status in middleware

---

#### 9. **image_processing Gem Required for Variants**

**Component:** ActiveStorage
**Impact:** Medium - Requires new gem for image variants
**Type:** Breaking for apps using image variants

**OLD (Rails 6.0):**
```ruby
# mini_magick was bundled/default
# Gemfile
gem "mini_magick"

# Usage
image.variant(resize: "100x100")
```

**NEW (Rails 6.1):**
```ruby
# image_processing gem now required
# Gemfile
gem "image_processing", "~> 1.2"

# Usage (same API, different backend)
image.variant(resize_to_limit: [100, 100])
```

**What Changed:**
- `image_processing` gem is now required for ActiveStorage variants
- Provides a more consistent API across ImageMagick and libvips
- Old `mini_magick` transformations syntax deprecated
- `resize` becomes `resize_to_limit`, `resize_to_fit`, etc.

**Migration Steps:**
1. Add `gem "image_processing", "~> 1.2"` to Gemfile
2. Run `bundle install`
3. Replace `resize: "WxH"` with `resize_to_limit: [W, H]`
4. Replace `combine_options` blocks with image_processing methods
5. Test all image variant generation

---

#### 10. **respond_to#any Sets Content-Type Based on Format**

**Component:** ActionPack
**Impact:** Medium - Changes Content-Type in respond_to blocks
**Type:** Behavior change

**OLD (Rails 6.0):**
```ruby
respond_to do |format|
  format.any { render json: @data }
  # Content-Type might not match the requested format
end
```

**NEW (Rails 6.1):**
```ruby
respond_to do |format|
  format.any { render json: @data }
  # Content-Type now matches the actual requested format
end
```

**What Changed:**
- `respond_to#any` now sets the response Content-Type based on the requested format
- Previously, Content-Type could be inconsistent with the format block

**Migration Steps:**
1. Review `respond_to` blocks using `format.any`
2. Verify Content-Type expectations in API tests
3. Update client code that depends on specific Content-Type headers

---

#### 11. **fixture_file_upload Relative Paths**

**Component:** ActionDispatch
**Impact:** Medium - Changes test file upload paths
**Type:** Behavior change

**OLD (Rails 6.0):**
```ruby
# Required file_fixture_path prefix or absolute path
fixture_file_upload("files/image.png", "image/png")
# Or
fixture_file_upload(Rails.root.join("test/fixtures/files/image.png"))
```

**NEW (Rails 6.1):**
```ruby
# Resolves relative to fixture_path automatically
fixture_file_upload("image.png", "image/png")
# Looks in test/fixtures/files/ by default
```

**What Changed:**
- `fixture_file_upload` now resolves paths relative to `file_fixture_path`
- Existing absolute paths still work
- Relative paths are resolved differently

**Migration Steps:**
1. Review `fixture_file_upload` calls in tests
2. Verify file paths resolve correctly
3. Update paths if they relied on old resolution behavior

---

#### 12. **Helper Loading Uses constantize**

**Component:** ActionController
**Impact:** Medium - Changes how helpers are loaded
**Type:** Behavior change

**OLD (Rails 6.0):**
```ruby
# Helpers were loaded using string manipulation
# Non-standard helper naming might have worked
```

**NEW (Rails 6.1):**
```ruby
# Helpers are now loaded using constantize
# Helper module must follow standard naming conventions
# UsersHelper for users_helper.rb
```

**What Changed:**
- Helper modules are now loaded using `String#constantize`
- Helpers must follow standard Ruby naming conventions
- Non-standard helper file/module names may fail to load

**Migration Steps:**
1. Verify all helper modules follow naming conventions
2. Ensure helper file names match module names
3. Test that all helpers load correctly

---

#### 13. **update_attributes Removed**

**Component:** ActiveRecord
**Impact:** Medium - Long-deprecated method finally removed
**Type:** Removal

**OLD (Rails 6.0):**
```ruby
# update_attributes still worked (deprecated since Rails 4)
user.update_attributes(name: "New Name")
user.update_attributes!(name: "New Name")
```

**NEW (Rails 6.1):**
```ruby
# Use update and update! instead
user.update(name: "New Name")
user.update!(name: "New Name")
```

**What Changed:**
- `update_attributes` and `update_attributes!` are removed
- These were deprecated since Rails 4.0
- `update` and `update!` are the replacements

**Migration Steps:**
1. Search for `update_attributes` in entire codebase
2. Replace `update_attributes` with `update`
3. Replace `update_attributes!` with `update!`
4. Check gems that may still use `update_attributes`

---

#### 14. **ActiveModel::Errors#to_hash Removed**

**Component:** ActiveModel
**Impact:** Medium - Removed deprecated method
**Type:** Removal

**OLD (Rails 6.0):**
```ruby
user.valid?
user.errors.to_hash
# => { name: ["can't be blank"], email: ["is invalid"] }
```

**NEW (Rails 6.1):**
```ruby
user.valid?
user.errors.to_hash  # Deprecated
# Use messages or group_by_attribute instead:
user.errors.messages
# => { name: ["can't be blank"], email: ["is invalid"] }

user.errors.group_by_attribute
# Returns hash of attribute => Error objects
```

**What Changed:**
- `errors.to_hash` behavior changed with new Error objects API
- `errors.messages` returns the same format as old `to_hash`
- New `errors.group_by_attribute` provides richer error info

**Migration Steps:**
1. Search for `errors.to_hash` in codebase
2. Replace with `errors.messages` for same output format
3. Consider `errors.group_by_attribute` for richer error data

---

### LOW IMPACT Changes

#### 15. **Feature-Policy Renamed to Permissions-Policy**

**Component:** ActionPack
**Impact:** Low - Header name change following web standard
**Type:** Standard compliance

**OLD (Rails 6.0):**
```ruby
# config/initializers/permissions_policy.rb
Rails.application.config.permissions_policy do |policy|
  # Used Feature-Policy header
end
```

**NEW (Rails 6.1):**
```ruby
# config/initializers/permissions_policy.rb
Rails.application.config.permissions_policy do |policy|
  # Now uses Permissions-Policy header (web standard)
  policy.camera :none
  policy.microphone :none
end
```

**What Changed:**
- `Feature-Policy` header renamed to `Permissions-Policy` per W3C spec
- Rails now sends the correct header name
- Old header may still be sent for backward compatibility

**Migration Steps:**
1. Update any middleware or proxies that reference `Feature-Policy`
2. Review CSP and permissions policies

---

#### 16. **Duration#iso8601 Sign Handling**

**Component:** ActiveSupport
**Impact:** Low - Changes ISO 8601 duration formatting
**Type:** Bug fix

**OLD (Rails 6.0):**
```ruby
(-1.year).iso8601
# => "-P1Y"  (sign on the period designator)
```

**NEW (Rails 6.1):**
```ruby
(-1.year).iso8601
# => "P-1Y"  (sign on the numeric value, per ISO 8601)
```

**What Changed:**
- Negative durations now place the sign on the numeric value
- This follows the ISO 8601 standard more correctly

**Migration Steps:**
1. Check if you serialize/parse ISO 8601 durations
2. Update any parsing logic that expected the old format

---

#### 17. **Partial Renders Logged at DEBUG Level**

**Component:** ActionView
**Impact:** Low - Changes log verbosity
**Type:** Logging change

**OLD (Rails 6.0):**
```
# Partial renders logged at INFO level
Rendered users/_form.html.erb (Duration: 2.1ms | Allocations: 234)
```

**NEW (Rails 6.1):**
```
# Partial renders now logged at DEBUG level
# Only visible when log level is DEBUG
```

**What Changed:**
- Individual partial render notifications moved to DEBUG level
- Reduces log noise in production (where level is usually INFO)
- Still visible in development (where level is DEBUG)

**Migration Steps:**
1. If you parse logs for partial render times, ensure log level is DEBUG
2. Update log monitoring tools if they filter by level

---

#### 18. **ActionMailer Default Delivery Job Changed**

**Component:** ActionMailer
**Impact:** Low - Changes default delivery job class
**Type:** Internal change

**OLD (Rails 6.0):**
```ruby
# Used ActionMailer::DeliveryJob
config.action_mailer.delivery_job = "ActionMailer::DeliveryJob"
```

**NEW (Rails 6.1):**
```ruby
# Uses ActionMailer::MailDeliveryJob
config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
```

**What Changed:**
- Default delivery job changed to `ActionMailer::MailDeliveryJob`
- Supports parameterized and unified mailer delivery
- Old `DeliveryJob` still works but is deprecated

**Migration Steps:**
1. Check for explicit `delivery_job` configuration
2. Update if you reference `ActionMailer::DeliveryJob` directly
3. Clear job queues during upgrade if needed

---

## Custom Code Detection Patterns

The assistant will automatically scan for these patterns and flag them:

### 1. Multi-Key where.not
```ruby
# PATTERN: where.not with multiple hash keys
where.not(key1: val1, key2: val2)

# WILL FLAG:
# Warning: Multi-key where.not detected - verify NAND vs NOR behavior
```

### 2. form_with Without Explicit Remote
```ruby
# PATTERN: form_with without local: or remote: option
form_with(model:

# WILL FLAG:
# Warning: form_with without explicit local/remote - now defaults to local
```

### 3. config_for String Key Access
```ruby
# PATTERN: String key access on config_for results
config["key"]

# WILL FLAG:
# Warning: String key access on config_for - use Symbol keys
```

### 4. Content-Type String Comparison
```ruby
# PATTERN: Direct content_type string comparison
request.content_type == "text/

# WILL FLAG:
# Warning: content_type now returns full header - use media_type instead
```

### 5. update_attributes Usage
```ruby
# PATTERN: Deprecated method
.update_attributes(
.update_attributes!(

# WILL FLAG:
# Warning: update_attributes removed - use update/update!
```

---

## Step-by-Step Upgrade Process

### Before You Begin

**Checklist:**
- [ ] Application under version control (git)
- [ ] All tests currently passing
- [ ] Database backup created
- [ ] Staging environment available
- [ ] Team notified of upgrade
- [ ] Documentation updated
- [ ] Rails MCP server connected

### Step 1: Analysis

1. Say: `"Analyze my Rails app for upgrade to 6.1"`
2. Review the generated report
3. Note all warnings
4. Identify breaking changes affecting your app

### Step 2: Gemfile Update

```ruby
# OLD
gem "rails", "~> 6.0.0"

# NEW
gem "rails", "~> 6.1.0"
```

Run:
```bash
bundle update rails
```

### Step 3: Configuration Updates

**Priority Order:**

1. **config/application.rb**
   ```ruby
   # Update load defaults
   config.load_defaults 6.1
   ```

2. **Review new_framework_defaults_6_1.rb**
   ```bash
   rails app:update
   # Review config/initializers/new_framework_defaults_6_1.rb
   # Enable settings one at a time
   ```

3. **Cookie configuration** (if using cross-site cookies)
   ```ruby
   # config/initializers/cookies.rb
   Rails.application.config.action_dispatch.cookies_same_site_protection = :lax
   ```

4. **Form configuration** (if relying on remote forms)
   ```ruby
   # config/application.rb
   config.action_view.form_with_generates_remote_forms = false  # New default
   ```

5. **ActiveStorage** (if using image variants)
   ```ruby
   # Gemfile
   gem "image_processing", "~> 1.2"
   ```

### Step 4: Code Updates

```bash
# Find and fix update_attributes
grep -rn "update_attributes" app/ lib/ test/

# Find multi-key where.not
grep -rn "where\.not(" app/ lib/

# Find config_for string key access
grep -rn 'config_for' app/ config/ lib/

# Find content_type comparisons
grep -rn 'content_type ==' app/ lib/
```

### Step 5: Testing

```bash
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
3. Monitor logs for issues
4. Test critical user paths
5. Verify OAuth/payment integrations (SameSite cookie impact)

### Step 7: Production Deployment

**Rolling Deploy Strategy:**

1. **First deploy:**
   - Monitor for cookie-related issues
   - Watch for query result changes (where.not)

2. **After 24-48 hours:**
   - Enable new framework defaults one at a time
   - Monitor error rates

3. **Monitor:**
   - Error rates
   - Performance metrics
   - User reports
   - Third-party integration callbacks

---

## Rollback Plan

### If Issues Arise

1. **Gemfile Rollback:**
   ```ruby
   gem "rails", "~> 6.0.6"  # Latest 6.0
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

- [ ] Development boots correctly
- [ ] Test suite runs
- [ ] Production boots correctly
- [ ] Staging works as expected

### Feature Tests

- [ ] User authentication (cookie changes!)
- [ ] Database operations (where.not queries!)
- [ ] Form submissions (remote default changed!)
- [ ] Background jobs
- [ ] Email delivery
- [ ] File uploads and image variants
- [ ] API endpoints (Content-Type changes!)
- [ ] OAuth/SSO flows (SameSite cookies!)
- [ ] Payment gateway callbacks (SameSite cookies!)

### Performance Tests

- [ ] Page load times acceptable
- [ ] Database query performance
- [ ] Image variant generation
- [ ] Background job processing

---

## Common Issues & Solutions

### Issue 1: Query Results Changed

**Symptom:** Different records returned from queries
**Cause:** `where.not` NAND semantics
**Solution:**
```ruby
# Chain separate where.not calls for NOR behavior
User.where.not(role: "admin").where.not(status: "active")
```

### Issue 2: Forms Not Submitting via AJAX

**Symptom:** Forms reload the page instead of AJAX submit
**Cause:** `form_with` no longer remote by default
**Solution:**
```ruby
# Add local: false to forms that need AJAX
<%= form_with(model: @user, local: false) do |f| %>
```

### Issue 3: Config Values Return Nil

**Symptom:** `config_for` values returning nil
**Cause:** String key access no longer works
**Solution:**
```ruby
# Use symbol keys
config = Rails.application.config_for(:my_config)
config[:api_key]  # Instead of config["api_key"]
```

### Issue 4: OAuth/SSO Broken

**Symptom:** Users redirected to login after cross-site requests
**Cause:** SameSite=Lax cookie default
**Solution:**
```ruby
# For cross-site cookies, explicitly set SameSite=None
cookies[:token] = { value: "abc", same_site: :none, secure: true }
```

### Issue 5: Image Variants Failing

**Symptom:** `MiniMagick::Error` or variants not generating
**Cause:** `image_processing` gem required
**Solution:**
```ruby
# Gemfile
gem "image_processing", "~> 1.2"
```

---

## Official Resources

### Rails Guides
- https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- https://guides.rubyonrails.org/6_1_release_notes.html

### GitHub CHANGELOGs
- ActionCable: https://github.com/rails/rails/blob/v6.1.0/actioncable/CHANGELOG.md
- ActionMailbox: https://github.com/rails/rails/blob/v6.1.0/actionmailbox/CHANGELOG.md
- ActionMailer: https://github.com/rails/rails/blob/v6.1.0/actionmailer/CHANGELOG.md
- ActionPack: https://github.com/rails/rails/blob/v6.1.0/actionpack/CHANGELOG.md
- ActionText: https://github.com/rails/rails/blob/v6.1.0/actiontext/CHANGELOG.md
- ActionView: https://github.com/rails/rails/blob/v6.1.0/actionview/CHANGELOG.md
- ActiveJob: https://github.com/rails/rails/blob/v6.1.0/activejob/CHANGELOG.md
- ActiveModel: https://github.com/rails/rails/blob/v6.1.0/activemodel/CHANGELOG.md
- ActiveRecord: https://github.com/rails/rails/blob/v6.1.0/activerecord/CHANGELOG.md
- ActiveStorage: https://github.com/rails/rails/blob/v6.1.0/activestorage/CHANGELOG.md
- ActiveSupport: https://github.com/rails/rails/blob/v6.1.0/activesupport/CHANGELOG.md
- Railties: https://github.com/rails/rails/blob/v6.1.0/railties/CHANGELOG.md
