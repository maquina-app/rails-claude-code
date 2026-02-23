---
title: "Breaking Changes by Version - Quick Reference"
description: "Comprehensive comparison table of all 106 breaking changes across Rails 6.0 through 8.1, organized by version and severity"
type: "reference-material"
reference_type: "comparison-table"
rails_versions: "6.0.x to 8.1.1"
breaking_changes_total: 106
versions_covered: 6
content_includes:
  - summary-statistics
  - priority-matrix
  - cumulative-impact-analysis
  - search-index
  - component-breakdown
tags:
  - breaking-changes
  - comparison
  - reference
  - quick-lookup
  - planning
category: "reference"
best_for:
  - multi-hop-planning
  - quick-comparison
  - impact-assessment
print_friendly: true
last_updated: "2025-11-01"
---

# Breaking Changes by Version - Quick Reference

**Complete comparison table for Rails 6.0 → 8.1**
**Last Updated:** November 1, 2025

---

## Summary Statistics

| Version               | Total Changes | HIGH   | MEDIUM | LOW    | Difficulty     |
| --------------------- | ------------- | ------ | ------ | ------ | -------------- |
| **6.0 → 6.1**         | 18            | 6      | 8      | 4      | Medium         |
| **6.1 → 7.0**         | 17            | 5      | 8      | 4      | Hard           |
| **7.0 → 7.1**         | 12            | 5      | 4      | 3      | Medium         |
| **7.1 → 7.2**         | 38            | 5      | 12     | 21     | Hard           |
| **7.2 → 8.0**         | 13            | 5      | 4      | 4      | Very Hard      |
| **8.0 → 8.1**         | 8             | 3      | 3      | 2      | Easy           |
| **TOTAL (6.0 → 8.1)** | **106**       | **29** | **39** | **38** |                |

---

## Rails 6.1 Breaking Changes (from 6.0)

### 🔴 HIGH PRIORITY (6)

| #    | Change                                    | Impact                  | Files Affected                       | Action Required                             |
| ---- | ----------------------------------------- | ----------------------- | ------------------------------------ | ------------------------------------------- |
| 1    | **where.not NAND semantics**              | All multi-key where.not | `app/models/*.rb`, scopes            | Audit all multi-key where.not, chain if NOR |
| 2    | **form_with non-remote default**          | All form_with views     | `app/views/**/*.erb`                 | Add local: false or set config              |
| 3    | **config_for Symbol-only keys**           | Config access code      | `app/`, `config/`, `lib/`            | Replace string keys with symbols            |
| 4    | **ActiveModel::Error new API**            | Error handling code     | `app/models/`, `app/validators/`     | Replace hash manipulation with errors.add   |
| 5    | **SameSite=Lax cookie default**           | Cross-site requests     | `config/`, OAuth/payment integrations | Set same_site: :none for cross-site cookies |
| 6    | **Content-Type full header**              | Content-Type checks     | `app/controllers/`, middleware       | Use request.media_type for MIME comparison  |

### 🟡 MEDIUM PRIORITY (8)

| #    | Change                              | Impact                  | Files Affected                         | Action Required                           |
| ---- | ----------------------------------- | ----------------------- | -------------------------------------- | ----------------------------------------- |
| 7    | **halted_callback_hook signature**  | Custom callback code    | `app/models/`, `lib/`                  | Add second parameter to override          |
| 8    | **HTTPS redirect 308**              | SSL redirect behavior   | Middleware, proxies                     | Test with older HTTP clients              |
| 9    | **image_processing gem required**   | ActiveStorage variants  | `Gemfile`, variant code                | Add image_processing gem, update API      |
| 10   | **respond_to#any Content-Type**     | API responses           | `app/controllers/`                     | Verify Content-Type in API tests          |
| 11   | **fixture_file_upload paths**       | Test files              | `test/`, `spec/`                       | Verify file path resolution               |
| 12   | **helper loading constantize**      | Helper modules          | `app/helpers/`                         | Ensure naming conventions match           |
| 13   | **update_attributes removed**       | All model updates       | `app/`, `lib/`, `test/`               | Replace with update/update!               |
| 14   | **errors.to_hash changed**          | Error serialization     | `app/`, `lib/`                         | Use errors.messages instead               |

### 🟢 LOW PRIORITY (4)

