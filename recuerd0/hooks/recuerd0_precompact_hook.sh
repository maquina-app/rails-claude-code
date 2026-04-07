#!/usr/bin/env bash
# Recuerd0 PreCompact hook — emergency save before context compression.
#
# Fires before Claude Code compacts the conversation. Always runs (no rate
# limit) because compaction is rare and always worth capturing.
#
# Never exits non-zero.

set -u

HOOK_TYPE="precompact"
TITLE_PREFIX="Claude Code pre-compact"

# shellcheck source=recuerd0_hook_common.sh
source "$(dirname "$0")/recuerd0_hook_common.sh"

run_save "$HOOK_TYPE" "$TITLE_PREFIX" || exit 0
exit 0
