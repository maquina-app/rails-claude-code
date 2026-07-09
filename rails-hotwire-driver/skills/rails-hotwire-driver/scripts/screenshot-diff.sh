#!/usr/bin/env bash
# screenshot-diff.sh — visual regression: save a baseline screenshot, or
# compare the current render against one, using agent-browser's pixel diff.
#
# Deliberately separate from screenshot.sh: a diff is only meaningful if both
# captures used the SAME framing, which conflicts with screenshot.sh's
# element-bbox-crop behavior. This script keeps the viewport fixed across
# save/compare runs instead. If you pass a selector, it's used to scroll the
# element into view consistently — not to crop.
#
# Usage:
#   screenshot-diff.sh save    <path> <baseline-file> [selector]
#   screenshot-diff.sh compare <path> <baseline-file> [selector] [diff-out] [threshold]
#
#   path           Rails path to open, e.g. /dashboard
#   baseline-file  where the baseline screenshot lives (save writes it;
#                  compare reads it)
#   selector       optional — scrollIntoView before capturing, for consistent
#                  framing across runs
#   diff-out       compare only: where to write the diff image (default:
#                  $SCREENSHOT_DIR/<slug>-diff-<ts>.png)
#   threshold      compare only: color-diff sensitivity 0-1 (agent-browser
#                  default if omitted)
#
# Env: same bridging/session vars as screenshot.sh (BASE_URL, JAR, STATE,
#      SESSION, SCREENSHOT_DIR, AGENT_BROWSER, RUBY, WAIT_LOAD, SETTLE_MS), plus:
#   VIEWPORT   default 1280x800 — fixed for both save and compare. Changing it
#              invalidates old baselines (different framing reads as a false diff).
#
# Example — catch unintended layout shift from a maquina_components change:
#   scripts/screenshot-diff.sh save /dashboard baselines/dashboard.png
#   # ... make a Tailwind/component change ...
#   scripts/screenshot-diff.sh compare /dashboard baselines/dashboard.png
#
# Notes:
# - Avoid diffing pages with inherently dynamic content (timestamps, live
#   counters) unless you've stubbed them — those will always "fail".
# - Requires agent-browser (npm install -g agent-browser && agent-browser
#   install) and jar_to_storage.rb in the same scripts/ dir.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_TO_STORAGE="$here/jar_to_storage.rb"
RUBY="${RUBY:-bundle exec ruby}"

BASE_URL="${BASE_URL:-http://localhost:3000}"
JAR="${JAR:-./.hotwire/cookies.txt}"
STATE="${STATE:-./.hotwire/state.json}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-./.hotwire/screenshots}"
WAIT_LOAD="${WAIT_LOAD:-domcontentloaded}"
SETTLE_MS="${SETTLE_MS:-300}"
VIEWPORT="${VIEWPORT:-1280x800}"
AGENT_BROWSER="${AGENT_BROWSER:-agent-browser}"

# --- guardrail: only talk to the local machine (same rule as req.sh) --------
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

mode="${1:--h}"
case "$mode" in
  -h|--help) sed -n '2,39p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  save|compare) : ;;
  *) echo "usage: screenshot-diff.sh save|compare <path> <baseline-file> [selector] [diff-out] [threshold]" >&2; exit 2 ;;
esac

page_path="${2:?path required}"
baseline="${3:?baseline-file required}"
selector="${4:-}"
diff_out="${5:-}"
threshold="${6:-}"

case "$VIEWPORT" in
  *x*) w="${VIEWPORT%x*}"; h="${VIEWPORT#*x}" ;;
  *) echo "VIEWPORT must be WxH, e.g. 1280x800 (got: $VIEWPORT)" >&2; exit 2 ;;
esac

ab() { "$AGENT_BROWSER" --session "$SESSION" "$@"; }

mkdir -p "$SCREENSHOT_DIR" "$(dirname "$STATE")" "$(dirname "$baseline")"

# --- 1. bridge the curl session into the browser -----------------------------
if [ -s "$JAR" ]; then
  echo "==> bridging cookie jar ($JAR) -> $STATE"
  $RUBY "$JAR_TO_STORAGE" --jar "$JAR" --origin "$BASE_URL" --out "$STATE"
  state_args=(--state "$STATE")
else
  echo "==> no cookie jar at $JAR; opening unauthenticated" >&2
  state_args=()
fi

# --- 2. open at a fixed viewport, wait, position ------------------------------
url="${BASE_URL}${page_path}"
echo "==> open $url (viewport ${w}x${h})"
"$AGENT_BROWSER" --session "$SESSION" "${state_args[@]}" open "$url"
ab set viewport "$w" "$h"
ab wait --load "$WAIT_LOAD" || echo "    (load-state wait didn't resolve cleanly, continuing)" >&2
ab wait "$SETTLE_MS"

if [ -n "$selector" ]; then
  ab scrollintoview "$selector" || {
    echo "ERROR: selector not found: $selector" >&2
    exit 1
  }
fi

# --- 3. save or compare --------------------------------------------------------
if [ "$mode" = save ]; then
  ab screenshot "$baseline"
  echo "saved baseline: $baseline (viewport ${w}x${h})"
else
  [ -f "$baseline" ] || {
    echo "ERROR: no baseline at $baseline" >&2
    echo "  run: screenshot-diff.sh save $page_path $baseline" >&2
    exit 1
  }
  if [ -z "$diff_out" ]; then
    slug="$(printf '%s' "$page_path" | sed -E 's#^/##; s#[^a-zA-Z0-9]+#-#g; s#-+$##')"
    [ -z "$slug" ] && slug="root"
    diff_out="$SCREENSHOT_DIR/${slug}-diff-$(date +%Y%m%d%H%M%S).png"
  fi
  diff_args=(diff screenshot --baseline "$baseline" -o "$diff_out")
  [ -n "$threshold" ] && diff_args+=(-t "$threshold")
  ab "${diff_args[@]}"
  echo "diff written: $diff_out"
  echo "(compared against $baseline, viewport ${w}x${h} — a blank/near-blank diff image means no visible change)"
fi

echo "(session '$SESSION' left open — screenshot.sh --close to shut it down)"
