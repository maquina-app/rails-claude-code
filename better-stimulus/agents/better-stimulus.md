---
name: better-stimulus
description: >
  Apply opinionated StimulusJS best practices from betterstimulus.com. Use this
  skill whenever writing, reviewing, debugging, or refactoring Stimulus
  controllers. Triggers when user asks to write, fix, or review a Stimulus
  controller, asks about data-controller, data-action, data-target, data-values,
  outlets, lifecycle callbacks, state management in Stimulus, Hotwire patterns,
  or Turbo and Stimulus integration.
---

# Better Stimulus

Opinionated StimulusJS best practices sourced directly from [betterstimulus.com](https://www.betterstimulus.com) / [julianrubisch/better-stimulus](https://github.com/julianrubisch/better-stimulus).

---

## ARCHITECTURE

### 1. Application Controller
Create a base `ApplicationController` that all controllers inherit from. Use it to share lifecycle hooks and utility methods across the app.

```js
// application_controller.js
import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  // shared helpers, error handling, etc.
}

// custom_controller.js
import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  // specialized behavior
}
```

**When NOT to use inheritance:** Ask whether the shared behavior is a *specialization* ("is a") → use inheritance; a *role* ("acts as a") → use mixins; a *collaborator* ("has a") → use composition.

---

### 2. Configurable Controllers (Late Binding)
Never hardcode dependencies (CSS classes, selectors, IDs) inside controllers. Use the Classes API, Values API, or dataset attributes so controllers are reusable.

Bad:
```js
toggle(e) {
  this.element.classList.toggle("active"); // hardcoded class
}
```

Good:
```html
<a data-controller="toggle" data-action="click->toggle#toggle" data-toggle-active-class="active">
```
```js
static classes = ["active"];

toggle(e) {
  e.preventDefault();
  this.element.classList.toggle(this.activeClass);
}
```

**Rationale:** Late binding of dependencies ensures controllers are reusable across multiple use cases without modification.

---

### 3. Mixins Over Inheritance for Shared Behavior
When behavior is a *role* (not a specialization), use mixins instead of inheritance.

Bad — extending a concrete controller:
```js
import OverlayController from "./overlay_controller";
export default class extends OverlayController { ... }
```

Good — mixin pattern:
```js
// mixins/useOverlay.js
export const useOverlay = controller => {
  Object.assign(controller, {
    showOverlay(e) { ... },
    hideOverlay(e) { ... }
  });
};

// dropdown_controller.js
import { useOverlay } from "./mixins/useOverlay";
export default class extends Controller {
  connect() {
    useOverlay(this);
  }
}
```

**Rule of thumb:** *is a* → inheritance; *acts as a* → mixin; *has a* → composition.
Reference: [stimulus-use](https://github.com/stimulus-use/stimulus-use)

---

### 4. State Management with Values API
Use Stimulus `values` as the single source of truth for controller state — not instance variables.

Bad:
```js
connect() {
  this.markers = []; // instance variable, not serialized
}
addMarker() {
  this.markers.push({...});
}
```

Good:
```js
static values = { markers: Array }

addMarker() {
  this.markersValue = [...this.markersValue, {...}];
}

markersValueChanged(markers) {
  this.map.updateMarkers(markers);
}
```

**Rationale:** Values are serialized in the DOM, providing a single source of truth. They enable state mutation from outside (Turbo Streams, morphing) and interact correctly with Turbo caching.
**Contraindication:** Don't use values for non-serializable state (e.g., library instances like Swiper) or sensitive data you don't want in HTML.

---

### 5. Namespaced Attributes
When you need an arbitrary set of controller-scoped parameters beyond what Values API provides, namespace them as `data-[controller]-param-[name]`.

```html
<input data-controller="filter"
       data-filter-param-category="cats"
       data-filter-param-rating="5"
       type="text"
       data-action="input->filter#update">
```

```js
update() {
  const url = new URL(window.location);
  Object.keys(Object.assign({}, this.element.dataset))
    .filter(attr => attr.startsWith("filterParam"))
    .forEach(attr => {
      url.searchParams.set(
        attr.slice(11).replace(/^\w/, c => c.toLowerCase()),
        this.element.dataset[attr]
      );
    });
  history.pushState({}, '', url.toString());
}
```

---

### 6. Targetless Controllers
Keep controllers that act on `this.element` separate from those that act on `targets`. Mixing them is a Single Responsibility violation.

Bad — form controller managing its own indicator:
```js
static targets = ["indicator"];
submit() {
  this.indicatorTarget.textContent = "Saving...";
  this.element.requestSubmit();
}
```

Good — split into two focused controllers:
```html
<form data-controller="form form-indicator" data-action="submit->form-indicator#display">
  <span data-form-indicator-target="indicator"></span>
  <input type="number" data-action="change->form#submit" />
</form>
```

**Signal:** If a controller would change for two different reasons (element behavior AND target behavior), split it.

---

## LIFECYCLE

### 7. Don't Overuse `connect()`
`connect()` is the correct place for: initializing 3rd party plugins (Swiper, Dropzone, Chart.js), DOM preconditions, browser capability checks.

`connect()` is **NOT** the right place for:
- Setting up state → use Values instead
- Adding event listeners → use `data-action` in markup instead

Bad:
```js
connect() {
  this.open = false; // state in instance var
  this.buttonTarget.addEventListener("click", this.toggle.bind(this)); // manual listener
}
```

Good:
```html
<div data-controller="toggle"
     data-toggle-open-value="false"
     data-toggle-hidden-class="hidden">
  <button data-action="toggle#toggle">Click to open</button>
  <div data-toggle-target="panel" class="hidden"></div>
</div>
```
```js
static values = { open: Boolean };
static classes = ["hidden"];

toggle() {
  this.openValue = !this.openValue;
}

openValueChanged() {
  this.panelTarget.classList.toggle(this.hiddenClass, !this.openValue);
}
```

---

## EVENTS

### 8. Register Global Events in Markup, Not in `connect()`
Stimulus automatically adds and removes event listeners declared in `data-action`.

Bad:
```js
connect() {
  document.addEventListener("resize", this.layout.bind(this));
}
```

Good:
```html
<div data-controller="gallery" data-action="resize@window->gallery#layout">
```

**If you must add listeners manually**, store the bound reference to ensure proper cleanup:

Bad — `.bind()` creates a new function each time, so `removeEventListener` won't find it:
```js
connect() {
  document.addEventListener("click", this.findFoo.bind(this));
}
disconnect() {
  document.removeEventListener("click", this.findFoo.bind(this)); // different reference!
}
```

Good:
```js
connect() {
  this.boundFindFoo = this.findFoo.bind(this);
  document.addEventListener("click", this.boundFindFoo);
}
disconnect() {
  document.removeEventListener("click", this.boundFindFoo);
}
```

---

## INTERACTION (INTER-CONTROLLER COMMUNICATION)

### 9. Outlets — Direct Controller-to-Controller Messaging
Use the Outlets API when you need to call methods directly on another controller.

```html
<body data-controller="job-dashboard"
      data-job-dashboard-job-outlet=".job">
  <button data-action="job-dashboard#refresh"></button>
  <ul>
    <li data-controller="job" class="job"></li>
  </ul>
</body>
```

```js
// job_dashboard_controller.js
static outlets = ['job'];

refresh() {
  this.jobOutlets.forEach(outlet => outlet.update({...}));
}
```

**Use sparingly** — outlet selectors in HTML can become bloated. Prefer custom events for broadcasting.

---

### 10. Callbacks — Loose Controller Coupling
When one controller needs data from another without tight coupling, use a callback pattern (request/respond via events).

Good:
```js
// first_controller.js — exposes itself via callback event
connect() {
  $(document).on('first_controller.state', (event, callback) => {
    callback(this);
  });
}
setName(value) { this.name = value; }

// second_controller.js — requests data when needed
render() {
  $(document).trigger('first_controller.state', firstController => {
    this.name = firstController.name;
  });
}
```

---

## DOM MANIPULATION

### 11. Use `<template>` to Restore DOM State
When an external library removes HTML from the page (e.g., after closing a Bootstrap modal), use a `<template>` element to restore it.

```html
<div data-controller="modal">
  <template data-modal-target="template">
    <div>
      <a href="#" data-action="modal#show">Click Me</a>
      <div class="modal invisible" data-modal-target="modal">
        <h1>A Modal</h1>
        <a href="#" data-action="modal#hide">Hide Me</a>
      </div>
    </div>
  </template>
</div>
```

```js
static targets = ["template", "modal"];

connect() {
  this.element.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML);
}

hide(e) {
  e.preventDefault();
  this.element.removeChild(this.element.lastElementChild);
  this.element.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML);
}
```

**Also useful:** Preparing DOM for Turbo caching (restore state before `turbo:before-cache`).

---

## INTEGRATING THIRD-PARTY LIBRARIES

### 12. Use Lifecycle Events for Setup and Teardown
Don't manage library instances globally — use `connect`/`disconnect`.

Bad (global array, manual DOM querying):
```js
let editors = [];
document.addEventListener("turbo:load", function() {
  document.querySelectorAll(".easymde").forEach(function(el) {
    editors.push(new EasyMDE({ element: el }));
  });
});
```

Good:
```js
import EasyMDE from "easymde";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    this.editor = new EasyMDE({ element: this.fieldTarget });
  }

  disconnect() {
    this.editor.toTextArea();
  }
}
```

**Benefits:** Stimulus creates separate instances automatically; each can be configured independently via data attributes; Turbo lifecycle is handled automatically.

---

## ERROR HANDLING

### 13. Global Error Handler via Application Controller
Catch all Stimulus and application errors in one place using the `handleError` hook.

```js
// application_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  handleError = (error) => {
    const context = {
      controller: this.identifier,
      user_id: this.userId,
    };
    this.application.handleError(
      error,
      `Error in controller: ${this.identifier}`,
      context
    );
  };

  get userId() {
    return document.head.querySelector(`meta[name="user_id"]`)?.content;
  }
}

// some_controller.js
export default class extends ApplicationController {
  someFunc() {
    try {
      // ...
    } catch (err) {
      this.handleError(err);
    }
  }
}
```

Plug in an error reporting service (e.g., Sentry) at the application level:

```js
// application.js
const defaultErrorHandler = application.handleError.bind(application);
application.handleError = (error, message, detail = {}) => {
  defaultErrorHandler(error, message, detail);
  Sentry.captureException(error, { message, ...detail });
};
```

---

## TURBO INTEGRATION

### 14. Global Teardown Before Turbo Caching
When a controller manipulates the DOM, implement a `teardown()` method so the page can be cleanly cached by Turbo. Trigger it globally via `turbo:before-cache`.

```js
// application.js
document.addEventListener('turbo:before-cache', () => {
  application.controllers.forEach(controller => {
    if (typeof controller.teardown === 'function') {
      controller.teardown();
    }
  });
});

// any_controller.js
export default class extends Controller {
  connect() { /* ... */ }

  teardown() {
    this.element.classList.remove('play-animation');
  }
}
```

**Rationale:** Keeps `disconnect` for controller-level teardown; `teardown` for Turbo-specific rollback. Prevents flash of stale/manipulated content on back navigation.

---

### 15. Form Submits
Submit forms in response to arbitrary events or intercept them for client-side logic.

Trigger submit on change:
```erb
<%= form_with(model: @article, data: { controller: "form" }) do |f| %>
  <%= select_tag "author", ..., data: { action: "change->form#update" } %>
<% end %>
```
```js
update(event) {
  event.preventDefault();
  this.element.requestSubmit();
}
```

Intercept and augment before sending:
```js
import { patch } from '@rails/request.js';

intercept(event) {
  event.preventDefault();
  const data = new FormData(this.element);
  // validate or append items here
  patch(this.element.action, { body: data, responseKind: 'turbo-stream' });
}
```

---

## SOLID PRINCIPLES

The three SOLID principles most relevant to Stimulus are Single Responsibility, Open-Closed, and Dependency Inversion. For detailed examples and rationale, read `references/solid.md`.

**Quick summaries:**
- **SRP:** One controller, one job. No "page controllers". If it would change for two reasons, split it.
- **OCP:** Use a polymorphic `setup()` hook instead of switch/case on type values.
- **DIP:** Use dynamic imports + Values API to select dependencies at runtime, not hardcoded imports.

---

## COOKBOOK PATTERNS

For ready-to-use controller implementations, read `references/cookbook.md`. It contains complete, copy-paste-ready controllers for:

- **Faceted Search** — Turbo Frame + form → URL params
- **Refresh When Visible** — Page Visibility API + Turbo Stream refresh
- **Auto Sort** — MutationObserver to sort children by data attribute
- **Dark Mode** — localStorage + CSS class toggling + flash-of-white fix
- **Radio Dropdown** — radio-like dropdown with change event dispatch

---

---

## QUICK REFERENCE CHECKLIST

Before committing a Stimulus controller, verify:

- [ ] State is in Values API, not instance variables
- [ ] CSS classes are in `static classes`, not hardcoded strings
- [ ] Events use `data-action` in markup, not `addEventListener` in `connect()`
- [ ] If `addEventListener` is used manually: bound reference stored for `disconnect()` cleanup
- [ ] Controller has a single responsibility (no "page controllers")
- [ ] Third-party libraries initialized in `connect()`, destroyed in `disconnect()`
- [ ] Turbo: `teardown()` implemented if DOM is mutated; wired via `turbo:before-cache`
- [ ] Inter-controller communication: Outlets for direct calls, custom events for broadcast
- [ ] No hardcoded selectors or class names inside controller logic
- [ ] If mixing `this.element` and `target` operations → consider splitting into two controllers
