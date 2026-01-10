---
title: "Rails 7.0 → 7.1.6 Upgrade Guide"
description: "Complete upgrade guide from Rails 7.0.x to 7.1.6 with breaking changes, migration steps, and testing procedures"
type: "version-guide"
rails_from: "7.0.x"
rails_to: "7.1.6"
difficulty: "medium"
estimated_time: "2-4 hours"
breaking_changes: 12
priority_high: 5
priority_medium: 4
priority_low: 3
major_changes:
  - cache_classes to enable_reloading (inverted)
  - force_ssl default ON
  - SQLite moved to storage/
  - lib/ autoloaded by default
  - preview_path to preview_paths
tags:
  - rails-7.1
  - upgrade-guide
  - breaking-changes
  - cache_classes
  - enable_reloading
  - force_ssl
  - sqlite
  - autoload
category: "rails-upgrade"
version_family: "rails-7.x"
last_updated: "2025-11-01"
copyright: Copyright (c) 2025 [Mario Alberto Chávez Cárdenas]
---

# Rails Upgrade Assistant Skill - Version 1.0

**For upgrading Ruby on Rails applications from 7.0.x to 7.1.6**

This skill provides comprehensive, step-by-step guidance for upgrading Rails applications based on official CHANGELOGs from the Rails GitHub repository.

---

## 🎯 Skill Purpose

This skill helps upgrade Rails applications by:
- **Analyzing** your Rails project using Rails MCP tools
- **Identifying** breaking changes from official CHANGELOGs
- **Detecting** custom code that needs attention
- **Generating** detailed upgrade reports with OLD/NEW examples
- **Updating** files interactively using Neovim MCP (optional)
- **Providing** rollback plans and testing checklists

---

## 📋 Supported Upgrade Path

**From:** Rails 7.0.x  
**To:** Rails 7.1.6

This is a **MEDIUM complexity** upgrade estimated to take **2-4 hours** for most applications.

---

## 🔧 How This Skill Works

### Phase 1: Project Analysis
1. Uses `railsMcpServer:project_info` to understand your Rails project
2. Uses `railsMcpServer:analyze_models` to understand data models
3. Uses `railsMcpServer:get_schema` to understand database structure
4. Uses `railsMcpServer:get_routes` to understand application routes
5. Uses `railsMcpServer:get_file` to read configuration files

### Phase 2: Change Detection
1. Compares project against breaking changes from CHANGELOGs
2. Identifies deprecated features being used
3. Detects custom configurations that may conflict
4. Flags files that need manual review

### Phase 3: Report Generation  
1. Generates comprehensive upgrade report
2. Provides OLD vs NEW code examples
3. Marks custom code with ⚠️ warnings
4. Includes step-by-step migration instructions

### Phase 4: Interactive Updates (Optional)
1. Uses `nvimMcpServer:get_project_buffers` to see open files
2. Uses `nvimMcpServer:update_buffer` to apply changes
3. User reviews and confirms each change

---

## 🚀 Usage Instructions

### Basic Usage (Report Only)

Simply say:
```
"Upgrade my Rails app from 7.0 to 7.1"
```

The assistant will:
1. Analyze your Rails project
2. Check all relevant CHANGELOGs
3. Generate a comprehensive upgrade report
4. Show you what needs to change

### Interactive Mode (with Neovim)

If you have files open in Neovim and want live updates:

```
"Upgrade my Rails app to 7.1 in interactive mode"
```

The assistant will:
1. Generate the upgrade report
2. Show which files need changes
3. Ask for permission before each update
4. Update files in your Neovim buffers
5. Reload the files automatically

**Important:** For interactive mode, you must have files open in Neovim and provide the project name.

---

## 📊 Breaking Changes - Rails 7.0 → 7.1.6

### HIGH IMPACT Changes (Breaking)

#### 1. **Cache Classes → Enable Reloading**

