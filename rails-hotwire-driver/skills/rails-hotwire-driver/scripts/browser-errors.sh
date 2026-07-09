#!/usr/bin/env bash
# browser-errors.sh — capture JS console output and uncaught errors from the
# browser session, to check alongside the X-Request-Id that req.sh/
# submit_form.rb print for the action that triggered them.
#
# This is a workflow aid, not automatic correlation — there's no shared trace
# id between a curl-issued request and a browser-side JS error. The pattern
# is: clear, trigger the action, check — the request id is printed next to
# the output so you (or the agent) can eyeball the adjacency, then run
# readlog.sh request <id> alongside for the server-side half of the story.
#
# Usage:
#   browser-errors.sh clear                 # clear console + error buffers
#   browser-errors.sh check [request-id]    # print what's been captured since
#
# Example:
#   scripts/browser-errors.sh clear
#   out="$(bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1")"
#   rid="$(echo "$out" | grep -i X-Request-Id | awk '{print $2}')"
#   scripts/browser-errors.sh check "$rid"
#   scripts/readlog.sh request "$rid"        # the server-side half
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
  -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  clear|check) : ;;
  *) echo "usage: browser-errors.sh clear | browser-errors.sh check [request-id]" >&2; exit 2 ;;
esac

if [ "$mode" = clear ]; then
  ab console --clear
  ab errors --clear
  echo "cleared console + error buffers for session: $SESSION"
else
  rid="${2:-}"
  [ -n "$rid" ] && echo "=== correlates with X-Request-Id: $rid (cross-check: readlog.sh request $rid) ==="
  echo "--- console ---"
  ab console
  echo "--- errors ---"
  ab errors
fi
