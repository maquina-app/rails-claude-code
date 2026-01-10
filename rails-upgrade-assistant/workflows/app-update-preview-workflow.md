# app:update Preview Workflow

**Purpose:** Generate preview reports showing exact configuration file changes before running `rails app:update`

**When to use:** Every upgrade request OR when user specifically asks for app:update preview

---

## Prerequisites

- Current Rails version (from project)
- Target Rails version (from user request)
- Version guide loaded

---

## Step-by-Step Workflow

### Step 1: Load Preview Template

Read the app:update preview template:

```
railsMcpServer:get_file("templates/app-update-preview-template.md")
```

**Template Placeholders:**
- `{FROM_VERSION}` - Current version
- `{TO_VERSION}` - Target version
- `{DATE}` - Current date
- `{PROJECT_NAME}` - Project name
- `{MODIFIED_COUNT}` - Number of files to modify
- `{NEW_FILES_COUNT}` - Number of new files
- `{REMOVED_COUNT}` - Number of files to remove
- `{HIGH_IMPACT_COUNT}` - Count of high-impact changes
- `{MODIFIED_FILES_SECTION}` - File diffs
- `{NEW_FILES_SECTION}` - New files
- `{REMOVED_FILES_SECTION}` - Removed files
- `{NEOVIM_FILE_LIST_BACKSLASH}` - Multiline nvim command
- `{FILE_LIST}` - Simple file list

---

### Step 2: Identify Configuration Files

Determine which files `rails app:update` will modify:

**HIGH IMPACT (Always Changed):**
- `config/application.rb` - load_defaults version
- `Gemfile` - Rails version
- `config/boot.rb` - Bootsnap settings
- `bin/setup` - Setup script updates

**MEDIUM IMPACT (Often Changed):**
- `config/environments/production.rb` - New defaults
- `config/environments/development.rb` - New defaults
- `config/environments/test.rb` - New defaults
- `config/cable.yml` - ActionCable config
- `config/storage.yml` - ActiveStorage config

**LOW IMPACT (Sometimes Changed):**
- `config/puma.rb` - Server config
- `config/database.yml` - Database config
- `.ruby-version` - Ruby version file
- `package.json` - JS dependencies

---

### Step 3: Identify Version-Specific New Files

Determine new files based on target version:

**Rails 7.2:**
- `config/manifest.json` - PWA manifest
- `config/pwa.json` - PWA configuration

**Rails 8.0:**
- `config/solid_cache.yml` - Solid Cache config
- `config/solid_queue.yml` - Solid Queue config
- `config/solid_cable.yml` - Solid Cable config

**Rails 8.1:**
- None (minor release)

---

### Step 4: Load Version Guide

Read the version guide to understand what changes:

```
railsMcpServer:get_file("version-guides/upgrade-{FROM}-to-{TO}.md")
```

Extract:
- Configuration changes
- New configuration options
- Removed configurations

---

### Step 5: Read User's Actual Config Files

**Critical:** Must read user's ACTUAL files (not generic examples)

```
railsMcpServer:get_file("config/application.rb")
railsMcpServer:get_file("config/environments/production.rb")
railsMcpServer:get_file("config/environments/development.rb")
railsMcpServer:get_file("config/environments/test.rb")
railsMcpServer:get_file("Gemfile")
railsMcpServer:get_file("config/boot.rb")
```

This allows you to:
- Show their actual OLD code
- Detect custom configurations
- Add specific warnings

---

### Step 6: Generate File Diffs

For each config file, create OLD vs NEW comparison.

**Format for Modified Files:**

```markdown
### config/application.rb

**Impact:** 🔴 HIGH  
**Action:** Modify existing file  
**Reason:** Update load_defaults to Rails {TO_VERSION}

#### Current Configuration (OLD)
\```ruby
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.0
    
    # User's custom configurations
    config.time_zone = "Pacific Time (US & Canada)"
    config.middleware.use CustomMiddleware
  end
end
\```

#### Updated Configuration (NEW)
\```ruby
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.2  # <-- CHANGED
    
    # User's custom configurations (preserved)
    config.time_zone = "Pacific Time (US & Canada)"
    config.middleware.use CustomMiddleware
  end
end
\```

#### What Changed
- `config.load_defaults` updated from 7.0 to 7.2
- This loads new framework defaults for Rails 7.2
- Your custom configurations below will be preserved

#### Custom Code Warning
⚠️ **Custom middleware detected:** `CustomMiddleware`  
⚠️ Review that this middleware is compatible with Rails 7.2 defaults!
```

**Format for New Files:**

```markdown
### config/manifest.json (NEW)

**Impact:** 🟡 MEDIUM  
**Action:** Create new file  
**Reason:** Rails 7.2 adds PWA (Progressive Web App) support

#### File Contents
\```json
{
  "name": "MyApp",
  "short_name": "MyApp",
  "start_url": "/",
  "display": "standalone",
  "icons": [
    {
      "src": "/icon.png",
      "type": "image/png",
      "sizes": "512x512"
    }
  ]
}
\```

#### Purpose
Enables your Rails app to be installed as a Progressive Web App on mobile devices.

#### Required Actions
1. Create this file in `config/`
2. Customize `name` and `short_name` for your app
3. Add your app icon to `public/icon.png`
4. Update paths if your app isn't at root URL

#### Optional
- You can skip this if you don't want PWA support
- To disable: Set `config.pwa.enabled = false` in application.rb
```

---

### Step 7: Detect Custom Configurations

While reading config files, flag customizations:

**Common Custom Patterns:**

1. **Custom Middleware:**
   ```ruby
   config.middleware.use SomeMiddleware
   ```
   Flag: ⚠️ Custom middleware detected

