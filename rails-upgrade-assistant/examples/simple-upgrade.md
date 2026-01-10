# Example: Simple Single-Hop Upgrade (Rails 8.0 → 8.1)

**Scenario:** User has Rails 8.0.4 and wants to upgrade to Rails 8.1.1

---

## User Request

```
User: "Upgrade my Rails app to 8.1"
```

---

## Claude's Response Workflow

### Step 1: Detect Version

```
Call: railsMcpServer:project_info
Result: Current = 8.0.4, Target = 8.1.1, Type = Full Stack
```

### Step 2: Load Resources

```
Read: workflows/upgrade-report-workflow.md
Read: workflows/detection-script-workflow.md
Read: workflows/app-update-preview-workflow.md
Read: templates/upgrade-report-template.md
Read: version-guides/upgrade-8.0-to-8.1.md
Read: detection-scripts/patterns/rails-81-patterns.yml
Read: detection-scripts/templates/detection-script-template.sh
Read: templates/app-update-preview-template.md
```

### Step 3: Analyze Project

```
Read: config/application.rb
Read: config/environments/production.rb
Read: Gemfile
Scan for: Custom SSL middleware, Redis configs, custom initializers
```

### Step 4: Generate Deliverable #1 - Upgrade Report

```
Follow: workflows/upgrade-report-workflow.md

Output: 50-page comprehensive report with:
- 2 breaking changes (SSL config, bundler-audit)
- 3 custom code warnings (detected in user's code)
- Step-by-step migration guide (8 phases)
- Testing checklist
- Rollback plan
```

### Step 5: Generate Deliverable #2 - Detection Script

```
Follow: workflows/detection-script-workflow.md

Output: Executable bash script that:
- Searches for SSL config patterns
- Searches for bundler-audit references
- Generates findings report
- Lists affected files for Neovim
```

### Step 6: Generate Deliverable #3 - app:update Preview

```
Follow: workflows/app-update-preview-workflow.md

Output: Configuration preview showing:
- config/application.rb changes (load_defaults 8.1)
- config/environments/production.rb changes (SSL config)
- Gemfile changes (Rails 8.1.1)
- Neovim file list
```

---

## Complete Claude Response

```markdown
I'll help you upgrade from Rails 8.0.4 to Rails 8.1.1. Let me analyze your project...

[Analyzing...]

I've generated three comprehensive deliverables for your upgrade:

---

## 📋 Deliverable #1: Comprehensive Upgrade Report

# Rails Upgrade Report: 8.0.4 → 8.1.1

**Generated:** November 2, 2025  
**Project:** my-rails-app  
**Complexity:** ⭐⭐ (Low-Medium)  
**Estimated Time:** 2-4 hours  
**Risk Level:** Low

## 🎯 Executive Summary

Your Rails 8.0.4 → 8.1.1 upgrade is straightforward with **2 breaking changes** and **3 custom code warnings**.

**Key Findings:**
- 🔴 SSL configuration must be updated (assume_ssl)
- 🟡 bundler-audit integration available
- ⚠️ 3 custom configurations detected that need review

**Recommendation:** ✅ Proceed with upgrade. Low risk.

---

## 🔄 Breaking Changes (2)

### 🔴 HIGH: SSL Configuration Changes

**Component:** ActionDispatch  
**Priority:** HIGH

#### What Changed
Rails 8.1 introduces `config.assume_ssl` to complement `config.force_ssl`.

#### Your Code (OLD)
\```ruby
# config/environments/production.rb
config.force_ssl = true
\```

#### Updated Code (NEW)
\```ruby
# config/environments/production.rb
config.assume_ssl = true  # <-- ADD THIS
config.force_ssl = true
\```

#### Why This Matters
- Improves SSL handling for apps behind proxies
- Prevents redirect loops in certain load balancer configs
- Required for proper HTTPS detection

#### Action Required
1. Add `config.assume_ssl = true` to production.rb
2. Keep existing `config.force_ssl = true`
3. Test SSL redirects work correctly
4. Verify secure cookies are set properly

---

### 🟡 MEDIUM: bundler-audit Integration

**Component:** Bundler  
**Priority:** MEDIUM

#### What Changed
Rails 8.1 integrates bundler-audit for security vulnerability checking.

#### Your Code (OLD)
\```ruby
# Gemfile - no bundler-audit
```

#### Updated Code (NEW)
\```ruby
# Gemfile
gem 'bundler-audit', require: false
```

#### Why This Matters
- Automatically checks for vulnerable gem versions
- Part of `bin/rails audit` command
- Improves security posture

#### Action Required
1. Review Gemfile.lock for vulnerable gems
2. Update any flagged gems
3. Run `bin/rails audit` after upgrade

---

## ⚠️ Custom Code Warnings (3)

### ⚠️ #1: Custom Redis Configuration

**Location:** `config/initializers/redis.rb`

