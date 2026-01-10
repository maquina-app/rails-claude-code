# Example: Preview Only Request

**Scenario:** User wants to see config changes before upgrading

---

## User Request

```
User: "Show me the app:update changes for Rails 7.2"
```

---

## Claude's Response

```markdown
I'll show you what `rails app:update` will change when upgrading to Rails 7.2.

---

# Rails app:update Preview: 7.1 → 7.2

**Generated:** November 2, 2025  
**Project:** my-rails-app  
**Current Version:** 7.1.4  
**Target Version:** 7.2.3

---

## 📊 Summary

| Metric | Count |
|--------|-------|
| **Files to modify** | 4 |
| **Files to create** | 2 |
| **Files to remove** | 0 |
| **High impact changes** | 2 |

---

## 🔄 Modified Files

### config/application.rb

**Impact:** 🔴 HIGH  
**Action:** Modify existing file

#### Current Configuration (OLD)
\```ruby
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.1
  end
end
\```

#### Updated Configuration (NEW)
\```ruby
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.2  # <-- CHANGED
  end
end
\```

#### What Changed
- `config.load_defaults` from 7.1 to 7.2
- Loads Rails 7.2 framework defaults

---

### Gemfile

**Impact:** 🔴 HIGH  
**Action:** Modify existing file

#### Current (OLD)
\```ruby
gem 'rails', '~> 7.1.4'
\```

#### Updated (NEW)
\```ruby
gem 'rails', '~> 7.2.3'
\```

---

## ✨ New Files

### config/manifest.json (NEW)

**Impact:** 🟡 MEDIUM  
**Action:** Create new file  
**Reason:** Rails 7.2 adds PWA support

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

---

## 📝 Neovim Buffer List

\```bash
nvim \
  config/application.rb \
  Gemfile \
  config/environments/production.rb \
  config/environments/development.rb
\```

---

## 🚀 Next Steps

1. Review changes above
2. Decide on update approach
3. Test after updating

Would you also like the complete upgrade report?
```

---

**Related:** `workflows/app-update-preview-workflow.md`
