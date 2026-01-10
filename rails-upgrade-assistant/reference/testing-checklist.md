---
title: "Rails Upgrade Testing Checklist"
description: "Comprehensive testing procedures for before, during, and after Rails upgrades with version-specific tests and production verification"
type: "reference-material"
reference_type: "checklist"
rails_versions: "7.0.x to 8.1.1"
test_phases: 3
content_includes:
  - pre-upgrade-testing
  - during-upgrade-testing
  - post-upgrade-testing
  - version-specific-tests
  - production-verification
  - testing-tools
  - templates
tags:
  - testing
  - checklist
  - qa
  - verification
  - production
category: "reference"
best_for:
  - testing-guidance
  - quality-assurance
  - production-verification
print_friendly: true
last_updated: "2025-11-01"
---

# ✅ Rails Upgrade Testing Checklist

**Comprehensive testing guide for Rails upgrades**  
**Last Updated:** November 1, 2025

---

## 📖 Table of Contents

1. [Pre-Upgrade Testing](#pre-upgrade-testing)
2. [During Upgrade Testing](#during-upgrade-testing)
3. [Post-Upgrade Testing](#post-upgrade-testing)
4. [Test Types](#test-types)
5. [Version-Specific Tests](#version-specific-tests)
6. [Production Verification](#production-verification)
7. [Testing Tools](#testing-tools)

---

## 🎯 Pre-Upgrade Testing

**Goal:** Establish baseline, ensure current version is stable

### Pre-Upgrade Checklist

#### 1. Verify Current Tests (MANDATORY)

```bash
# Run full test suite
bin/rails test

Expected: 100% passing
Status: [ ] PASS / [ ] FAIL

If FAIL:
- Fix all failing tests before upgrading
- Document any skipped tests
- Get team signoff on test status
```

#### 2. System Tests

```bash
# Run system/integration tests
bin/rails test:system

Expected: All green
Status: [ ] PASS / [ ] FAIL
```

#### 3. Code Coverage Check

```bash
# Check coverage (if using SimpleCov)
open coverage/index.html

Coverage: _____%
Target: >70% recommended
Status: [ ] ACCEPTABLE / [ ] NEEDS IMPROVEMENT
```

#### 4. Performance Baseline

```bash
# Record current performance
bin/rails test --profile 20

Slowest Tests:
1. ____________ (___ms)
2. ____________ (___ms)
3. ____________ (___ms)
4. ____________ (___ms)
5. ____________ (___ms)

Total Time: ______s
```

#### 5. Deprecation Warnings Check

```bash
# Check for existing warnings
bin/rails test 2>&1 | grep -i "deprecation"

Current Warnings: ____
Status: [ ] ZERO / [ ] SOME / [ ] MANY

Document all current warnings:
- ____________________
- ____________________
- ____________________
```

#### 6. Application Smoke Test

```
Manual Testing Checklist:

[ ] App boots successfully
[ ] Home page loads
[ ] User can sign in
[ ] User can sign up
[ ] User can sign out
[ ] Search functionality works
[ ] Create/edit operations work
[ ] Delete operations work
[ ] File upload works (if applicable)
[ ] Email sending works
[ ] Background jobs process
[ ] API endpoints respond (if applicable)
```

---

## 🔧 During Upgrade Testing

**Goal:** Verify each change doesn't break existing functionality

### Incremental Testing Strategy

**After EACH change:**

#### 1. Quick Test Run

```bash
# Test affected area only
bin/rails test test/path/to/affected_test.rb

Status: [ ] PASS / [ ] FAIL
```

#### 2. Commit Point

```bash
# Only commit if tests pass
git add .
git commit -m "Upgrade: [describe change]"
```

### Phase-Based Testing

#### Phase 1: Gemfile Update

```bash
# Update Gemfile
gem "rails", "~> X.Y.Z"

# Install
bundle update rails
bundle install

# Verify installation
bin/rails -v
Expected: X.Y.Z

# Run tests
bin/rails test
Status: [ ] PASS / [ ] FAIL
```

#### Phase 2: Configuration Changes

For EACH config file changed:

```bash
# Example: config/application.rb updated
bin/rails test

# Check for new deprecation warnings
bin/rails test 2>&1 | grep -i "deprecation" | wc -l
New Warnings: ____

# Boot application
bin/rails server
Status: [ ] BOOTS / [ ] FAILS
```

#### Phase 3: Code Changes

For EACH code change (controllers, models, etc.):

```bash
# Run related tests
bin/rails test test/models/user_test.rb
bin/rails test test/controllers/users_controller_test.rb

# Run full suite
bin/rails test

Status: [ ] PASS / [ ] FAIL
```

#### Phase 4: Database Migrations (if any)

```bash
# Run migrations
bin/rails db:migrate

# Verify schema
bin/rails db:schema:dump

# Test migrations are reversible
bin/rails db:rollback STEP=X
bin/rails db:migrate

# Update test database
bin/rails db:test:prepare

# Run tests
bin/rails test

Status: [ ] PASS / [ ] FAIL
```

---

## ✨ Post-Upgrade Testing

**Goal:** Comprehensive verification before deployment

### Complete Testing Checklist

#### 1. Full Test Suite (MANDATORY)

```bash
# Run ALL tests
bin/rails test

Duration: _____s
Passed: _____
Failed: _____
Skipped: _____

Expected: 100% passing
Status: [ ] PASS / [ ] FAIL

If FAIL: Fix ALL failures before proceeding
```

#### 2. System Tests (MANDATORY)

```bash
# Run system/integration tests
bin/rails test:system

Duration: _____s
Status: [ ] PASS / [ ] FAIL
```

#### 3. Deprecation Warnings Audit

```bash
# Capture all deprecation warnings
bin/rails test 2>&1 | grep -i "deprecation" > deprecations.txt

# Count warnings
wc -l deprecations.txt
Count: _____

# Review each warning
cat deprecations.txt

Action Plan:
[ ] No warnings (perfect!)
[ ] Warnings documented for future
[ ] Critical warnings fixed
```

#### 4. Code Quality Checks

```bash
# Run linter (if using)
bundle exec rubocop

Issues: _____
Status: [ ] CLEAN / [ ] NEEDS FIXES

# Run security audit
bundle exec brakeman

Issues: _____
Status: [ ] CLEAN / [ ] NEEDS REVIEW

# Check for N+1 queries (if using bullet)
# Review bullet log after test run
cat log/bullet.log
Issues: _____
Status: [ ] CLEAN / [ ] NEEDS FIXES
```

#### 5. Performance Testing

```bash
# Compare with baseline
bin/rails test --profile 20

Slowest Tests:
1. ____________ (___ms) [vs ___ms baseline]
2. ____________ (___ms) [vs ___ms baseline]
3. ____________ (___ms) [vs ___ms baseline]

Total Time: ______s [vs ______s baseline]

Performance Change: ___% faster/slower
Status: [ ] IMPROVED / [ ] SAME / [ ] DEGRADED

If DEGRADED by >10%: Investigate before deploying
```

#### 6. Database Tests

```bash
# Test database queries
bin/rails runner "
  puts 'Testing database connection...'
  User.count
  puts 'Connection successful'
"

Status: [ ] SUCCESS / [ ] FAIL

# Test migrations are reversible
bin/rails db:rollback STEP=X
bin/rails db:migrate

Status: [ ] SUCCESS / [ ] FAIL
```

#### 7. Manual Application Testing

```
Complete Manual Test Suite:

AUTHENTICATION:
[ ] Sign up new user
[ ] Sign in existing user
[ ] Password reset flow
[ ] Sign out
[ ] Session persistence

CRUD OPERATIONS:
[ ] Create new record
[ ] Read/view record
[ ] Update record
[ ] Delete record
[ ] List/index page

SEARCH/FILTER:
[ ] Search functionality
[ ] Filter options
[ ] Pagination
[ ] Sorting

FILE OPERATIONS (if applicable):
[ ] File upload
[ ] File download
[ ] File deletion
[ ] Image processing

EMAIL (if applicable):
[ ] Transactional emails
[ ] Welcome email
[ ] Password reset email
[ ] Notification emails

BACKGROUND JOBS (if applicable):
[ ] Job enqueuing
[ ] Job processing
[ ] Job retries
[ ] Job failure handling

API ENDPOINTS (if applicable):
[ ] GET requests
[ ] POST requests
[ ] PUT/PATCH requests
[ ] DELETE requests
[ ] Authentication
[ ] Rate limiting

EDGE CASES:
[ ] Error pages (404, 500)
[ ] Validation errors
[ ] Permission denied
[ ] Empty states
[ ] Large datasets
```

---

## 🧪 Test Types

### Unit Tests

**What:** Test individual models, helpers, libraries

```bash
# Run unit tests only
bin/rails test test/models/
bin/rails test test/helpers/
bin/rails test test/lib/

# What to verify
[ ] Model validations work
[ ] Model associations work
[ ] Model callbacks work
[ ] Helper methods work
[ ] Business logic correct
```

### Integration Tests

**What:** Test controller actions and routes

```bash
# Run integration tests
bin/rails test test/controllers/
bin/rails test test/integration/

# What to verify
[ ] Routes work correctly
[ ] Controller actions respond
[ ] Redirects work
[ ] Session handling works
[ ] Cookies work
[ ] Request/response cycle
```

### System Tests

**What:** Test full user workflows with browser

```bash
# Run system tests
bin/rails test:system

# What to verify
[ ] JavaScript works
[ ] User can complete workflows
[ ] Forms submit correctly
[ ] AJAX requests work
[ ] Turbo/Stimulus work (if using)
[ ] Real browser behavior
```

### Job Tests

**What:** Test background job processing

```bash
# Run job tests
bin/rails test test/jobs/

# What to verify
[ ] Jobs enqueue correctly
[ ] Jobs process successfully
[ ] Job arguments passed correctly
[ ] Job retries work
[ ] Job failures handled
```

**Version-Specific (Rails 7.2+):**

```ruby
# Test transaction-aware job enqueuing
test "jobs wait for transaction commit" do
  assert_no_enqueued_jobs do
    User.transaction do
      user = User.create!(name: "Test")
      WelcomeJob.perform_later(user)
    end
  end
  
  # Job enqueued after transaction
  assert_enqueued_jobs 1
end

# Test rollback prevents job enqueue
test "jobs not enqueued on rollback" do
  assert_no_enqueued_jobs do
    User.transaction do
      user = User.create!(name: "Test")
      WelcomeJob.perform_later(user)
      raise ActiveRecord::Rollback
    end
  end
end
```

### Mailer Tests

**What:** Test email generation and delivery

```bash
# Run mailer tests
bin/rails test test/mailers/

# What to verify
[ ] Emails generate correctly
[ ] Email content correct
[ ] Attachments work (if any)
[ ] Templates render
[ ] Links work
```

### Request Tests

**What:** Test API endpoints

```bash
# Run request tests
bin/rails test test/requests/

# What to verify
[ ] Endpoints return correct status
[ ] JSON/XML responses correct
[ ] Authentication required
[ ] Authorization works
[ ] Rate limiting works
[ ] CORS headers correct
```

---

## 🎯 Version-Specific Tests

### Rails 7.1 Specific Tests

```bash
# Verify enable_reloading works
# config/environments/development.rb: config.enable_reloading = true
bin/rails console
> ApplicationController.new
# Make a change to ApplicationController
> reload!
> ApplicationController.new
# Should reflect change

Status: [ ] WORKS / [ ] FAILS

# Test SSL redirect (if enabled)
# Start server
curl -I http://localhost:3000
# Should redirect to https in production

Status: [ ] WORKS / [ ] FAILS / [ ] NOT APPLICABLE

# Test lib/ autoloading
# Create class in lib/
# Should be available without require
bin/rails runner "puts MyLibClass.new.inspect"

Status: [ ] WORKS / [ ] FAILS
```

### Rails 7.2 Specific Tests

```bash
# Test show_exceptions config
# config/environments/test.rb: config.action_dispatch.show_exceptions = :none
bin/rails test
# Should not show exception pages in tests

Status: [ ] CORRECT / [ ] INCORRECT

# Test params.to_h conversions
# Search for: params ==
grep -r "params.*==" app/controllers/
Found: _____ instances
All Fixed: [ ] YES / [ ] NO

# Test connection usage
# Search for deprecated .connection
grep -rn "\.connection[^_]" app/ lib/ | grep -v "with_connection\|lease_connection"
Found: _____ instances
All Fixed: [ ] YES / [ ] NO

# Test job transaction timing (CRITICAL)
# See Job Tests section above
bin/rails test test/jobs/

Status: [ ] ALL PASS / [ ] SOME FAIL
```

### Rails 8.0 Specific Tests

```bash
# Test asset loading (Propshaft)
bin/rails server
# Visit http://localhost:3000
# Open browser console
# Check for:
[ ] No 404 errors for CSS
[ ] No 404 errors for JS
[ ] Images load correctly
[ ] No Sprockets errors

# Test database connections (multi-database)
bin/rails runner "
  ActiveRecord::Base.connected_to(role: :writing, shard: :default) do
    puts 'Primary: ' + User.count.to_s
  end
  
  ActiveRecord::Base.connected_to(database: :cache) do
    puts 'Cache connected'
  end
"

Status: [ ] SUCCESS / [ ] FAIL

# Test Solid gems (if using)
bin/rails runner "
  Rails.cache.write('test', 'value')
  puts Rails.cache.read('test')
"

Status: [ ] WORKS / [ ] FAILS / [ ] NOT USING
```

### Rails 8.1 Specific Tests

```bash
# Test max_connections
bin/rails runner "
  config = ActiveRecord::Base.connection_pool.db_config.configuration_hash
  puts 'Max connections: ' + config[:max_connections].to_s
"

Status: [ ] CONFIGURED / [ ] MISSING

# Run bundler-audit
bin/bundler-audit

Vulnerabilities: _____
Status: [ ] CLEAN / [ ] HAS VULNERABILITIES

# Test SSL redirect (if not using Kamal)
# Production environment
curl -I https://yourapp.com
# Should have SSL

Status: [ ] WORKS / [ ] FAILS / [ ] NOT APPLICABLE
```

---

## 🚀 Production Verification

**After deploying to production**

### Immediate Checks (0-1 hour)

```
[ ] Application boots successfully
[ ] Home page loads (200 response)
[ ] Health check endpoint works
[ ] Login works
[ ] Sign up works
[ ] No spike in error rates

Error Tracking Dashboard:
  Before deploy errors/min: _____
  After deploy errors/min:  _____
  Change: _____%
  
Status: [ ] HEALTHY / [ ] ISSUES
```

### Short-Term Monitoring (1-24 hours)

```
[ ] All features working normally
[ ] No new error patterns
[ ] Performance within acceptable range
[ ] Background jobs processing
[ ] Email delivery working
[ ] Database performance normal
[ ] Memory usage stable
[ ] No user complaints

Performance Metrics:
  Avg response time: _____ms (baseline: _____ms)
  95th percentile: _____ms (baseline: _____ms)
  Error rate: ____% (baseline: ___%)
  
Status: [ ] GOOD / [ ] CONCERNING
```

### Medium-Term Monitoring (24-48 hours)

```
[ ] All automated tests still passing
[ ] No hidden edge cases discovered
[ ] User feedback positive
[ ] Team confident in upgrade
[ ] Documentation updated
[ ] Rollback plan validated (not used!)

Status: [ ] SUCCESS / [ ] ISSUES
```

### Long-Term Verification (48+ hours)

```
[ ] System stable for 48+ hours
[ ] No unexpected behavior
[ ] Performance sustained or improved
[ ] Team comfortable with new version
[ ] Ready for next hop (if multi-hop)

Status: [ ] COMPLETE / [ ] MONITORING
```

---

## 🛠️ Testing Tools

### Essential Tools

**RSpec / Minitest**

```bash
# Installation
gem 'rspec-rails'  # or built-in Minitest

# Usage
bin/rails test           # Minitest
bundle exec rspec        # RSpec
```

**SimpleCov (Coverage)**

```bash
# Installation
gem 'simplecov', require: false

# Add to test_helper.rb or spec_helper.rb
require 'simplecov'
SimpleCov.start 'rails'

# View coverage
open coverage/index.html
```

**Brakeman (Security)**

```bash
# Installation
gem 'brakeman'

# Usage
bundle exec brakeman

# Check specific confidence levels
bundle exec brakeman --confidence-level 2
```

**Bullet (N+1 Queries)**

```bash
# Installation
gem 'bullet', group: :development

# Configuration in config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.console = true
end

# Usage (automatic during development)
# Check log/bullet.log after testing
```

**Bundler Audit (Vulnerabilities)**

```bash
# Installation (Rails 8.1+)
gem 'bundler-audit'

# Usage
bin/bundler-audit

# Update database
bundle audit update
```

**Database Cleaner**

```bash
# Installation
gem 'database_cleaner-active_record'

# Ensures clean state between tests
# Especially important for testing transactions
```

---

## 📝 Testing Templates

### Test Run Record Template

```
Date: __________
Rails Version: __________
Branch: __________
Commit: __________

TEST RESULTS:
  Unit Tests:        ____ / ____ passed
  Integration Tests: ____ / ____ passed
  System Tests:      ____ / ____ passed
  Total Duration:    ____ seconds
  
ISSUES FOUND:
1. __________________ [Status: Fixed / Pending]
2. __________________ [Status: Fixed / Pending]
3. __________________ [Status: Fixed / Pending]

PERFORMANCE:
  Baseline:  ____ seconds
  Current:   ____ seconds
  Change:    ____% faster/slower

DEPRECATIONS:
  Count: ____
  Critical: ____
  Minor: ____

NEXT STEPS:
[ ] ____________________
[ ] ____________________
[ ] ____________________

Sign-off: __________
```

### Production Deployment Test Report

```
DEPLOYMENT DATE: __________
RAILS VERSION: __________
DEPLOYED BY: __________

PRE-DEPLOYMENT CHECKLIST:
[ ] All tests passing
[ ] Code reviewed
[ ] Staging tested
[ ] Rollback plan ready
[ ] Team notified

POST-DEPLOYMENT CHECKS (1 hour):
[ ] Application boots
[ ] Home page loads
[ ] Authentication works
[ ] No error spikes
[ ] Performance acceptable

MONITORING (24 hours):
Error Rate:
  Before: ____%
  After:  ____%
  
Performance:
  Avg response: ____ms
  95th %ile:    ____ms
  
Issues: ____

MONITORING (48 hours):
[ ] System stable
[ ] No user complaints
[ ] Performance good
[ ] Ready to proceed

SIGN-OFF:
Developer: __________
QA: __________
DevOps: __________
Manager: __________
```

---

## 🎯 Testing Success Criteria

### Minimum (Before Staging)

- ✅ 100% test suite passing
- ✅ Zero test failures
- ✅ Application boots
- ✅ Core features work manually

### Good (Before Production)

All minimum criteria plus:

- ✅ System tests passing
- ✅ Performance acceptable
- ✅ No critical deprecations
- ✅ Security audit clean
- ✅ Code review complete

### Excellent (Best Practice)

All good criteria plus:

- ✅ All deprecations fixed
- ✅ Coverage improved or maintained
- ✅ Performance improved
- ✅ Documentation updated
- ✅ Team trained

---

## 💡 Testing Tips

### Do's

✅ **Test incrementally** - After each change
✅ **Test automatically** - Use CI/CD
✅ **Test in production-like environment** - Use production data copy
✅ **Test edge cases** - Not just happy paths
✅ **Test rollback** - Practice before needed

### Don'ts

❌ **Don't skip tests** - "I'll test later" = never
❌ **Don't test only locally** - CI might fail
❌ **Don't ignore deprecations** - Will break in future
❌ **Don't test in production first** - Use staging
❌ **Don't assume tests are enough** - Manual testing important too

---

## 🔗 Related Resources

- **Breaking Changes:** `reference/breaking-changes-by-version.md`
- **Multi-Hop Strategy:** `reference/multi-hop-strategy.md`
- **Version Guides:** `version-guides/upgrade-X-to-Y.md`
- **Usage Guide:** `USAGE-GUIDE.md`

---

**Last Updated:** November 1, 2025  
**Rails Versions:** 7.0.x → 8.1.1

**Remember:** Good testing is the difference between a smooth upgrade and a production nightmare. Test early, test often, test thoroughly! ✅