**What We Found:**
\```ruby
REDIS = Redis.new(url: ENV['REDIS_URL'], timeout: 5)
\```

**Recommendation:**
- This custom Redis configuration is preserved
- Verify it works with Rails 8.1 defaults
- Test cache operations thoroughly
- Consider migrating to Solid Cache if appropriate

---

### ⚠️ #2: Custom Middleware

**Location:** `config/application.rb`

**What We Found:**
\```ruby
config.middleware.use Rack::Attack
config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
\```

**Recommendation:**
- Custom middleware detected
- Verify Rack::Attack is compatible with Rails 8.1
- Test rate limiting after upgrade
- Check middleware order is correct

---

### ⚠️ #3: Custom Generator Configuration

**Location:** `config/application.rb`

**What We Found:**
\```ruby
config.generators do |g|
  g.test_framework :rspec
  g.fixture_replacement :factory_bot
end
\```

**Recommendation:**
- Custom generator configuration will be preserved
- Verify RSpec and FactoryBot are Rails 8.1 compatible
- Test generator commands after upgrade

---

## 📋 8-Phase Migration Guide

### Phase 1: Preparation
- [ ] Read this complete report
- [ ] Create git branch: `git checkout -b upgrade-rails-8.1`
- [ ] Backup database
- [ ] Run all tests (verify 100% pass)

### Phase 2: Update Dependencies
- [ ] Update Gemfile: `gem 'rails', '~> 8.1.1'`
- [ ] Run: `bundle update rails`
- [ ] Review bundler output for conflicts

### Phase 3: Update Configuration
- [ ] Update `config/application.rb`: `config.load_defaults 8.1`
- [ ] Add SSL config to `config/environments/production.rb`
- [ ] Run detection script (see Deliverable #2)

### Phase 4: Run rails app:update
- [ ] Run: `rails app:update`
- [ ] Review each conflict
- [ ] Keep your custom configurations

### Phase 5: Fix Breaking Changes
- [ ] Fix SSL configuration (HIGH priority)
- [ ] Review bundler-audit integration (MEDIUM priority)
- [ ] Run detection script again to verify fixes

### Phase 6: Update Tests
- [ ] Run test suite: `rails test` or `bundle exec rspec`
- [ ] Fix any test failures
- [ ] Verify 100% pass rate

### Phase 7: Staging Deployment
- [ ] Deploy to staging
- [ ] Run smoke tests
- [ ] Monitor logs for errors
- [ ] Test SSL redirects

### Phase 8: Production Deployment
- [ ] Deploy to production
- [ ] Monitor closely for 24 hours
- [ ] Be ready to rollback if needed

---

## 🧪 Testing Checklist

- [ ] All existing tests pass
- [ ] SSL redirects work (http → https)
- [ ] Custom middleware functions correctly
- [ ] Redis caching works
- [ ] Generator commands work
- [ ] No deprecation warnings in logs

---

## 🔙 Rollback Plan

**When to Rollback:**
- Critical functionality broken
- Database errors
- SSL redirect loops
- Performance issues

**How to Rollback:**
1. `git revert HEAD`
2. `bundle install`
3. Redeploy previous version
4. Verify all systems operational

---

## 📚 Resources

- [Rails 8.1 Release Notes](https://edgeguides.rubyonrails.org/8_1_release_notes.html)
- [Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [CHANGELOG](https://github.com/rails/rails/blob/8-1-stable/CHANGELOG.md)

---

*Report generated by Rails Upgrade Assistant v1.0*

---

## 🔍 Deliverable #2: Breaking Changes Detection Script

Run this script to find issues in your codebase:

\```bash
chmod +x detect_rails_81_changes.sh
./detect_rails_81_changes.sh
\```

[Complete bash script here - 200+ lines]

---

## 📝 Deliverable #3: app:update Preview Report

Here's what will change in your configuration files:

[Complete preview report showing OLD vs NEW for each file]

---

## 🚀 Next Steps

1. Review all three deliverables above
2. Run the detection script
3. Share the findings report with me if issues found
4. Choose your update approach:
   - **Manual:** Apply changes one by one
   - **Interactive:** Open files in Neovim, I'll help update them
   - **rails app:update:** Let Rails update, resolve conflicts

Would you like me to:
- Help you fix specific issues found by the detection script?
- Update files interactively (requires Neovim)?
- Explain any breaking change in more detail?
```

---

## Key Characteristics of This Response

✅ **Generated all 3 deliverables**  
✅ **Used user's actual code** (not generic examples)  
✅ **Flagged custom configurations** (⚠️)  
✅ **Provided OLD vs NEW** examples  
✅ **Included step-by-step plan**  
✅ **Offered next steps**  

---

**Related Files:**
- Workflow: `workflows/upgrade-report-workflow.md`
- Workflow: `workflows/detection-script-workflow.md`
- Workflow: `workflows/app-update-preview-workflow.md`
