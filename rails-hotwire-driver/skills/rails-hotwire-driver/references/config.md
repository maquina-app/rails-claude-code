# Config reference — environment variables

Every script is configured through environment variables, with sane defaults. The core (curl) scripts need only the first group; the browser scripts add the second.

## Core scripts

- `BASE_URL` — default `http://localhost:3000`. For kamal-proxy use the routed name, e.g. `http://fragua.localhost`.
- `RESOLVE` — force the host to resolve to an IP when `*.localhost` doesn't resolve on its own. `RESOLVE=1` → `127.0.0.1`; `RESOLVE=<ip>` → that IP. The `Host` header is preserved either way.
- `JAR` — cookie jar path, default `./.hotwire/cookies.txt`.
- `LOG_FILE` — default `./log/development.log` (point at the specific app's log).
- `MAX_BYTES` — response body cap for `req.sh`, default `100000`.
- `RUBY` — how to run the `.rb` scripts, default `bundle exec ruby`.

## Browser scripts only

- `STATE` — bridged storageState cache, default `./.hotwire/state.json`.
- `SESSION` — agent-browser session name, default derived from `BASE_URL`'s host (e.g. `hotwire-fragua-localhost`), so calls against different apps don't collide.
- `SCREENSHOT_DIR` — default `./.hotwire/screenshots`.
- `FORMAT` / `QUALITY` — `screenshot.sh` output format (`png`/`jpeg`) and JPEG quality, default `png`/`80`.
- `WAIT_LOAD` — default `domcontentloaded`, deliberately not `networkidle` (Hotwire holds an open ActionCable connection, so `networkidle` can hang).
- `SETTLE_MS` — extra wait after load for Turbo morph/animations, default `300`.
- `MIN_DIM` / `MAX_DIM` — clamp for `screenshot.sh`'s element-scoped viewport size, default `100`/`1600`.
- `VIEWPORT` — fixed viewport for `screenshot-diff.sh`, default `1280x800` (changing it invalidates old baselines).
- `STIMULUS_GLOBAL` — window property holding the Stimulus `Application` instance, default `Stimulus`.
- `AGENT_BROWSER` — binary name/path, default `agent-browser`.
