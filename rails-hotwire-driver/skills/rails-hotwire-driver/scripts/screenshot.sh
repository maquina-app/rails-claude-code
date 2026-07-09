#!/usr/bin/env bash
# screenshot.sh — take a screenshot of the current app state via agent-browser,
# reusing the authenticated session that req.sh / submit_form.rb / flow.sh built
# with curl. Meant to run right after a turbo action, to see what actually
# rendered.
#
# Usage:
#   screenshot.sh <path> [selector] [output]
#   screenshot.sh --no-bridge <path> [selector] [output]
#   screenshot.sh --close
#
#   path       Rails path to open, e.g. /cart
#   selector   optional CSS selector to scope the shot to (e.g. a turbo-stream
#              target). Approximate: sizes the viewport to the element's
#              bounding box rather than pixel-cropping, so it's a "does this
#              look right" check, not a pixel-exact crop.
#   output     optional output path (default: $SCREENSHOT_DIR/<slug>-<ts>.<fmt>)
#
# Flags:
#   --no-bridge     don't re-import the curl cookie jar into the browser; use
#                   whatever auth state the browser session already has
#   --close         close the agent-browser session for this app and exit
#   --device NAME   emulate a device, e.g. --device "iPhone 14". Sets its own
#                   viewport, so it DISABLES the element-bbox crop below — with
#                   a selector, you get scrollIntoView + a normal (uncropped)
#                   shot at the device's resolution instead.
#   --media MODE    dark|light — sets prefers-color-scheme before capture
#   --annotate      overlay numbered [N] labels on interactive elements
#                   (Chrome/CDP only, not the Safari/WebDriver backend)
#   -h, --help
#
# Env:
#   BASE_URL        default http://localhost:3000   (must be localhost/127.0.0.1)
#   JAR             default ./.hotwire/cookies.txt   (curl session to bridge from)
#   STATE           default ./.hotwire/state.json    (bridged storageState cache)
#   SESSION         default derived from BASE_URL host, e.g. hotwire-fragua-localhost
#   SCREENSHOT_DIR  default ./.hotwire/screenshots
#   FORMAT          default png   (png|jpeg)
#   QUALITY         default 80    (jpeg only)
#   WAIT_LOAD       default domcontentloaded — NOT networkidle. Hotwire apps
#                   hold an open ActionCable connection, so networkidle can
#                   hang for the full timeout instead of resolving quickly.
#   SETTLE_MS       default 300   (extra wait after load, for Turbo morph/animations)
#   MIN_DIM/MAX_DIM default 100/1600 (clamp the element-scoped viewport size)
#   AGENT_BROWSER   default agent-browser  (binary name/path)
#   RUBY            default "bundle exec ruby" (used to run jar_to_storage.rb)
#
# For a sweep across breakpoints/devices, loop the script rather than adding
# that here — it doesn't need new capability, just repeated calls:
#   for d in "iPhone 14" "iPad Pro"; do
#     screenshot.sh --device "$d" /dashboard "" "dash-${d// /-}.png"
#   done
#
# For visual regression (before/after diffing), use screenshot-diff.sh instead
# — a diff is only meaningful with a fixed viewport, which conflicts with this
# script's element-crop behavior, so it's a separate tool on purpose.
#
# Typical use — screenshot exactly what a turbo-stream said it touched:
#   bundle exec ruby scripts/submit_form.rb /cart/add "product_id=1" "qty=2"
#   #   Turbo Streams:
#   #     - replace #cart_summary
#   scripts/screenshot.sh /cart '#cart_summary' cart-after-add.png
#
# Requires: agent-browser (npm install -g agent-browser && agent-browser install)
# and jar_to_storage.rb in the same scripts/ dir.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_TO_STORAGE="$here/jar_to_storage.rb"
RUBY="${RUBY:-bundle exec ruby}"

BASE_URL="${BASE_URL:-http://localhost:3000}"
JAR="${JAR:-./.hotwire/cookies.txt}"
STATE="${STATE:-./.hotwire/state.json}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-./.hotwire/screenshots}"
FORMAT="${FORMAT:-png}"
QUALITY="${QUALITY:-80}"
WAIT_LOAD="${WAIT_LOAD:-domcontentloaded}"
SETTLE_MS="${SETTLE_MS:-300}"
MIN_DIM="${MIN_DIM:-100}"
MAX_DIM="${MAX_DIM:-1600}"
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

# --- parse args ---------------------------------------------------------------
no_bridge=false
close_only=false
device=""
media=""
annotate=false
positional=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-bridge) no_bridge=true; shift ;;
    --close)     close_only=true; shift ;;
    --device)    device="${2:?--device requires a name}"; shift 2 ;;
    --media)     media="${2:?--media requires dark or light}"; shift 2 ;;
    --annotate)  annotate=true; shift ;;
    -h|--help)   sed -n '2,65p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          echo "unknown flag: $1" >&2; exit 2 ;;
    *)           positional+=("$1"); shift ;;
  esac