| #    | Change                              | Impact              | Files Affected                       | Action Required                    |
| ---- | ----------------------------------- | ------------------- | ------------------------------------ | ---------------------------------- |
| 15   | **Permissions-Policy rename**       | Security headers    | `config/initializers/`               | Update header references           |
| 16   | **Duration iso8601 sign**           | Duration formatting | Code parsing ISO 8601 durations      | Update parsing logic if needed     |
| 17   | **Partial renders DEBUG level**     | Log monitoring      | Log parsers                          | Set DEBUG level if parsing partials |
| 18   | **ActionMailer queue change**       | Job configuration   | `config/`, mailer code               | Update delivery_job references     |

---

## Rails 7.0 Breaking Changes (from 6.1)

### 🔴 HIGH PRIORITY (5)

| #    | Change                                    | Impact                   | Files Affected                         | Action Required                              |
| ---- | ----------------------------------------- | ------------------------ | -------------------------------------- | -------------------------------------------- |
| 1    | **Zeitwerk mandatory (classic removed)**  | ENTIRE application       | `config/application.rb`, all app code  | Run zeitwerk:check, fix all naming issues    |
| 2    | **Key generator SHA1 → SHA256**           | Sessions, cookies, encryption | `config/application.rb`           | Keep SHA1 during transition, plan rotation   |
| 3    | **button_to defaults to PATCH**           | All button_to views      | `app/views/**/*.erb`                   | Add explicit method: :post where needed      |
| 4    | **Sprockets optional**                    | Asset pipeline           | `Gemfile`, asset config                | Keep sprockets-rails or migrate to importmap |
| 5    | **Autoloading during init errors**        | Initializers             | `config/initializers/*.rb`             | Wrap app code refs in to_prepare block       |

### 🟡 MEDIUM PRIORITY (8)

| #    | Change                                    | Impact                 | Files Affected                          | Action Required                            |
| ---- | ----------------------------------------- | ---------------------- | --------------------------------------- | ------------------------------------------ |
| 6    | **AS::Dependencies private API deleted**  | Internal API usage     | `app/`, `lib/`, `config/`              | Use Zeitwerk API: Rails.autoloaders.main   |
| 7    | **Autoloaded paths off $LOAD_PATH**       | Bare require calls     | `app/`, `lib/`, `config/`              | Remove bare require, use constants directly |
| 8    | **request.content_type full header**      | API content checks     | `app/controllers/`, middleware          | Use request.media_type                     |
| 9    | **Cache serialization format**            | Cache compatibility    | `config/application.rb`                 | Keep 6.1 format initially, migrate later   |
| 10   | **AS variant processor → vips**           | Image processing       | `config/application.rb`                 | Set :mini_magick or install libvips        |
| 11   | **Transaction rollback on early return**  | Transaction code       | `app/models/`, `app/services/`          | Restructure to avoid return in transactions |
| 12   | **show_exceptions values changed**        | Environment config     | `config/environments/*.rb`              | Replace booleans with symbols              |
| 13   | **#to_s format deprecated**               | Date/Time formatting   | `app/`, `lib/`                          | Replace .to_s(:fmt) with .to_fs(:fmt)      |

### 🟢 LOW PRIORITY (4)

| #    | Change                              | Impact               | Files Affected                        | Action Required                     |
| ---- | ----------------------------------- | -------------------- | ------------------------------------- | ----------------------------------- |
| 14   | **AS::Digest SHA256**               | Cache keys, ETags    | Internal                              | Cache entries regenerate automatically |
| 15   | **AS video preview FFmpeg**         | Video file handling  | System dependencies                   | Install FFmpeg if using video previews |
| 16   | **Schema dump Rails version**       | Schema file          | `db/schema.rb`                        | Run db:schema:dump to regenerate    |
| 17   | **Spring 3.0.0+ required**         | Development          | `Gemfile`                             | Update Spring or remove it          |

---

## Rails 7.1 Breaking Changes (from 7.0)

### 🔴 HIGH PRIORITY (5)

