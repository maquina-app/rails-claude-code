---
title: "Rails 7.1.6 → 7.2.3 Upgrade Guide"
description: "Complete upgrade guide from Rails 7.1.6 to 7.2.3 featuring transaction-aware jobs and 38 breaking changes - the most complex upgrade in this series"
type: "version-guide"
rails_from: "7.1.6"
rails_to: "7.2.3"
difficulty: "hard"
estimated_time: "4-8 hours"
breaking_changes: 38
priority_high: 5
priority_medium: 12
priority_low: 21
major_changes:
  - Transaction-aware job enqueuing (CRITICAL)
  - show_exceptions now symbols only
  - params comparison removed
  - ActiveRecord.connection deprecated
  - Rails.application.secrets removed
tags:
  - rails-7.2
  - upgrade-guide
  - breaking-changes
  - transaction-aware-jobs
  - show_exceptions
  - params-comparison
  - activerecord-connection
  - secrets-removal
category: "rails-upgrade"
version_family: "rails-7.x"
critical_warning: "Transaction-aware job enqueuing behavior change - test job timing extensively"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails Upgrade Skill: 7.1.6 → 7.2.3

**Skill Version:** 1.0  
**Last Updated:** November 1, 2025  
**Rails Source Version:** 7.1.6  
**Rails Target Version:** 7.2.3  
**Complexity:** ⭐⭐ Medium  
**Estimated Time:** 4-8 hours  

---

## 📋 Skill Overview

This skill teaches Claude how to upgrade any Ruby on Rails application from version 7.1.6 to version 7.2.3. All information is based on official Rails CHANGELOGs from the Rails GitHub repository and the official rails diff.

### What This Skill Does

When a user asks to upgrade their Rails application from 7.1.6 to 7.2.3, Claude will:

1. ✅ Analyze the project using Rails MCP tools
2. ✅ Identify breaking changes affecting the specific application
3. ✅ Generate a comprehensive upgrade report
4. ✅ Provide step-by-step migration instructions
5. ✅ Detect custom code that needs attention
6. ✅ Optionally update files via Neovim MCP integration

### When to Use This Skill

- User says: "Upgrade my Rails app from 7.1 to 7.2"
- User says: "Update Rails to 7.2.3"
- User says: "What do I need to change for Rails 7.2?"
- User explicitly mentions upgrading from Rails 7.1.x to 7.2.x

---

## 🎯 Upgrade Process Workflow

### Step 1: Project Analysis

**Always start by analyzing the project:**

```
1. Use railsMcpServer:project_info to get current Rails version
2. Use railsMcpServer:get_file to read key configuration files:
   - Gemfile
   - config/application.rb
   - config/environments/*.rb
3. Use railsMcpServer:list_files to understand project structure
```

### Step 2: Generate Upgrade Report

**Create a comprehensive report with these sections:**

1. **Executive Summary**
   - Current version
   - Target version
   - Complexity rating
   - Time estimate
   - Breaking changes count

2. **Critical Breaking Changes** (High Impact)
   - List all breaking changes that WILL cause errors
   - Mark each with ⚠️
   - Provide OLD/NEW code examples
   - Indicate which files in THEIR project are affected

3. **Medium Impact Changes**
   - Deprecations that should be fixed
   - Behavior changes
   - Configuration updates

4. **New Features** (Optional)
   - New Rails 7.2 features they can adopt
   - Mark as optional

5. **Step-by-Step Migration Plan**
   - Phase by phase breakdown
   - Estimated time per phase
   - Testing checkpoints

6. **Project-Specific Warnings**
   - Custom code detection
   - Mark with ⚠️ WARNING
   - Files that need manual review

### Step 3: Offer Interactive Updates

**If user wants file updates:**

```
1. Use nvimMcpServer:get_project_buffers to see open files
2. Ask user to open the file they want to update
3. Use nvimMcpServer:update_buffer to apply changes
4. Provide clear before/after explanations
```

---

## 📊 Rails 7.2.3 Breaking Changes Reference

### CRITICAL: ActionPack Changes

#### 1. Browser Version Enforcement (NEW FEATURE)

**Impact:** HIGH - May block users  
**Status:** New default behavior

Rails 7.2 adds `allow_browser` to ApplicationController by default:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # This is added by default in new Rails 7.2 apps
  allow_browser versions: :modern
end
```

**What it does:**
- Blocks browsers that don't support modern web features
- Returns HTTP 406 with `public/406-unsupported-browser.html`
- Blocks: Old Internet Explorer, Safari < 16.4, Firefox < 121, etc.

**Detection:** Check if `ApplicationController` exists in project

**Migration:**
```ruby
# If upgrading existing app, this is NOT automatically added
# User must decide if they want it

# Option 1: Don't add it (keep supporting old browsers)
# No action needed

# Option 2: Add browser restrictions
class ApplicationController < ActionController::Base
  # Allow only modern browsers
  allow_browser versions: :modern
  
  # OR customize per browser
  allow_browser versions: { safari: 16.4, firefox: 121, chrome: 119 }
end
```

**Files to check:**
- `app/controllers/application_controller.rb`
- Any other base controllers

---

#### 2. Removed Deprecated show_exceptions Configuration

**Impact:** HIGH - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# config/environments/production.rb
# OLD (NO LONGER WORKS)
config.action_dispatch.show_exceptions = true
config.action_dispatch.show_exceptions = false
```

