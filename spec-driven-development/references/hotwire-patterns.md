# Hotwire Patterns Reference

A condensed guide for Turbo + Stimulus patterns in Rails 8 apps. This supplements the `standards/frontend/hotwire.md` standard with decision guidance and pitfall details.

---

## Decision Guide: Which Turbo Feature?

| Situation | Use |
|-----------|-----|
| Standard page navigation | Turbo Drive (automatic) |
| Form submission with redirect | Turbo Drive (automatic) — redirect with 303 |
| Scope update to one page region | Turbo Frame |
| Broadcast to multiple clients | Turbo Streams via Action Cable |
| Complex multi-element update | Turbo Streams (direct response) |
| Full page refresh needed | `redirect_to same_path` (morphs) |

**Default:** Turbo Drive + morph handles 90% of Rails CRUD. Reach for Frames/Streams when Drive can't solve the problem.

---

## Turbo Drive: The Foundation

### Morph Setup (In Layout)
```erb
<%# app/views/layouts/application.html.erb %>
<%= turbo_refresh_method_tag :morph %>
<%= turbo_refresh_scroll_tag :preserve %>
```

### The Standard CRUD Response Pattern
```ruby
def update
  if @resource.update(resource_params)
    redirect_to @resource, notice: t(".updated")    # 303 → morph
  else
    render :edit, status: :unprocessable_entity      # 422 → replace
  end
end
```

The `303 See Other` status is what makes Turbo follow the redirect. Rails produces 303 automatically for PATCH/POST/DELETE, so `redirect_to` is sufficient.

### When NOT to use turbo_stream.refresh

`turbo_stream.refresh` is for **broadcasting** to other connected clients (Action Cable). When returned as a direct form response, Turbo silently ignores it due to `request_id` deduplication.

```ruby
# ❌ This silently does nothing when used as a form response
render turbo_stream: turbo_stream.refresh

# ✅ Use redirect_to instead
redirect_to resource_path
```

---

## Turbo Frames: Scoped Updates

### Basic Frame
```erb
<%# Wrapping content in a frame %>
<%= turbo_frame_tag "user_profile" do %>
  <%= render "profile", user: @user %>
<% end %>

<%# Link that targets the frame (navigation stays scoped) %>
<%= link_to "Edit", edit_user_path(@user), data: { turbo_frame: "user_profile" } %>
```

### Important: Every response must include the matching frame
If the server response doesn't contain `<turbo-frame id="user_profile">`, Turbo throws a `turbo:frame-missing` event and writes an error. Always wrap frame responses in the same frame tag.

### Nested Forms Workaround
HTML doesn't allow nested `<form>` elements. For frame-targeted forms inside another form, use a sibling form:

```erb
<%# Main form %>
<%= form_with model: @post do |f| %>
  <%= f.text_area :content, data: { markdown_editor_target: "textarea" } %>
<% end %>

<%# Preview form — sibling, not nested %>
<%= form_with url: preview_path, 
    data: { turbo_frame: "preview", controller: "preview" },
    class: "hidden" do |f| %>
  <%= f.hidden_field :content %>
<% end %>

<%= turbo_frame_tag "preview" do %>
  <p>Click Preview</p>
<% end %>
```

---

## Stimulus: Patterns and Best Practices

### Controller Anatomy
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { mode: { type: String, default: "write" } }

  connect() {
    // Setup — runs when element enters DOM
    this.boundHandleClick = this.handleClick.bind(this)
    document.addEventListener("click", this.boundHandleClick)
  }

  disconnect() {
    // Cleanup — runs when element leaves DOM
    document.removeEventListener("click", this.boundHandleClick)
  }

  teardown() {
    // Turbo cache cleanup — reset visual state only
    // Called by global turbo:before-cache handler
    this.outputTarget.classList.add("hidden")
  }

  modeValueChanged() {
    // Reactive — auto-called when this.modeValue changes
    this.syncUI()
  }
}
```

### When to Implement teardown()

Add `teardown()` when the controller modifies DOM state that shouldn't persist in the Turbo snapshot cache:

| State | teardown() needed? |
|-------|-------------------|
| Toggled visibility (show/hide) | ✅ Yes |
| Active tabs or selected states | ✅ Yes |
| Pending timers/timeouts | ✅ Yes (clearTimeout) |
| CSS classes added dynamically | ✅ Yes |
| Read-only or navigating only | ❌ No |

### Global Teardown (in application.js)
```javascript
document.addEventListener("turbo:before-cache", () => {
  application.controllers.forEach(controller => {
    if (typeof controller.teardown === "function") {
      controller.teardown()
    }
  })
})
```

### data-turbo-temporary vs teardown()

`data-turbo-temporary` removes elements from the cache snapshot. However, **it does NOT work with morph mode** — morph diffs the DOM instead of restoring from cache. Always use the `teardown()` pattern.

---

## Turbo Events: Key Hooks

```javascript
// Fires before Turbo caches the page
document.addEventListener("turbo:before-cache", handler)

// Fires before rendering (including back/forward cache restores)
document.addEventListener("turbo:before-render", event => {
  // event.detail.newBody is the incoming DOM
  cleanup(event.detail.newBody)
})

// Fires after every page load (initial + Turbo visits)
document.addEventListener("turbo:load", handler)

// Fires after morph completes
document.addEventListener("turbo:morph", handler)

// Form submission started
form.addEventListener("turbo:submit-start", event => {
  // event.detail.formSubmission.stop() to abort
})
```

---

## Turbo Data Attributes Quick Reference

| Attribute | Use |
|-----------|-----|
| `data-turbo="false"` | Disable Turbo on element |
| `data-turbo-frame="id"` | Target a Turbo Frame |
| `data-turbo-confirm="msg"` | Confirm dialog before action |
| `data-turbo-method="delete"` | Change link HTTP method |
| `data-turbo-permanent` | Preserve element across morphs (needs unique `id`) |
| `data-turbo-track="reload"` | Reload page when asset fingerprint changes |
| `data-turbo-submits-with="..."` | Button text during submission |

---

## Common Pitfalls

1. **`turbo_stream.refresh` as form response** — silently ignored. Use `redirect_to`.

2. **200 response to POST** — Turbo won't update URL. Always redirect on success.

3. **Missing frame in response** — Turbo throws error. All frame responses need matching `<turbo-frame>` tag.

4. **`data-turbo-temporary` with morph** — Has no effect. Use `teardown()` instead.

5. **Lazy I18n in gem partials** — `t(".key")` inside a gem component block resolves to the gem's path, not your app's. Use full I18n keys inside `do...end` blocks.

6. **Stale Stimulus state in cache** — Any controller that toggles visibility or has timers must implement `teardown()`.

7. **Forgetting `local: true` on special forms** — If a form needs full-page navigation lifecycle (e.g., complex Stimulus controllers), add `local: true` to opt out of Turbo Drive.
