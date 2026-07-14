# Stimulus: designing reusable, composable controllers

Complex UIs = simple, focused controllers reused and combined (the cockpit-of-switches model). Two questions govern everything: how to make a controller reusable, and how to make controllers cooperate.

## Reusability principles

1. **HTML is the source of truth.** Store no state on the controller instance. Stimulus assumes something else renders the HTML; lean into that.
2. **Configure from HTML.** Values over hard-coded constants. Provide value defaults when reasonable so the attribute becomes optional.
3. **Eliminate assumptions about the document.** Fewer expectations → usable in more places. Gracefully degrade when elements are absent (`this.has[Name]Target`, optional targets).
4. **Narrow scope.** Prefer several small controllers over one broad one. Lots of internal code is fine; it's the *outward-facing* assumptions and side effects that must stay minimal.

## Callbacks are the engine

Put logic in the most specific callback available:

| Concern | Callback |
|---|---|
| Per-target setup | `nameTargetConnected(el)` |
| Per-target teardown | `nameTargetDisconnected(el)` |
| React to config/state | `nameValueChanged(current, previous)` |
| Wiring only | `connect()` |
| Residual cleanup | `disconnect()` |

Why this matters:
- Target callbacks fire both at initial connect **and** whenever a target appears/disappears later — controllers become robust to frames loading, streams tweaking the DOM, other controllers, or third-party libraries acting on the same subtree.
- `nameValueChanged` fires on initialization and on every attribute change, from any source. Writing `this.nameValue` writes the data attribute; editing the attribute (dev tools, another controller, a Turbo update) flows back in. Rendering that lives in the value-changed callback keeps HTML and behavior in lockstep and skips no-op updates.
- These observers sit on Stimulus's optimized `MutationObserver` machinery — don't reimplement it.

Countdown example shape: `static values = { count: Number }`; the interval only decrements `this.countValue`; `countValueChanged(current)` writes the target's text. Editing the data attribute live changes the countdown; server-rendered updates just work.

## Composition mechanisms (in order of preference)

1. **Indirect via shared HTML.** One controller mutates the DOM, another reacts through its callbacks. Fully decoupled; interaction is visible as HTML diffs. Reach for this first — it falls out automatically if the reusability principles were followed.
2. **Custom browser events.** `element.dispatchEvent(new CustomEvent("app:thing", { bubbles: true, cancelable: true }))` — both flags must be set explicitly on CustomEvent. Prefix event names (`hot:`, app-derived) to avoid clashes. Listen either by:
   - Hand-attached listener in `connect` (remove in `disconnect`; declare handlers as arrow-function instance fields to bind `this`) — use when the controller must "just work" by being attached, e.g. a loader that must catch several Turbo events.
   - `data-action="app:thing->ctrl#method"` — Stimulus does the bookkeeping; behavior is visible in HTML. Default choice; migrate into `connect` only if usage proves error-prone.
   - Listener on `this.element` only works if the event dispatches within its subtree; otherwise listen on `document`.
3. **Outlets.** Direct controller-to-controller method calls. `static outlets = ["form"]` + `data-<ctrl>-form-outlet=".selector"` on the host element. Selector is global (`querySelectorAll` semantics — outlets can live anywhere on the page, unlike targets). Access via `this.formOutlet` / `this.formOutlets` / `this.hasFormOutlet`, plus `formOutletConnected/Disconnected` callbacks (prefer them, same as targets). Selector tip: match `[data-controller~='form']` rather than design CSS classes that a restyle might rename. Beware: an empty selector match is silently valid.

## Events vs outlets decision guide

- Page-wide significant changes with unknown listeners (e.g., online/offline status) → **events**.
- Clear parent→child relationship where the parent drives children → **outlets**.
- Emitter shouldn't care whether anyone reacts → **events**.
- Receiver shouldn't care whether anyone calls it → **outlets**.
- Events: harder to trace/debug, but zero coupling. Outlets: easy call-stack debugging and precise addressing, but interface coupling and silent selector rot.

Classic OO maintainability intuition transfers directly.

## Misc mechanics worth remembering

- `data-action` DSL extras: `keydown.esc->modal#close`; `@window` / `@document` suffixes for global events (last resort); `:stop` / `:prevent` modifiers; `data-<ctrl>-<name>-param` attributes populate `event.params`.
- Registration without Rails sugar: `Application.start()` then `Stimulus.register("name", class extends Controller {...})`; Rails infers the name from the filename.
- Everything (controller lifecycle, values, targets, outlets) is driven by a `MutationObserver` rooted at `<html>`, dispatching on attribute mutations and childList changes. When Stimulus "misses" something, the bug is almost always a data-attribute typo, not the observer.
