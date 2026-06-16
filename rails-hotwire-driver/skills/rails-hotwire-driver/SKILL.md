---
name: rails-hotwire-driver
description: Drive a running local Rails dev server without a browser — log in (incl. OTP/magic-link codes read straight from the log), submit ERB forms with correct CSRF tokens, and inspect Turbo Stream responses — then correlate everything against the development log by request id. Use this whenever the user wants to exercise a Rails app's UI from the terminal with curl instead of a browser, debug Hotwire/Turbo behavior, verify a server-rendered turbo-stream, read OTP or verification codes out of the dev log, follow an authenticated session flow, or trace what a specific request did in the logs. Especially apt for ERB + Hotwire apps with minimal JavaScript. Pairs with the rails-mcp-server (which does static code analysis) by adding live runtime interaction, and bridges sessions to/from Playwright (storageState) so you can log in once and share the authenticated session between curl and a real browser.
---

# Rails Hotwire Driver

Exercise a **running local Rails dev server** from the shell: authenticate, submit
forms, trigger and read Turbo Streams, and read the development log — including
OTP/verification codes that Rails prints to the log in development. This is the
runtime complement to `rails-mcp-server`, which only reads code statically.

## When this fits (and when it doesn't)

Good fit: ERB + Hotwire apps with minimal JavaScript. The server renders HTML and
`text/vnd.turbo-stream.html`; you are verifying that server-rendered contract.

It will **not** execute JavaScript. No Stimulus controllers run, no DOM morphing,
no `requestSubmit`, no ActionCable-broadcast rendering. You *can* see a broadcast
happen in the log (via request-id correlation) but not its DOM effect. For those
residual cases, tell the user a browser-driving tool (e.g. a Playwright MCP) is the
right complement — don't try to fake JS here.

## Prerequisites — confirm before driving

1. The Rails app is **running locally** in development (e.g. `bin/rails s`), and you
   know its port. Set `BASE_URL` (default `http://localhost:3000`). The scripts
   refuse any non-local host (allowed: `localhost`, loopback IPs, and any
   `*.localhost` name).
2. `Nokogiri` is available — it ships with essentially every Rails bundle. Run the
   Ruby script via the project's bundle: `bundle exec ruby .../submit_form.rb`.
3. Recommended for best log correlation: request-id tagging on. In
   `config/environments/development.rb`:
   ```ruby
   config.log_tags = [ :request_id ]
   ```
   Without it, `readlog.sh request` falls back to a context window instead of an
   exact filter — still useful, just noisier.

These scripts only ever talk to a local server and only read the **development**
log. Reading secrets like OTP codes out of a log is a development-only affordance;
`readlog.sh` refuses any path containing `production`.

### kamal-proxy and `*.localhost` hosts

If you front your apps with **kamal-proxy** and reach them at names like
`http://fragua.localhost`, set `BASE_URL=http://fragua.localhost` (with the port if
not 80). The proxy routes by the `Host` header, which curl and `Net::HTTP` send
automatically from the URL — so routing just works as long as the name resolves.

`*.localhost` resolves to loopback automatically on macOS and most browsers, but
**not always on Linux** without an `/etc/hosts` entry or systemd-resolved config.
If a request fails to connect, force resolution to loopback with `RESOLVE`:

```
RESOLVE=1 BASE_URL=http://fragua.localhost:80 req.sh GET /
# connects to 127.0.0.1 but still sends Host: fragua.localhost, so the proxy
# routes to the right app. RESOLVE=10.0.0.5 targets a specific IP instead.
```

`RESOLVE` works for both `req.sh` (via curl `--resolve`) and `submit_form.rb` (via
`Net::HTTP#ipaddr=`); in both cases the `Host` header is preserved for routing.
The log scripts are unaffected — point `LOG_FILE` at the right app's
`log/development.log`, since each app under the proxy has its own log.

## Pairing with Playwright

This skill verifies the **server's contract** (turbo-stream actions, SQL, logs, the
raw HTML before JS runs). Playwright verifies **client behavior** (did Stimulus
wire up, did the stream actually mutate the DOM, did a lazy frame load). They're
complementary; the session bridges between them so you only log in once.

