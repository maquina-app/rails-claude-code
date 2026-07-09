#!/usr/bin/env bash
# dom-diff.sh — structural diff of a scoped part of the page, to confirm a
# Turbo action changed exactly what it should. More precise than eyeballing a
# screenshot: this diffs the accessibility tree under a selector.
#
# Usage:
#   dom-diff.sh mark <selector> [baseline-file]
#   dom-diff.sh diff <selector> [baseline-file] [--compact]
#
#   mark   snapshot the element now, as the baseline to diff against
#   diff   snapshot the element again and diff against the baseline
#
#   selector       CSS selector to scope to, e.g. '#cart_summary'
#   baseline-file  optional — save/load the baseline to/from disk. Omit it
#                  and `diff` compares against the in-session "last snapshot"
#                  instead — fine as long as mark and diff run in the same
#                  SESSION (the default, derived from BASE_URL's host).
#
# Example — confirm a turbo-stream replaced exactly #cart_summary and nothing
# else changed around it:
#   scripts/dom-diff.sh mark '#cart_summary'
#   bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1"
#   scripts/dom-diff.sh diff '#cart_summary' --compact
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
  -h|--help) sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  mark|diff) : ;;
  *) echo "usage: dom-diff.sh mark|diff <selector> [baseline-file] [--compact]" >&2; exit 2 ;;
esac
shift

selector="${1:?selector required}"
shift || true
baseline=""
compact_flag=()
for arg in "$@"; do
  case "$arg" in
    --compact) compact_flag=(--compact) ;;
    *)         baseline="$arg" ;;
  esac
done

if [ "$mode" = mark ]; then
  if [ -n "$baseline" ]; then
    mkdir -p "$(dirname "$baseline")"
    ab snapshot -s "$selector" --json > "$baseline"
    echo "marked baseline: $baseline"
  else
    ab snapshot -s "$selector" >/dev/null
    echo "marked (in-session — run diff in the same SESSION: $SESSION)"
  fi
else
  diff_args=(diff snapshot --selector "$selector" "${compact_flag[@]}")
  [ -n "$baseline" ] && diff_args+=(--baseline "$baseline")
  ab "${diff_args[@]}"
fi