**Migration:**
```ruby
# NEW (Required)
config.action_dispatch.show_exceptions = :all      # Show all exceptions (like true)
config.action_dispatch.show_exceptions = :rescuable # Show rescuable exceptions
config.action_dispatch.show_exceptions = :none     # Don't show exceptions (like false)
```

**Detection pattern:**
```bash
grep -r "show_exceptions.*true\|show_exceptions.*false" config/
```

**Files to check:**
- `config/environments/production.rb`
- `config/environments/development.rb`
- `config/environments/test.rb`

---

#### 3. Removed Deprecated return_only_request_media_type_on_content_type

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.action_dispatch.return_only_request_media_type_on_content_type = false
```

**Migration:**
This config is removed. Rails 7.2 always returns the full media type.

**Detection pattern:**
```bash
grep -r "return_only_request_media_type" config/
```

---

#### 4. Removed Comparison Between ActionController::Parameters and Hash

**Impact:** HIGH - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
if params == { name: "John" }
  # ...
end

if { name: "John" } == params
  # ...
end
```

**Migration:**
```ruby
# NEW (Use .to_h)
if params.to_h == { name: "John" }
  # ...
end

# Or use permit
if params.permit(:name) == { name: "John" }
  # ...
end
```

**Detection pattern:**
```bash
grep -rn "params.*==" app/controllers/
grep -rn "==.*params" app/controllers/
```

**Files to check:**
- All controllers in `app/controllers/`
- Any service objects that compare params

---

#### 5. Removed AbstractController::Helpers::MissingHelperError

**Impact:** LOW - BREAKING  
**Status:** Removed constant

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
rescue AbstractController::Helpers::MissingHelperError
  # ...
end
```

**Migration:**
```ruby
# NEW (Use the correct constant)
rescue AbstractController::Helpers::MissingHelper
  # ...
end
```

**Detection pattern:**
```bash
grep -r "MissingHelperError" app/
```

---

#### 6. Removed ActionDispatch::IllegalStateError

**Impact:** LOW - BREAKING  
**Status:** Removed constant

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
rescue ActionDispatch::IllegalStateError
  # ...
end
```

**Migration:**
This constant no longer exists. Use standard error handling.

**Detection pattern:**
```bash
grep -r "IllegalStateError" app/
```

---

#### 7. New Rate Limiting API (NEW FEATURE)

**Impact:** NONE - Optional  
**Status:** New feature

**New capability:**
```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create
end

class SignupsController < ApplicationController
  rate_limit to: 1000, within: 10.seconds,
    by: -> { request.domain }, 
    with: -> { redirect_to busy_controller_url, alert: "Too many signups!" }, 
    only: :new
end
```

**When to mention:**
- User has API controllers
- User asks about new features
- User mentions rate limiting

---

### CRITICAL: ActionMailer Changes

#### 8. Removed assert_enqueued_email_with :args Parameter

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
assert_enqueued_email_with UserMailer, :welcome, args: [user]
```

**Migration:**
```ruby
# NEW (Use params)
assert_enqueued_email_with UserMailer, :welcome, params: { user: user }
```

**Detection pattern:**
```bash
grep -r "assert_enqueued_email_with.*:args" spec/ test/
```

**Files to check:**
- `spec/mailers/`
- `test/mailers/`

---

#### 9. Removed config.action_mailer.preview_path

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# config/environments/development.rb
# OLD (NO LONGER WORKS)
config.action_mailer.preview_path = "test/mailers/previews"
```

**Migration:**
```ruby
# NEW (Use preview_paths array)
config.action_mailer.preview_paths << "test/mailers/previews"
```

**Detection pattern:**
```bash
grep -r "preview_path[^s]" config/
```

**Files to check:**
- `config/environments/development.rb`

---

### CRITICAL: ActiveJob Changes

#### 10. Transaction-Aware Job Enqueuing (BEHAVIOR CHANGE)

**Impact:** VERY HIGH - BREAKING BEHAVIOR CHANGE  
**Status:** Default behavior changed

**What changed:**
Jobs enqueued inside database transactions now wait for the transaction to commit before being enqueued.

```ruby
# Rails 7.1 behavior: Job enqueued immediately
# Rails 7.2 behavior: Job waits for transaction commit

Topic.transaction do
  topic = Topic.create(name: "Rails 7.2")
  NewTopicNotificationJob.perform_later(topic)  # Waits for commit in 7.2!
end
# In 7.1: Job runs immediately (topic might not exist yet!)
# In 7.2: Job runs after commit (topic guaranteed to exist)
```

**Why this matters:**
- Prevents jobs from running before data is committed
- Could break tests or code expecting immediate enqueuing
- Generally safer, but changes timing

**Migration:**

```ruby
# Option 1: Keep new default (recommended)
class MyJob < ApplicationJob
  # No change needed - new behavior is safer
end

# Option 2: Restore old behavior (immediate enqueue)
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end

# Option 3: Always wait (explicit)
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :always
end
```

**Detection strategy:**
1. Look for jobs enqueued inside transactions
2. Check for tests that assert on job queue immediately after transaction
3. Look for timing-sensitive job logic

**Detection pattern:**
```bash
# Find jobs in transactions
grep -r "\.transaction do" app/models/ | head -20
grep -r "perform_later\|perform_now" app/models/ | head -20
```

**Files to check:**
- All files in `app/jobs/`
- Models that enqueue jobs in callbacks
- Service objects that use transactions

