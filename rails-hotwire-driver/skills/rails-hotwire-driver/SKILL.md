---
name: rails-hotwire-driver
description: Drive a running local Rails dev server without a browser — log in (incl. OTP/magic-link codes read straight from the log), submit ERB forms with correct CSRF tokens, and inspect Turbo Stream responses — then correlate everything against the development log by request id. Optionally pairs with the agent-browser CLI for the JS-dependent residual — full-page/scoped/device screenshots, visual regression diffing, waiting on Turbo events or DOM conditions instead of guessing timeouts, Stimulus controller introspection, structural (accessibility-tree) diffs around a Turbo action, and console/error capture. Use this whenever the user wants to exercise a Rails app's UI from the terminal with curl instead of a browser, debug Hotwire/Turbo behavior, verify a server-rendered turbo-stream, read OTP or verification codes out of the dev log, follow an authenticated session flow, trace what a specific request did in the logs, screenshot a page or Turbo Frame, wait for a broadcast to land, or inspect Stimulus controller state. Especially apt for ERB + Hotwire apps with minimal JavaScript. Pairs with the rails-mcp-server (which does static code analysis) by adding live runtime interaction, and bridges sessions to/from Playwright or agent-browser (storageState) so you can log in once and share the authenticated session between curl and a real browser.
---

# Rails Hotwire Driver

Exercise a **running local Rails dev server** from the shell: authenticate, submit
forms, trigger and read Turbo Streams, and read the development log — including
OTP/verification codes that Rails prints to the log in development. This is the
runtime complement to `rails-mcp-server`, which only reads code statically.

## When this fits (and when it doesn't)

Good fit: ERB + Hotwire apps with minimal JavaScript. The server renders HTML and
`text/vnd.turbo-stream.html`; you are verifying that server-rendered contract.

The core scripts (`req.sh`, `submit_form.rb`, `readlog.sh`, `flow.sh`) will **not**
execute JavaScript, by design — no Stimulus controllers run, no DOM morphing, no
`requestSubmit`, no ActionCable-broadcast rendering. Don't try to fake JS here.

For the JS-dependent residual, this skill also ships a thin layer of **optional**
scripts around the [agent-browser](https://github.com/vercel-labs/agent-browser)
CLI — see **Pairing with a browser** below. They cover the common cases
(screenshots, waiting for a broadcast to actually update the DOM, Stimulus
controller state, structural diffs) without reaching for a separate MCP or writing
Playwright test code. Anything past that — full end-to-end flows, cross-browser
testing — is still better served by a dedicated browser-testing tool.

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

## Pairing with a browser: agent-browser (or Playwright)

This skill verifies the **server's contract** (turbo-stream actions, SQL, logs, the
raw HTML before JS runs). A real browser verifies **client behavior** (did Stimulus
wire up, did the stream actually mutate the DOM, did a lazy frame load). They're
complementary; the session bridges between them so you only log in once.

The default choice is the **agent-browser CLI** — the browser scripts below wrap it
directly, and it's what the rest of this section assumes. Playwright (e.g. the
Playwright MCP, `npx @playwright/mcp@latest`) still works exactly the same way if
that's what's already installed: the bridge scripts emit the standard `storageState`
format, which both consume identically. Pick one; don't run both against the same
app at once (each maintains its own idea of "the session").

### Prerequisites for the browser scripts (optional)

The core scripts above have zero dependencies beyond curl/Ruby. The browser scripts
need agent-browser installed separately:
```
npm install -g agent-browser
agent-browser install            # downloads its own Chrome for Testing, first run only
agent-browser install --with-deps  # Linux: also installs system libs (fonts, GTK, etc.)
```
If you already have Chrome, Brave, Playwright, or Puppeteer installed, `agent-browser
install` detects and reuses it instead of downloading a second copy. None of this is
needed for the core curl scripts — only for `screenshot.sh` and the other scripts
listed under **Browser scripts** below.

### curl → browser (the common case)
Authenticate fast with the OTP-from-log trick, then hand the logged-in session to a
real browser. The browser can't easily read the OTP out of the log, so doing login
here and bridging over is the natural split.
```
flow.sh --email me@x.com --otp-path /session/otp --then-path /   # logs in, fills jar
ruby jar_to_storage.rb --origin http://fragua.localhost > state.json
# agent-browser: agent-browser --state state.json open http://fragua.localhost
# Playwright:    newContext({ storageState: 'state.json' })
#                or: npx @playwright/mcp@latest --storage-state state.json
```
The browser scripts (`screenshot.sh`, `screenshot-diff.sh`, `dom-diff.sh`) do this
bridging step automatically from `JAR` — you don't need to run it by hand for those.

