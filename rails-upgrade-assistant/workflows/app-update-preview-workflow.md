# app:update Preview Workflow

> **Note:** The app:update preview is now Section 4 ("Configuration Changes") of the unified upgrade report. See `workflows/upgrade-report-workflow.md` Step 11 for generation instructions.

This file retains version-specific reference data for the configuration changes section.

---

## Version-Specific File Changes

### Rails 6.0 → 6.1
**Typical changes:**
- `config/application.rb` - load_defaults 6.1
- `config/environments/*.rb` - New Rails 6.1 defaults
- `Gemfile` - Rails 6.1.x

**New files:** None

### Rails 6.1 → 7.0
**Typical changes:**
- `config/application.rb` - load_defaults 7.0
- `config/environments/*.rb` - New Rails 7.0 defaults
- `Gemfile` - Rails 7.0.x

**New files:** None

### Rails 7.0 → 7.1
**Typical changes:**
- `config/application.rb` - load_defaults 7.1
- `config/environments/*.rb` - New Rails 7.1 defaults
- `Gemfile` - Rails 7.1.x

**New files:** None

### Rails 7.1 → 7.2
**Typical changes:**
- `config/application.rb` - load_defaults 7.2
- `config/environments/*.rb` - New Rails 7.2 defaults
- Browser support checks
- PWA configurations

**New files:**
- `config/manifest.json` - PWA manifest
- `config/pwa.json` - PWA config

### Rails 7.2 → 8.0
**Typical changes:**
- `config/application.rb` - load_defaults 8.0
- `config/environments/*.rb` - Solid defaults
- Asset pipeline → Propshaft
- Sprockets removal

**New files:**
- `config/solid_cache.yml` - Solid Cache
- `config/solid_queue.yml` - Solid Queue
- `config/solid_cable.yml` - Solid Cable

### Rails 8.0 → 8.1
**Typical changes:**
- `config/application.rb` - load_defaults 8.1
- `config/environments/production.rb` - SSL changes
- Bundler-audit integration

**New files:** None (minor release)

---

## Impact Level Guidelines

**HIGH:**
- Changes to `config/application.rb` load_defaults
- Changes to `Gemfile` Rails version
- Removal of deprecated features you use
- SSL/security configuration changes

**MEDIUM:**
- New configuration files
- Environment-specific changes
- Optional new features

**LOW:**
- Minor default changes
- Non-breaking enhancements

---

**Related Files:**
- Workflow: `workflows/upgrade-report-workflow.md` (Step 11)
- Template: `templates/upgrade-report-template.md`
- Version Guides: `version-guides/upgrade-{FROM}-to-{TO}.md`
