---
name: hotwire-patterns
description: Deep Hotwire (Turbo, Stimulus, Hotwire Native) mental models, decision frameworks, and internals-informed debugging for Rails apps. Use whenever working with Turbo Drive/Frames/Streams, Morphing, ActionCable broadcasting, Turbo Cache, Stimulus controller design, Hotwire Native (iOS/Android, Path Configuration, Bridge Components), system testing Hotwire features, migrating legacy apps to Turbo, or debugging Hotwire behavior. Triggers on "Turbo Frame not updating", "Content missing", "morphing wipes my form", "broadcast not arriving", "flaky system test", "add Hotwire to legacy app", "wrap app with Hotwire Native", or any Turbo/Stimulus/Hotwire design decision.
---

# Hotwire Patterns

Internals-informed patterns for building and debugging Hotwire applications. Core philosophy: **enhance the browser, don't reinvent it**. Start by imagining a JS-free, plain-HTML version of every feature, then compose the separate pages into an integrated UI with Turbo. HTML is the source of truth for state, everywhere.

## The escalation ladder (choose the cheapest tool that works)

Hotwire is a cost/benefit dial, not a single approach. Escalate only when the previous rung stops being a good tradeoff:

1. **Turbo Drive + Morphing refreshes** — re-render everything server-side; fastest to build.
2. **Turbo Frames** — decompose the page; localize updates without touching the rest.
3. **Turbo Stream actions** — surgical DOM updates; more precise, more maintenance cost.
4. **Stimulus** — small client-side behavior where a server round-trip makes no sense.
5. **Island of reactive framework (React/Vue) or API calls** — only for genuinely high-interactivity widgets (maps, editors).

Different parts of one app can sit on different rungs; it all composes.

## Turbo Drive essentials