### browser → curl (reverse)
If a login is too JS-heavy for curl to replay (OAuth popup, Stimulus-driven form),
let the browser do it through the real UI, export its session, and drop back to the
fast curl + log tools.
```
# agent-browser: agent-browser --session x state save state.json
# Playwright:    await context.storageState({ path: 'state.json' })
ruby storage_to_jar.rb --in state.json     # writes ./.hotwire/cookies.txt
req.sh GET /dashboard                       # now authenticated
```

### Suggested workflow
1. Log in once (curl `flow.sh`, or the browser if the login needs JS).
2. Bridge the session in the needed direction.
3. Use curl for the fast assertions: server returned the right turbo-stream
   targets, the expected SQL ran, no errors logged (`readlog.sh request <id>`).
4. Use the browser scripts (or Playwright) only for the JS-dependent assertions the
   curl tools structurally can't make — see **Core workflows** for the common ones.

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

### `scripts/jar_to_storage.rb` / `scripts/storage_to_jar.rb` — browser session bridge
Convert the curl session jar to `storageState` JSON (agent-browser's `--state`,
or Playwright's `newContext`) and back, so you log in once and share the session
across tools. See **Pairing with a browser**.
```
ruby jar_to_storage.rb --origin http://fragua.localhost > state.json   # curl -> browser
ruby storage_to_jar.rb --in state.json                                 # browser  -> curl
```

### Browser scripts (optional — require agent-browser)

`npm install -g agent-browser && agent-browser install` (see **Prerequisites for
the browser scripts** above). All of these bridge the cookie jar automatically,
enforce the same local-only guardrail as the curl scripts, and derive a stable
`SESSION` name from `BASE_URL`'s host so repeated calls reuse the same
already-open browser instead of relaunching one each time.

#### `scripts/screenshot.sh` — full-page, scoped, device, or dark/light screenshots
```
screenshot.sh /cart                                   # full page
screenshot.sh /cart '#cart_summary' cart.png           # approximate crop to an element
screenshot.sh --device "iPhone 14" /cart               # device emulation
screenshot.sh --media dark /cart                       # dark mode
screenshot.sh --close                                  # shut down the browser session
```
No selector → full page. With a selector → sizes the viewport to the element's
bounding box (an approximation, not a pixel-exact crop). `--device` overrides that
and just frames on the element instead, since a device profile already fixes the
viewport. Waits on `domcontentloaded`, not `networkidle` — Hotwire apps hold an
open ActionCable connection, so `networkidle` can hang for the full timeout.

#### `scripts/screenshot-diff.sh` — visual regression against a saved baseline
```
screenshot-diff.sh save    /dashboard baselines/dashboard.png
screenshot-diff.sh compare /dashboard baselines/dashboard.png
```
Deliberately separate from `screenshot.sh`: a pixel diff is only meaningful with a
**fixed** viewport (`VIEWPORT`, default `1280x800`) across both runs, which
conflicts with `screenshot.sh`'s crop-to-element behavior.

#### `scripts/turbo-wait.sh` — wait for a Turbo event or DOM condition
```
turbo-wait.sh dom "document.querySelector('#cart_summary')?.textContent.includes('3 items')"
turbo-wait.sh arm 'turbo:before-stream-render'          # arm BEFORE the trigger
bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1"
turbo-wait.sh for 'turbo:before-stream-render' 8000
```
`dom` polls a JS boolean expression — the recommended default, no race condition.
`arm`/`for` listen for a named Turbo event but **must be armed before** the
triggering action, or a one-shot event fired before the listener attaches is
missed. Replaces guessing a fixed sleep for "did the broadcast actually land".

#### `scripts/stimulus.sh` — introspect connected Stimulus controllers
```
stimulus.sh tree                # every connected controller: identifier, element
stimulus.sh inspect cart-item   # targets + values for one, by identifier or index
```
Reads `window.Stimulus.controllers` (the default Rails `stimulus:install` output)
plus each controller's static `targets`/`values`. Set `STIMULUS_GLOBAL` if you
exposed it under a different name.

#### `scripts/dom-diff.sh` — structural diff around a Turbo action
```
dom-diff.sh mark '#cart_summary'
bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1"
dom-diff.sh diff '#cart_summary' --compact
```
Diffs the accessibility tree under a selector, before vs. after — more precise
than eyeballing a screenshot for confirming a stream replaced exactly what it
claimed to and nothing else moved.

#### `scripts/browser-errors.sh` — console/error capture, paired with request ids
```
browser-errors.sh clear
out="$(bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1")"
rid="$(echo "$out" | grep -i X-Request-Id | awk '{print $2}')"
browser-errors.sh check "$rid"
readlog.sh request "$rid"     # the server-side half
```
A workflow aid, not automatic correlation — there's no shared trace id between a
curl-issued request and a browser-side JS error. `check` just prints the request
id alongside the console/error output so the adjacency is easy to read.

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

### Confirm a Turbo Stream broadcast actually updated the DOM
The server-side half (`req.sh`/`submit_form.rb` + `readlog.sh`) can't see this —
it only sees the log line, not the browser. The browser-script half can:
1. `dom-diff.sh mark '#target'` — snapshot the target before the action.
2. Trigger the broadcast (`submit_form.rb`, a background job, another user).
3. `turbo-wait.sh dom "document.querySelector('#target')?.textContent.includes('...')"`
   — wait for the actual change, not a guessed sleep.
4. `dom-diff.sh diff '#target' --compact` and/or `screenshot.sh /page '#target'`
   to confirm exactly what changed.

### Debug a Stimulus controller not behaving as expected
1. `stimulus.sh tree` to confirm the controller connected at all (if it's missing,
   the problem is registration/`data-controller`, not the controller's logic).
2. `stimulus.sh inspect <identifier>` to check its targets resolved and its values
   hold what you expect.
3. `browser-errors.sh check` to catch an uncaught exception in `connect()` that
   would silently prevent the rest of the controller from running.

## Guardrails (don't weaken these)
- **Local only.** Both shell scripts reject non-localhost hosts; keep it that way.
- **No production logs.** `readlog.sh` refuses paths containing `production`.
- **Don't echo cookies.** `req.sh` redacts `Set-Cookie`; the session value never
  needs to enter the transcript. Report auth state, not the cookie.
- **Don't route this through the rails-mcp-server `execute_ruby` sandbox** — that
  sandbox blocks network on purpose. These scripts are a deliberately separate,
  narrowly-scoped affordance.
- **The browser scripts carry the same local-only guardrail independently** — they
  don't import it from `req.sh`, so don't weaken it there either if you touch them.

## Config (env vars)
- `BASE_URL`  — default `http://localhost:3000`. For kamal-proxy use the routed
  name, e.g. `http://fragua.localhost`.
- `RESOLVE`   — force the host to resolve to an IP when `*.localhost` doesn't
  resolve on its own. `RESOLVE=1` → `127.0.0.1`; `RESOLVE=<ip>` → that IP. Host
  header is preserved either way.
- `JAR`       — cookie jar path, default `./.hotwire/cookies.txt`
- `LOG_FILE`  — default `./log/development.log` (point at the specific app's log)
- `MAX_BYTES` — response body cap for `req.sh`, default `100000`

### Browser scripts only
- `STATE`           — bridged storageState cache, default `./.hotwire/state.json`
- `SESSION`         — agent-browser session name, default derived from `BASE_URL`'s
  host (e.g. `hotwire-fragua-localhost`), so calls against different apps don't
  collide
- `SCREENSHOT_DIR`  — default `./.hotwire/screenshots`
- `FORMAT`/`QUALITY` — `screenshot.sh` output format (`png`/`jpeg`) and JPEG quality,
  default `png`/`80`
- `WAIT_LOAD`       — default `domcontentloaded`, deliberately not `networkidle`
- `SETTLE_MS`       — extra wait after load for Turbo morph/animations, default `300`
- `MIN_DIM`/`MAX_DIM` — clamp for `screenshot.sh`'s element-scoped viewport size,
  default `100`/`1600`
- `VIEWPORT`        — fixed viewport for `screenshot-diff.sh`, default `1280x800`
  (changing it invalidates old baselines)
- `STIMULUS_GLOBAL` — window property holding the Stimulus `Application` instance,
  default `Stimulus`
- `AGENT_BROWSER`   — binary name/path, default `agent-browser`
- `RUBY`            — how to run the `.rb` bridge scripts, default `bundle exec ruby`
