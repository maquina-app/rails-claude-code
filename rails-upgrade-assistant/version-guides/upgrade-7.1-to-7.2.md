---
title: "Rails 7.1.6 → 7.2.3 Upgrade Guide"
description: "Complete upgrade guide from Rails 7.1.6 to 7.2.3 featuring transaction-aware jobs and 39 breaking changes"
type: "version-guide"
rails_from: "7.1.6"
rails_to: "7.2.3"
difficulty: "hard"
breaking_changes: 39
priority_high: 5
priority_medium: 12
priority_low: 22
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

# Rails 7.1 → 7.2 Upgrade Guide

## Supported Upgrade Path

**Source:** Rails 7.1.6
**Target:** Rails 7.2.3
**Difficulty:** Hard

> **CRITICAL WARNING:** Transaction-aware job enqueuing is now the default behavior. Jobs enqueued inside database transactions wait for the transaction to commit before being sent to the queue. Test job timing extensively before deploying.

---

## Breaking Changes Reference

### ActionPack Changes

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

```ruby
# OLD (NO LONGER WORKS)
config.action_dispatch.show_exceptions = true
config.action_dispatch.show_exceptions = false
```

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

```ruby
# OLD (NO LONGER WORKS)
if params == { name: "John" }
  # ...
end

if { name: "John" } == params
  # ...
end
```

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

```ruby
# OLD (NO LONGER WORKS)
rescue AbstractController::Helpers::MissingHelperError
  # ...
end
```

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

---

### ActionMailer Changes

#### 8. Removed assert_enqueued_email_with :args Parameter

**Impact:** MEDIUM - BREAKING
**Status:** Removed

```ruby
# OLD (NO LONGER WORKS)
assert_enqueued_email_with UserMailer, :welcome, args: [user]
```

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

```ruby
# OLD (NO LONGER WORKS)
config.action_mailer.preview_path = "test/mailers/previews"
```

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

### ActiveJob Changes

#### 10. Transaction-Aware Job Enqueuing (BEHAVIOR CHANGE)

**Impact:** VERY HIGH - BREAKING BEHAVIOR CHANGE
**Status:** Default behavior changed

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

---

#### 11. Removed :exponentially_longer Value for :wait in retry_on

**Impact:** MEDIUM - BREAKING
**Status:** Removed

```ruby
# OLD (NO LONGER WORKS)
retry_on SomeError, wait: :exponentially_longer
```

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

```ruby
# OLD (NO LONGER WORKS)
job.scheduled_at = 1234567890  # Unix timestamp
```

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

### ActiveRecord Changes

#### 14. Deprecated ActiveRecord::Base.connection

**Impact:** VERY HIGH - SOFT DEPRECATION
**Status:** Deprecated (still works, but discouraged)

```ruby
# OLD (Deprecated, but still works)
ActiveRecord::Base.connection.execute("SELECT 1")
```

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

---

#### 15. Removed Multiple Deprecated Connection Pool Methods

**Impact:** HIGH - BREAKING
**Status:** Removed

```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Base.clear_active_connections!
ActiveRecord::Base.clear_reloadable_connections!
ActiveRecord::Base.clear_all_connections!
ActiveRecord::Base.flush_idle_connections!
ActiveRecord::Base.connection_pool_list     # without role argument
ActiveRecord::Base.active_connections?      # without role argument
```

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

```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Base.all_connection_pools
```

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

```ruby
# OLD (NO LONGER WORKS)
serialize :metadata, Hash
serialize :metadata, JSON
serialize :metadata, coder: JSON
```

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

```ruby
# For models with custom primary key
# OLD (NO LONGER WORKS)
model.read_attribute(:id)  # Returned custom primary key value
```

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

```ruby
# OLD (NO LONGER WORKS)
ActiveSupport::TestCase.fixture_path
```

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

```ruby
# Given: has_many :posts
# OLD (NO LONGER WORKS)
user.post  # Referring to has_many by singular name
```

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

```ruby
# OLD (NO LONGER WORKS)
ActiveRecord::Migration.check_pending!
```

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

```ruby
# OLD (Deprecated)
has_many :posts, query_constraints: [:user_id, :tenant_id]
```

```ruby
# NEW (Use foreign_key for composite keys)
has_many :posts, foreign_key: [:user_id, :tenant_id]
```

**Detection pattern:**
```bash
grep -r "query_constraints" app/models/
```

---

### ActiveStorage Changes

#### 25. Removed silence_invalid_content_types_warning

**Impact:** LOW - BREAKING
**Status:** Removed

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

### ActiveSupport Changes

#### 27. Removed ActiveSupport::Notifications::Event#children and #parent_of?

**Impact:** LOW - BREAKING
**Status:** Removed

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

```ruby
# OLD (NO LONGER WORKS)
deprecate :old_method
ActiveSupport::Deprecation.new.deprecate_methods(self, old: :new)
```

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

```ruby
# OLD (NO LONGER WORKS)
buffer.clone_empty
```

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

```ruby
# OLD (NO LONGER WORKS)
[1, 2, 3].to_default_s
Date.today.to_default_s
Time.now.to_default_s
```

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