**Component:** Railties, Environment Configuration  
**Impact:** High - Changes core configuration pattern  
**Type:** Breaking - old config will trigger deprecation

**OLD (Rails 7.0):**
```ruby
# config/environments/development.rb
config.cache_classes = false
```

**NEW (Rails 7.1):**
```ruby
# config/environments/development.rb
config.enable_reloading = true
```

**What Changed:**
- `config.cache_classes` is now read-only
- New `config.enable_reloading` provides more intuitive naming
- `config.cache_classes` is supported for backwards compatibility but deprecated

**Migration Steps:**
1. Search for `config.cache_classes` in all environment files
2. Replace with `config.enable_reloading` with inverse boolean
3. `cache_classes = false` becomes `enable_reloading = true`
4. `cache_classes = true` becomes `enable_reloading = false`

---

#### 2. **Force SSL Now Enabled by Default**

**Component:** ActionPack, Security  
**Impact:** High - Changes production behavior  
**Type:** Breaking - affects deployment

**OLD (Rails 7.0):**
```ruby
# config/environments/production.rb  
# SSL was opt-in
# config.force_ssl = true
```

**NEW (Rails 7.1):**
```ruby
# config/environments/production.rb
# SSL is now default
config.force_ssl = true  # This is now ON by default

# New option for load balancers
# config.assume_ssl = true
```

**What Changed:**
- `force_ssl` now defaults to `true` in production
- New `assume_ssl` option for load balancer scenarios
- All production traffic forced to HTTPS by default

⚠️ **Custom Code Warning:** If you have custom SSL middleware, review for conflicts

**Migration Steps:**
1. If you DON'T want forced SSL, explicitly set `config.force_ssl = false`
2. If behind a load balancer that terminates SSL, set `config.assume_ssl = true`
3. Review custom SSL middleware for compatibility
4. Test in staging before production deploy

---

#### 3. **Action Mailer Preview Path Now Plural**

**Component:** ActionMailer  
**Impact:** High - Breaking API change  
**Type:** Breaking

**OLD (Rails 7.0):**
```ruby
# config/application.rb
config.action_mailer.preview_path = "test/mailers/previews"
```

**NEW (Rails 7.1):**
```ruby
# config/application.rb
config.action_mailer.preview_paths = ["test/mailers/previews"]
```

**What Changed:**
- `preview_path` (singular) is deprecated
- `preview_paths` (plural) now accepts an array
- Allows multiple preview directories

**Migration Steps:**
1. Find `config.action_mailer.preview_path` in configuration files
2. Change to `config.action_mailer.preview_paths`
3. Wrap value in array brackets

---

#### 4. **Database Location Changed for SQLite**

**Component:** ActiveRecord  
**Impact:** High - Changes file locations  
**Type:** Breaking - affects data storage

**OLD (Rails 7.0):**
```yaml
# config/database.yml
development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3
```

**NEW (Rails 7.1):**
```yaml
# config/database.yml
development:
  <<: *default
  database: storage/development.sqlite3

test:
  <<: *default
  database: storage/test.sqlite3
```

**What Changed:**
- SQLite databases moved from `db/` to `storage/`
- `storage/` directory now used for all persistent files
- Containers can mount single `storage/` directory

⚠️ **Custom Code Warning:** Check for hard-coded `db/*.sqlite3` paths

**Migration Steps:**
1. Update `config/database.yml` paths
2. Move existing SQLite databases: `mv db/*.sqlite3 storage/`
3. Update any scripts that reference `db/` for SQLite files
4. Verify `.gitignore` includes `storage/` not just `db/*.sqlite3`
5. Update Docker volumes if applicable

---

#### 5. **Autoload from lib/ by Default**

**Component:** Railties, Autoloading  
**Impact:** High - Changes autoloading behavior  
**Type:** Breaking - may load unexpected files

**OLD (Rails 7.0):**
```ruby
# config/application.rb
# lib/ was NOT autoloaded by default
# Had to manually configure if needed
```