**Warning for users:**
```
⚠️ CRITICAL BEHAVIOR CHANGE: Jobs enqueued inside transactions now wait for commit.

Your application has X job classes. Review any jobs enqueued inside database 
transactions. In most cases, the new behavior is safer and prevents race conditions.

Files to review:
- [List specific job files found in their project]
- [List models with transaction + perform_later patterns]

Test thoroughly: Any specs that assert on job queue immediately after a 
transaction may need updating.
```

---

#### 11. Removed :exponentially_longer Value for :wait in retry_on

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
retry_on SomeError, wait: :exponentially_longer
```

**Migration:**
```ruby
# NEW (Use custom proc)
retry_on SomeError, wait: ->(executions) { executions * 2 }
```

**Detection pattern:**
```bash
grep -r "exponentially_longer" app/jobs/
```

---

#### 12. Removed Support to Set Numeric Values to scheduled_at

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
job.scheduled_at = 1234567890  # Unix timestamp
```

**Migration:**
```ruby
# NEW (Use Time object)
job.scheduled_at = Time.at(1234567890)
```

**Detection pattern:**
```bash
grep -r "scheduled_at\s*=\s*[0-9]" app/jobs/
```

---

#### 13. Removed Primitive BigDecimal Serializer

**Impact:** LOW - BREAKING  
**Status:** Removed, deprecated config removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.active_job.use_big_decimal_serializer = false
```

**Migration:**
Rails 7.2 always uses the modern BigDecimal serializer. Remove this config if present.

**Detection pattern:**
```bash
grep -r "use_big_decimal_serializer" config/
```

---

### CRITICAL: ActiveRecord Changes

#### 14. Deprecated ActiveRecord::Base.connection

**Impact:** VERY HIGH - SOFT DEPRECATION  
**Status:** Deprecated (still works, but discouraged)

**What's deprecated:**
```ruby
# OLD (Deprecated, but still works)
ActiveRecord::Base.connection.execute("SELECT 1")
```

**Migration:**
```ruby
# NEW - Option 1: Use with_connection for block scope (RECOMMENDED)
ActiveRecord::Base.with_connection do |conn|
  conn.execute("SELECT 1")
end

# NEW - Option 2: Use lease_connection (for short operations)
ActiveRecord::Base.lease_connection.execute("SELECT 1")
```

**Why this matters:**
- `connection` leases a connection for the entire request/job
- Can cause connection pool exhaustion
- `with_connection` returns connection to pool after block
- `lease_connection` makes the lease explicit

**Detection pattern:**
```bash
# Find all .connection calls (excluding with_connection and lease_connection)
grep -rn "\.connection[^_]" app/ lib/ | grep -v "with_connection\|lease_connection"
```

**Files to check:**
- Any file using direct database access
- Background jobs
- Rake tasks
- Scripts in `scripts/` or `lib/tasks/`
- Migrations (usually okay in migrations)

**Warning for users:**
```
⚠️ IMPORTANT: ActiveRecord::Base.connection is deprecated.

Found X occurrences in your project. While these still work, they can cause 
connection pool exhaustion. Consider migrating to:
- with_connection (for block-scoped operations) 
- lease_connection (for explicit leasing)

Files affected:
[List files with .connection calls]
```

---

#### 15. Removed Multiple Deprecated Connection Pool Methods

**Impact:** HIGH - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Base.clear_active_connections!
ActiveRecord::Base.clear_reloadable_connections!
ActiveRecord::Base.clear_all_connections!
ActiveRecord::Base.flush_idle_connections!
ActiveRecord::Base.connection_pool_list     # without role argument
ActiveRecord::Base.active_connections?      # without role argument
```

**Migration:**
```ruby
# NEW (Must specify role)
ActiveRecord::Base.clear_active_connections!(:writing)
ActiveRecord::Base.clear_reloadable_connections!(:writing)
ActiveRecord::Base.clear_all_connections!(:writing)
ActiveRecord::Base.flush_idle_connections!(:writing)

# Or use connection handler directly
ActiveRecord::Base.connection_handler.clear_active_connections!(:writing)
```

**Detection pattern:**
```bash
grep -r "clear_active_connections!\|clear_reloadable_connections!\|clear_all_connections!\|flush_idle_connections!" app/ lib/
```

---

#### 16. Removed #all_connection_pools

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Base.all_connection_pools
```

**Migration:**
```ruby
# NEW
ActiveRecord::Base.connection_handler.all_connection_pools
```

**Detection pattern:**
```bash
grep -r "all_connection_pools" app/ lib/
```

---

#### 17. Removed serialize with Old Signature

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
serialize :metadata, Hash
serialize :metadata, JSON
serialize :metadata, coder: JSON
```

**Migration:**
```ruby
# NEW (Use type: parameter)
serialize :metadata, type: Hash
serialize :metadata, type: Array
serialize :metadata, coder: JSON  # coder still supported
```

**Detection pattern:**
```bash
grep -r "serialize\s*:" app/models/ | grep -v "type:"
```

**Files to check:**
- All models in `app/models/`

---

#### 18. Removed read_attribute(:id) Custom Primary Key Support

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# For models with custom primary key
# OLD (NO LONGER WORKS)
model.read_attribute(:id)  # Returned custom primary key value
```

**Migration:**
```ruby
# NEW
model.read_attribute(model.class.primary_key)  # Explicit primary key
# OR
model.id  # Use id method directly
```

**Detection pattern:**
```bash
grep -r 'read_attribute.*:id\|read_attribute.*"id"' app/models/
```

---

#### 19. Removed TestFixtures.fixture_path

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
ActiveSupport::TestCase.fixture_path
```