The easiest Playwright to run is the **Playwright MCP** (`npx @playwright/mcp@latest`)
— no test code, the agent drives the browser. The bridge scripts emit the standard
`storageState` format, so they work equally with the MCP, the Node test runner, or
`playwright-ruby-client`. All three need Node available, but it's a dev-only tool —
your NoBuild/Importmaps app is untouched.

### curl → Playwright (the common case)
Authenticate fast with the OTP-from-log trick, then hand the logged-in session to a
real browser. Playwright can't easily read the OTP out of the log, so doing login
here and bridging over is the natural split.
```
flow.sh --email me@x.com --otp-path /session/otp --then-path /   # logs in, fills jar
ruby jar_to_storage.rb --origin http://fragua.localhost > state.json
# then in Playwright: newContext({ storageState: 'state.json' })
# or: npx @playwright/mcp@latest --storage-state state.json
```

### Playwright → curl (reverse)
If a login is too JS-heavy for curl to replay (OAuth popup, Stimulus-driven form),
let Playwright do it through the real UI, export its session, and drop back to the
fast curl + log tools.
```
# in Playwright: await context.storageState({ path: 'state.json' })
ruby storage_to_jar.rb --in state.json     # writes ./.hotwire/cookies.txt
req.sh GET /dashboard                       # now authenticated
```

### Suggested workflow
1. Log in once (curl `flow.sh`, or Playwright if the login needs JS).
2. Bridge the session in the needed direction.
3. Use curl for the fast assertions: server returned the right turbo-stream
   targets, the expected SQL ran, no errors logged (`readlog.sh request <id>`).
4. Use Playwright only for the JS-dependent assertions the curl tools structurally
   can't make.

**Note on `*.localhost`:** Chromium accepts cookies on `localhost`/`*.localhost`
without HTTPS, so the bridge keeps `secure:false` for http origins — matching how
your dev session cookie is set. If you serve dev over https, pass an `https://`
`--origin` and the bridge marks cookies secure.

## The scripts

All live in `scripts/`. Copy this skill's folder into the project (or run the
scripts by absolute path) so the cookie jar and log resolve against the app.
A shared cookie jar at `./.hotwire/cookies.txt` carries the session across calls.

### `scripts/req.sh` — one HTTP request, cookies persisted
```
req.sh GET  /products
req.sh GET  /cart turbo          # Accept: text/vnd.turbo-stream.html
req.sh GET  /messages frame:inbox  # Turbo-Frame: inbox  (load a lazy frame)
req.sh POST /cart/add 'product_id=1&qty=2'
```
Prints response headers (with `X-Request-Id`, and `Set-Cookie` redacted), then the
body (truncated past `MAX_BYTES`, default 100k). Use the printed `X-Request-Id` to
pull that exact request's log lines.

### `scripts/submit_form.rb` — submit a form with the right CSRF token
This is the tool to reach for on any POST/PUT/PATCH/DELETE that goes through an ERB
form. It GETs the page, reads the form's hidden inputs **including
`authenticity_token`**, merges your fields over them, and submits — eliminating the
single most common hand-driving failure (a missing/stale CSRF token). It also
honors Rails' `_method` hidden field for non-POST verbs.
```
bundle exec ruby scripts/submit_form.rb /session/new "email=me@x.com" "password=secret"
bundle exec ruby scripts/submit_form.rb /posts/new "form#new_post" "post[title]=Hi"
```
Reports status, `X-Request-Id`, any redirect `Location`, and — for turbo-stream
responses — a parsed list of `action #target` pairs.

### `scripts/readlog.sh` — read the dev log safely
```
readlog.sh tail 200
readlog.sh grep 'SQL|SELECT' 500
readlog.sh request <x-request-id>   # exact lines for one request (needs log_tags)
readlog.sh otp                      # grep common OTP / magic-link / token patterns
```

