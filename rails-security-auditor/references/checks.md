# Security Checks Catalog

Full catalog of checks for the Rails Security Auditor. Organized by category, each check includes what to look for, the severity, why it matters, and the exact fix.

---

## Table of Contents

1. [PROD — Production Environment](#prod--production-environment)
2. [CSRF — Cross-Site Request Forgery](#csrf--cross-site-request-forgery)
3. [HDR — Security Headers](#hdr--security-headers)
4. [CSP — Content Security Policy](#csp--content-security-policy)
5. [SESS — Session Configuration](#sess--session-configuration)
6. [RATE — Rate Limiting](#rate--rate-limiting)
7. [AUTH — Authentication & Authorization](#auth--authentication--authorization)
8. [GEM — Gems & Dependencies](#gem--gems--dependencies)
9. [CI — Continuous Integration](#ci--continuous-integration)
10. [DATA — Data Protection](#data--data-protection)
11. [FWKD — Framework Defaults](#fwkd--framework-defaults)

---

## PROD — Production Environment

### PROD-01 `force_ssl` not enabled
**Severity:** Critical
**Look for:** `config.force_ssl = true` in `config/environments/production.rb`
**Fail condition:** Missing or set to `false`

**Why it matters:** Without `force_ssl`, your app accepts plain HTTP connections. Session cookies travel unencrypted. Attackers on the same network can steal sessions trivially. The `Secure` flag on cookies is also only set by Rails when this is enabled.

**Fix:**
```ruby
# config/environments/production.rb
config.force_ssl = true
```

---

### PROD-02 `assume_ssl` missing or SSL config doesn't match the proxy setup
**Severity:** High
**Look for:** `config.assume_ssl`, `config.force_ssl`, and `config.ssl_options` in `config/environments/production.rb`. Also detect proxy type from: presence of `config/initializers/cloudflare.rb`, `cloudflared` in any config, `CLOUDFLARE` references, kamal config files (`config/deploy.yml`), or trusted proxy configuration.
**Fail condition:** Any mismatch between the detected proxy setup and the SSL config — see the three cases below.

**Why it matters:**
When TLS is terminated by a proxy upstream, traffic arrives at Rails over plain HTTP. Without `assume_ssl = true`, `request.ssl?` returns false, causing redirect loops and incorrect cookie/CSRF behaviour. The `ssl_options: { hsts: false }` setting should only be used when something else (Cloudflare) is sending HSTS — if nothing else is, browsers never receive it.

**Three cases — check which applies and verify the config matches:**

**Case 1 — Cloudflare in front (direct proxy or Cloudflare Tunnel + kamal-proxy):**

Evidence: `config/initializers/cloudflare.rb` exists, or `CLOUDFLARE` appears in config, or `trusted_proxies` includes Cloudflare IP ranges.

Cloudflare sends HSTS. kamal-proxy's Docker IPs are already in Rails' default `TRUSTED_PROXIES` (private network ranges). The traffic chain — whether via direct Cloudflare proxy or Cloudflare Tunnel → kamal-proxy — is identical from Rails' perspective.

```ruby
# config/environments/production.rb
config.assume_ssl  = true
config.force_ssl   = true
config.ssl_options = { hsts: false }  # Cloudflare sends HSTS
```

**Case 2 — kamal-proxy only, no Cloudflare:**

Evidence: `config/deploy.yml` exists (Kamal config), no Cloudflare evidence found.

kamal-proxy terminates TLS via Let's Encrypt but does not send HSTS. Rails must send it.

```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl  = true
# Do NOT set ssl_options: { hsts: false } — nothing else sends HSTS
config.ssl_options = {
  hsts: { expires: 1.year, subdomains: true, preload: true }
}
```

Flag as a finding if `ssl_options: { hsts: false }` is set without Cloudflare evidence — browsers would never receive HSTS.

**Case 3 — No proxy, Rails handles TLS directly:**

Evidence: No proxy indicators found.

`assume_ssl` is not needed. `force_ssl` handles redirect, HSTS, and Secure cookies.

```ruby
# config/environments/production.rb
config.force_ssl = true
```

Flag `assume_ssl = true` without proxy evidence as an unnecessary but harmless setting — note it rather than treating it as an error.

---

### PROD-03 Log level too verbose
**Severity:** Medium
**Look for:** `config.log_level` in `config/environments/production.rb`
**Fail condition:** Set to `:debug` or `:info`, or not set (defaults to `:debug` in some older Rails versions)

**Why it matters:** Debug and info level logs capture full request parameters, which often include passwords, tokens, and session data — even after `filter_parameters` runs. `:warn` dramatically reduces what gets written to disk.

**Fix:**
```ruby
# config/environments/production.rb
config.log_level = :warn
```

---

### PROD-04 `filter_parameters` too narrow
**Severity:** High
**Look for:** `config.filter_parameters` in `config/application.rb` or `config/environments/production.rb`
**Fail condition:** Only contains the Rails default `[:passw]` or is not extended

**Why it matters:** Parameters not in this list are logged in plaintext. Common omissions: `token`, `api_key`, `secret`, `otp`, `ssn`, `credit_card`, `cvv`, `pin`, `auth`.

**Fix:**
```ruby
# config/application.rb
config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate,
  :otp, :ssn, :credit_card, :cvv, :pin, :api_key, :auth, :authorization
]
```

---

### PROD-05 Trusted proxies not configured
**Severity:** High
**Look for:** `config.action_dispatch.trusted_proxies` in `config/application.rb` or an initializer
**Fail condition:** Not configured, and there's evidence of a proxy (Cloudflare, load balancer, Nginx)

**Why it matters:** Without trusted proxy configuration, `request.remote_ip` returns the proxy's IP address, not the real client IP. This makes Rack::Attack and `rate_limit` throttle the proxy — effectively throttling all users simultaneously — instead of individual clients.

**Fix (generic reverse proxy):**
```ruby
# config/application.rb
config.action_dispatch.trusted_proxies =
  ActionDispatch::RemoteIp::TRUSTED_PROXIES + [IPAddr.new("your.proxy.ip")]
```

**Fix (Cloudflare):**
```ruby
# config/initializers/cloudflare.rb
require "ipaddr"
require "open-uri"

cloudflare_ips = begin
  ipv4 = URI.open("https://www.cloudflare.com/ips-v4/").read.lines.map { |ip| IPAddr.new(ip.strip) }
  ipv6 = URI.open("https://www.cloudflare.com/ips-v6/").read.lines.map { |ip| IPAddr.new(ip.strip) }
  ipv4 + ipv6
rescue
  [] # fail open — add hardcoded fallback here if needed
end

Rails.application.config.action_dispatch.trusted_proxies =
  ActionDispatch::RemoteIp::TRUSTED_PROXIES + cloudflare_ips
```

---

## CSRF — Cross-Site Request Forgery

### CSRF-01 `protect_from_forgery` not set
**Severity:** Critical
**Look for:** `protect_from_forgery` in `app/controllers/application_controller.rb`
**Fail condition:** Not present, or explicitly disabled with `skip_before_action :verify_authenticity_token`

**Why it matters:** Without CSRF protection, any website can forge form submissions on behalf of your logged-in users — transferring funds, changing emails, deleting data. This is a top-10 web vulnerability.

**Fix:**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
```

---

### CSRF-02 CSRF strategy using `:null_session`
**Severity:** High
**Look for:** `protect_from_forgery with: :null_session`
**Fail condition:** Present in ApplicationController

**Why it matters:** `:null_session` silently provides an empty session on CSRF failure instead of raising an error. CSRF attacks fail silently — no logs, no alerts, and the attacker may still get partial functionality.

**Fix:**
```ruby
protect_from_forgery with: :exception
```

---

### CSRF-03 Per-form CSRF tokens not enabled (pre-8.0 apps)
**Severity:** Medium
**Look for:** `config.action_controller.per_form_csrf_tokens` in `config/application.rb` or environment files
**Fail condition:** Set to `false` or absent on apps using Rails `load_defaults` below 8.0

**Why it matters:** Without per-form tokens, a single leaked token is valid for any endpoint. With per-form tokens, a token stolen from one endpoint cannot be replayed against another.

**Fix:**
```ruby
# config/application.rb
config.action_controller.per_form_csrf_tokens = true
```

---

## HDR — Security Headers

### HDR-01 `X-Frame-Options` not set or too permissive
**Severity:** High
**Look for:** `X-Frame-Options` in `config/application.rb` default_headers or ActionDispatch configuration
**Fail condition:** Missing entirely, or set to `ALLOWALL`

**Why it matters:** Without this header, any website can embed your app in an invisible iframe and trick users into clicking your buttons (clickjacking).

**Fix:**
```ruby
# config/application.rb
config.action_dispatch.default_headers["X-Frame-Options"] = "SAMEORIGIN"
# Or use DENY if you never legitimately embed your app in iframes
config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"
```

---

### HDR-02 `X-Content-Type-Options` missing
**Severity:** Medium
**Look for:** `X-Content-Type-Options` in default headers
**Fail condition:** Missing or set to something other than `nosniff`

**Why it matters:** Browsers may MIME-sniff responses and execute uploaded files as scripts. This header stops that.

**Fix:**
```ruby
config.action_dispatch.default_headers["X-Content-Type-Options"] = "nosniff"
```

---

### HDR-03 `X-XSS-Protection` still set
**Severity:** Info
**Look for:** `X-XSS-Protection` in default headers
**Fail condition:** Present with any value other than `0`

**Why it matters:** All major browsers removed the XSS auditor this header controlled. The header is now a no-op at best, and at worst can be exploited to selectively block legitimate scripts. Rails 8.2 removes it from defaults.

**Fix:**
```ruby
# Remove it entirely, or set to 0 to explicitly disable
config.action_dispatch.default_headers.delete("X-XSS-Protection")
```

---

### HDR-04 `Referrer-Policy` missing or too permissive
**Severity:** Medium
**Look for:** `Referrer-Policy` in default headers
**Fail condition:** Missing, or set to `unsafe-url` or `no-referrer-when-downgrade`

**Why it matters:** Without a strict referrer policy, your app's URLs (including tokens in query strings) are sent to third-party sites users navigate to.

**Fix:**
```ruby
config.action_dispatch.default_headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
# For maximum privacy:
config.action_dispatch.default_headers["Referrer-Policy"] = "no-referrer"
```

---

## CSP — Content Security Policy

### CSP-01 No CSP initializer
**Severity:** High
**Look for:** `config/initializers/content_security_policy.rb`
**Fail condition:** File does not exist

**Why it matters:** Without a Content Security Policy, browsers will execute any script on your page — including scripts injected by an XSS attack. CSP is the primary defence against XSS escalation.

**Fix:** Create `config/initializers/content_security_policy.rb`:
```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :none
  policy.script_src  :self
  policy.style_src   :self
  policy.img_src     :self, :data
  policy.font_src    :self
  policy.connect_src :self
  policy.frame_ancestors :none
  policy.base_uri    :self
  policy.form_action :self
end

# Start in report-only mode — watch for violations before enforcing
Rails.application.config.content_security_policy_report_only = true
```

---

### CSP-02 CSP uses `unsafe-inline` for scripts
**Severity:** High
**Look for:** `:unsafe_inline` in `script_src` policy
**Fail condition:** Present

**Why it matters:** `unsafe-inline` allows any inline `<script>` tag to execute, which defeats the XSS protection CSP provides. Use nonces instead.

**Fix:**
```ruby
policy.script_src :self, :nonce
```
```erb
<%# In your layout — Rails generates a unique nonce per request %>
<%= javascript_tag nonce: true do %>
  // Your inline JS
<% end %>
```

---

### CSP-03 CSP uses `unsafe-eval`
**Severity:** High
**Look for:** `:unsafe_eval` in `script_src`
**Fail condition:** Present

**Why it matters:** `unsafe-eval` allows `eval()`, `new Function()`, and similar dynamic code execution, which can be exploited via prototype pollution or injected data.

**Fix:** Remove `:unsafe_eval`. If a library requires it, replace that library.

---

### CSP-04 CSP in report-only mode in production
**Severity:** Medium
**Look for:** `config.content_security_policy_report_only = true`
**Fail condition:** Present in production configuration without being behind a feature flag

**Why it matters:** Report-only mode logs violations but does not block anything. A CSP in report-only mode permanently provides no protection.

**Note:** Flag as Warning, not Fail — it may be intentional during a transition. Ask the user.

---

## SESS — Session Configuration

### SESS-01 `SameSite` not set to `:strict`
**Severity:** Medium
**Look for:** `same_site:` in `config/initializers/session_store.rb`
**Fail condition:** Set to `:lax` (the default) or not set

**Why it matters:** `SameSite=Lax` still allows cookies to be sent on top-level navigations from other sites (e.g. a link click). `SameSite=Strict` prevents cookies from being sent in any cross-site context.

**Fix:**
```ruby
Rails.application.config.session_store :cookie_store,
  key:       "_myapp_session",
  same_site: :strict,
  httponly:  true,
  secure:    Rails.env.production?
```

---

### SESS-02 No session expiry configured
**Severity:** Medium
**Look for:** `expire_after:` in session store configuration
**Fail condition:** Not set

**Why it matters:** Without an expiry, sessions live as long as the cookie's browser session (until the browser is closed), or indefinitely if the user has "keep me logged in" set. A stolen session remains valid forever.

**Fix:**
```ruby
Rails.application.config.session_store :cookie_store,
  expire_after: 2.hours   # Adjust to your app's risk tolerance
```

---

### SESS-03 `httponly` not set to `true`
**Severity:** High
**Look for:** `httponly:` in session store
**Fail condition:** Explicitly set to `false`

**Why it matters:** Without `HttpOnly`, JavaScript on your page can read the session cookie. An XSS vulnerability becomes an instant session hijack.

**Fix:**
```ruby
Rails.application.config.session_store :cookie_store, httponly: true
```
Note: `httponly: true` is the default in Rails — flag this only if it's explicitly overridden to `false`.

---

## RATE — Rate Limiting

### RATE-01 No rate limiting on authentication endpoints
**Severity:** Critical
**Look for:** `rate_limit` macro in `SessionsController` or `PasswordResetsController`, OR Rack::Attack throttle rules targeting `/session` or `/password_resets`
**Fail condition:** Neither found

**Why it matters:** Without rate limiting, an attacker can try unlimited passwords against any account. Credential stuffing and brute force attacks are trivial without this protection.

**Fix (Rails 8.0+):**
```ruby
class SessionsController < ApplicationController
  rate_limit to: 5, within: 3.minutes, only: :create,
             by: -> { request.remote_ip },
             with: -> { redirect_to new_session_url, alert: "Too many attempts." }
end
```

---

### RATE-02 No Rack::Attack initializer
**Severity:** High
**Look for:** `config/initializers/rack_attack.rb`
**Fail condition:** File does not exist AND `rack-attack` is not in Gemfile

**Why it matters:** Rails' `rate_limit` protects specific controller actions but doesn't block scanner bots, PHP probes, WordPress login attempts, and other low-level noise that consumes server resources before your router processes them.

**Fix:** Create `config/initializers/rack_attack.rb` — see the full example in the main document or the blog posts. Minimum viable config:
```ruby
class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  safelist("allow /up") { |req| req.path == "/up" }

  SCANNER_PATHS = %r{\.(php|env|git|htaccess|DS_Store)|/wp-admin|/phpmyadmin}i
  blocklist("block scanner paths") { |req| req.path.match?(SCANNER_PATHS) }

  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end
end
```

---

### RATE-03 Rack::Attack missing health check safelist
**Severity:** Medium
**Look for:** A `safelist` rule matching `/up` or your health check path in `rack_attack.rb`
**Fail condition:** Rack::Attack is configured but no health check safelist exists

**Why it matters:** Load balancers poll the health check endpoint constantly from a small pool of IPs. Without a safelist, these legitimate requests trip your global throttle and the load balancer marks your app as unhealthy.

**Fix:**
```ruby
safelist("allow health check") { |req| req.path == "/up" }
```

---

### RATE-04 Rack::Attack missing scanner blocklist
**Severity:** Medium
**Look for:** A `blocklist` rule targeting common scanner paths in `rack_attack.rb`
**Fail condition:** Rack::Attack is configured but no scanner path blocklist

**Why it matters:** Every public Rails app receives constant probes for PHP files, WordPress admin, `.env` files, and similar paths. Blocking them at the Rack layer stops them before they consume a thread.

**Fix:**
```ruby
SCANNER_PATHS = %r{
  \.(php|asp|aspx|env|git|svn|htaccess|DS_Store) |
  /wp-admin | /wp-login | /phpmyadmin | /actuator
}xi
blocklist("block scanner paths") { |req| req.path.match?(SCANNER_PATHS) }
```

---

### RATE-05 `rack-attack` gem missing from Gemfile
**Severity:** High
**Look for:** `rack-attack` in `Gemfile` or `Gemfile.lock`
**Fail condition:** Not present (and RATE-02 would also fire)

**Fix:**
```ruby
# Gemfile
gem "rack-attack"
```
Then run `bundle install` and add the initializer (see RATE-02).

---

## AUTH — Authentication & Authorization

### AUTH-01 No authorization library
**Severity:** High
**Look for:** `pundit`, `cancancan`, `action_policy` in Gemfile/Gemfile.lock
**Fail condition:** None present

**Why it matters:** Rails provides authentication (who are you?) but not authorization (what can you do?). Without an explicit authorization layer, controllers commonly fetch resources by ID without verifying ownership — exposing every user's data to every other user.

**Note:** This is flagged as High, not Critical, because some apps implement authorization manually or don't need it yet. Flag it and explain the risk.

**Fix:** Add Pundit (recommended for clarity and testability):
```ruby
# Gemfile
gem "pundit"
```
```ruby
# app/controllers/application_controller.rb
include Pundit::Authorization
after_action :verify_authorized, except: :index
after_action :verify_policy_scoped, only: :index
```

---

### AUTH-02 Controllers not scoping queries to current user
**Severity:** High
**Look for:** `find(params[:id])` calls in controllers that are not preceded by a scope like `current_user.` or `Current.account.`
**Fail condition:** Any unscoped `Model.find(params[:id])` in a controller that requires authentication

**Why it matters:** An authenticated user can access any record in your database by changing the ID in the URL. This is called Insecure Direct Object Reference (IDOR) and is one of the most common real-world vulnerabilities.

**Fix:**
```ruby
# Wrong
@document = Document.find(params[:id])

# Right
@document = Current.account.documents.find(params[:id])
# or
@document = current_user.documents.find(params[:id])
```

---

### AUTH-03 `allow_unauthenticated_access` used too broadly
**Severity:** Medium
**Look for:** `allow_unauthenticated_access` in controllers
**Fail condition:** Used in `ApplicationController` or on controllers that should require authentication

**Why it matters:** `allow_unauthenticated_access` in `ApplicationController` disables authentication for the entire app. It should only appear in controllers with public actions (sessions, registrations, password resets).

**Note:** Flag only if used in ApplicationController or a controller that handles sensitive data.

---

## GEM — Gems & Dependencies

### GEM-01 `brakeman` not in Gemfile
**Severity:** High
**Look for:** `brakeman` in `Gemfile` or `Gemfile.lock`
**Fail condition:** Not present

**Why it matters:** Brakeman is a static analysis tool that catches Rails-specific security issues: SQL injection from string interpolation, unescaped output, mass assignment vulnerabilities, unsafe deserialization, and more. Running it in CI ensures every change is automatically scanned.

**Fix:**
```ruby
# Gemfile
group :development do
  gem "brakeman"
end
```

---

### GEM-02 `bundler-audit` not in use
**Severity:** High
**Look for:** `bundler-audit` in Gemfile, Gemfile.lock, or CI configuration files
**Fail condition:** Not present anywhere

**Why it matters:** Your dependencies have known CVEs. Bundler-audit cross-references your `Gemfile.lock` against a CVE database and fails if any dependency has a known vulnerability.

**Fix:**
```yaml
# .github/workflows/security.yml
- name: Security Audit
  run: |
    gem install bundler-audit
    bundle-audit check --update
```

---

### GEM-03 Rails version with known CVEs
**Severity:** Critical (if found)
**Look for:** `rails (X.Y.Z)` in `Gemfile.lock`
**Action:** Check against https://www.cvedetails.com/vendor/12043/Rubyonrails.html for the detected version. Only flag if a known CVE applies.

**Why it matters:** Running a Rails version with a known, unpatched CVE is the highest-risk configuration possible.

**Fix:** Update Rails:
```bash
bundle update rails
```

---

## CI — Continuous Integration

### CI-01 No security scanning in CI
**Severity:** High
**Look for:** Brakeman and bundler-audit invocations in `.github/workflows/*.yml`, `Makefile`, or CI scripts
**Fail condition:** Neither tool is run in any CI configuration found

**Why it matters:** Security regressions introduced by a pull request are caught automatically only if scanning runs in CI. Without it, vulnerabilities accumulate silently.

**Fix:**
```yaml
# .github/workflows/security.yml
name: Security

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Brakeman
        run: bundle exec brakeman --no-pager -q
      - name: Bundler Audit
        run: |
          gem install bundler-audit
          bundle-audit check --update
```

---

## DATA — Data Protection

### DATA-01 No column-level encryption for PII
**Severity:** Info
**Look for:** `encrypts` declarations in models, or `attr_encrypted` gem
**Fail condition:** No encryption found AND models appear to store sensitive data (phone, ssn, tax_id, account_number, etc. — look at column names in schema.rb or migrations)

**Why it matters:** If your database is dumped, plaintext PII is immediately readable. Column-level encryption means stolen data is useless without the encryption keys.

**Note:** This is Info severity because it's architectural — not every app needs it, and adding it to an existing app requires a migration. Flag it with context.

**Fix:**
```ruby
class User < ApplicationRecord
  encrypts :phone_number, :tax_id
  encrypts :email_address, deterministic: true  # Allows WHERE queries
end
```

---

### DATA-02 Hardcoded secrets in configuration files
**Severity:** Critical (if found)
**Look for:** API keys, passwords, tokens as string literals in `config/` files (not in `credentials.yml.enc`)
**Pattern:** `/(?:password|secret|key|token)\s*[=:]\s*["'][^'"]{8,}/i` in config files

**Why it matters:** Secrets committed to version control are permanently exposed, even after deletion. Any past contributor, CI system, or fork has access.

**Fix:** Move to encrypted credentials:
```bash
bin/rails credentials:edit
```
```ruby
# Access in code
Rails.application.credentials.my_service_api_key
```

---

## FWKD — Framework Defaults

### FWKD-01 Rails 8.2 CSRF header strategy not opted in
**Severity:** Info
**Look for:** `forgery_protection_verification_strategy` in `new_framework_defaults_8_2.rb` or application config
**Fail condition:** Not set (still using token-based CSRF on a Rails 8.2 app)
**Note:** Only flag if `Gemfile.lock` shows Rails >= 8.2.

**Why it matters:** The `Sec-Fetch-Site` header strategy eliminates stale-token 422 errors from cached pages, removes the need for JavaScript frameworks to manage CSRF tokens, and is browser-enforced (cannot be spoofed by malicious JS).

**Fix:**
```ruby
# config/initializers/new_framework_defaults_8_2.rb
Rails.application.config.action_controller.forgery_protection_verification_strategy = :header_only
# Or use :header_or_legacy_token for a safer migration path
```

---

### FWKD-02 Default CSRF failure mode is `:null_session`
**Severity:** Medium
**Look for:** `default_protect_from_forgery_with` in app config
**Fail condition:** Set to `:null_session` or not set on Rails 8.2 apps

**Why it matters:** `:null_session` silently provides an empty session on CSRF failure. `:exception` raises an error, making failures visible in logs and monitoring.

**Fix:**
```ruby
Rails.application.config.action_controller.default_protect_from_forgery_with = :exception
```

---

### FWKD-03 Active Job not transaction-aware (Rails 8.2)
**Severity:** Info
**Look for:** `enqueue_after_transaction_commit` in config
**Fail condition:** Not set on Rails 8.2 apps that use background jobs for sensitive operations

**Why it matters:** Jobs enqueued inside a transaction may execute against data from a rolled-back transaction — acting on records that no longer exist, potentially causing privilege escalation or data inconsistency in access-control-sensitive jobs.

**Fix:**
```ruby
Rails.application.config.active_job.enqueue_after_transaction_commit = true
```
