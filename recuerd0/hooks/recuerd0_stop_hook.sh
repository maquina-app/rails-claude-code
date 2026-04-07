#!/usr/bin/env bash
# Recuerd0 Stop hook — rate-limited checkpoint save.
#
# Fires after each assistant turn. Creates a memory in the configured recuerd0
# workspace at most once every RECUERD0_STOP_INTERVAL_MINUTES (default 15).
#
# Never exits non-zero: a misconfigured or offline recuerd0 CLI must not
# interrupt the user's Claude Code session. Failures log to
# ~/.recuerd0/hook-errors.log and the hook returns 0.

set -u

HOOK_TYPE="stop"
TITLE_PREFIX="Claude Code checkpoint"
INTERVAL_MINUTES="${RECUERD0_STOP_INTERVAL_MINUTES:-15}"

# shellcheck source=recuerd0_hook_common.sh
source "$(dirname "$0")/recuerd0_hook_common.sh"

state_dir="${HOME}/.recuerd0"
stamp_file="${state_dir}/last_stop_save"
mkdir -p "$state_dir" 2>/dev/null || exit 0

# Rate-limit: skip if last save was within the interval.
if [[ -f "$stamp_file" ]]; then
  last=$(cat "$stamp_file" 2>/dev/null || echo 0)
  now=$(date +%s)
  elapsed=$(( now - last ))
  min_elapsed=$(( INTERVAL_MINUTES * 60 ))
  if (( elapsed < min_elapsed )); then
    exit 0
  fi
fi

run_save "$HOOK_TYPE" "$TITLE_PREFIX" || exit 0

date +%s > "$stamp_file" 2>/dev/null || true
exit 0