```ruby
# OLD (NO LONGER WORKS)
config.cache_store = :mem_cache_store, Dalli::Client.new('localhost')
```

```ruby
# NEW (Pass server addresses directly)
config.cache_store = :mem_cache_store, 'localhost:11211'
```

**Detection pattern:**
```bash
grep -r "Dalli::Client" config/
```

---

### Railties Changes

#### 32. Removed Rails.application.secrets

**Impact:** HIGH - BREAKING
**Status:** Removed

```ruby
# OLD (NO LONGER WORKS)
Rails.application.secrets.api_key
```

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

### New Features

#### 35. PWA (Progressive Web App) Support

**Impact:** NONE - Optional
**Status:** New feature

Rails 7.2 includes built-in PWA support with:
- Manifest file: `app/views/pwa/manifest.json.erb`
- Service worker: `app/views/pwa/service-worker.js`
- Default routes for PWA files

---

#### 36. Improved Docker Configuration

**Impact:** NONE - Optional
**Status:** New defaults

Rails 7.2 includes better Docker defaults:
- Jemalloc for memory optimization
- Numeric UID/GID for Kubernetes
- Better `.dockerignore` patterns

---

#### 37. GitHub CI/CD by Default

**Impact:** NONE - Optional
**Status:** New defaults

Rails 7.2 includes:
- `.github/workflows/ci.yml` for testing
- `.github/dependabot.yml` for dependency updates
- Brakeman for security scanning
- RuboCop with rails-omakase rules

---

#### 38. Dev Container Support

**Impact:** NONE - Optional
**Status:** New feature

Rails 7.2 can generate `.devcontainer/` configuration for development containers.

---

#### 39. Better System Test Defaults

**Impact:** NONE - Optional
**Status:** New defaults

Rails 7.2 uses headless Chrome by default for system tests.

---

## File-Specific Migration Patterns

### Pattern 1: Updating Gemfile

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

```ruby
# Before
config.load_defaults 7.1

# After
config.load_defaults 7.2
```

Also update autoload_lib if present:

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

Fix serialize syntax if needed:

```ruby
# Before (old syntax)
serialize :metadata, Hash
serialize :settings, JSON

# After (new syntax)
serialize :metadata, type: Hash
serialize :settings, coder: JSON
```

Fix association query_constraints:

```ruby
# Before (deprecated)
has_many :posts, query_constraints: [:user_id, :tenant_id]

# After
has_many :posts, foreign_key: [:user_id, :tenant_id]
```

---

### Pattern 7: Updating Jobs

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

Fix mailer test assertions:

```ruby
# Before
assert_enqueued_email_with UserMailer, :welcome, args: [user]

# After
assert_enqueued_email_with UserMailer, :welcome, params: { user: user }
```

Update fixture_path to fixture_paths:

```ruby
# Before
self.fixture_path = "spec/fixtures"

# After
self.fixture_paths << "spec/fixtures"
```

---

## Critical Detection Patterns

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

## Testing Checklist

Before deploying to production:

- [ ] All unit tests pass with no deprecation warnings
- [ ] All integration tests pass
- [ ] Background jobs enqueue and process correctly (transaction-aware behavior)
- [ ] Jobs enqueued inside transactions fire after commit
- [ ] No connection pool exhaustion under load
- [ ] `show_exceptions` uses symbol values in all environments
- [ ] `Rails.application.secrets` calls replaced with `credentials`
- [ ] `serialize` calls use `type:` parameter
- [ ] Mailer previews work with `preview_paths` (plural)
- [ ] System tests run with headless Chrome defaults
- [ ] Browser enforcement (if enabled) does not block intended users

---

## Common Issues

### Tests failing with NoMethodError

**Likely cause:** Using removed methods or constants (`MissingHelperError`, `IllegalStateError`, `fixture_path`, `to_default_s`, etc.)

**Solution:** Check the error message for the method name and find the corresponding breaking change above for the migration pattern.

### Jobs not processing

**Likely cause:** Transaction-aware enqueuing changed job timing.

**Solution:**
```ruby
# Restore old behavior temporarily:
class MyJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end

# Then debug why the new behavior causes issues
```

### Connection pool exhausted

**Likely cause:** Still using deprecated `.connection` which leases connections for the entire request/job lifecycle.

**Solution:** Migrate to `with_connection` (block-scoped) or `lease_connection` (explicit lease). Monitor connection pool metrics after migration.

### Browser blocked errors (HTTP 406)

**Likely cause:** `allow_browser versions: :modern` was added to ApplicationController.

**Solution:**
```ruby
# Remove or customize in ApplicationController:
allow_browser versions: { safari: 13, chrome: 90, firefox: 88 }
```

---

## Official Resources

- **Rails 7.2 Release Notes:** https://edgeguides.rubyonrails.org/7_2_release_notes.html
- **Upgrading Guide:** https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- **Rails Diff:** https://railsdiff.org/7.1.6/7.2.3
- **Rails GitHub CHANGELOGs:** https://github.com/rails/rails/tree/v7.2.3
