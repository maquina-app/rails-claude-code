#!/usr/bin/env bash
# stimulus.sh — introspect connected Stimulus controllers via the browser's
# window.Stimulus application instance. Uses Stimulus's public Application#
# controllers API plus each controller's static targets/values — accurate
# for a standard Rails 7/8 Stimulus setup where application.js does
# `window.Stimulus = application` (the default stimulus:install output).
#
# If window.Stimulus isn't found, either add that line to
# app/javascript/controllers/application.js, or set STIMULUS_GLOBAL to
# whatever name you exposed it under.
#
# Usage:
#   stimulus.sh tree                        # list all connected controllers
#   stimulus.sh inspect <identifier|index>  # targets + values for one controller
#
# Examples:
#   stimulus.sh tree
#   stimulus.sh inspect cart-item
#   stimulus.sh inspect 2                   # by index from `tree`'s output
#
# Env: BASE_URL, JAR, SESSION, AGENT_BROWSER (same as screenshot.sh), plus:
#   STIMULUS_GLOBAL   default "Stimulus" — the window property holding the
#                     Stimulus Application instance
#
# Requires: agent-browser (npm install -g agent-browser && agent-browser install)

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
AGENT_BROWSER="${AGENT_BROWSER:-agent-browser}"
STIMULUS_GLOBAL="${STIMULUS_GLOBAL:-Stimulus}"

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
run_js() { printf '%s' "$1" | ab eval --stdin; }

mode="${1:--h}"
case "$mode" in
  -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  tree|inspect) : ;;
  *) echo "usage: stimulus.sh tree | stimulus.sh inspect <identifier|index>" >&2; exit 2 ;;
esac

case "$mode" in
  tree)
    js="$(cat <<'JS'
(function(){
  var app = window.__STIMULUS_GLOBAL__;
  if (!app || !app.controllers) {
    return JSON.stringify({ error: "window.__STIMULUS_GLOBAL__ not found or has no .controllers — expose it in application.js, or set STIMULUS_GLOBAL" });
  }
  var list = app.controllers.map(function(c, i){
    var el = c.element;
    var label = el.id ? ('#' + el.id) : (el.tagName.toLowerCase() + (el.className ? ('.' + String(el.className).trim().replace(/\s+/g, '.')) : ''));
    return { index: i, identifier: c.identifier, element: label };
  });
  return JSON.stringify(list, null, 2);
})()
JS
)"
    js="${js//__STIMULUS_GLOBAL__/$STIMULUS_GLOBAL}"
    run_js "$js"
    ;;

  inspect)
    id="${2:?identifier or index required}"
    js="$(cat <<'JS'
(function(id){
  var app = window.__STIMULUS_GLOBAL__;
  if (!app || !app.controllers) {
    return JSON.stringify({ error: "window.__STIMULUS_GLOBAL__ not found or has no .controllers" });
  }
  var list = app.controllers;
  var c = /^\d+$/.test(id) ? list[parseInt(id, 10)] : list.find(function(x){ return x.identifier === id; });
  if (!c) return JSON.stringify({ error: "no connected controller matching: " + id });
  var ctor = c.constructor;
  var targetNames = ctor.targets || [];
  var targets = {};
  targetNames.forEach(function(t){
    var cap = t.charAt(0).toUpperCase() + t.slice(1);
    try {
      targets[t] = {
        has: !!c['has' + cap + 'Target'],
        count: c[t + 'Targets'] ? c[t + 'Targets'].length : 0
      };
    } catch (e) { targets[t] = { error: String(e) }; }
  });
  var valueNames = ctor.values ? Object.keys(ctor.values) : [];
  var values = {};
  valueNames.forEach(function(v){
    try { values[v] = c[v + 'Value']; } catch (e) { values[v] = 'error: ' + String(e); }
  });
  var el = c.element;
  return JSON.stringify({
    identifier: c.identifier,
    element: el.id ? ('#' + el.id) : el.tagName.toLowerCase(),
    targets: targets,
    values: values
  }, null, 2);
})('__ID__')
JS
)"
    js="${js//__STIMULUS_GLOBAL__/$STIMULUS_GLOBAL}"
    js="${js/__ID__/$id}"
    run_js "$js"
    ;;
esac