| #    | Change                               | Impact             | Files Affected                       | Action Required                          |
| ---- | ------------------------------------ | ------------------ | ------------------------------------ | ---------------------------------------- |
| 1    | **cache_classes → enable_reloading** | All environments   | `config/environments/*.rb`           | Replace in ALL files, INVERT boolean     |
| 2    | **Force SSL default ON**             | Production only    | `config/environments/production.rb`  | Explicitly disable if not using SSL      |
| 3    | **preview_path → preview_paths**     | Mailer config      | `config/application.rb` or env files | Singular → Plural, wrap in array         |
| 4    | **SQLite database location**         | SQLite users only  | `config/database.yml` + files        | Move db/*.sqlite3 → storage/             |
| 5    | **lib/ autoloaded by default**       | All apps with lib/ | `config/application.rb`              | Add autoload_lib config, check conflicts |

### 🟡 MEDIUM PRIORITY (4)

| #    | Change                      | Impact              | Files Affected                                   | Action Required                   |
| ---- | --------------------------- | ------------------- | ------------------------------------------------ | --------------------------------- |
| 6    | **Query log format**        | Optional            | `config/application.rb`                          | Set sqlcommenter or legacy        |
| 7    | **Cache format 7.1**        | Optional            | `config/application.rb`                          | Enable after all servers upgraded |
| 8    | **Content Security Policy** | Security headers    | `config/initializers/content_security_policy.rb` | Review and update                 |
| 9    | **ActionText includes**     | ActiveStorage users | Models with ActionText                           | Verify includes work              |

### 🟢 LOW PRIORITY (3)

| #    | Change                    | Impact           | Files Affected                       | Action Required            |
| ---- | ------------------------- | ---------------- | ------------------------------------ | -------------------------- |
| 10   | **Health check route**    | Optional feature | `config/routes.rb`                   | Add `/up` route if desired |
| 11   | **Verbose job logs**      | Development only | `config/environments/development.rb` | Enable for debugging       |
| 12   | **Dockerfile generation** | Optional feature | Root directory                       | Run rails app:update       |

---

## Rails 7.2 Breaking Changes (from 7.1)

### 🔴 HIGH PRIORITY (5)

| #    | Change                                 | Impact                             | Files Affected                     | Action Required                         |
| ---- | -------------------------------------- | ---------------------------------- | ---------------------------------- | --------------------------------------- |
| 1    | **Transaction-aware jobs** ⚠️           | ALL apps with jobs in transactions | `app/models/*.rb`, `app/jobs/*.rb` | Find jobs in transactions, test timing  |
| 2    | **show_exceptions symbols only**       | All environments                   | `config/environments/*.rb`         | true/false → :all/:rescuable/:none      |
| 3    | **params == hash removed**             | Controllers                        | `app/controllers/*.rb`             | Convert to params.to_h == hash          |
| 4    | **ActiveRecord.connection deprecated** | Direct connection usage            | `app/`, `lib/`                     | Use with_connection or lease_connection |
| 5    | **Rails.application.secrets removed**  | Apps using secrets                 | Entire app                         | Migrate to credentials                  |

### 🟡 MEDIUM PRIORITY (12)

| #    | Change                           | Impact                | Files Affected                      | Action Required                   |
| ---- | -------------------------------- | --------------------- | ----------------------------------- | --------------------------------- |
| 6    | **serialize syntax**             | Models with serialize | `app/models/*.rb`                   | Add type: or coder: parameter     |
| 7    | **query_constraints deprecated** | Composite keys        | `app/models/*.rb`                   | Use foreign_key instead           |
| 8    | **Mailer test syntax**           | Test files            | `test/mailers/*.rb`                 | args: → params:                   |
| 9    | **ActiveSupport methods**        | Various code          | `app/`, `lib/`                      | Replace to_default_s, clone_empty |
| 10   | **fixture_path → fixture_paths** | Test config           | Test files                          | Plural form                       |
| 11   | **Mailer config updates**        | Development/test      | Environment files                   | Add default_url_options           |
| 12   | **autoload_lib syntax**          | Application config    | `config/application.rb`             | %w() → %w[]                       |
| 13   | **SSL options**                  | Production            | `config/environments/production.rb` | Add ssl_options for /up exclusion |
| 14   | **Puma configuration**           | Server config         | `config/puma.rb`                    | Simplify configuration            |
| 15   | **attributes_for_inspect**       | Development           | `config/environments/production.rb` | Set to [:id] for performance      |
| 16   | **Browser restrictions**         | Optional              | Controllers                         | Add allow_browser if desired      |
| 17   | **Rate limiting**                | Optional              | Controllers                         | Enhanced rate_limit syntax        |

### 🟢 LOW PRIORITY (21)

| #     | Change                                                    | Impact                                                     | Files Affected | Action Required |
| ----- | --------------------------------------------------------- | ---------------------------------------------------------- | -------------- | --------------- |
| 18-38 | Various deprecations, new features, optional enhancements | See version-guides/upgrade-7.1-to-7.2.md for complete list |                |                 |

---

## Rails 8.0 Breaking Changes (from 7.2)

### 🔴 HIGH PRIORITY (5)

| #    | Change                    | Impact                   | Files Affected                      | Action Required                                  |
| ---- | ------------------------- | ------------------------ | ----------------------------------- | ------------------------------------------------ |
| 1    | **Sprockets → Propshaft** | ALL apps                 | `Gemfile`, `app/assets/`, layouts   | Remove Sprockets, install Propshaft              |
| 2    | **Multi-database config** | Database setup           | `config/database.yml`               | Restructure for primary/cache/queue/cable        |
| 3    | **Solid gems defaults**   | Optional but recommended | `Gemfile`, config                   | Install Solid Cache/Queue/Cable or keep existing |
| 4    | **assume_ssl setting**    | Production SSL           | `config/environments/production.rb` | Add assume_ssl = true                            |
| 5    | **Removed deprecations**  | Various                  | Check for usage                     | Remove sqlite3_deprecated_warning, etc.          |

### 🟡 MEDIUM PRIORITY (4)

| #    | Change                  | Impact             | Files Affected             | Action Required                  |
| ---- | ----------------------- | ------------------ | -------------------------- | -------------------------------- |
| 6    | **Docker/Thruster**     | Docker deployments | `Dockerfile`, `Gemfile`    | Add thruster gem if using Docker |
| 7    | **Kamal deployment**    | Kamal users        | Deployment config          | Update for Rails 8 defaults      |
| 8    | **PWA manifest**        | PWA apps           | Routes, public files       | Uncomment if using PWA           |
| 9    | **Environment configs** | All environments   | `config/environments/*.rb` | Update various settings          |

### 🟢 LOW PRIORITY (4)

| #    | Change                       | Impact           | Files Affected | Action Required                 |
| ---- | ---------------------------- | ---------------- | -------------- | ------------------------------- |
| 10   | **params.expect()**          | Optional new API | Controllers    | Adopt if desired                |
| 11   | **Authentication generator** | New apps         | N/A            | Use if starting fresh           |
| 12   | **Form helper aliases**      | Optional         | Views          | textarea/checkbox/rich_textarea |
| 13   | **Script folder**            | Optional         | `script/`      | Custom scripts location         |

---

## Rails 8.1 Breaking Changes (from 8.0)

### 🔴 HIGH PRIORITY (3)

| #    | Change                     | Impact             | Files Affected                      | Action Required                   |
| ---- | -------------------------- | ------------------ | ----------------------------------- | --------------------------------- |
| 1    | **SSL commented out**      | Production (Kamal) | `config/environments/production.rb` | Uncomment if NOT using Kamal      |
| 2    | **pool → max_connections** | Database config    | `config/database.yml`               | Replace ALL occurrences           |
| 3    | **bundler-audit required** | Security           | `Gemfile`, `bin/`, `config/`        | Add gem, create script and config |

### 🟡 MEDIUM PRIORITY (3)

| #    | Change                          | Impact              | Files Affected | Action Required                      |
| ---- | ------------------------------- | ------------------- | -------------- | ------------------------------------ |
| 4    | **Semicolon separator removed** | Query parsing       | API code       | Replace ; with & in URLs             |
| 5    | **ActiveJob adapters removed**  | Sidekiq/SuckerPunch | `Gemfile`      | Update to gem versions with adapters |
| 6    | **Azure storage removed**       | Azure users         | Storage config | Switch to S3/GCS/Disk                |

### 🟢 LOW PRIORITY (2)

| #    | Change                   | Impact      | Files Affected | Action Required         |
| ---- | ------------------------ | ----------- | -------------- | ----------------------- |
| 7    | **MySQL unsigned types** | MySQL users | Migrations     | Use constraints instead |
| 8    | **.gitignore update**    | Git config  | `.gitignore`   | Update to /config/*.key |

---

## Cumulative Impact Analysis

### If Upgrading 6.0 → 8.1 (All 6 Hops)

**Critical Changes You'll Face:**

| Priority | Count | Examples                                                        |
| -------- | ----- | --------------------------------------------------------------- |
| 🔴 HIGH   | 29    | Zeitwerk, where.not, transaction jobs, asset pipeline, SSL      |
| 🟡 MEDIUM | 39    | Key generator, connection pools, serialize syntax, adapters     |
| 🟢 LOW    | 38    | Optional features, deprecations, enhancements                   |

**Top 12 Most Impactful (Across All Versions):**

1. 🔴 **Zeitwerk mandatory** (7.0) - Classic autoloader completely removed
2. 🔴 **where.not NAND semantics** (6.1) - Silent query behavior change
3. 🔴 **Transaction-aware jobs** (7.2) - Behavior change affecting job timing
4. 🔴 **Sprockets → Propshaft** (8.0) - Complete asset pipeline replacement
5. 🔴 **Key generator SHA1 → SHA256** (7.0) - Invalidates sessions/cookies
6. 🔴 **cache_classes → enable_reloading** (7.1) - Inverted boolean in ALL envs
7. 🔴 **Multi-database config** (8.0) - Database.yml restructure
8. 🔴 **show_exceptions symbols** (7.2) - Breaking config change
9. 🔴 **ActiveRecord.connection deprecated** (7.2) - Common pattern change
10. 🔴 **params comparison removed** (7.2) - Controller code breaks
11. 🔴 **SSL configuration changes** (7.1, 8.0, 8.1) - Evolving security setup
12. 🔴 **form_with non-remote default** (6.1) - AJAX form behavior changes

---

## Migration Priority Matrix

### Phase 1: Must Fix Before Deploy (Will Break App)

| Version | Must Fix                                                    |
| ------- | ----------------------------------------------------------- |
| **6.1** | where.not queries, form_with remote, config_for keys        |
| **7.0** | Zeitwerk migration, autoloading in initializers             |
| **7.1** | cache_classes, SSL (if no SSL), preview_paths, SQLite paths |
| **7.2** | show_exceptions, params comparison, secrets removal         |
| **8.0** | Asset pipeline, database.yml                                |
| **8.1** | max_connections, SSL uncomment (if not Kamal)               |

### Phase 2: Fix During Implementation (Will Cause Issues)

| Version | Should Fix                                            |
| ------- | ----------------------------------------------------- |
| **6.1** | SameSite cookies, image_processing gem, errors API    |
| **7.0** | Key generator rotation, button_to methods, transactions |
| **7.1** | lib/ autoload conflicts                               |
| **7.2** | Transaction jobs, .connection usage, serialize syntax |
| **8.0** | Solid gems setup, deprecated config removal           |
| **8.1** | bundler-audit, semicolons, job adapters               |

### Phase 3: Fix Post-Deploy (Deprecations)

| Version | Can Fix Later                                          |
| ------- | ------------------------------------------------------ |
| **6.1** | Permissions-Policy, Duration iso8601, log levels       |
| **7.0** | Schema dump format, Spring update, AS::Digest          |
| **7.1** | Cache format, query log format                         |
| **7.2** | query_constraints, fixture_paths, browser restrictions |
| **8.0** | PWA routes, form helper aliases                        |
| **8.1** | Minor deprecations                                     |

---

## Quick Decision Guide

### "Should I upgrade?"

**YES, upgrade if:**

- ✅ Your app is actively maintained
- ✅ You have good test coverage (>70%)
- ✅ You can allocate 1-4 weeks
- ✅ You have staging environment
- ✅ You follow semantic versioning

**WAIT if:**

- ⏸️ App is in maintenance mode only
- ⏸️ No test coverage
- ⏸️ Critical deadline in next 2 weeks
- ⏸️ No staging environment
- ⏸️ Team is inexperienced with Rails

### "Which version should I upgrade to?"

**Latest stable (8.1.1)** if:

- Starting new project
- Have time for multi-hop
- Want latest features

**Latest 7.x (7.2.3)** if:

- Not ready for Rails 8 architectural changes
- Using heavy custom asset pipeline
- Need more time to plan 8.0 migration

**Stay current (7.1.6 or 7.0.x)** if:

- App works fine
- No critical security issues
- Upgrade planned for future

---

## Breaking Changes by Component

### Most Impacted Components

| Component        | 6.1  | 7.0  | 7.1  | 7.2  | 8.0  | 8.1  | Total |
| ---------------- | ---- | ---- | ---- | ---- | ---- | ---- | ----- |
| **Railties**     | 2    | 5    | 5    | 8    | 6    | 4    | 30    |
| **ActionPack**   | 4    | 2    | 2    | 10   | 3    | 2    | 23    |
| **ActiveRecord** | 2    | 2    | 2    | 12   | 2    | 2    | 22    |
| **ActiveModel**  | 2    | 0    | 0    | 1    | 0    | 0    | 3     |
| **ActionView**   | 2    | 1    | 0    | 0    | 0    | 0    | 3     |
| **ActiveSupport**| 2    | 4    | 0    | 2    | 0    | 0    | 8     |
| **ActiveStorage**| 1    | 2    | 0    | 0    | 0    | 1    | 4     |
| **ActionMailer** | 1    | 0    | 1    | 3    | 0    | 0    | 5     |
| **ActiveJob**    | 0    | 0    | 0    | 3    | 1    | 2    | 6     |
| **Other**        | 2    | 1    | 2    | 2    | 1    | 0    | 8     |

### Least Impacted Components

- ActionCable: 0 breaking changes
- ActionMailbox: 0 breaking changes
- ActionText: 1 breaking change (7.1)
- ActiveModel: 1 breaking change (7.2)
- ActiveSupport: 2 breaking changes (7.2)
- ActiveStorage: 1 breaking change (8.1)

---

## Quick Search Index

### By Symptom

**"My tests are failing with..."**

- `Zeitwerk::NameError` → Rails 7.0, fix file/constant naming
- `update_attributes` undefined → Rails 6.1, use `update` instead
- `show_exceptions` error → Rails 7.2, change to symbols
- `params ==` error → Rails 7.2, use params.to_h
- `connection` deprecated → Rails 7.2, use with_connection
- Assets not loading → Rails 8.0, check Propshaft migration
- `pool` unknown keyword → Rails 8.1, rename to max_connections

**"I can't deploy because..."**

- App won't boot, constant errors → Rails 7.0, Zeitwerk naming issues
- Users logged out → Rails 7.0, key generator SHA1→SHA256 change
- SSL redirect loop → Check force_ssl/assume_ssl in each version
- Jobs not processing → Rails 7.2 transaction-aware jobs
- Database connection errors → Check config structure (7.2, 8.0, 8.1)
- Assets 404 → Rails 8.0 Propshaft migration incomplete
- OAuth/SSO broken → Rails 6.1, SameSite=Lax cookie default

**"The upgrade guide says to..."**

- "Replace cache_classes" → Rails 7.1, invert to enable_reloading
- "Update show_exceptions" → Rails 7.2, use symbols
- "Migrate to Propshaft" → Rails 8.0, remove Sprockets
- "Add bundler-audit" → Rails 8.1, security requirement

### By File Type

**Config files:**

- `config/application.rb` → 7.1 (3), 7.2 (2), 8.0 (2), 8.1 (1)
- `config/database.yml` → 7.1 (1), 8.0 (1), 8.1 (1)
- `config/environments/*.rb` → 7.1 (3), 7.2 (4), 8.0 (2), 8.1 (1)

**Code files:**

- `app/controllers/` → 7.2 (3), 8.0 (1)
- `app/models/` → 7.1 (1), 7.2 (4)
- `app/jobs/` → 7.2 (1), 8.1 (1)

**Asset files:**

- `app/assets/` → 8.0 (3 major changes)
- `app/views/layouts/` → 8.0 (1)

---

## Notes

### Using This Reference

**For Planning:**

1. Find your current version
2. Scan HIGH priority changes for target version
3. Assess difficulty using rating
4. Plan for multi-hop if needed

**For Implementation:**

1. Sort by priority (HIGH → MEDIUM → LOW)
2. Use "Files Affected" to find code
3. Follow "Action Required" for each
4. Cross-reference with version guides for details

**For Testing:**

1. Test HIGH priority changes thoroughly
2. Check for patterns in "Impact" column
3. Use symptom search to debug issues
4. Verify all components listed

### Keeping Updated

This reference is based on:

- Rails 6.1.0 (December 2020)
- Rails 7.0.0 (December 2021)
- Rails 7.1.6 (October 2023)
- Rails 7.2.3 (Latest 7.2)
- Rails 8.0.4 (Latest 8.0)
- Rails 8.1.1 (Latest 8.1)

When new versions release:

- Review official CHANGELOGs
- Add new breaking changes
- Update statistics
- Revise difficulty ratings

---

## Related References

- **Multi-Hop Strategy:** `reference/multi-hop-strategy.md`
- **Testing Checklist:** `reference/testing-checklist.md`
- **Deprecations Timeline:** `reference/deprecations-timeline.md`
- **Version Guides:** `version-guides/upgrade-X-to-Y.md`
- **Quick Reference:** `QUICK-REFERENCE.md`

---

**Last Updated:** November 1, 2025
**Rails Versions:** 6.0.x → 8.1.1
**Total Breaking Changes:** 106 documented

**For detailed information on each change, see the version-specific guides in `version-guides/` directory.**