**Migration:**
```ruby
# NEW
ActiveSupport::TestCase.fixture_paths  # Note: plural
```

**Detection pattern:**
```bash
grep -r "fixture_path[^s]" spec/ test/
```

---

#### 20. Removed Support for Singular Association Name Reference

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# Given: has_many :posts
# OLD (NO LONGER WORKS)
user.post  # Referring to has_many by singular name
```

**Migration:**
```ruby
# NEW (Use correct plural name)
user.posts
```

**Detection strategy:**
This is hard to detect automatically. Look for association definitions and check if code uses singular names.

**Files to check:**
- Models with `has_many` associations
- Controllers/services using those associations

---

#### 21. Removed allow_deprecated_singular_associations_name Config

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.active_record.allow_deprecated_singular_associations_name = false
```

**Migration:**
Remove this config line if present.

**Detection pattern:**
```bash
grep -r "allow_deprecated_singular_associations_name" config/
```

---

#### 22. Removed ActiveRecord::Migration.check_pending!

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Migration.check_pending!
```

**Migration:**
```ruby
# NEW
ActiveRecord::Migration.check_pending!(ActiveRecord::Base.connection_pool)
```

**Detection pattern:**
```bash
grep -r "Migration\.check_pending!" app/ lib/
```

---

#### 23. Removed Multiple LogSubscriber Methods

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::LogSubscriber.runtime
ActiveRecord::LogSubscriber.runtime=
ActiveRecord::LogSubscriber.reset_runtime
```

**Migration:**
These are internal APIs. If you were using them, use `ActiveRecord::RuntimeRegistry` instead.

**Detection pattern:**
```bash
grep -r "LogSubscriber\.runtime\|LogSubscriber\.reset_runtime" app/ lib/
```

---

#### 24. Query Constraints Deprecation

**Impact:** MEDIUM - DEPRECATION  
**Status:** Deprecated in favor of foreign_key

**What's deprecated:**
```ruby
# OLD (Deprecated)
has_many :posts, query_constraints: [:user_id, :tenant_id]
```

**Migration:**
```ruby
# NEW (Use foreign_key for composite keys)
has_many :posts, foreign_key: [:user_id, :tenant_id]
```

**Detection pattern:**
```bash
grep -r "query_constraints" app/models/
```

---

### CRITICAL: ActiveStorage Changes

#### 25. Removed silence_invalid_content_types_warning

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.active_storage.silence_invalid_content_types_warning = true
```

**Migration:**
Remove this line. Rails 7.2 handles content types differently.

**Detection pattern:**
```bash
grep -r "silence_invalid_content_types_warning" config/
```

---

#### 26. Removed replace_on_assign_to_many

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.active_storage.replace_on_assign_to_many = false
```

**Migration:**
Remove this line. Rails 7.2 always uses replacement behavior.

**Detection pattern:**
```bash
grep -r "replace_on_assign_to_many" config/
```

---

### CRITICAL: ActiveSupport Changes

#### 27. Removed ActiveSupport::Notifications::Event#children and #parent_of?

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
event.children
event.parent_of?(other_event)
```

**Migration:**
These internal APIs are removed. If you were using them, you'll need alternative instrumentation strategies.

**Detection pattern:**
```bash
grep -r "\.children\|\.parent_of?" app/ lib/
```

---

#### 28. Removed Deprecation Methods Without Deprecator

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
deprecate :old_method
ActiveSupport::Deprecation.new.deprecate_methods(self, old: :new)
```

**Migration:**
```ruby
# NEW (Must pass deprecator)
deprecate :old_method, deprecator: Rails.deprecator
ActiveSupport::Deprecation.new.deprecate_methods(self, {old: :new}, deprecator: Rails.deprecator)
```

**Detection pattern:**
```bash
grep -r "deprecate " app/ lib/ | grep -v "deprecator:"
```

---

#### 29. Removed SafeBuffer#clone_empty

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
buffer.clone_empty
```

**Migration:**
```ruby
# NEW
buffer.class.new
```

**Detection pattern:**
```bash
grep -r "clone_empty" app/ lib/
```

---

#### 30. Removed #to_default_s from Array, Date, DateTime, Time

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
[1, 2, 3].to_default_s
Date.today.to_default_s
Time.now.to_default_s
```

**Migration:**
```ruby
# NEW (Use to_s directly)
[1, 2, 3].to_s
Date.today.to_s
Time.now.to_s
```

**Detection pattern:**
```bash
grep -r "to_default_s" app/ lib/
```

---

#### 31. Removed Dalli::Client Support in MemCacheStore

**Impact:** MEDIUM - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.cache_store = :mem_cache_store, Dalli::Client.new('localhost')
```

**Migration:**
```ruby
# NEW (Pass server addresses directly)
config.cache_store = :mem_cache_store, 'localhost:11211'
```

**Detection pattern:**
```bash
grep -r "Dalli::Client" config/
```

---

### CRITICAL: Railties Changes

#### 32. Removed Rails.application.secrets

**Impact:** HIGH - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
Rails.application.secrets.api_key
```

**Migration:**
```ruby
# NEW (Use credentials)
Rails.application.credentials.api_key
```

**Detection pattern:**
```bash
grep -r "Rails\.application\.secrets" app/ lib/ config/
```

**Files to check:**
- Any file accessing secrets
- Initializers
- Controllers
- Service objects

