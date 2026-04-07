#!/usr/bin/env bash
# Shared helpers for recuerd0 auto-save hooks. Sourced by the individual
# hook scripts. Not intended to be executed directly.
#
# Contract:
#   run_save <hook_type> <title_prefix>
#     - hook_type: tag suffix, e.g. "stop" or "precompact"
#     - title_prefix: human-readable title prefix
#
# Reads Claude Code hook payload JSON from stdin. Required field:
#   transcript_path  — absolute path to the session transcript file
# Optional:
#   session_id       — included in the memory title when present
#
# Environment:
#   RECUERD0_HOOK_TAIL_LINES  lines of transcript to capture (default 200)
#   RECUERD0_HOOK_DISABLE     if set to "1", skip entirely
#
# On failure, writes a one-line entry to ~/.recuerd0/hook-errors.log and
# returns non-zero. Callers ignore the return code and exit 0 themselves.

log_error() {
  local msg="$1"
  local log_dir="${HOME}/.recuerd0"
  local log_file="${log_dir}/hook-errors.log"
  mkdir -p "$log_dir" 2>/dev/null || return 0
  printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${HOOK_TYPE:-unknown}" "$msg" \
    >> "$log_file" 2>/dev/null || true
}

run_save() {
  local hook_type="$1"
  local title_prefix="$2"

  if [[ "${RECUERD0_HOOK_DISABLE:-0}" == "1" ]]; then
    return 0
  fi

  if ! command -v recuerd0 >/dev/null 2>&1; then
    # CLI not installed — silent no-op. Don't log; this is expected for
    # users who haven't set up recuerd0 yet.
    return 0
  fi

  # Read stdin payload (may be empty if Claude Code doesn't pipe one).
  local payload=""
  if [[ ! -t 0 ]]; then
    payload=$(cat 2>/dev/null || true)
  fi

  # Extract transcript_path and session_id without requiring jq.
  local transcript_path=""
  local session_id=""
  transcript_path=$(extract_json_string "$payload" "transcript_path")
  session_id=$(extract_json_string "$payload" "session_id")

  if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    log_error "transcript_path missing or unreadable"
    return 1
  fi

  local tail_lines="${RECUERD0_HOOK_TAIL_LINES:-200}"
  local body
  body=$(tail -n "$tail_lines" "$transcript_path" 2>/dev/null || true)
  if [[ -z "$body" ]]; then
    log_error "transcript empty: $transcript_path"
    return 1
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  local title="${title_prefix} — ${timestamp}"
  if [[ -n "$session_id" ]]; then
    title="${title_prefix} — ${session_id} — ${timestamp}"
  fi

  # Wrap body in a fenced block so it survives Markdown rendering.
  local content
  content=$(printf '# %s\n\nSession transcript (last %s lines):\n\n```\n%s\n```\n' \
    "$title" "$tail_lines" "$body")

  local tags="claude-code,auto-save,${hook_type}"

  local output
  if ! output=$(printf '%s' "$content" | recuerd0 memory create \
      --title "$title" \
      --source "claude-code-session" \
      --tags "$tags" \
      --content - 2>&1); then
    log_error "recuerd0 memory create failed: ${output//$'\n'/ }"
    return 1
  fi

  return 0
}

# Minimal JSON string field extractor — handles `"key": "value"` with
# backslash-escape awareness. Good enough for the small, well-formed
# payloads Claude Code emits; avoids a jq dependency.
extract_json_string() {
  local json="$1"
  local key="$2"
  [[ -z "$json" ]] && return 0
  # Match: "key"<ws>:<ws>"value"
  # Value may contain \" escapes.
  printf '%s' "$json" | awk -v key="$key" '
    BEGIN { RS = "\0" }
    {
      n = split($0, _, "")
      # Walk the string looking for "key" followed by : and a quoted value.
      s = $0
      pat = "\"" key "\""
      pos = index(s, pat)
      if (pos == 0) exit 0
      rest = substr(s, pos + length(pat))
      # Skip whitespace and colon.
      sub(/^[[:space:]]*:[[:space:]]*"/, "", rest)
      # Read until unescaped closing quote.
      out = ""
      i = 1
      while (i <= length(rest)) {
        c = substr(rest, i, 1)
        if (c == "\\") {
          nxt = substr(rest, i + 1, 1)
          if (nxt == "\"") { out = out "\""; i += 2; continue }
          if (nxt == "\\") { out = out "\\"; i += 2; continue }
          if (nxt == "n")  { out = out "\n"; i += 2; continue }
          if (nxt == "t")  { out = out "\t"; i += 2; continue }
          out = out nxt; i += 2; continue
        }
        if (c == "\"") break
        out = out c
        i++
      }
      print out
    }
  '
}