- Drive intercepts link clicks and form submissions, fetches via `fetch`, replaces `<body>` wholesale, and diff-merges `<head>` children (identical nodes untouched → assets not re-parsed; that's the speed win). Order of head children isn't preserved and doesn't matter.
- Assets must live in `<head>`. Modern `async` scripts + HTTP/2 remove old reasons for body-bottom scripts.
- UJS replacements: `data: {turbo_method: :delete}` for non-GET links; `data: {turbo_confirm: "..."}` for confirm dialogs (works on forms and non-GET links; add `turbo_method: :get` to use on plain links). Customize globally via `Turbo.config.forms.confirm = (message, formEl, submitter) => Promise<boolean>`.
- Submit buttons auto-disable during submission. `turbo:submit-start` / `turbo:submit-end` events carry `event.detail.formSubmission.submitter` — use for loaders.
- **Failed form submissions must return 4xx** (`render :new, status: :unprocessable_entity`). Turbo requires a redirect on success; it renders 4xx bodies happily.
- `Turbo.visit(location)` is the programmatic navigation entry point; `Turbo.visit(location, { frame })` navigates a frame.
- Non-GET links work by Turbo building a hidden form on the fly and submitting it — everything true of forms is true of these links.
- Visit types: `advance` (link click), `replace` (redirect after form submit), `restore` (history). This matters for morphing (below).
- Link prefetch fires after 100ms hover on plain GET links (no turbo-stream expectation, no confirm dialog). GET idempotency becomes mandatory; the `X-Sec-Purpose: prefetch` header identifies prefetches server-side if you must special-case.

## Turbo Frames

Mental model: **a page within a page**. A frame runs the same three observers as Drive (link clicks, non-GET links, form submits) but scoped, and updates only itself.

- Links/forms inside a frame load the response, find the frame with the **matching id** in it, and swap only that frame's content. The response page needs the same `turbo_frame_tag` — you don't need to frame the whole target template, just the part you want.
- `data-turbo-frame="_top"` on a link/button/form escapes the frame and drives the full page. `target: "_top"` on the frame tag itself makes everything inside escape by default.
- Use `dom_id` for frame ids everywhere; `turbo_frame_tag record` uses it under the hood. For "new" records that need per-context frames (e.g., one new-form per kanban column), build custom string ids in a helper — frame ids are global on the page.
- Remote frames: `src:` attribute loads content on render (eager) or on scroll into view with `loading: "lazy"`. Great for decomposing heavy pages (dashboards) into independent endpoints — progressive enhancement applied to composition.
- Missing frame in the response → console warning + `TurboFrameMissingError` + "Content missing" in the UI. Catch `turbo:frame-missing` to handle it yourself (`preventDefault`), and consider reporting these to error tracking (ignore 5xx statuses — already logged server-side; get status from `event.detail.response.status`).
- `data-turbo-permanent` elements (must have unique ids) are transplanted as the same live JS objects across updates — listeners and state survive.
- Frame renderer re-runs inline `<script>` tags unless `data-turbo-eval="false"`.

## Turbo Streams

Custom `<turbo-stream action=... target=...>` elements that **execute instead of render** (their `connectedCallback` interprets the action and removes the tag). Standard actions: append, prepend, replace, update, remove, before, after, refresh (no target). `targets=` (plural) takes a CSS selector.

- **The classic frame-id mismatch**: a "new" form frame (`new_ticket`) redirects on success to a page whose frame is `ticket_4` → Content missing. Fix with a `create.turbo_stream.erb` responding to `format.turbo_stream`, either with precise actions (append + clear form + prepend notice) or a single `turbo_stream.refresh request_id: nil`.
- The general problem: **the correct UI update is only known server-side after processing**. Streams (or refresh) are how the server takes control.
- `refresh` re-fetches the current page and re-renders via replace or morph. `request_id: nil` is required when returning refresh in the HTTP response itself — otherwise the frontend recognizes its own request id and ignores it (the dedup mechanism exists so broadcasts don't double-refresh the originating user).
- **Custom stream actions** are the sanctioned way to run backend-driven browser behavior: `Turbo.StreamActions.log = function() { ... this.getAttribute("message") ... }` (executes with `this` = the stream element; attributes aren't parsed into params). Pair with a Ruby helper module included into `Turbo::Streams::TagBuilder`. Benefits: a constrained **vocabulary of UI manipulations** (maintainability) and CSP compatibility (no `unsafe-inline` needed). Prefer app-specific actions over dropping in big libraries like turbo_power.

## Morphing

Read `references/morphing.md` before debugging any morph behavior — it covers the idiomorph algorithm, id maps, and match scoring.

Quick rules:
- Enable with `turbo_refreshes_with method: :morph, scroll: :preserve` in the layout head, **above** `yield :head`.
- Morph only happens when: visit action is `replace` AND the new URL equals the current URL (trailing slash sensitive!). Redirect back to the same path or you silently get `replace` rendering. Verify with `turbo:render` → `event.detail.renderMethod`.
- `data-turbo-permanent` survives all updates including frame updates — too blunt when the element must still be frame-updatable. Roll a scoped attribute instead: listen to `turbo:before-morph-element` and `preventDefault()` when the element has e.g. `data-turbo-prevent-morph`. Requires stable ids and identical child structure between old/new so the morpher pairs the elements.
- Think of morphing as **VirtualDOM on the server**: server renders the ideal tree, idiomorph reconciles the browser to it.

## Broadcasting (ActionCable)

- `turbo_stream_from @record` (or a plain string) renders a `<turbo-cable-stream-source>` with a signed stream name (via `to_gid_param`, falling back to `to_param` — that's why strings work).
- `broadcasts_refreshes` on the model = after commit callbacks calling `broadcast_refresh_later_to`. To broadcast to a shared stream on create/update/destroy, write the three callbacks yourself against the stream name.
- Broadcasts run through a **background job** (`Turbo::Streams::BroadcastStreamJob`) and are **debounced ~0.5s per thread** — multiple saves in one request emit one refresh. For latency-critical paths, enqueue the job directly and skip the debouncer.
- Originating clients ignore their own refresh via the `X-Turbo-Request-Id` mechanism.
- Refreshes from different models aren't aggregated — ask whether each model really needs to broadcast.
- Everything (websockets, SSE) works identically inside Hotwire Native webviews — collaborative features are free on mobile.

## Stimulus

This section covers the *mental model* — how Stimulus fits the Hotwire picture. For exhaustive controller-authoring patterns (Values API, targetless controllers, mixins, teardown, SOLID, cookbook), use the **`better-stimulus`** skill; it's the authority for writing a controller. Read `references/stimulus.md` here for the design principles (reusability, callbacks, composition via events vs outlets). Core rules:

- HTML is the source of truth; controllers store no state. Prefer `[name]TargetConnected`/`Disconnected` and `[name]ValueChanged` callbacks over `connect` — they make controllers robust to any DOM change source (Turbo, other controllers, anything).
- `connect` = wiring only; `disconnect` = cleanup not handled by target callbacks.
- Action DSL: `event->controller#method`, `keydown.esc->modal#close`, `resize@window->x#y` (last resort), `:stop`/`:prevent` options, `data-<controller>-<name>-param` → `event.params`.
- Dynamic forms pattern: instead of encoding variation logic in JS, a generic controller serializes the form and re-submits it to the `new` endpoint on any watched input change; the **server renders the variation**. One reusable controller, all form logic in one backend place.
- Rails registers controllers by inferring names from filenames; under the hood a `MutationObserver` on `<html>` powers everything (controller attach/detach, values, targets, outlets).

## Turbo Cache

- Turbo snapshots the last 10 pages (`cloneNode(true)` — **HTML only**; listeners/state don't survive, which is fine if Stimulus reconnects rebuild everything).
- Back/Forward restores from cache with no revalidation ("read your own writes": any form submission clears the whole cache; call `Turbo.cache.clear()` if you mutate state outside forms).
- In-page navigation to a cached URL shows a **preview** then immediately fetches and updates — flashing happens when cached HTML holds transient UI state (open dropdowns). Fixes, pick per situation: `data-turbo-temporary` (auto-removed before caching; ideal for flash messages), clean up in Stimulus `disconnect` (fires on snapshot clone), `turbo:before-cache` listener for global resets, or `<meta name="turbo-cache-control" content="no-preview">` / `no-cache`.
- Cache key is the URL minus the anchor. Passwords are cleared; selects are reset. `data-turbo-visit-direction` on `<html>` (`forward`/`back`/`none`) helps animate view transitions.
- Snapshotting only happens on GET; it runs async and never blocks rendering.

## Hotwire Native

Read `references/hotwire-native.md` when building or debugging the mobile apps (setup, Path Configuration, Bridge Components, publishing, native debugging).

One-line mental model: a webview wrapper that injects `turbo.js` to register a **native Turbo adapter**; full-page visits get proposed to native code (push/pop screen stacks), frame/stream updates stay pure-web. Different URLs = different screens; mind trailing slashes.

## Testing & legacy migration

Read `references/testing-and-legacy.md` for: system-test flakiness (always assert a stable state; Capybara waiting), multi-session collaborative tests (`Capybara.using_session`, `perform_enqueued_jobs` wrapping the waiting assertion because broadcasts are debounced, `connect_turbo_cable_stream_sources`), and the 7-step gradual Turbo adoption plan for legacy apps (start with everything disabled: `Turbo.session.drive = false`, `Turbo.session.history.stop()`, `Turbo.setFormMode("optin")`, then expand frame by frame).

## Debugging

Read `references/debugging.md` when hunting a Hotwire bug. Highlights: unminify Turbo in the importmap (`turbo.js` not `turbo.min.js`); use DOM "Break on" (subtree/attribute/removal) breakpoints to catch Turbo mid-update; key Turbo source landmarks (`Navigator#proposeVisit`, `LinkInterceptor#linkClicked`, `StreamActions`, search `"turbo:morph"` / `shouldMorphPage =`); check `Turbo-Frame` request header for frame issues; filter ActionCable pings in the Network Socket tab with `^(?!.*"type":"ping").*$`; `Stimulus.debug = true` for lifecycle prints; disable cache to rule it out.
