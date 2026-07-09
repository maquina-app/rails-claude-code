#!/usr/bin/env bash
# turbo-wait.sh — wait for a Turbo event or a DOM condition in the browser,
# instead of a fixed sleep or (unreliable, for Hotwire apps) networkidle.
#
# Two ways to wait:
#   dom     — poll a JS boolean expression (recommended default; checks
#             current state, so there's no race condition to worry about)
#   arm/for — listen for a named Turbo event (turbo:load, turbo:frame-load,
#             turbo:before-stream-render, turbo:submit-end, ...). You MUST
#             call `arm` BEFORE the action that triggers the event — a
#             one-shot event that fires before the listener is registered
#             can't be caught after the fact.
#
# Usage:
#   turbo-wait.sh dom  '<js-boolean-expr>' [timeout-ms]
#   turbo-wait.sh arm  '<event1,event2,...>'
#   turbo-wait.sh for  '<event>' [timeout-ms]
#
# Examples:
#   # Wait for a Turbo Stream broadcast to land and update the DOM:
#   turbo-wait.sh dom "document.querySelector('#cart_summary')?.textContent.includes('3 items')"
#
#   # Wait for confirmation a specific event fired (arm first, then act, then wait):
#   turbo-wait.sh arm 'turbo:before-stream-render'
#   bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1"
#   turbo-wait.sh for 'turbo:before-stream-render' 8000
#
# Env: BASE_URL, JAR, SESSION, AGENT_BROWSER (same as screenshot.sh)
#
# Requires: agent-browser (npm install -g agent-browser && agent-browser install)

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
AGENT_BROWSER="${AGENT_BROWSER:-agent-browser}"

host="$(printf '%s' "$BASE_URL" | sed -E 's#^[a-z]+://([^:/]+).*#\1#')"
case "$host" in
  localhost|127.0.0.1|0.0.0.0|::1) : ;;
  *.localhost) : ;;
  *) echo "REFUSED: BASE_URL host '$host' is not local." >&2; exit 2 ;;
esac
SESSION="${SESSION:-hotwire-$(printf '%s' "$host" | tr -c 'a-zA-Z0-9' '-')}"

command -v "$AGENT_BROWSER" >/dev/null 2>&1 || {
  echo "agent-browser not found. Install it with:" >&2
  echo "  npm install -g agent-browser && agent-browser install" >&2
  exit 3
}

ab() { "$AGENT_BROWSER" --session "$SESSION" "$@"; }

mode="${1:--h}"
case "$mode" in
  -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  dom|arm|for) : ;;
  *) echo "usage: turbo-wait.sh dom|arm|for ..." >&2; exit 2 ;;
esac

case "$mode" in
  dom)
    expr="${2:?js boolean expression required}"
    timeout_ms="${3:-10000}"
    echo "==> waiting (up to ${timeout_ms}ms) for: $expr"
    AGENT_BROWSER_DEFAULT_TIMEOUT="$timeout_ms" ab wait --fn "$expr"
    echo "condition met."
    ;;

  arm)
    events_csv="${2:?comma-separated event list required, e.g. turbo:load,turbo:frame-load}"
    events_json="$(printf '%s' "$events_csv" | ruby -rjson -e 'puts JSON.generate(STDIN.read.strip.split(","))')"
    js="$(cat <<'JS'
(function(list){
  window.__hotwireEvents = window.__hotwireEvents || {};
  list.forEach(function(name){
    window.__hotwireEvents[name] = { count: 0, detail: null };
    document.addEventListener(name, function(e){
      window.__hotwireEvents[name].count++;
      try { window.__hotwireEvents[name].detail = JSON.stringify(e.detail || null); } catch (err) {}
    });
  });
  return 'armed: ' + list.join(', ');
})(__EVENTS__)
JS
)"
    js="${js/__EVENTS__/$events_json}"
    printf '%s' "$js" | ab eval --stdin
    ;;

  for)
    event="${2:?event name required}"
    timeout_ms="${3:-10000}"
    echo "==> waiting (up to ${timeout_ms}ms) for event: $event"
    check="window.__hotwireEvents && window.__hotwireEvents['$event'] && window.__hotwireEvents['$event'].count > 0"
    AGENT_BROWSER_DEFAULT_TIMEOUT="$timeout_ms" ab wait --fn "$check" || {
      echo "ERROR: '$event' did not fire within ${timeout_ms}ms." >&2
      echo "  Did you 'arm' it before the triggering action? A one-shot event" >&2
      echo "  that fires before the listener is registered can't be caught." >&2
      exit 1
    }
    echo "fired: $event"
    ab eval "JSON.stringify(window.__hotwireEvents['$event'])"
    ;;
esac