**NEW (Rails 7.1):**
```ruby
# config/application.rb
# Automatically added in Rails 7.1 apps
config.autoload_lib(ignore: %w(assets tasks))
```

**What Changed:**
- New Rails 7.1 apps autoload from `lib/` automatically
- Ignores `lib/assets` and `lib/tasks` by default
- Classes in `lib/` now available without explicit require

⚠️ **Custom Code Warning:** 
- Check for name conflicts in `lib/` 
- Files in `lib/` will now be autoloaded

**Migration Steps:**
1. Add `config.autoload_lib(ignore: %w(assets tasks))` to `config/application.rb`
2. Review files in `lib/` for name conflicts
3. Move non-autoloadable files to ignored directories
4. Test that classes load correctly

---

### MEDIUM IMPACT Changes

#### 6. **ActiveRecord Query Log Format**

**Component:** ActiveRecord  
**Impact:** Medium - Changes log format  
**Type:** Behavior change

**OLD (Rails 7.0):**
```ruby
# Logs used custom format
# config.active_record.query_log_tags_format = :legacy
```

**NEW (Rails 7.1):**
```ruby
# Now uses SQLCommenter format by default
config.active_record.query_log_tags_format = :sqlcommenter

# To keep old format:
config.active_record.query_log_tags_format = :legacy
```

**What Changed:**
- Default format changed to SQLCommenter (W3C standard)
- Better compatibility with database tools
- Log parsing scripts may break

**Migration Steps:**
1. If you parse query logs, update parsers for SQLCommenter format
2. OR set `config.active_record.query_log_tags_format = :legacy`
3. Test log parsing in staging

---

#### 7. **Content Security Policy (CSP) Updates**

**Component:** ActionPack  
**Impact:** Medium - Security configuration  
**Type:** Behavior change

**OLD (Rails 7.0):**
```ruby
# config/initializers/content_security_policy.rb
config.content_security_policy do |policy|
  policy.script_src :unsafe_hashes, "'sha256-abc123'"
end
```

**NEW (Rails 7.1):**
```ruby
# config/initializers/content_security_policy.rb  
config.content_security_policy do |policy|
  # Can now pass arrays to style-src
  policy.style_src :self, :unsafe_inline
  
  # unsafe_hashes now available as symbol
  policy.script_src :unsafe_hashes, "'sha256-abc123'"
end
```

**What Changed:**
- Added `:unsafe_hashes` symbol support
- Improved CSP directive handling
- Can generate nonces for style-src

---

#### 8. **Cache Format Version 7.1**

**Component:** ActiveSupport::Cache  
**Impact:** Medium - Performance improvement  
**Type:** Opt-in enhancement

**OLD (Rails 7.0):**
```ruby
# Used format version 7.0
# Slower string caching
```

**NEW (Rails 7.1):**
```ruby
# config/application.rb
config.load_defaults 7.1

# OR explicitly:
config.active_support.cache_format_version = 7.1
```

**What Changed:**
- New cache format with better string performance
- Can read old 7.0 format entries
- Write new format when enabled

**Migration Steps:**
1. Enable after all servers upgraded
2. Rolling deploy: keep 7.0 format initially
3. After complete deploy, enable 7.1 format
4. Optionally flush cache for cleanup

---

#### 9. **Dockerfile Generated by Default**

**Component:** Railties  
**Impact:** Medium - New files  
**Type:** Addition (non-breaking)

**What Changed:**
- New Rails apps include Dockerfile
- Includes `.dockerignore`
- Includes `bin/docker-entrypoint`

**Files Added:**
- `Dockerfile`
- `.dockerignore`
- `bin/docker-entrypoint`

**Migration Steps:**
1. These files are optional for existing apps
2. Run `rails app:update` to add them
3. Review and customize for your needs

---

### LOW IMPACT Changes

#### 10. **Verbose Active Job Enqueue Logs**

