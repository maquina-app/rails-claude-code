#!/usr/bin/env bash
# flow.sh — run a full authenticated session in one command:
#   1. submit the login form (CSRF handled by submit_form.rb)
#   2. read the OTP / magic-link code from the dev log, scoped to that request
#   3. submit the OTP form
#   4. (optional) perform one authenticated action and report the result
#
# The session cookie is carried across every step via the shared jar, so step 4
# runs as the logged-in user.
#
# Usage:
#   flow.sh --email me@x.com --password secret \
#           [--login-path /session/new] [--login-fields 'k=v&k2=v2'] \
#           [--otp-path /session/otp]  [--otp-field code] \
#           [--otp-pattern 'code is (\d{6})'] \
#           [--then-path /dashboard]   [--then-method GET] \
#           [--then-fields 'k=v'] [--then-accept html|turbo|json]
#
# OTP is optional: if --otp-path is omitted, the flow assumes password-only login
# and skips straight to the action (step 4).
#
# Env (shared with req.sh / submit_form.rb):
#   BASE_URL, RESOLVE, JAR, LOG_FILE
#   RUBY  — how to run submit_form.rb (default: "bundle exec ruby"). Set to
#           "ruby" if you're not inside the app's bundle.
#
# Requires: req.sh, readlog.sh, submit_form.rb in the same scripts/ dir.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ="$here/req.sh"
READLOG="$here/readlog.sh"
SUBMIT="$here/submit_form.rb"
RUBY="${RUBY:-bundle exec ruby}"

# --- defaults ---------------------------------------------------------------
email=""; password=""
login_path="/session/new"; login_fields=""
otp_path=""; otp_field="code"; otp_pattern='(?:code|otp)[^0-9]{0,20}(\d{4,8})'
then_path=""; then_method="GET"; then_fields=""; then_accept="html"

# --- parse args -------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --email)        email="$2"; shift 2 ;;
    --password)     password="$2"; shift 2 ;;
    --login-path)   login_path="$2"; shift 2 ;;
    --login-fields) login_fields="$2"; shift 2 ;;
    --otp-path)     otp_path="$2"; shift 2 ;;
    --otp-field)    otp_field="$2"; shift 2 ;;
    --otp-pattern)  otp_pattern="$2"; shift 2 ;;
    --then-path)    then_path="$2"; shift 2 ;;
    --then-method)  then_method="$2"; shift 2 ;;
    --then-fields)  then_fields="$2"; shift 2 ;;
    --then-accept)  then_accept="$2"; shift 2 ;;
    -h|--help)      sed -n '2,40p' "$0"; exit 0 ;;
    *)              echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$email" ] || { echo "--email is required" >&2; exit 2; }

# Build the credential fields for submit_form.rb (which takes k=v positionals).
# Extra --login-fields are split on & and passed through.
cred_args=("email=$email")
[ -n "$password" ] && cred_args+=("password=$password")
if [ -n "$login_fields" ]; then
  IFS='&' read -ra extra <<< "$login_fields"
  for kv in "${extra[@]}"; do [ -n "$kv" ] && cred_args+=("$kv"); done
fi

extract_rid() { grep -i 'x-request-id' | head -1 | awk '{print $2}' | tr -d '\r'; }

echo "==> [1/4] login: POST form at $login_path"
login_out="$("$RUBY" "$SUBMIT" "$login_path" "${cred_args[@]}")"
echo "$login_out" | sed 's/^/    /'
login_rid="$(printf '%s\n' "$login_out" | grep -i 'X-Request-Id' | head -1 | awk '{print $2}' | tr -d '\r')"

if [ -z "$otp_path" ]; then
  echo "==> [2/4] no --otp-path given; skipping OTP (password-only login)"
else
  echo "==> [2/4] reading OTP from log (request $login_rid)"
  if [ -n "$login_rid" ]; then
    log_slice="$(LOG_FILE="${LOG_FILE:-./log/development.log}" "$READLOG" request "$login_rid" || true)"
  else
    echo "    (no request id from login; falling back to recent OTP lines)"
    log_slice="$(LOG_FILE="${LOG_FILE:-./log/development.log}" "$READLOG" otp || true)"
  fi
  printf '%s\n' "$log_slice" | sed 's/^/    | /'

  # Extract the code with the (PCRE-ish) pattern via grep -oP, fallback to grep -oE.
  code="$(printf '%s' "$log_slice" | grep -oiP "$otp_pattern" 2>/dev/null | grep -oE '[0-9]{4,8}' | head -1 || true)"
  [ -z "$code" ] && code="$(printf '%s' "$log_slice" | grep -oE '[0-9]{4,8}' | head -1 || true)"
  if [ -z "$code" ]; then
    echo "    ERROR: could not extract an OTP code from the log slice." >&2
    echo "    Adjust --otp-pattern or check LOG_FILE / log_tags config." >&2
    exit 1
  fi
  echo "    extracted OTP: $code"

  echo "==> [3/4] submit OTP: POST form at $otp_path ($otp_field=$code)"
  otp_out="$("$RUBY" "$SUBMIT" "$otp_path" "$otp_field=$code")"
  echo "$otp_out" | sed 's/^/    /'
fi

if [ -z "$then_path" ]; then
  echo "==> [4/4] no --then-path; session is authenticated. Done."
  exit 0
fi

echo "==> [4/4] authenticated action: $then_method $then_path"
case "$then_method" in
  GET)
    "$REQ" GET "$then_path" "$then_accept" | sed 's/^/    /'
    ;;
  POST|PUT|PATCH|DELETE)
    if [ -n "$then_fields" ]; then
      # CSRF-bearing action: prefer submit_form.rb against a page that holds the form.
      # If you pass a direct endpoint with no form, use req.sh instead via --then-method POST.
      IFS='&' read -ra tf <<< "$then_fields"
      "$RUBY" "$SUBMIT" "$then_path" "${tf[@]}" | sed 's/^/    /'
    else
      "$REQ" "$then_method" "$then_path" "$then_accept" | sed 's/^/    /'
    fi
    ;;
  *)
    echo "unknown --then-method: $then_method" >&2; exit 2 ;;
esac

echo "==> flow complete."
