# Debugging Hotwire applications

Debugging loop: reproduce reliably → isolate → fix and verify. The more of the internals you know, the faster isolation goes — when stuck, re-read the relevant mechanism (morphing, cache, frames) before spending hours searching. Stepping into library source with the debugger is usually faster than the internet.

## Setup

Unminify Turbo so you can read and breakpoint it (importmap):

```ruby
pin "@hotwired/turbo-rails", to: "turbo.js"  # instead of turbo.min.js
```

Essential dev-tool tabs: Elements (inspect HTML + DOM breakpoints), Console (executes in the paused debugger's scope), Sources (line breakpoints in JS assets), Network (requests + websocket messages).

## Turbo: page-update issues

DOM breakpoints are the key tool. Right-click an element → *Break on*:
- **subtree modifications** — any descendant change; ideal for catching Turbo mid-update and reading the call stack.
- **attribute modifications** — great for frame lifecycle issues (remote frames inside morphed content have the most complex lifecycle; breakpoint inside `FrameController` in Turbo source if frames act strange).
- **node removal** — least useful; a wrongly-removed node usually just means it's absent from the new server HTML.

Playbook: reproduce reliably → mark the misbehaving element with a DOM breakpoint → re-trigger → walk the call stack, inspecting locals at each level.

Morphing-specific: element breakpoints fire on unrelated earlier updates, so first pause just before the morph, then set element breakpoints while paused. Useful Turbo-source landmarks (search these strings in Sources):
- `"turbo:morph"` — the dispatch site; the enclosing `renderElements` performs the actual morph.
- `shouldMorphPage =` — inside `PageView#renderPage`, fires on every response render; start here if the morph breakpoint never hits.
- `linkClicked=` — the link-interception callback, if the request never even leaves.

Don't over-invest in a minimal repro for morph bugs — element breakpoints work fine amid noise; minimize later only if filing an upstream issue.

## Turbo: request issues

Rule out the cache first: `Turbo.session.history.stop()` — if the bug vanishes, it's a cache problem (see the cache section of SKILL.md); if not, cache is exonerated.

Wrong verb (GET instead of DELETE/POST) or Turbo not intercepting at all: every potential request passes through `Navigator#proposeVisit`. For link-specific issues, `LinkInterceptor#linkClicked` — step into `shouldInterceptLinkClick` (why isn't Turbo taking it?) or `linkClickIntercepted` (why is the request malformed?).

## Turbo: response issues

"Content missing" (frame not found in response):
1. Check the request's `Turbo-Frame` header — is it the frame you expect?
2. Check the Response tab, then Rails logs — why doesn't the response contain that frame? From there it's ordinary controller debugging.
3. Report `turbo:frame-missing` events to error tracking (skip 5xx — already captured server-side). Capture target outerHTML, origin/request URLs, status, content-type, and the response body text from `event.detail.response`.

Streams not applying:
1. Pure stream responses need `Content-Type: text/vnd.turbo-stream.html`.
2. Eyeball the returned `<turbo-stream>` markup for typos.
3. Breakpoint the matching method in Turbo's `StreamActions` class — the classic failure is `this.targetElements` being empty from a wrong id/selector, which Turbo silently ignores.

## Broadcasts

Network tab → filter **Socket** → the `cable` request → **Messages** subtab. Filter out keepalive pings with the regex `^(?!.*"type":"ping").*$` (Firefox: wrap in slashes). Messages absent → backend problem (callbacks, job execution, stream names). Messages present but no UI change → it's a stream-execution problem; debug as above.

## Stimulus

- Controller ran but did the wrong thing → the bug is almost certainly in your controller code; use standard JS debugging. Stimulus only routes calls.
- Controller did **nothing** → almost always a data-attribute typo; Stimulus is deliberately forgiving and silently skips what it doesn't recognize. Turn on `Stimulus.debug = true` and compare the printed lifecycle (`application #start`, `ctrl #initialize/#connect/#disconnect`, method names on data-action invocations) against what you expected: missing entry, unexpected entry, wrong order? Console search filters the noise.
- Extra tooling: the Hotwire Dev Tool browser extension (inspect frames/controllers on the page) and Stimulus LSP (VSCode/Zed; assumes standard Rails layout).

## Hotwire Native

First question: does it reproduce on the mobile **web**? If yes, ignore native entirely. If not, it's native code or the bridge:
1. `Hotwire.config.debugLoggingEnabled = true` (Android also `webViewDebuggingEnabled = BuildConfig.DEBUG`). Watch `bridgeDidReceiveMessage` entries (Xcode Debug Area / Android Logcat) — bridge messages are the top error source.
2. Attach browser dev tools to the embedded webview: Safari's Develop menu → your simulator (main and modal stacks appear as separate "tabs"); Android via `chrome://inspect/#devices` → inspect. Then debug with normal web techniques.
3. Only if the fault is genuinely native: platform debugger (Xcode / Android Studio debug build), plain line breakpoints. Bridge logic is ~all JavaScript, so this is rare.