2. **Manual Cache Configuration:**
   ```ruby
   config.cache_store = :redis_cache_store
   ```
   Flag: ⚠️ Custom cache configuration

3. **Custom Generators:**
   ```ruby
   config.generators do |g|
     g.orm :active_record
   end
   ```
   Flag: ⚠️ Custom generator configuration

4. **Custom Paths:**
   ```ruby
   config.paths['app/models'] << 'lib/models'
   ```
   Flag: ⚠️ Custom load path configuration

---

### Step 8: Generate Neovim File List

Create two formats for opening files:

**Format 1: Multi-line Neovim Command**
```bash
nvim \
  config/application.rb \
  config/environments/production.rb \
  config/environments/development.rb \
  config/boot.rb \
  Gemfile
```

**Format 2: Simple List**
```
config/application.rb
config/environments/production.rb
config/environments/development.rb
config/boot.rb
Gemfile
```

---

### Step 9: Calculate Counts

Count files for summary:

```
MODIFIED_COUNT = Number of files to modify (e.g., 5)
NEW_FILES_COUNT = Number of new files (e.g., 2)
REMOVED_COUNT = Number of files to remove (usually 0)
HIGH_IMPACT_COUNT = Files marked 🔴 HIGH (e.g., 2)
```

---

### Step 10: Populate Template

Replace all template variables:

| Placeholder | Replacement | Example |
|-------------|-------------|---------|
| `{FROM_VERSION}` | Current version | "7.1.4" |
| `{TO_VERSION}` | Target version | "7.2.3" |
| `{DATE}` | Current date | "November 2, 2025" |
| `{PROJECT_NAME}` | Project name | "my-rails-app" |
| `{MODIFIED_COUNT}` | Files to modify | "5" |
| `{NEW_FILES_COUNT}` | New files | "2" |
| `{REMOVED_COUNT}` | Files to remove | "0" |
| `{HIGH_IMPACT_COUNT}` | High impact changes | "2" |
| `{MODIFIED_FILES_SECTION}` | All file diffs | (generated diffs) |
| `{NEW_FILES_SECTION}` | New files | (generated new files) |
| `{REMOVED_FILES_SECTION}` | Removed files | (usually empty) |
| `{NEOVIM_FILE_LIST_BACKSLASH}` | Multiline command | (Format 1) |
| `{FILE_LIST}` | Simple list | (Format 2) |

---

### Step 11: Quality Check

Before delivering, verify:

- [ ] Used user's ACTUAL code (not generic)
- [ ] Every diff shows OLD vs NEW
- [ ] Custom configurations flagged with ⚠️
- [ ] New files have complete contents
- [ ] Neovim file list generated
- [ ] Impact levels assigned (HIGH/MEDIUM/LOW)
- [ ] Counts are accurate

**Full Checklist:** See `reference/quality-checklist.md`

---

### Step 12: Deliver Preview Report

Present the complete preview report:

```markdown
# Rails app:update Preview: 7.1 → 7.2

**Generated:** November 2, 2025  
**Project:** my-rails-app  
**Report Type:** Configuration Changes Preview

---

## 📊 Summary

| Metric | Count |
|--------|-------|
| **Files to modify** | 5 |
| **Files to create** | 2 |
| **Files to remove** | 0 |
| **High impact changes** | 2 |

---

## 🔄 Modified Files

[All file diffs here]

---

## ✨ New Files

[All new files here]

---

## 📝 Neovim Buffer List

To update these files with Claude's help:

\```bash
nvim \
  config/application.rb \
  config/environments/production.rb \
  Gemfile
\```

---

## ⚠️ Action Required

Before running `rails app:update`:

1. ✅ Review all diffs carefully
2. ✅ Check custom configurations
3. ✅ Backup your config files
4. ✅ Run tests after each change
5. ✅ Commit changes incrementally

---

## 🚀 Next Steps

Choose your approach:

### Option A: Manual Updates (Recommended)
1. Review each diff above
2. Apply changes manually
3. Test after each file
4. Commit incrementally

### Option B: Interactive Mode with Claude
1. Open all files in Neovim
2. Tell Claude: "Update these files interactively"
3. Review and test each update

### Option C: Run rails app:update
1. Run: `rails app:update`
2. Review each conflict
3. Choose whether to keep/overwrite
4. Test thoroughly
```

---

## Version-Specific File Changes

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

## Common Custom Configurations

### Detected Customizations to Review

**Middleware:**
```ruby
config.middleware.use Rack::Attack
config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
```

**Caching:**
```ruby
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
config.action_controller.perform_caching = true
```

**Assets:**
```ruby
config.assets.precompile += %w( admin.js admin.css )
config.assets.css_compressor = :sass
```

**Sessions:**
```ruby
config.session_store :redis_store, {
  servers: ENV['REDIS_URL'],
  expire_after: 90.minutes
}
```

**Generators:**
```ruby
config.generators do |g|
  g.test_framework :rspec
  g.fixture_replacement :factory_bot
end
```

---

## Impact Level Guidelines

**🔴 HIGH:**
- Changes to `config/application.rb` load_defaults
- Changes to `Gemfile` Rails version
- Removal of deprecated features you use
- SSL/security configuration changes

**🟡 MEDIUM:**
- New configuration files
- Environment-specific changes
- Optional new features
- Performance improvements

**🟢 LOW:**
- Documentation updates
- Minor default changes
- Cosmetic improvements
- Non-breaking enhancements

---

**Related Files:**
- Template: `templates/app-update-preview-template.md`
- Version Guides: `version-guides/upgrade-{FROM}-to-{TO}.md`
- Examples: `examples/preview-only.md`
- Quality Check: `reference/quality-checklist.md`