**Component:** ActiveJob  
**Impact:** Low - Logging enhancement  
**Type:** Opt-in feature

**NEW (Rails 7.1):**
```ruby
# config/environments/development.rb
config.active_job.verbose_enqueue_logs = true
```

**What Changed:**
- Can now log where jobs are enqueued from
- Shows caller location in logs
- Disabled by default in production

**Example Log:**
```
Enqueued SendEmailJob (Job ID: 123) to Sidekiq(default)
↳ app/controllers/users_controller.rb:23:in `create'
```

---

#### 11. **Health Check Endpoint**

**Component:** Railties  
**Impact:** Low - New feature  
**Type:** Addition (non-breaking)

**NEW (Rails 7.1):**
```ruby
# config/routes.rb
# Automatically added to new apps
get "up" => "rails/health#show", as: :rails_health_check
```

**What Changed:**
- New `/up` endpoint for health checks
- Returns 200 if app boots successfully
- Useful for load balancers

**Migration Steps:**
1. Add route to existing apps if desired
2. Configure load balancer health checks

---

#### 12. **Test Runner Improvements**

**Component:** Railties  
**Impact:** Low - Better testing experience  
**Type:** Enhancement

**NEW Features:**
```bash
# Show slow tests
bin/rails test --profile
bin/rails test --profile 20  # show 20 slowest

# Filter by line ranges
bin/rails test test/models/user_test.rb:10-20

# Filter unused routes
bin/rails routes --unused
```

---

## 🔍 Custom Code Detection Patterns

The assistant will automatically scan for these patterns and flag them with ⚠️:

### 1. Database Configuration
```ruby
# PATTERN: Hard-coded database paths
database: db/

# WILL FLAG:
# ⚠️ Custom SQLite path detected - review database.yml
```

### 2. SSL Middleware
```ruby
# PATTERN: Custom SSL/HTTPS enforcement
middleware.use SomeSSLMiddleware

# WILL FLAG:
# ⚠️ Custom SSL middleware detected - review compatibility with force_ssl
```

### 3. Cache Configuration
```ruby
# PATTERN: Custom cache format settings
cache_format_version =

# WILL FLAG:
# ⚠️ Explicit cache format detected - review compatibility
```

### 4. Autoloading Configuration
```ruby
# PATTERN: Manual autoload_paths configuration
config.autoload_paths <<

# WILL FLAG:
# ⚠️ Custom autoload_paths detected - review with new lib/ autoloading
```

### 5. CSP Configuration
```ruby
# PATTERN: Complex CSP with inline styles/scripts
unsafe_inline, unsafe_eval

# WILL FLAG:
# ⚠️ CSP with unsafe directives detected - review nonce generation
```

---

## 📝 Step-by-Step Upgrade Process

### Before You Begin

**Checklist:**
- [ ] Application under version control (git)
- [ ] All tests currently passing
- [ ] Database backup created
- [ ] Staging environment available
- [ ] Team notified of upgrade
- [ ] Documentation updated
- [ ] Rails MCP server connected

### Step 1: Analysis (5-10 minutes)

1. Say: `"Analyze my Rails app for upgrade to 7.1"`
2. Review the generated report
3. Note all ⚠️ warnings
4. Identify breaking changes affecting your app

### Step 2: Gemfile Update (5 minutes)

```ruby
# OLD
gem "rails", "~> 7.0.0"

