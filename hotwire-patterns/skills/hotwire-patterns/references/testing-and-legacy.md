# System testing Hotwire apps & adding Turbo to legacy apps

## Why Hotwire tests get flaky

Business logic lives on the backend, so skip JS unit tests (stubbing HTML costs more than it's worth) and rely on system tests with a headless browser. But system tests interact far faster than humans, and Hotwire does many small incremental updates with server round-trips — a 100ms transition a human never notices is a race condition for the test runner.

**Principle: assert a stable state before every interaction.** Capybara's finders/matchers already retry until a timeout (`within`, `click_on`, `fill_in`, `assert_text` all wait). Where a built-in helper doesn't cover you:

- `assert_text "..."` — wait for content that signals readiness.
- `assert_no_text "Loading ..."` — wait for a transition to finish. Beware: a typo'd never-rendered string makes this pass trivially.

Assert on **user-visible** content, not implementation details — more robust and closer to real behavior. Capybara has richer matchers beyond text; use them.

Never `sleep`: it doesn't actually fix the race (any finite guess still fails sometimes) and it bloats suite runtime, wrecking the feedback loop. There is always something visible to assert on instead.

## Testing collaborative / broadcast features

Simulate multiple users with fully separate browser sessions:

```ruby
Capybara.using_session("other user") do
  visit root_url
  # acting as the second user
end
# back in the default session
```

Two Hotwire-specific traps:

1. **Broadcasts run as background jobs**, which don't execute in system tests by default. Wrap the mutating interaction in `perform_enqueued_jobs { ... }`.
2. **Broadcasts are debounced (~0.5s)**, so the job is enqueued *after* a naive `perform_enqueued_jobs` block has already closed. Fix: put the *other user's waiting assertion inside the block* — Capybara's retry loop keeps the block open long enough for the debounced job to enqueue and run:

```ruby
perform_enqueued_jobs do
  click_on "Update Ticket"
  Capybara.using_session("other user") do
    assert_text new_title
  end
end
```

3. **Websocket connection setup takes time.** turbo-rails patches `visit` to call `connect_turbo_cable_stream_sources` (waits for all stream sources to connect). If you navigate via clicks rather than `visit`, call it yourself before relying on a broadcast arriving.

Test shape for "user B sees user A's change live": B visits and asserts absence; A edits; inside `perform_enqueued_jobs`, A submits and B asserts presence.

## Adding Turbo to a legacy application

Never big-rewrite. Start with everything installed but **dormant**, then enable incrementally so every step ships value and you can pause anywhere:

```js
// application.js
Turbo.session.drive = false      // Drive off globally
Turbo.session.history.stop()     // cache off
Turbo.setFormMode("optin")       // forms opt in explicitly
```

Scoping tools:
- `data-turbo="false"` / `"true"` nest; nearest ancestor wins.
- Inside a Turbo Frame, Turbo is on by default (selectively re-disable inside with `data-turbo="false"`).
- `<meta name="turbo-root" content="/subpath">` enables Drive for one section of the site only.

The gradual plan (adapt freely):
1. Introduce Frames, Streams, and Stimulus in isolated spots — they assume nothing about the page and are safe anywhere. Start where you're already thinking "this would be easy with Hotwire."
2. Expand frame usage; remove the internal `data-turbo="false"` exceptions. Frames scope actions to themselves and don't need Drive's page-lifecycle takeover (the main source of conflicts).
3. Move `<script>`/`<style>` tags from body to head (modern `async` etc. removed the old reasons).
4. Enable Turbo beyond frames on selected page regions via `data-turbo`.
5. Move whole pages to Drive using `turbo-root` scoping.
6. Enable full-page morphing on pages that are ready for it.
7. Enable Drive globally — done.

Prefetch caveat for legacy apps: GET endpoints that mutate state become dangerous once hovering triggers requests; either fix them or special-case the `X-Sec-Purpose: prefetch` header server-side.

## Prioritizing the migration

Treat it as an investment; front-load returns:
1. **Parts with planned new features** — the payoff (cheaper feature work) arrives soonest.
2. **Highest-pain areas** — similar migration cost, bigger relief.
3. **Areas with uncertain future evolution** — cheap-to-change code widens your option space.
