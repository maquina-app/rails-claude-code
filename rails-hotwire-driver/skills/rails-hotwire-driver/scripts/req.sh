#!/usr/bin/env bash
# req.sh — make an HTTP request to the local Rails dev server, persisting cookies.
#
# Usage:
#   req.sh GET  /path
#   req.sh GET  /path turbo          # sets Accept: text/vnd.turbo-stream.html
#   req.sh GET  /path frame:cart     # sets Turbo-Frame: cart
#   req.sh POST /path 'a=1&b=2'      # form-encoded body
#
# Env:
#   BASE_URL   default http://localhost:3000   (must be localhost/127.0.0.1)
#   JAR        default ./.hotwire/cookies.txt
#   MAX_BYTES  default 100000  (body is truncated past this, with a notice)
#
# Output: response headers, a blank line, then the (possibly truncated) body.
# The X-Request-Id is always surfaced in the headers so you can grep the log.

set -euo pipefail

METHOD="${1:?method required}"
PATH_ARG="${2:?path required}"
EXTRA="${3:-}"
BODY="${4:-}"

BASE_URL="${BASE_URL:-http://localhost:3000}"
JAR="${JAR:-./.hotwire/cookies.txt}"
MAX_BYTES="${MAX_BYTES:-100000}"

# --- guardrail: only talk to the local machine -----------------------------
# Accepts localhost, loopback IPs, and any *.localhost name (kamal-proxy routes
# by Host header, e.g. fragua.localhost). Everything else is refused.
host="$(printf '%s' "$BASE_URL" | sed -E 's#^[a-z]+://([^:/]+).*#\1#')"
case "$host" in
  localhost|127.0.0.1|0.0.0.0|::1) : ;;
  *.localhost) : ;;
  *) echo "REFUSED: BASE_URL host '$host' is not local. This tool only drives a local dev server." >&2; exit 2 ;;
esac

# Optional: force the hostname to resolve to a given IP (default 127.0.0.1).
# Needed on systems where *.localhost doesn't resolve on its own. The Host
# header still carries '$host', so kamal-proxy routes correctly.
#   RESOLVE=1            -> --resolve <host>:<port>:127.0.0.1
#   RESOLVE=10.0.0.5     -> --resolve <host>:<port>:10.0.0.5
resolve_arg=()
if [ -n "${RESOLVE:-}" ]; then
  port="$(printf '%s' "$BASE_URL" | sed -E 's#^[a-z]+://[^:/]+:([0-9]+).*#\1#')"
  case "$port" in ''|*[!0-9]*) port=80 ;; esac
  ip="$RESOLVE"; [ "$RESOLVE" = "1" ] && ip="127.0.0.1"
  resolve_arg=(--resolve "${host}:${port}:${ip}")
fi

mkdir -p "$(dirname "$JAR")"
touch "$JAR"

accept="text/html,application/xhtml+xml"
frame_hdr=()
case "$EXTRA" in
  turbo)        accept="text/vnd.turbo-stream.html, text/html" ;;
  json)         accept="application/json" ;;
  frame:*)      frame_hdr=(-H "Turbo-Frame: ${EXTRA#frame:}") ;;
  ""|html)      : ;;
  *)            echo "unknown modifier: $EXTRA" >&2; exit 2 ;;
esac

args=(
  -sS -i
  -X "$METHOD"
  -b "$JAR" -c "$JAR"
  -H "Accept: $accept"
  -H "X-Requested-With: XMLHttpRequest"
  --max-time 30
  ${resolve_arg[@]+"${resolve_arg[@]}"}
  ${frame_hdr[@]+"${frame_hdr[@]}"}
)

if [ -n "$BODY" ]; then
  args+=(-H "Content-Type: application/x-www-form-urlencoded" --data "$BODY")
fi

# Capture, then split headers/body and truncate the body only.
raw="$(curl "${args[@]}" "${BASE_URL}${PATH_ARG}")"

# headers = up to first blank line; body = the rest
headers="$(printf '%s' "$raw" | sed -n '1,/^\r\{0,1\}$/p')"
body="$(printf '%s' "$raw" | sed -n '/^\r\{0,1\}$/,$p' | sed '1d')"

printf '%s\n\n' "$headers" | sed -E 's/^[Ss]et-[Cc]ookie:.*/Set-Cookie: [redacted]/'

bytes="$(printf '%s' "$body" | wc -c | tr -d ' ')"
if [ "$bytes" -gt "$MAX_BYTES" ]; then
  printf '%s' "$body" | head -c "$MAX_BYTES"
  printf '\n\n[...truncated %s of %s bytes...]\n' "$MAX_BYTES" "$bytes"
else
  printf '%s\n' "$body"
fi