### `scripts/flow.sh` — full login → OTP → action in one command
Orchestrates the other three: submits the login form (CSRF handled), reads the OTP
from the log **scoped to the login's request id** (not a blind grep), submits the
OTP, then optionally performs one authenticated action — all sharing the cookie jar
so the action runs logged-in.
```
# OTP / magic-link login, then hit an authenticated page:
flow.sh --email me@x.com --password secret \
        --login-path /session/new \
        --otp-path /session/otp --otp-field code \
        --then-path /dashboard --then-method GET

# Password-only (omit --otp-path to skip the OTP steps):
flow.sh --email me@x.com --password secret --then-path /account

# Authenticated POST through a form (CSRF auto-handled):
flow.sh --email me@x.com --otp-path /session/otp \
        --then-path /posts/new --then-method POST --then-fields 'post[title]=Hi'
```
Key flags: `--login-path` (default `/session/new`), `--login-fields 'k=v&k2=v2'`
for extra login inputs, `--otp-field` (default `code`), `--otp-pattern` (a regex if
your log phrasing is unusual; the default matches "code is 123456", "OTP: 1234",
"code = 9981", "token=224466"), and `--then-accept html|turbo|json`. Set
`RUBY="ruby"` if you're not running inside the app's bundle (default is
`bundle exec ruby`).

### `scripts/jar_to_storage.rb` / `scripts/storage_to_jar.rb` — Playwright bridge
Convert the curl session jar to Playwright `storageState` JSON and back, so you log
in once and share the session across both tools. See **Pairing with Playwright**.
```
ruby jar_to_storage.rb --origin http://fragua.localhost > state.json   # curl -> PW
ruby storage_to_jar.rb --in state.json                                 # PW  -> curl
```

## Core workflows

### Authenticated session
1. `submit_form.rb /session/new "email=..." "password=..."` — token handled for you;
   the session cookie lands in the jar automatically.
2. Subsequent `req.sh` / `submit_form.rb` calls reuse the jar, so you're logged in.
3. If the response was a redirect, follow it with `req.sh GET <Location>`.

### OTP / magic-link login (the log trick)
The one-command version is `flow.sh` (see above). Manually, the steps are:
1. Trigger it: `submit_form.rb /session/new "email=..."` (or the OTP request form).
2. Read the code from the log: `readlog.sh otp` — or, more precisely, take the
   `X-Request-Id` from step 1 and run `readlog.sh request <id>` to see only that
   request's lines, then extract the 6-digit code.
3. Submit it: `submit_form.rb /otp "code=123456"`.
This works because in development the mailer/notifier writes the code to the log
rather than sending real email.

### Verify a Turbo Stream
1. `req.sh POST /cart/add 'product_id=1' turbo` (or `submit_form.rb` for CSRF forms).
2. Read the parsed `action #target` list to confirm the server returned the streams
   you expected (e.g. `replace #cart_summary`, `append #flash`).
3. Correlate render details: `readlog.sh request <X-Request-Id>` shows which
   partials rendered and what SQL ran for that exact response.

### Trace one request end to end
Any `req.sh`/`submit_form.rb` call prints `X-Request-Id`. Feed it to
`readlog.sh request <id>` to get a clean, single-request slice of the log — the most
reliable way to see params, SQL, partial renders, and errors without log noise.

## Guardrails (don't weaken these)
- **Local only.** Both shell scripts reject non-localhost hosts; keep it that way.
- **No production logs.** `readlog.sh` refuses paths containing `production`.
- **Don't echo cookies.** `req.sh` redacts `Set-Cookie`; the session value never
  needs to enter the transcript. Report auth state, not the cookie.
- **Don't route this through the rails-mcp-server `execute_ruby` sandbox** — that
  sandbox blocks network on purpose. These scripts are a deliberately separate,
  narrowly-scoped affordance.

## Config (env vars)
- `BASE_URL`  — default `http://localhost:3000`. For kamal-proxy use the routed
  name, e.g. `http://fragua.localhost`.
- `RESOLVE`   — force the host to resolve to an IP when `*.localhost` doesn't
  resolve on its own. `RESOLVE=1` → `127.0.0.1`; `RESOLVE=<ip>` → that IP. Host
  header is preserved either way.
- `JAR`       — cookie jar path, default `./.hotwire/cookies.txt`
- `LOG_FILE`  — default `./log/development.log` (point at the specific app's log)
- `MAX_BYTES` — response body cap for `req.sh`, default `100000`