# NEW  
gem "rails", "~> 7.1.6"
```

Run:
```bash
bundle update rails
```

### Step 3: Configuration Updates (30-60 minutes)

**Priority Order:**

1. **config/environments/development.rb**
   ```ruby
   # Change cache_classes to enable_reloading
   config.enable_reloading = true
   ```

2. **config/environments/production.rb**
   ```ruby
   # Review force_ssl setting
   config.force_ssl = true  # Now default
   config.assume_ssl = true  # If behind load balancer
   ```

3. **config/application.rb**
   ```ruby
   # Update load defaults
   config.load_defaults 7.1
   
   # Add lib autoloading
   config.autoload_lib(ignore: %w(assets tasks))
   ```

4. **config/database.yml** (if using SQLite)
   ```yaml
   # Move databases to storage/
   database: storage/development.sqlite3
   ```

5. **config/initializers/** (review each for compatibility)

### Step 4: Database Migration (10 minutes)

```bash
# Move SQLite databases
mkdir -p storage
mv db/*.sqlite3 storage/

# Run migrations
rails db:migrate

# Verify
rails db:migrate:status
```

### Step 5: Testing (1-2 hours)

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

### Step 6: Staging Deployment (30 minutes)

1. Deploy to staging
2. Run smoke tests
3. Monitor logs for issues
4. Test critical user paths

### Step 7: Production Deployment (variable)

**Rolling Deploy Strategy:**

1. **First deploy:**
   - Keep cache format 7.0
   - Monitor for issues

2. **After 24-48 hours:**
   - Enable cache format 7.1
   - Clear cache: `Rails.cache.clear`

3. **Monitor:**
   - Error rates
   - Performance metrics
   - User reports

---

## 🔄 Rollback Plan

### If Issues Arise

1. **Gemfile Rollback:**
   ```ruby
   gem "rails", "~> 7.0.8"  # Latest 7.0
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
   # Revert migrations if necessary
   rails db:rollback STEP=X
   ```

5. **Redeploy Previous Version**

---

## ✅ Testing Checklist

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

- [ ] User authentication
- [ ] Database operations (CRUD)
- [ ] Background jobs
- [ ] Email delivery
- [ ] File uploads (if using)
- [ ] API endpoints
- [ ] WebSocket connections
- [ ] Caching works correctly

### Performance Tests

- [ ] Page load times acceptable
- [ ] Database query performance
- [ ] Cache hit rates normal
- [ ] Background job processing

---

## 🔧 Rails MCP Tool Integration

### Available Tools

This skill uses the following Rails MCP tools:

1. **railsMcpServer:project_info**
   - Gets Rails version
   - Identifies directory structure
   - Detects API-only mode

2. **railsMcpServer:list_files**
   - Lists configuration files
   - Finds models and controllers
   - Locates initializers

3. **railsMcpServer:get_file**
   - Reads configuration files
   - Analyzes custom code
   - Detects patterns

4. **railsMcpServer:analyze_models**
   - Understands data models
   - Identifies associations
   - Checks schema

5. **railsMcpServer:get_schema**
   - Reviews database structure
   - Identifies migrations needed

6. **railsMcpServer:get_routes**
   - Maps application endpoints
   - Identifies route conflicts

### Tool Workflow

```
User Request
    ↓
railsMcpServer:project_info (understand project)
    ↓
railsMcpServer:list_files (find relevant files)
    ↓
railsMcpServer:get_file (read configurations)
    ↓
Analyze against CHANGELOGs
    ↓
Generate upgrade report
    ↓
(Optional) nvimMcpServer:update_buffer (apply changes)
```

---

## 📱 Neovim MCP Integration

### Interactive Mode Workflow

1. **Check Open Files:**
   ```
   nvimMcpServer:get_project_buffers
   ```
   Returns list of files open in Neovim

2. **Show Proposed Changes:**
   Assistant shows OLD vs NEW for each file

3. **User Confirms:**
   User says "yes" or "update that file"

4. **Update Buffer:**
   ```
   nvimMcpServer:update_buffer
   ```
   Updates the file in Neovim with new content

5. **File Auto-Reloads:**
   Neovim detects change and reloads

### Benefits of Interactive Mode

- ✅ See changes immediately in your editor
- ✅ Review before committing
- ✅ Keep your workflow
- ✅ No context switching
- ✅ Instant feedback

### Requirements

- Neovim running with MCP server
- Files open in Neovim
- Project name specified
- Socket at `/tmp/nvim-{project_name}.sock`

---

## 🎯 Example Usage Scenarios

### Scenario 1: First Time Upgrade

**User Says:**
> "I want to upgrade my Rails app from 7.0 to 7.1"

**Assistant Response:**
1. Analyzes project using Rails MCP
2. Generates full upgrade report
3. Shows all breaking changes
4. Provides step-by-step instructions
5. Offers to answer questions

### Scenario 2: Specific Component Question

**User Says:**
> "What ActiveRecord changes are in Rails 7.1?"

**Assistant Response:**
1. Filters CHANGELOG for ActiveRecord
2. Shows relevant changes
3. Provides code examples
4. Explains impact

### Scenario 3: Interactive Upgrade

**User Says:**
> "Upgrade to Rails 7.1 in interactive mode, project name is 'blog'"

**Assistant Response:**
1. Checks Neovim buffers for project 'blog'
2. Generates upgrade plan
3. For each file needing changes:
   - Shows OLD code
   - Shows NEW code
   - Asks for confirmation
   - Updates buffer if approved
4. Summarizes changes made

### Scenario 4: Configuration Only

**User Says:**
> "Just show me configuration changes for Rails 7.1"

**Assistant Response:**
1. Filters for config/* file changes
2. Shows environment file updates
3. Shows application.rb updates
4. Shows initializer changes
5. Skips model/controller changes

---

## 🚨 Common Issues & Solutions

### Issue 1: SSL Redirects in Development

**Symptom:** Development redirects to HTTPS
**Cause:** `force_ssl = true` in wrong environment
**Solution:**
```ruby
# config/environments/development.rb
config.force_ssl = false  # Ensure this is false
```

### Issue 2: Autoload Conflicts

**Symptom:** `NameError: uninitialized constant`
**Cause:** Name conflicts with new `lib/` autoloading
**Solution:**
```ruby
# config/application.rb
# Add more to ignore list
config.autoload_lib(ignore: %w(assets tasks generators))
```

### Issue 3: Cache Issues

**Symptom:** Stale cached data after upgrade
**Cause:** Format version mismatch
**Solution:**
```ruby
# In Rails console
Rails.cache.clear
```

### Issue 4: Database Not Found

**Symptom:** `ActiveRecord::NoDatabaseError`
**Cause:** SQLite files not moved
**Solution:**
```bash
# Move databases
mkdir -p storage
mv db/*.sqlite3 storage/

# Update config/database.yml
```

### Issue 5: Tests Fail with Deprecation Warnings

**Symptom:** Many deprecation warnings in tests
**Cause:** Using deprecated APIs
**Solution:**
```ruby
# config/environments/test.rb
# Temporarily silence deprecations while fixing
ActiveSupport::Deprecation.silenced = true

# Then fix deprecations one by one
# Then set silenced = false
```

---

## 📚 Official Resources

### Rails Guides
- https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- https://guides.rubyonrails.org/7_1_release_notes.html

### GitHub CHANGELOGs
- ActionCable: https://github.com/rails/rails/blob/v7.1.6/actioncable/CHANGELOG.md
- ActionMailbox: https://github.com/rails/rails/blob/v7.1.6/actionmailbox/CHANGELOG.md
- ActionMailer: https://github.com/rails/rails/blob/v7.1.6/actionmailer/CHANGELOG.md
- ActionPack: https://github.com/rails/rails/blob/v7.1.6/actionpack/CHANGELOG.md
- ActionText: https://github.com/rails/rails/blob/v7.1.6/actiontext/CHANGELOG.md
- ActionView: https://github.com/rails/rails/blob/v7.1.6/actionview/CHANGELOG.md
- ActiveJob: https://github.com/rails/rails/blob/v7.1.6/activejob/CHANGELOG.md
- ActiveModel: https://github.com/rails/rails/blob/v7.1.6/activemodel/CHANGELOG.md
- ActiveRecord: https://github.com/rails/rails/blob/v7.1.6/activerecord/CHANGELOG.md
- ActiveStorage: https://github.com/rails/rails/blob/v7.1.6/activestorage/CHANGELOG.md
- ActiveSupport: https://github.com/rails/rails/blob/v7.1.6/activesupport/CHANGELOG.md
- Railties: https://github.com/rails/rails/blob/v7.1.6/railties/CHANGELOG.md

---

## 🎓 Skill Capabilities Summary

This skill can:

✅ Analyze any Rails 7.0 project structure
✅ Identify all breaking changes affecting the project
✅ Detect custom code requiring manual review
✅ Generate comprehensive upgrade reports
✅ Provide OLD vs NEW code examples
✅ Show step-by-step migration instructions
✅ Offer rollback procedures
✅ Include comprehensive testing checklists
✅ Integrate with Neovim for interactive updates
✅ Answer specific questions about changes
✅ Filter information by Rails component
✅ Explain impact of each change

This skill cannot:

❌ Automatically upgrade your code without permission
❌ Modify files without explicit confirmation
❌ Guarantee all custom code will work
❌ Test your application automatically
❌ Make architectural decisions for you
❌ Replace careful code review
❌ Deploy your application

---

## 🔐 Safety Features

1. **Read-Only by Default:** Reports only, no modifications
2. **Explicit Permission:** Interactive mode requires confirmation
3. **Custom Code Warnings:** All customizations marked with ⚠️
4. **Rollback Plans:** Complete rollback procedures provided
5. **Testing Checklists:** Comprehensive test coverage guidance
6. **Official Sources:** All info from Rails GitHub CHANGELOGs
7. **Conservative Approach:** Warns about edge cases

---

## 💡 Best Practices

### Before Upgrading

1. ✅ Read the full upgrade report
2. ✅ Review all ⚠️ warnings carefully
3. ✅ Create a staging environment
4. ✅ Ensure tests are comprehensive
5. ✅ Document custom configurations
6. ✅ Plan for rollback scenarios

### During Upgrade

1. ✅ Upgrade one component at a time
2. ✅ Test after each change
3. ✅ Commit frequently
4. ✅ Monitor deprecation warnings
5. ✅ Keep notes of issues found
6. ✅ Ask questions when uncertain

### After Upgrade

1. ✅ Run full test suite
2. ✅ Deploy to staging first
3. ✅ Monitor production closely
4. ✅ Keep rollback plan ready
5. ✅ Document any workarounds
6. ✅ Share learnings with team

---

## 📞 Getting Help

### From This Skill

Ask specific questions like:
- "What ActionPack changes affect me?"
- "Show me SSL configuration changes"
- "What's the migration path for [feature]?"
- "How do I rollback this change?"

### From Claude

Claude can:
- Explain breaking changes in detail
- Show more code examples
- Troubleshoot specific errors
- Suggest testing strategies
- Review your custom code

### From Rails Community

- Rails Forum: https://discuss.rubyonrails.org
- Rails GitHub Issues
- Stack Overflow (tag: ruby-on-rails)
- Rails Discord server

---

## 🎉 Skill Version Information

**Version:** 1.0
**Last Updated:** November 1, 2025  
**Rails Coverage:** 7.0.x → 7.1.6  
**CHANGELOG Sources:** Official Rails GitHub (v7.1.6 tag)

**Includes:**
- 12 official Rails component CHANGELOGs
- File diff analysis from rails-new-output
- Interactive Neovim editing support
- Rails MCP tool integration
- Custom code detection patterns
- Step-by-step workflows

---

**Ready to upgrade? Just say:**
```
"Upgrade my Rails app to 7.1"
```

**Or for interactive mode:**
```
"Upgrade to Rails 7.1 in interactive mode with project 'myapp'"
```

---

*This skill is designed to work with Claude's Projects feature, Rails MCP server, and optional Neovim MCP server. All recommendations are based on official Rails CHANGELOGs and best practices from the Rails core team.*