---

#### 33. Removed find_cmd_and_exec Console Helper

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS - in rails console)
>> find_cmd_and_exec
```

**Migration:**
This internal helper is removed. Use standard shell commands or Ruby equivalents.

---

#### 34. Removed enable_dependency_loading Config

**Impact:** LOW - BREAKING  
**Status:** Removed

**What was removed:**
```ruby
# OLD (NO LONGER WORKS)
config.enable_dependency_loading = true
```

**Migration:**
Remove this line. Dependency loading is now always managed by Zeitwerk.

**Detection pattern:**
```bash
grep -r "enable_dependency_loading" config/
```

---

### New Features Worth Mentioning

#### 35. PWA (Progressive Web App) Support

**Impact:** NONE - Optional  
**Status:** New feature

Rails 7.2 includes built-in PWA support with:
- Manifest file: `app/views/pwa/manifest.json.erb`
- Service worker: `app/views/pwa/service-worker.js`
- Default routes for PWA files

**When to mention:**
- User asks about new features
- User mentions mobile/offline support
- User wants to add PWA capabilities

---

#### 36. Improved Docker Configuration

**Impact:** NONE - Optional  
**Status:** New defaults

Rails 7.2 includes better Docker defaults:
- Jemalloc for memory optimization
- Numeric UID/GID for Kubernetes
- Better `.dockerignore` patterns

**When to mention:**
- User has a `Dockerfile`
- User mentions Docker/Kubernetes
- User asks about deployment

---

#### 37. GitHub CI/CD by Default

**Impact:** NONE - Optional  
**Status:** New defaults

Rails 7.2 includes:
- `.github/workflows/ci.yml` for testing
- `.github/dependabot.yml` for dependency updates
- Brakeman for security scanning
- RuboCop with rails-omakase rules

**When to mention:**
- User has `.github/` directory
- User mentions CI/CD
- User asks about testing/security

---

#### 38. Dev Container Support

**Impact:** NONE - Optional  
**Status:** New feature

Rails 7.2 can generate `.devcontainer/` configuration for development containers.

**When to mention:**
- User mentions Docker/development environment
- User asks about new features

---

#### 39. Better System Test Defaults

**Impact:** NONE - Optional  
**Status:** New defaults

Rails 7.2 uses headless Chrome by default for system tests.

**When to mention:**
- User has system tests
- User asks about testing changes

---

## 🔧 File-Specific Migration Patterns

### Pattern 1: Updating Gemfile

**Always update Gemfile first:**

```ruby
# Before
gem "rails", "~> 7.1.6"

# After
gem "rails", "~> 7.2.3"

# Also recommend updating these:
gem "puma", ">= 6.0"
gem "importmap-rails", "~> 2.0"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
```

---

### Pattern 2: Updating config/application.rb

**Find and replace load_defaults:**

```ruby
# Before
config.load_defaults 7.1

# After
config.load_defaults 7.2
```

**Also update autoload_lib if present:**

```ruby
# Before (Rails 7.1)
config.autoload_lib(ignore: %w(assets tasks))

# After (Rails 7.2 - use square brackets)
config.autoload_lib(ignore: %w[assets tasks])
```

---

### Pattern 3: Updating config/environments/*.rb

**Development environment:**

```ruby
# config/environments/development.rb

# ADD (if not present):
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

# ADD (optional - useful feature):
config.action_view.annotate_rendered_view_with_filenames = true

# ADD (optional - for RuboCop integration):
# config.generators.apply_rubocop_autocorrect_after_generate!
```

**Production environment:**

```ruby
# config/environments/production.rb

# FIX: show_exceptions if using old syntax
# Before:
# config.action_dispatch.show_exceptions = true
# After:
config.action_dispatch.show_exceptions = :all

# ADD (optional - health check SSL redirect exclusion):
config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

# ADD (optional - better performance):
config.active_record.attributes_for_inspect = [:id]
```

**Test environment:**

```ruby
# config/environments/test.rb

# ADD (if not present):
config.action_mailer.default_url_options = { host: "www.example.com" }
```

---

### Pattern 4: Updating config/puma.rb

**Rails 7.2 simplifies Puma configuration:**

```ruby
# Before (Rails 7.1)
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch("RAILS_ENV") { "development" }

if rails_env == "production"
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 1 })
  if worker_count > 1
    workers worker_count
  else
    preload_app!
  end
end

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT") { 3000 }
environment rails_env
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
plugin :tmp_restart

# After (Rails 7.2 - simplified)
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
```

**Note:** This is optional. Old config still works.

---

### Pattern 5: Updating Controllers

**Check ApplicationController for allow_browser:**

```ruby
# app/controllers/application_controller.rb

# Rails 7.2 does NOT automatically add this to existing apps
# But new apps have it by default

class ApplicationController < ActionController::Base
  # If user wants browser restrictions, ADD:
  # allow_browser versions: :modern
  
  # If user wants to support old browsers, DON'T ADD IT
end
```

---

### Pattern 6: Updating Models

**Fix serialize syntax if needed:**

```ruby
# Before (old syntax)
serialize :metadata, Hash
serialize :settings, JSON

# After (new syntax)
serialize :metadata, type: Hash
serialize :settings, coder: JSON
```

**Fix association query_constraints:**

```ruby
# Before (deprecated)
has_many :posts, query_constraints: [:user_id, :tenant_id]

