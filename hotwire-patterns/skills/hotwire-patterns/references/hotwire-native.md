# Hotwire Native: wrapping the web app into iOS/Android apps

Hotwire Native (launched Sep 2024) merged Turbo Native + Strada (Strada → "Bridge Components"). Treat Turbo Native/Strada resources as deprecated when searching online.

## Mental model

- A native app embeds a **webview** (WKWebView on iOS, Android WebView) running the platform browser engine (WebKit/Safari; Chromium/V8). Feature and performance parity with the mobile browser is a safe assumption except for cutting-edge/experimental features. Websockets, SSE, file-upload pickers all work — collaborative features come for free.
- Web = **pages forming history**; native = **screens stacking**. Hotwire Native assumes **different URLs are different screens**: full-page Drive navigation pushes/pops screens; frame/stream updates within a page don't touch the stack. Trailing slashes matter twice as much — a mismatched redirect URL pushes a spurious screen.
- Two default screen stacks (sessions): main + modal. Each `Session` owns one webview. More sessions/native screens are possible (e.g., an offline ticket wallet screen) but usually unnecessary.
- **The integration trick**: the native side injects `turbo.js` into the webview, which registers a custom Turbo **adapter** (replacing `BrowserAdapter`). Full-page visits flow `Session → Navigator#proposeVisit → adapter.visitProposedToLocation`, where the native adapter decides: let Turbo handle it, or take over natively. That method is the first place to look when web/native integration misbehaves.
- Injected JS boot: try immediately → wait for `turbo:load` → last-resort timeout (Android ~4s, iOS ~30s — a source of Android-only loading differences). iOS talks native via `postMessage`; Android via `addJavascriptInterface`.
- User-Agent gains `Hotwire Native <platform>` plus a `bridge-components: [...]` list — the basis for `hotwire_native_app?` and bridge feature detection.

## Server-side customization (no native code)

- `hotwire_native_app?` helper (turbo-rails) for conditional rendering. Downsides: must be sprinkled everywhere and doubles cache keys for cached partials.
- Prefer CSS: add a class in the layout (`<html class="<%= "hotwire-native" if hotwire_native_app? %>">`) and write `html.hotwire-native ...` rules; or conditionally include a native-only stylesheet for sweeping changes. A generic `.hide-on-native` utility class covers redundant links (e.g., "Back" links inside a native modal that has its own dismiss UI).
- The HTML `<title>` becomes the native screen title automatically; hide the in-page `<h1>` on native.
- Cookies persist across app restarts (given proper expiry) and are shared across all the app's webviews — log users in with permanent "remember me" sessions and login works everywhere.

## Path Configuration

JSON (bundled with the build AND fetched remotely from your server, remote overrides bundled) with `settings` (yours) and `rules`: each rule = `patterns` (regexes matched against the URL) + `properties` (later rules override earlier; go general → specific). `"context": "modal"` renders matching pages in the native modal stack.

Serving pattern: a plain Rails controller with **per-platform, versioned endpoints** (`ios_v1`, `android_v1`, bump versions only for breaking changes — old app versions keep the old endpoint). Keep iOS and Android configs separate; their supported options differ, and DRYing hashes in Ruby is trivial if needed.

