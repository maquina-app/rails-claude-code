# Security Checks Catalog

Full catalog of checks for the Rails Security Auditor. Organized by category, each check includes what to look for, the severity, why it matters, and the exact fix.

## Reading the app's configuration

Apply these three rules to every check below.

- **Two config spellings.** Current Rails guides write settings as `Rails.app.config.x`; older apps use `Rails.application.config.x` or, inside `config/application.rb` and the environment files, plain `config.x`. All three are the same setting — match any of them, in `config/application.rb`, `config/environments/*.rb`, and `config/initializers/*.rb`.
- **A default is not a finding.** Many protections are on unless the app turns them off (CSRF protection, the default security headers, `HttpOnly` and `SameSite=Lax` on the session cookie). A setting that is simply absent means the default applies — pass the check. Fail only when the app removes or weakens the default.
- **Defaults follow `load_defaults`, not the installed gem.** Read `config.load_defaults X.Y` in `config/application.rb`. An app can run the Rails 8.2 gem with `load_defaults 8.0`, in which case it does **not** have the 8.2 defaults until it sets them (usually in `config/initializers/new_framework_defaults_8_2.rb`). Report both versions when they differ.

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
11. [STOR — File Uploads & Active Storage](#stor--file-uploads--active-storage)
12. [FWKD — Framework Defaults](#fwkd--framework-defaults)

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
**Look for:** `filter_parameters` in `config/initializers/filter_parameter_logging.rb`, `config/application.rb`, or `config/environments/production.rb`; and `filter_redirect` in the same places
**Fail condition:** The list is missing, emptied, or shorter than the list Rails generates (below) — or the app handles values that none of the entries match (card numbers, API keys, national IDs)

**Why it matters:** Parameters not matched by this list are written to the log in plaintext. The same list also masks attributes in `inspect` output, so it protects what gets sent to error trackers. Entries are partial matches: `:passw` covers `password` and `password_confirmation`, `:_key` covers `api_key`.

**Fix:**
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
```

**Also check `filter_redirect` (Info):** if the app redirects to URLs that carry secrets — presigned storage URLs, magic-link or password-reset tokens in the query string — those URLs are logged in full unless filtered.
```ruby
Rails.application.config.filter_redirect += ["s3.amazonaws.com", /token/]
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

### PROD-06 No allowed hosts in production
**Severity:** Medium
**Look for:** `config.hosts` (`config.hosts <<`, `config.hosts =`, `config.hosts.concat`) and `config.host_authorization` in `config/environments/production.rb`, `config/application.rb`, or an initializer
**Fail condition:** No host is configured for production, or `config.hosts.clear` / `config.hosts = nil` is set. Also fail if `config.hosts.clear` appears in `config/environments/development.rb`.

**Why it matters:** `ActionDispatch::HostAuthorization` rejects requests whose `Host` header is not on the list. It is on in development but does nothing in production until hosts are listed. Without it the app answers for any hostname pointed at its IP, which enables DNS rebinding and lets a forged `Host` header leak into generated URLs — password-reset links being the classic case.

**Note:** If a proxy in front of the app already rejects unknown hostnames (kamal-proxy with `host:` set, Cloudflare), report this as "Verify:" rather than a failure. Exclude the health check path so load balancer probes by IP still pass.

**Fix:**
```ruby
# config/environments/production.rb
config.hosts << "app.example.com"
config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
```

---

### PROD-07 Multipart encoding hardening turned off
**Severity:** High
**Look for:** `config.action_dispatch.allow_rack_multipart_encoding`
**Fail condition:** Set to `true`

**Why it matters:** Rails patches Rack so multipart form data is accepted only as UTF-8 or binary. Parts submitted in arbitrary encodings have been used as a step in exploit chains. The setting defaults to `false`; it exists in Rails 8.2 and was backported to the 8.1 and 8.0 branches. Setting it to `true` removes the protection.

**Fix:** Delete the line. If a client really does send another encoding, transcode in the one endpoint that needs it rather than opting the whole app out.

---

## CSRF — Cross-Site Request Forgery

### CSRF-01 CSRF protection disabled
**Severity:** Critical
**Look for:**
- `config.action_controller.default_protect_from_forgery = false`
- `config.action_controller.allow_forgery_protection = false` outside `config/environments/test.rb`
- `skip_forgery_protection` or `skip_before_action :verify_authenticity_token` in `app/controllers/`

**Fail condition:** Any of the first two; or a skip in `ApplicationController`; or a skip in a controller that is reached with the browser session cookie.

**Pass condition:** None of the above. `protect_from_forgery` does **not** need to appear in `ApplicationController` — `default_protect_from_forgery` has been `true` since `load_defaults 5.2`, so `ActionController::Base` is protected with no code at all. Only apps on `load_defaults` below 5.2 need the explicit call.

**Why it matters:** Without CSRF protection, any website can submit forms on behalf of your logged-in users — changing emails, deleting data, moving money.

**Note:** A skip is legitimate on endpoints that do not authenticate with the session cookie: webhook receivers that verify a signature, and API controllers using token auth. Report those as "Verify:" and name what authenticates the request. Turning `default_protect_from_forgery` off also used to drop protection from the Active Storage controllers; newer releases keep it there regardless.

**Fix:** Remove the line that disables it. For a skip that is too broad, narrow it to the action that needs it:
```ruby
class WebhooksController < ApplicationController
  skip_forgery_protection only: :create   # request is verified by signature instead
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

### HDR-01 `X-Frame-Options` removed or too permissive
**Severity:** High
**Look for:** `X-Frame-Options` in any `config.action_dispatch.default_headers` assignment, `.delete`, or `.tap` block
**Fail condition:** The app removes it (`default_headers.delete("X-Frame-Options")`), replaces the whole `default_headers` hash without it, or sets `ALLOWALL`. If `default_headers` is never touched, Rails sends `SAMEORIGIN` — pass.
**Note:** Removing the header is fine when the CSP sets `frame_ancestors`, which supersedes it. Report as "Verify:" in that case.

**Why it matters:** Without this header, any website can embed your app in an invisible iframe and trick users into clicking your buttons (clickjacking).

**Fix:**
```ruby
# config/application.rb
config.action_dispatch.default_headers["X-Frame-Options"] = "SAMEORIGIN"
# Or use DENY if you never legitimately embed your app in iframes
config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"
```

---

### HDR-02 `X-Content-Type-Options` removed or changed
**Severity:** Medium
**Look for:** `X-Content-Type-Options` in any `default_headers` assignment or `.delete`
**Fail condition:** The app removes it, replaces the whole `default_headers` hash without it, or sets something other than `nosniff`. Untouched defaults send `nosniff` — pass.

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

**Why it matters:** All major browsers removed the XSS auditor this header controlled. The header is now a no-op at best, and at worst can be exploited to selectively block legitimate scripts. `load_defaults 7.0` set it to `0`; `load_defaults 8.2` removes it from the defaults entirely.

**Fix:**
```ruby
# Remove it entirely, or set to 0 to explicitly disable
config.action_dispatch.default_headers.delete("X-XSS-Protection")
```

---

### HDR-04 `Referrer-Policy` removed or too permissive
**Severity:** Medium
**Look for:** `Referrer-Policy` in any `default_headers` assignment or `.delete`
**Fail condition:** The app removes it, replaces the whole `default_headers` hash without it, or sets `unsafe-url` or `no-referrer-when-downgrade`. Untouched defaults send `strict-origin-when-cross-origin` — pass.

**Why it matters:** Without a strict referrer policy, your app's URLs (including tokens in query strings) are sent to third-party sites users navigate to.

**Fix:**
```ruby
config.action_dispatch.default_headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
# For maximum privacy:
config.action_dispatch.default_headers["Referrer-Policy"] = "no-referrer"
```

---

### HDR-05 `X-Permitted-Cross-Domain-Policies` removed or loosened
**Severity:** Info
**Look for:** `X-Permitted-Cross-Domain-Policies` in any `default_headers` assignment or `.delete`
**Fail condition:** The app removes it, replaces the whole `default_headers` hash without it, or sets a value other than `none`. Untouched defaults send `none` — pass.

**Why it matters:** The header tells clients such as Adobe Acrobat whether they may load data from your domain across origins. `none` forbids it. This is a legacy vector, hence Info, but there is rarely a reason to loosen it.

**Fix:**
```ruby
config.action_dispatch.default_headers["X-Permitted-Cross-Domain-Policies"] = "none"
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

### CSP-05 `'strict-dynamic'` used in a Turbo app
**Severity:** High
**Look for:** `:strict_dynamic` or `'strict-dynamic'` in the CSP initializer, together with `turbo-rails` in `Gemfile.lock`
**Fail condition:** Both present

**Why it matters:** Turbo inserts the `<script>` tags it receives with `createElement`. `'strict-dynamic'` trusts any script inserted that way, with or without a nonce. An injected script that a nonce-based policy would block on a full page load therefore runs after a Turbo navigation.

**Fix:** Remove `:strict_dynamic` and allowlist script sources explicitly.
```ruby
policy.script_src :self, :https
```

---

### CSP-06 Per-request CSP nonce in a Turbo app
**Severity:** Medium
**Look for:** `content_security_policy_nonce_generator` in the CSP initializer, together with `turbo-rails` in `Gemfile.lock`
**Fail condition:** The generator returns a fresh random value on every request, e.g. `->(request) { SecureRandom.base64(16) }`

**Why it matters:** The browser fixes the CSP when the document first loads, and Turbo navigations do not reload the document. A nonce that changes per request stops matching after the first Turbo visit, so inline scripts break — and the usual "fix" is to add `:unsafe_inline`. Per-request nonces also change the ETag on every response, defeating conditional GET caching.

**Fix:** Derive the nonce from the session so it is stable for the life of the document.
```ruby
Rails.application.config.content_security_policy_nonce_generator = ->(request) {
  request.session[:nonce] ||= SecureRandom.base64(16)
}
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
```

**Note:** `csp_meta_tag` in the layout lets Turbo copy the nonce onto every script it loads, including one injected through an XSS hole. Mention this trade-off when the app has `csp_meta_tag`; do not fail on it.

---

## SESS — Session Configuration

### SESS-01 Session cookie `SameSite` weakened
**Severity:** High
**Look for:** `same_site:` in the `session_store` call (`config/initializers/session_store.rb` or `config/application.rb`), and `config.action_dispatch.cookies_same_site_protection`
**Fail condition:** Set to `:none`, `nil`, or `false`
**Pass condition:** `:lax`, `:strict`, or not set. Rails sends `SameSite=Lax` on the session cookie by default, and Lax is the baseline the Rails security guide documents.

**Why it matters:** `SameSite` decides whether the browser attaches the session cookie to requests that start on another site. With `None` (or no attribute) a form or `fetch` on an attacker's page is sent with the victim's session, leaving the CSRF token as the only defence.

**Note:** `:strict` goes further — the cookie is also withheld when a user follows a link from another site, so they arrive signed out. Suggest it as an Info-level hardening for apps that are never entered from external links; do not fail an app for using `:lax`. Apps on a non-cookie session store (`:cache_store`, Active Record, Redis) running a Rails release below the floor in GEM-03 may be missing the attribute entirely; that is fixed by upgrading.

**Fix:**
```ruby
Rails.application.config.session_store :cookie_store,
  key:       "_myapp_session",
  same_site: :lax
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

### AUTH-04 Login looks up the user before checking the password
**Severity:** Medium
**Look for:** `find_by(...)&.authenticate(...)` or `find_by(...)` followed by `&& user.authenticate(...)` in `app/controllers/` (sessions, API token, and password-change controllers)
**Fail condition:** Present, on an app that uses `has_secure_password`

**Why it matters:** When no user matches, the lookup returns `nil` and the password hash is never computed, so the response comes back measurably faster. An attacker can time responses to learn which email addresses have accounts. `authenticate_by` (Rails 7.1+) hashes the password either way.

**Fix:**
```ruby
# Wrong
user = User.find_by(email_address: params[:email_address])
if user&.authenticate(params[:password])

# Right
if user = User.authenticate_by(params.permit(:email_address, :password))
```

**Note:** Not applicable to passwordless auth or to apps that delegate login to Devise or Rodauth.

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

### GEM-03 Rails version below the patched release
**Severity:** Critical
**Look for:** `rails (X.Y.Z)` in `Gemfile.lock`
**Fail condition:** The version is below the fixed release for its branch, or the branch no longer receives security fixes.

**Version floors — last updated 2026-11-21.** These go stale with every security release; when the audit date is well past this one, also check https://rubyonrails.org/category/releases for anything newer.

| Branch | Minimum safe version | Status |
|--------|----------------------|--------|
| 8.1 | `8.1.4.1` | Supported |
| 8.0 | `8.0.5.2` | Security support ended 2026-11-07 — no further fixes |
| 7.2 and earlier | none | Not patched by the 2026-11-04 release; treat as unsupported and confirm at https://rubyonrails.org/maintenance |

Apps tracking `main` or an 8.2 pre-release must be on a revision from after 2026-11-04.

**Why it matters:** The 2026-11-04 release fixed 21 vulnerabilities. The worst are in Active Storage: arbitrary file write and read during image analysis (GHSA-f3w6-w445-fwh9, Critical) and file read plus remote code execution through video previews and image processing (GHSA-v924-7rp8-4mxh, High). The same release fixes a Strong Parameters bypass via `Parameters#each_key` (GHSA-wm3x-v3qw-4jh3), client IP spoofing through the `Forwarded` header on 8.1 (GHSA-2gff-2mmg-m73p), several XSS holes in Action View helpers, destroyed sessions that could be restored from the cache store (GHSA-2586-8ghr-69fj), and session cookies sent without `SameSite` by some session stores (GHSA-gmj8-hvj3-49mw). An app that accepts uploads is exposed to the first two with no configuration mistake on its part.

**Reporting:**
- Below the floor on a supported branch → Critical.
- At the floor on a branch whose support has ended (8.0) → High: patched today, but the next vulnerability will not be fixed. Recommend moving to 8.1.
- Below the floor on an unsupported branch → Critical, and the fix is a branch upgrade, not a patch bump.

**Fix:**
```bash
bundle update rails --conservative   # then confirm the version in Gemfile.lock
```
For a branch upgrade (8.0 → 8.1), follow the Rails upgrade guide rather than only bumping the version.

---

### GEM-04 Ruby version with known vulnerabilities
**Severity:** Critical
**Look for:** the Ruby version everywhere it is pinned:
- `.ruby-version`
- the `ruby` line in `Gemfile` and `RUBY VERSION` in `Gemfile.lock`
- `.tool-versions`, `mise.toml` / `.mise.toml`
- `ARG RUBY_VERSION=` and `FROM ruby:` in `Dockerfile`
- `ruby-version:` in `.github/workflows/*.yml`

**Fail condition:** Any pinned version is below the fixed release for its branch, or is on a branch that has reached end of life.

**Version floors — last updated 2026-11-21.** Check https://www.ruby-lang.org/en/news/ for newer releases when the audit date is well past this one.

| Branch | Vulnerable | Minimum safe version | Status |
|--------|------------|----------------------|--------|
| 4.0 | 4.0.0 – 4.0.9 | `4.0.10` | Supported |
| 3.4 | 3.4.0 – 3.4.12 | `3.4.13` | Supported |
| 3.3 | 3.3.13 and earlier | `3.3.14` | Legacy maintenance; support ends March 2027 |
| 3.2 and earlier | all | none | End of life — will not be fixed |

**Why it matters:** The 2026-11-18 releases fix seven memory-safety bugs in Ruby's regular expression engine and in string case conversion. Six can lead to remote code execution and the Ruby team reports working proofs of concept. Two are in case conversion itself (GHSA-34m4-m9fh-gqp5, GHSA-87fm-7w84-j2px), so calling `upcase`, `downcase`, or `capitalize` on a crafted string is enough — something nearly every Rails app does with user input. The others need an attacker-influenced regular expression. The bugs are in Ruby itself, so no gem update fixes them and no workaround exists. CVE identifiers had not been assigned when this was written; the advisory uses GHSA identifiers.

**Sources disagree:** When the pinned versions differ, report each one. The `Dockerfile` decides what runs in production, so a patched `.ruby-version` next to an old `FROM ruby:` or `ARG RUBY_VERSION` is still a Critical finding. A version given only as a branch (`ruby "~> 3.4"`, `FROM ruby:3.4`) cannot be confirmed from the files — report "Verify:" and ask the user to run `ruby -v` in the deployed image.

**Fix:** Change the version in every file that pins it, then rebuild and redeploy the image.
```bash
echo "3.4.13" > .ruby-version
# Dockerfile:  ARG RUBY_VERSION=3.4.13
bundle install   # refreshes RUBY VERSION in Gemfile.lock
```

---

### GEM-05 JavaScript packages pinned with importmap are not audited
**Severity:** Medium
**Look for:** `config/importmap.rb`, and an `importmap audit` invocation in `bin/ci`, `.github/workflows/*.yml`, or other CI scripts
**Fail condition:** `config/importmap.rb` pins packages and nothing runs `bin/importmap audit`
**Note:** Not applicable to apps without importmap. For apps that bundle with npm, yarn, or bun, look for the matching audit command (`npm audit`, `yarn npm audit`, `bun audit`) instead.

**Why it matters:** bundler-audit only reads `Gemfile.lock`. Packages pinned in the importmap are dependencies too, and a vulnerable one ships straight to every browser.

**Fix:**
```yaml
- name: Importmap audit
  run: bin/importmap audit
```

---

## CI — Continuous Integration

### CI-01 No security scanning in CI
**Severity:** High
**Look for:** Brakeman and bundler-audit invocations in `.github/workflows/*.yml`, `bin/ci`, `config/ci.rb`, `Makefile`, or CI scripts
**Fail condition:** Neither tool is run in any CI configuration found

**Why it matters:** Security regressions introduced by a pull request are caught automatically only if scanning runs in CI. Without it, vulnerabilities accumulate silently.

**Also check (Info):** Brakeman is run without `--ensure-latest`. An old Brakeman does not know about recent vulnerability classes; `--ensure-latest 3` fails the run when the installed version is more than three days behind the newest release, so the scanner cannot quietly go stale.

**Fix:**
```yaml
# .github/workflows/security.yml
name: Security

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<full-commit-sha> # v4
        with:
          persist-credentials: false
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Brakeman
        run: bundle exec brakeman --no-pager -q --ensure-latest 3
      - name: Bundler Audit
        run: |
          gem install bundler-audit
          bundle-audit check --update
```

---

### CI-02 GitHub Actions workflows not hardened
**Severity:** Medium
**Look for:** every `uses:` line and every `actions/checkout` step in `.github/workflows/*.yml`
**Fail condition:** Either of:
- an action is referenced by tag or branch (`@v4`, `@main`) instead of a full 40-character commit SHA
- an `actions/checkout` step does not set `persist-credentials: false`

**Why it matters:** A tag can be moved to different code after you reviewed it; if an action's repository is compromised, every workflow using `@v4` runs the attacker's code with your secrets on the next build. A commit SHA cannot be changed. Separately, `actions/checkout` leaves the repository token in `.git/config` by default, where any later step — including a compromised dependency's install script — can read it and push.

**Note:** Rails' own generated workflow pins everything to a SHA except `ruby/setup-ruby`, which is left on its tag so new Ruby versions keep working. Do not fail on `ruby/setup-ruby@v1`. A workflow that must push (release, deploy) legitimately needs the credentials — report "Verify:".

**Fix:**
```yaml
- uses: actions/checkout@<full-commit-sha> # v4
  with:
    persist-credentials: false
```
Look the SHA up on the action's releases page and keep the version in a trailing comment so Dependabot can update it.

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

### DATA-03 Credentials key committed to the repository
**Severity:** Critical
**Look for:** run `git ls-files config/master.key 'config/credentials/*.key'`, and check `.gitignore` for `/config/master.key` and `/config/credentials/*.key`
**Fail condition:** Any key file is tracked by git. If the files are untracked but missing from `.gitignore`, report Medium instead — one `git add .` away from a leak.

**Why it matters:** The key decrypts `credentials.yml.enc`, which is committed on purpose. With both in the repository, everyone with read access — and anyone who ever obtains a clone — has every secret in it, including `secret_key_base`, which lets them forge session cookies.

**Fix:** Removing the file is not enough, because it stays in git history. Treat every secret in the file as leaked.
```bash
git rm --cached config/master.key
echo "/config/master.key" >> .gitignore
echo "/config/credentials/*.key" >> .gitignore
```
Then rotate each secret stored in the credentials file at its provider, generate a new `secret_key_base`, and re-encrypt the file with a new key. Supply the new key to production through `RAILS_MASTER_KEY`.

---

### DATA-04 Production secrets share the development credentials file
**Severity:** Info
**Look for:** `config/credentials/production.yml.enc`
**Fail condition:** `config/credentials.yml.enc` exists and there is no `config/credentials/production.yml.enc`
**Note:** Report as "Verify:". Apps that keep production secrets entirely in environment variables or a secret manager have nothing to split.

**Why it matters:** With a single credentials file, every developer who can run the app locally holds the key that decrypts the production secrets. A separate production file has its own key, which only the deploy environment needs.

**Fix:**
```bash
bin/rails credentials:edit --environment production
```
This creates `config/credentials/production.yml.enc` and `config/credentials/production.key`. Keep the key out of git and set `RAILS_MASTER_KEY` to its value in production.

---

## STOR — File Uploads & Active Storage

### STOR-01 ffmpeg and ffprobe accept every codec
**Severity:** High
**Look for:**
- Active Storage in use: `config/storage.yml`, and `has_one_attached` / `has_many_attached` in `app/models/`
- ffmpeg present in the deployed image: `ffmpeg` in `Dockerfile`, `Aptfile`, or a deploy script
- `config.active_storage.video_preview_input_arguments` and `config.active_storage.ffprobe_arguments`

**Fail condition:** Active Storage is in use, ffmpeg is installed, and neither argument is set.
**Not applicable:** Active Storage is unused, or ffmpeg is not installed (without the binaries nothing is decoded). If you cannot tell whether ffmpeg is installed, report "Verify:".

**Why it matters:** Active Storage analyzes every blob when it is uploaded, and uses `ffprobe` for video and audio metadata and `ffmpeg` for video previews. Both are large C programs with several hundred decoders and demuxers, and they read whatever bytes an attacker uploads — the app does not need a video feature for this to happen, only an upload field. Restricting them to the few formats the app really accepts removes most of that attack surface.

**Fix:** List only the codecs the app supports, audio included.
```ruby
# config/environments/production.rb
config.active_storage.video_preview_input_arguments = "-codec_whitelist h264,aac"
config.active_storage.ffprobe_arguments             = "-codec_whitelist h264,aac"
```
`-f` forces a single container format and `-protocol_whitelist` limits the protocols an input may reference. A file using any other codec then fails analysis (`JSON::ParserError`), so check the names against `ffmpeg -decoders` for the build you deploy and try the change with real uploads before enforcing it.

**Note:** This narrows exposure; it does not replace GEM-03. The Active Storage vulnerabilities fixed on 2026-11-04 need the Rails upgrade.

---

## FWKD — Framework Defaults

### FWKD-01 Header-based CSRF verification not adopted on Rails 8.2
**Severity:** Info
**Look for:** `forgery_protection_verification_strategy` in `new_framework_defaults_8_2.rb` or application config, and the `load_defaults` version
**Fail condition:** The app runs Rails >= 8.2 with `load_defaults` below 8.2 and has not set the strategy
**Pass condition:** `load_defaults 8.2` (the default is then `:header_only`), or the strategy is set explicitly
**Note:** Only applies when `Gemfile.lock` shows Rails >= 8.2.

**Why it matters:** Rails 8.2 can verify requests with the browser-supplied `Sec-Fetch-Site` header instead of an authenticity token. That removes stale-token 422 errors from cached pages, and page JavaScript cannot forge the header. Apps that have not adopted the 8.2 defaults run `:header_or_legacy_token`, which checks the header and falls back to the token when it is missing.

**Fix:**
```ruby
# config/initializers/new_framework_defaults_8_2.rb
Rails.application.config.action_controller.forgery_protection_verification_strategy = :header_only
```
`:header_only` rejects requests that arrive without the header, so confirm that non-browser clients using cookie auth still work. Rails 8.2 also deprecates `ActionController::InvalidAuthenticityToken` in favor of `InvalidCrossOriginRequest` — update any `rescue_from` that names the old class.

---

### FWKD-02 Bare `protect_from_forgery` falls back to `:null_session`
**Severity:** Medium
**Look for:** `protect_from_forgery` called without `with:` in `app/controllers/`, and `default_protect_from_forgery_with` in app config
**Fail condition:** A bare `protect_from_forgery` call exists, and the app neither sets `default_protect_from_forgery_with = :exception` nor uses `load_defaults 8.2`
**Pass condition:** No explicit `protect_from_forgery` call at all (the automatic protection from `default_protect_from_forgery` raises an exception), or every call passes `with:`

**Why it matters:** The protection Rails adds automatically uses `:exception`, but calling `protect_from_forgery` yourself without `with:` has always meant `:null_session` — the action still runs, with an empty session, and nothing is logged. Adding the call to be "explicit" therefore weakens the app. Rails 8.2 deprecates the bare call and `load_defaults 8.2` changes its meaning to `:exception`.

**Fix:**
```ruby
# Either pass the strategy at the call site
protect_from_forgery with: :exception

# or change what the bare call means, app-wide
Rails.application.config.action_controller.default_protect_from_forgery_with = :exception
```

---

### FWKD-03 Jobs enqueued before the transaction commits (Rails 8.2)
**Severity:** Info
**Look for:** `enqueue_after_transaction_commit` in app config and in job classes
**Fail condition:** The app runs Rails >= 8.2 with `load_defaults` below 8.2 and has not set it; or it is set to `false` globally or on a job that performs access-control-sensitive work
**Note:** Only applies on Rails >= 8.2. The setting was deprecated in 8.0 and had no effect in 8.1; 8.2 restores it as a boolean, and `load_defaults 8.2` sets it to `true`.

**Why it matters:** A job enqueued inside a transaction can start before the transaction commits, or after it rolls back. It then acts on records that do not exist or on state that was never saved — sending a notification for a change that was rejected, or granting access based on a membership that was rolled back.

**Fix:**
```ruby
Rails.application.config.active_job.enqueue_after_transaction_commit = true
```

---

### FWKD-04 Association scopes can drop the owner condition (Rails 8.2)
**Severity:** Medium
**Look for:** `config.active_record.association_scope_keeps_owner_conditions` in app config, the `load_defaults` version, and association scopes in `app/models/` that call `unscope(:where)`, `unscope(where: ...)`, or `rewhere`
**Fail condition:** The app runs Rails >= 8.2 with `load_defaults` below 8.2 and has not set the option to `true`. Raise to High when a model has an association scope using `unscope` or `rewhere`.
**Note:** Only applies on Rails >= 8.2, where the option exists. On older versions, still report any association scope using `unscope(:where)` or `rewhere` as "Verify:".

**Why it matters:** An association is tied to its owner by a foreign key condition (and a type condition for polymorphic `as:` associations). A scope such as `-> { unscope(:where) }` removes that condition along with whatever it meant to remove, so `owner.things` returns every row in the table — and `owner.things.delete_all`, `update_all`, or `dependent: :delete_all` reach other owners' records. In a multi-tenant app that is a cross-tenant data leak or deletion. With the option on, the owner conditions are always applied.

**Fix:**
```ruby
# config/initializers/new_framework_defaults_8_2.rb
Rails.application.config.active_record.association_scope_keeps_owner_conditions = true
```
Without it, Rails 8.2 keeps the old behaviour and logs a deprecation warning for each affected association. Review those associations before switching: one that relied on escaping the owner condition will return fewer records afterwards.