done

case "$media" in
  ""|dark|light) : ;;
  *) echo "--media must be 'dark' or 'light', got: $media" >&2; exit 2 ;;
esac

ab() { "$AGENT_BROWSER" --session "$SESSION" "$@"; }

if [ "$close_only" = true ]; then
  ab close
  echo "closed session: $SESSION"
  exit 0
fi

page_path="${positional[0]:?path required}"
selector="${positional[1]:-}"
output="${positional[2]:-}"

mkdir -p "$SCREENSHOT_DIR" "$(dirname "$STATE")"

# --- 1. bridge the curl session into the browser -----------------------------
if [ "$no_bridge" = true ]; then
  echo "==> [1/4] --no-bridge: using whatever auth the browser session already has"
  state_args=()
elif [ -s "$JAR" ]; then
  echo "==> [1/4] bridging cookie jar ($JAR) -> $STATE"
  $RUBY "$JAR_TO_STORAGE" --jar "$JAR" --origin "$BASE_URL" --out "$STATE"
  state_args=(--state "$STATE")
else
  echo "==> [1/4] no cookie jar at $JAR; opening unauthenticated" >&2
  state_args=()
fi

# --- 2. open + wait -----------------------------------------------------------
url="${BASE_URL}${page_path}"
echo "==> [2/4] open $url"
"$AGENT_BROWSER" --session "$SESSION" ${state_args[@]+"${state_args[@]}"} open "$url"
ab wait --load "$WAIT_LOAD" || echo "    (load-state wait didn't resolve cleanly, continuing)" >&2
ab wait "$SETTLE_MS"

if [ -n "$device" ]; then
  echo "==> device: $device"
  ab set device "$device"
fi
if [ -n "$media" ]; then
  echo "==> media: $media"
  ab set media "$media"
fi
[ -n "$device$media" ] && ab wait "$SETTLE_MS"   # let the reflow settle

# --- 3. default output path ---------------------------------------------------
if [ -z "$output" ]; then
  slug="$(printf '%s' "$page_path" | sed -E 's#^/##; s#[^a-zA-Z0-9]+#-#g; s#-+$##')"
  [ -z "$slug" ] && slug="root"
  output="$SCREENSHOT_DIR/${slug}-$(date +%Y%m%d%H%M%S).${FORMAT}"
fi

shot_args=(--screenshot-format "$FORMAT")
[ "$FORMAT" = "jpeg" ] && shot_args+=(--screenshot-quality "$QUALITY")
[ "$annotate" = true ] && shot_args+=(--annotate)

# --- 4. screenshot --------------------------------------------------------------
if [ -n "$selector" ] && [ -z "$device" ]; then
  echo "==> [3/4] scoping to '$selector'"
  ab scrollintoview "$selector" || {
    echo "ERROR: selector not found: $selector" >&2
    echo "  Did the turbo-stream target actually render? Check submit_form.rb's" >&2
    echo "  'Turbo Streams:' output for the real target id, or run:" >&2
    echo "  $AGENT_BROWSER --session $SESSION snapshot -i" >&2
    exit 1
  }

  box_json="$(ab get box "$selector" --json)"
  read -r w h <<EOF
$(ruby -rjson -e '
    d = JSON.parse(STDIN.read)
    box = d["data"] || d
    w = box["width"].to_f.ceil
    h = box["height"].to_f.ceil
    puts "#{w} #{h}"
  ' <<< "$box_json")
EOF

  clamp() { local v="$1" min="$2" max="$3"; [ "$v" -lt "$min" ] && v="$min"; [ "$v" -gt "$max" ] && v="$max"; echo "$v"; }
  w="$(clamp "$w" "$MIN_DIM" "$MAX_DIM")"
  h="$(clamp "$h" "$MIN_DIM" "$MAX_DIM")"

  ab set viewport "$w" "$h"
  ab scrollintoview "$selector"   # viewport resize can reset scroll position
  echo "==> [4/4] screenshot ($w x $h, approximate crop) -> $output"
  ab screenshot "$output" "${shot_args[@]}"
elif [ -n "$selector" ]; then
  # --device given: keep its viewport, just frame on the element instead of cropping to it
  echo "==> [3/4] device '$device', framing on '$selector' (uncropped)"
  ab scrollintoview "$selector" || {
    echo "ERROR: selector not found: $selector" >&2
    exit 1
  }
  echo "==> [4/4] screenshot -> $output"
  ab screenshot "$output" "${shot_args[@]}"
else
  echo "==> [3/4] full page"
  echo "==> [4/4] screenshot -> $output"
  ab screenshot "$output" --full "${shot_args[@]}"
fi

echo "saved: $output"
echo "(session '$SESSION' left open for follow-up shots — screenshot.sh --close to shut it down)"