# After
has_many :posts, foreign_key: [:user_id, :tenant_id]
```

---

### Pattern 7: Updating Jobs

**Review transaction-aware enqueuing:**

```ruby
# If job must enqueue immediately (old behavior):
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
  
  def perform
    # ...
  end
end

# If job should wait for commit (new default, recommended):
class MyJob < ApplicationJob
  # No change needed - this is the new default
  
  def perform
    # ...
  end
end
```

---

### Pattern 8: Updating Tests/Specs

**Fix mailer test assertions:**

```ruby
# Before
assert_enqueued_email_with UserMailer, :welcome, args: [user]

# After
assert_enqueued_email_with UserMailer, :welcome, params: { user: user }
```

**Update fixture_path to fixture_paths:**

```ruby
# Before
self.fixture_path = "spec/fixtures"

# After
self.fixture_paths << "spec/fixtures"
```

---

## 🎯 Step-by-Step Upgrade Instructions

When a user asks to upgrade, follow this exact process:

### Phase 1: Initial Analysis (5 minutes)

1. **Gather project information:**
```
Use railsMcpServer:project_info
Record: Rails version, API-only status, project structure
```

2. **Read key files:**
```
Use railsMcpServer:get_file for:
- Gemfile (check Rails version, gems used)
- config/application.rb (check load_defaults)
- config/environments/production.rb (check show_exceptions)
- config/environments/development.rb (check configs)
```

3. **Understand job usage:**
```
Use railsMcpServer:list_files with pattern: app/jobs/*.rb
Count jobs for transaction-aware warning
```

4. **Understand model usage:**
```
Use railsMcpServer:list_files with pattern: app/models/*.rb
Check for ActiveRecord usage
```

### Phase 2: Generate Report (10 minutes)

5. **Create comprehensive report with:**
   - Executive Summary
   - Critical Breaking Changes (personalized to their project)
   - Medium Impact Changes
   - New Features (optional)
   - Step-by-Step Migration Plan
   - Project-Specific Warnings
   - Testing Checklist

6. **Mark each breaking change with:**
   - ⚠️ for critical issues
   - Impact level (HIGH/MEDIUM/LOW)
   - Detection pattern used
   - Files in THEIR project affected
   - OLD/NEW code examples
   - Clear migration instructions

### Phase 3: Provide Migration Guide (15 minutes)

7. **Create step-by-step plan with:**
   - Phase 1: Preparation
   - Phase 2: Gemfile Updates
   - Phase 3: Configuration Updates
   - Phase 4: Code Updates
   - Phase 5: Testing
   - Phase 6: Deployment

8. **For each phase, provide:**
   - Estimated time
   - Commands to run
   - Files to update
   - Testing checkpoints

### Phase 4: Offer Interactive Updates (Variable)

9. **If user wants file updates:**
```
1. Use nvimMcpServer:get_project_buffers(project_name: "their-project")
2. List files they have open in Neovim
3. Ask: "Which file would you like me to update?"
4. Use nvimMcpServer:update_buffer to apply changes
5. Explain what changed and why
```

10. **Update files in this order:**
```
1. Gemfile
2. config/application.rb
3. config/environments/*.rb
4. Controllers (if allow_browser needed)
5. Models (if serialize or associations need updates)
6. Jobs (if transaction behavior needs customization)
7. Tests (if assertions need updates)
```

---

## 🚨 Critical Detection Patterns

Use these bash commands to detect issues in the user's project:

```bash
# 1. Old show_exceptions syntax
grep -r "show_exceptions.*true\|show_exceptions.*false" config/

# 2. ActionController::Parameters comparison
grep -rn "params.*==" app/controllers/

# 3. Deprecated .connection calls
grep -rn "\.connection[^_]" app/ lib/ | grep -v "with_connection\|lease_connection"

# 4. Old serialize syntax
grep -r "serialize\s*:" app/models/ | grep -v "type:\|coder:"

# 5. query_constraints usage
grep -r "query_constraints" app/models/

# 6. Removed mailer configs
grep -r "preview_path[^s]" config/

# 7. Removed mailer test syntax
grep -r "assert_enqueued_email_with.*:args" spec/ test/

# 8. Rails.application.secrets usage
grep -r "Rails\.application\.secrets" app/ lib/ config/

# 9. Jobs with transactions (manual review needed)
grep -r "\.transaction do" app/models/
grep -r "perform_later\|perform_now" app/models/

# 10. Deprecated ActiveSupport methods
grep -r "to_default_s\|clone_empty" app/ lib/

# 11. Old fixture_path
grep -r "fixture_path[^s]" spec/ test/

# 12. Removed constants
grep -r "MissingHelperError\|IllegalStateError" app/
```

---

## 💬 Communication Guidelines

### How to Present the Upgrade Report

1. **Start with Executive Summary:**
   - Be encouraging but realistic
   - State complexity clearly
   - Give time estimate
   - Highlight biggest risks

2. **Present Breaking Changes:**
   - Start with highest impact first
   - Use ⚠️ emoji for critical items
   - Show OLD/NEW code side by side
   - Be specific about THEIR files affected

3. **Provide Clear Migration Path:**
   - Number steps clearly
   - Group related changes
   - Provide copy-paste commands
   - Include testing checkpoints

4. **Warn About Custom Code:**
   - Mark with ⚠️ WARNING
   - Explain why manual review needed
   - List specific files to check
   - Provide detection commands

5. **Offer Interactive Help:**
   - "I can update these files for you"
   - "Just open the file in Neovim and let me know"
   - "I'll apply the changes and explain each one"

### What NOT to Do

- ❌ Don't apply changes without user approval
- ❌ Don't update files that aren't open in Neovim (unless explicitly requested)
- ❌ Don't skip warnings about custom code
- ❌ Don't assume their testing strategy
- ❌ Don't make assumptions about their deployment process
- ❌ Don't downplay breaking changes
- ❌ Don't forget to mention transaction-aware job enqueuing

### Tone and Style

- ✅ Be clear and direct
- ✅ Use technical terms (users upgrading Rails are experienced)
- ✅ Provide specific file names and line numbers
- ✅ Give copy-paste commands
- ✅ Explain WHY changes are needed
- ✅ Acknowledge complexity honestly
- ✅ Celebrate when upgrade is done!

---

## 📊 Example Report Template

When generating a report, use this structure:

```markdown
# Rails Upgrade Report: 7.1.6 → 7.2.3

**Project:** [Project Name]
**Current Version:** [Detected Version]
**Target Version:** 7.2.3
**Complexity:** ⭐⭐ Medium
**Estimated Time:** 4-8 hours
**Date:** [Current Date]

---

## 📋 Executive Summary

Your Rails application can be upgraded from 7.1.6 to 7.2.3. This is a medium-complexity upgrade with [X] breaking changes that require attention.

**Key Highlights:**
- ✅ No major architectural changes
- ⚠️ [X] breaking changes found in your project
- ⚠️ Transaction-aware job enqueuing will change behavior
- ✅ Many new features available
- ⚠️ Estimated [X] hours for completion

**Biggest Risks:**
1. [List top 3 risks specific to their project]

---

## 🚨 CRITICAL BREAKING CHANGES

### 1. [Breaking Change Title]
**Impact:** HIGH  
**Status:** BREAKING CHANGE  
**Detected in your project:** [Yes/No]

[Explanation]

**Your files affected:**
- [List specific files from their project]

**Current code (will break):**
```ruby
[Their code example]
```

**Updated code (required):**
```ruby
[Fixed code example]
```

**Detection command:**
```bash
[Command they can run]
```

[Repeat for each breaking change]

---

## 📝 MEDIUM IMPACT CHANGES

[List medium priority items]

---

## 🆕 NEW FEATURES (Optional)

[List new features they might want]

---

## 📋 STEP-BY-STEP MIGRATION PLAN

### Phase 1: Preparation (30 minutes)
[Steps]

### Phase 2: Gemfile Updates (15 minutes)
[Steps]

[Continue for all phases]

---

## ⚠️ PROJECT-SPECIFIC WARNINGS

### ⚠️ Warning 1: [Specific Issue]
[Detailed explanation of what they need to check manually]

[Repeat for each warning]

---

## ✅ TESTING CHECKLIST

Before deploying to production:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] [Project-specific critical paths]
- [ ] Background jobs process correctly
- [ ] [Other critical functionality]

---

## 🚀 READY TO START?

I can help you update files interactively using Neovim. Just:
1. Open the file you want to update in Neovim
2. Tell me: "Update [filename]"
3. I'll show you the changes and apply them

Or you can do it manually using this guide.

Would you like me to start with updating the Gemfile?
```

---

## 🔄 Interactive File Update Process

When user wants interactive updates:

### Step 1: Check Available Files

```
1. Call nvimMcpServer:get_project_buffers(project_name: "user-project-name")
2. List files user has open
3. If target file not open, ask user to open it
```

### Step 2: Read Current Content

```
1. Parse buffer list from get_project_buffers
2. Identify file path
3. Prepare changes
```

### Step 3: Show Changes

```
1. Show BEFORE code block
2. Show AFTER code block
3. Explain what's changing and why
4. Ask for confirmation
```

### Step 4: Apply Changes

```
1. Get user approval
2. Call nvimMcpServer:update_buffer with:
   - project_name: [from user]
   - file_path: [from buffer list]
   - content: [full new content]
3. Confirm update succeeded
```

### Step 5: Verify

```
1. Ask user to review changes in Neovim
2. Ask if they want to update another file
3. Keep track of what's been updated
```

---

## 🎓 Teaching Moments

When appropriate, explain the reasoning:

### Why Transaction-Aware Jobs Matter

```
"The new transaction-aware job enqueuing prevents race conditions. 

Before: Job could run before the transaction commits, causing it to 
fail when looking for records that don't exist yet.

After: Job waits for commit, guaranteeing data exists.

In most cases, this is safer and you want this behavior."
```

### Why .connection is Deprecated

```
"ActiveRecord::Base.connection leases a connection for the entire 
request/job, which can exhaust your connection pool.

.with_connection returns the connection to the pool immediately 
after your block, making better use of limited connections.

This is especially important in apps with many threads/workers."
```

### Why allow_browser is Added

```
"Rails 7.2 adds optional browser version enforcement to ensure users 
have modern features like:
- WebP images
- Web push notifications  
- Import maps
- CSS nesting

For existing apps, this is opt-in. For new apps, it's on by default."
```

---

## 🔍 Quality Checklist

Before sending report, verify:

- [ ] Used railsMcpServer:project_info to get actual Rails version
- [ ] Read Gemfile to check which gems are used
- [ ] Read config files to detect deprecated settings
- [ ] Listed specific files in THEIR project affected
- [ ] Provided OLD/NEW code examples for each change
- [ ] Explained WHY each change is needed
- [ ] Gave detection commands they can run
- [ ] Estimated time per phase
- [ ] Warned about transaction-aware job enqueuing
- [ ] Warned about .connection deprecation
- [ ] Provided testing checklist
- [ ] Offered interactive update help
- [ ] Used appropriate ⚠️ warnings
- [ ] Maintained encouraging but realistic tone

---

## 📚 Official Resources

Always reference:

- **Rails 7.2 Release Notes:** https://edgeguides.rubyonrails.org/7_2_release_notes.html
- **Upgrading Guide:** https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- **Rails Diff:** https://railsdiff.org/7.1.6/7.2.3
- **Rails GitHub CHANGELOGs:** https://github.com/rails/rails/tree/v7.2.3

---

## 🎯 Success Criteria

Upgrade is successful when:

- ✅ Gemfile updated to Rails 7.2.3
- ✅ config.load_defaults changed to 7.2
- ✅ All deprecated configurations removed
- ✅ All breaking code patterns fixed
- ✅ All tests passing
- ✅ No deprecation warnings in logs
- ✅ Application runs correctly in all environments
- ✅ Background jobs process correctly
- ✅ No connection pool issues

---

## 🎉 Completion Message

When upgrade is done:

```markdown
🎉 Congratulations! Your Rails 7.2.3 upgrade is complete!

**What was done:**
- ✅ Updated Gemfile
- ✅ Updated configuration files
- ✅ Fixed [X] breaking changes
- ✅ Updated [X] deprecated patterns
- ✅ All tests passing

**Next Steps:**
1. Deploy to staging first
2. Monitor for:
   - Background job processing
   - Connection pool usage
   - Error rates
   - Performance metrics
3. Deploy to production when staging looks good

**Watch Out For:**
- Transaction-aware job behavior changes
- Deprecated .connection usage warnings
- Any custom code that needs review

Great job! 🚀
```

---

## 🔧 Troubleshooting

If user reports issues after upgrade:

### Issue: Tests failing with NoMethodError

**Likely cause:** Using removed methods

**Solution:**
```
1. Check error message for method name
2. Search this skill for that method
3. Provide migration pattern
```

### Issue: Jobs not processing

**Likely cause:** Transaction-aware enqueuing

**Solution:**
```ruby
# Restore old behavior temporarily:
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end

# Then debug why the new behavior causes issues
```

### Issue: Connection pool exhausted

**Likely cause:** Still using deprecated .connection

**Solution:**
```
1. Search for remaining .connection calls
2. Migrate to with_connection
3. Monitor connection pool metrics
```

### Issue: Browser blocked errors

**Likely cause:** allow_browser added

**Solution:**
```ruby
# In ApplicationController:
# Remove or customize:
allow_browser versions: { safari: 13, chrome: 90, firefox: 88 }
```

---

## 📝 Skill Usage Examples

### Example 1: Basic Upgrade Request

**User:** "Upgrade my Rails app from 7.1 to 7.2"

**Claude Response:**
```
I'll help you upgrade your Rails application from 7.1 to 7.2. Let me analyze 
your project first.

[Calls railsMcpServer:project_info]
[Calls railsMcpServer:get_file for key files]

[Generates comprehensive report with]:
- Executive summary
- Breaking changes specific to their project
- Step-by-step plan
- Warnings about custom code
- Testing checklist

Would you like me to help update files interactively via Neovim?
```

### Example 2: Specific File Update

**User:** "Update my Gemfile for Rails 7.2"

**Claude Response:**
```
I'll update your Gemfile. Let me check if you have it open in Neovim.

[Calls nvimMcpServer:get_project_buffers]

I see you have these files open:
- Gemfile ✅

Here are the changes I'll make to your Gemfile:

[Shows BEFORE/AFTER comparison]

Shall I apply these changes?
```

### Example 3: Breaking Change Query

**User:** "What breaking changes do I need to worry about?"

**Claude Response:**
```
For Rails 7.1.6 → 7.2.3, here are the critical breaking changes:

1. ⚠️ Transaction-Aware Job Enqueuing
   [Detailed explanation specific to their project]
   
2. ⚠️ Removed ActiveRecord::Base.connection
   [Explanation with their specific files]

[Continue for all high-impact changes]

Would you like me to analyze your project to see which of these affect you?
```

---

## ⚙️ Configuration

This skill integrates with:

- **Rails MCP Server** - For project analysis
- **Neovim MCP Server** - For interactive file updates

**Required Tools:**
- `railsMcpServer:project_info`
- `railsMcpServer:get_file`
- `railsMcpServer:list_files`
- `nvimMcpServer:get_project_buffers`
- `nvimMcpServer:update_buffer`

---

## 📄 Skill Metadata

**Skill Name:** Rails Upgrade 7.1.6 to 7.2.3  
**Skill Type:** Rails Framework Upgrade  
**Complexity:** Medium  
**Prerequisites:** Rails MCP Server, Neovim MCP Server (optional)  
**Target Audience:** Rails developers upgrading from 7.1.x to 7.2.x  
**Maintenance:** Update when new Rails 7.2.x versions released  

---

## 🎓 Learning Resources for Users

Point users to:

- Rails 7.2 Release Notes
- Official Upgrade Guide
- Rails Diff website
- Component CHANGELOGs on GitHub

---

## ✨ Skill End

This skill provides comprehensive guidance for upgrading Rails applications from 7.1.6 to 7.2.3, based on official Rails CHANGELOGs and community best practices. Use it to generate personalized upgrade reports and help users migrate safely.

