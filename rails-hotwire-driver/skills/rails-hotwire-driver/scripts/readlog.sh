#!/usr/bin/env bash
# readlog.sh — read the Rails dev log safely, with request-id correlation.
#
# Usage:
#   readlog.sh tail [N]               last N lines (default 200)
#   readlog.sh grep <regex> [N]       last N lines matching regex (default scan 2000)
#   readlog.sh request <request-id>   only lines tagged with that X-Request-Id
#   readlog.sh otp                    convenience grep for common OTP/magic-link patterns
#
# Env:
#   LOG_FILE   default ./log/development.log
#
# Guard: refuses to read *production* logs. Reading secrets (OTP codes) out of
# a log is a development-only affordance.

set -euo pipefail

LOG_FILE="${LOG_FILE:-./log/development.log}"

case "$LOG_FILE" in
  *production*) echo "REFUSED: will not read a production log ($LOG_FILE)." >&2; exit 2 ;;
esac
[ -f "$LOG_FILE" ] || { echo "Log not found: $LOG_FILE" >&2; exit 1; }

cmd="${1:?command required: tail|grep|request|otp}"

case "$cmd" in
  tail)
    tail -n "${2:-200}" "$LOG_FILE"
    ;;
  grep)
    pattern="${2:?regex required}"
    scan="${3:-2000}"
    tail -n "$scan" "$LOG_FILE" | grep -E -i "$pattern" || echo "(no matches in last $scan lines)"
    ;;
  request)
    rid="${2:?request-id required}"
    # Works when config.log_tags includes :request_id (lines look like [<rid>] ...).
    # Falls back to a context window around the id if tagging is off.
    if grep -qF "[$rid]" "$LOG_FILE"; then
      grep -F "[$rid]" "$LOG_FILE"
    else
      echo "(request_id not used as a log tag; showing 40 lines of context around first mention)"
      grep -nF "$rid" "$LOG_FILE" | head -1 | cut -d: -f1 | while read -r ln; do
        start=$(( ln > 5 ? ln - 5 : 1 ))
        sed -n "${start},$(( ln + 40 ))p" "$LOG_FILE"
      done
    fi
    ;;
  otp)
    tail -n 3000 "$LOG_FILE" \
      | grep -E -i 'otp|one[- ]?time|verification code|magic.?link|token=|confirmation' \
      || echo "(no OTP-like lines in last 3000 lines)"
    ;;
  *)
    echo "unknown command: $cmd" >&2; exit 2 ;;
esac