Gotchas:
- Patterns match path **and query** by default. `/new$` won't match `/new?state=x`. iOS can set `Hotwire.config.pathConfiguration.matchQueryStrings = false`; Android has no such switch — widen the regex (`/new(\\?.*)?$`).
- On Android, add a base `".*"` rule declaring defaults (`context: "default"`, `uri: "hotwire://fragment/web"`) so you can customize globally, e.g. `pull_to_refresh_enabled: true` everywhere but `false` on modals (pull-down dismisses modals).
- Config loads at app boot — restart the app after changing it.
- **Only full-page visits are intercepted natively.** Links/forms living inside Turbo Frames must be escalated: `data: {turbo_frame: ("_top" if hotwire_native_app?)}` on links, `target: ("_top" if hotwire_native_app?)` on the frame tag for form pages. Turbo can't decide this for you (sometimes inline is right). Strategy: keep web unchanged, add explicit conditionals, then extract app-specific helpers once patterns emerge.
- Form flows: redirect to where the board/list lives (often `root_path` when native) so the modal dismisses (new page's context is no longer modal → Hotwire Native closes the modal and navigates the main screen). Turbo-stream responses that `refresh` will refresh *the modal's page* on native — replace with `redirect_to root_path if hotwire_native_app?` inside `format.turbo_stream`.

## Bridge Components

Terminology: **bridge controller** = web side (Stimulus subclass); **bridge component** = native side (Swift/Kotlin `BridgeComponent` subclass registered with Hotwire).

Web side:
- Install `@hotwired/hotwire-native-bridge` (importmap pin). Controller extends `BridgeComponent` (which extends Stimulus `Controller`), declares `static component = "submit-button"`, and attaches via normal `data-controller="bridge--submit-button"`. Convention: keep them in a `controllers/bridge/` subfolder.
- `this.send(event, data, callback)`: event string (often mirrors the method, e.g. `"connect"`), payload, and a callback invoked when native replies. `this.bridgeElement` wraps the element: `.title` (looks up `data-bridge-title` → `aria-label` → text/value) and `.click()` (platform-safe simulated click).
- Send `"disconnect"` from `disconnect()` so native can clean up.
- **Auto feature detection**: the controller only attaches if the running app advertises the component name in the UA (`static shouldLoad`). Old app versions silently fall back to the web UI — deployments stay safe.
- Hide the now-redundant HTML element with CSS keyed off attributes the bridge JS sets on `<html>`: `data-bridge-components` (space-separated list) and `data-bridge-platform`. e.g. `[data-bridge-components~="submit-button"] [data-controller~="bridge--submit-button"] { display: none; }`.
- Even when a platform needs no native work (Android's built-in modal "X" covers cancel), implement a **no-op component** and use the same component-advertised hiding mechanism rather than platform CSS. Uniform logic + correct fallback for old app versions.

Native side (both platforms): subclass `BridgeComponent`, expose the matching name, implement `onReceive(message)` switching on `message.event`, decode the typed payload (Swift `Decodable` struct / Kotlin `@Serializable` data class — Android also needs `Hotwire.config.jsonConverter = KotlinXJsonConverter()`), render native UI (iOS: `UIBarButtonItem` with a `UIAction` calling `reply(to: "connect")`; Android: `ComposeView` with a `Button(onClick = { replyTo("connect") })` added to the toolbar), and register via `Hotwire.registerBridgeComponents(...)`. Android must handle `"disconnect"` by removing the view (track it with an assigned view id) or repeated opens duplicate it; iOS avoids this because assignment to `rightBarButtonItem` overwrites.

Message plumbing: bridge `send` assigns a unique message id, stashes the callback in a pending-callbacks map, ships id+payload to native; native's reply carries the id back; the bridge looks up and invokes the callback. Boot ordering is handled by the injected adapter waiting for the `web-bridge:ready` event and a message queue that flushes when the adapter registers. Nearly all bridge logic is JavaScript (~300 lines) — debug there, not in Swift/Kotlin.

## Setup & publishing quick notes

- iOS: Xcode project (Storyboard/Swift), add the hotwire-native-ios package, replace `SceneDelegate` with a `Navigator(configuration:)` pointed at the root URL and `navigator.start()`. Path config + bridge registration go in `AppDelegate.application(...)`. Use `#if DEBUG` compiler directives to switch localhost vs production root URLs. App Store: $99/yr program, bundle id, archive → distribute; first-archive signing errors are usually fixed by selecting a team and building once against a physical device.
- Android: Empty Views Activity (Kotlin, min SDK 28), add `dev.hotwire:core` + `dev.hotwire:navigation-fragments`, layout = a `FragmentContainerView` naming `NavigatorHost`, `MainActivity : HotwireActivity` returning `navigatorConfigurations()`. Emulator reaches the host machine at `10.0.2.2`; dev needs `INTERNET` permission + `usesCleartextTraffic`. Configure Hotwire in a custom `Application` subclass (registered in the manifest) to avoid init races. Release: `buildConfigField` per build type for BASE_URL, signed App Bundle with a keystore (gitignore it), Play Console internal testing ($25 one-time).
- Debug logging: `Hotwire.config.debugLoggingEnabled = true` (Android also `webViewDebuggingEnabled`). Inspect the webview with Safari's Develop menu (iOS sim) or `chrome://inspect/#devices` (Android). Bug triage order: does it reproduce on mobile web? → web bug. Otherwise native or the bridge; watch `bridgeDidReceiveMessage` logs.
