# SOLID Principles Applied to Stimulus

---

## Single Responsibility Principle

Each controller should have exactly one reason to change. Avoid "page controllers" that accumulate unrelated behaviors.

Bad — one controller doing two jobs:
```js
// page_controller.js
static targets = ["modal", "form"];
openModal() { this.modalTarget.classList.add("open"); }
submitForm() { this.formTarget.submit(); }
```

Good — each controller has one job:
```js
// modal_controller.js
open() { this.element.classList.add("open"); }

// form_controller.js
submit() { this.element.submit(); }
```

**Test:** Ask "what would be reasons for this controller to change?" If you get two different answers, split it.

References: [Practical Object Oriented Design](https://www.poodr.com/) by Sandi Metz, [Wikipedia](https://en.wikipedia.org/wiki/Single_responsibility_principle)

---

## Open-Closed Principle

Controllers should be **closed** for modification but **open** to extension. Avoid switch/case on type values inside `connect()`.

Bad — every new widget type requires modifying the class:
```js
async connect() {
  switch(this.typeValue) {
    case "toggle": this.toggledValue = false; break;
    case "dropdown": this.options = await fetch(`...`); break;
  }
}
```

Good — use inheritance with a polymorphic hook:
```js
// Base controller — closed for modification
export default class WidgetController extends Controller {
  connect() { this.setup(); }
}

// Specialized controllers — open for extension
export default class ToggleController extends WidgetController {
  static values = { toggled: Boolean };
  setup() { super.setup(); this.toggledValue = false; }
}

export default class DropdownController extends WidgetController {
  async setup() { super.setup(); this.options = await fetch(`...`); }
}
```

Adding a new widget = add a new class. The base never changes.

Reference: [Wikipedia](https://en.m.wikipedia.org/wiki/Open%E2%80%93closed_principle)

---

## Dependency Inversion Principle

Depend on abstractions, not concretes. Don't hardcode service classes inside controllers — inject them via Values API + dynamic imports.

Bad — tightly coupled to a specific implementation:
```js
import { SearchAPI } from "./SearchAPI";

connect() {
  this.searchAPI = new SearchAPI(); // can't swap without editing controller
}
```

Good — dependency selected at runtime via data attribute:
```html
<div data-controller="search" data-search-api-value="google"></div>
<div data-controller="search" data-search-api-value="algolia"></div>
```

```js
static values = { api: String };

async apiValueChanged(apiValue) {
  if (apiValue === "google") {
    this.searchAPI = await import("./GoogleAPI");
  } else if (apiValue === "algolia") {
    this.searchAPI = await import("./AlgoliaAPI");
  }
}

search() {
  this.searchAPI.search(...);
}
```

**Benefits:**
- Switch APIs at runtime by changing the data attribute
- Add new services by adding a conditional — no controller changes needed
- Each API module just needs to implement the same interface (e.g., a `search` method)

Reference: [Wikipedia](https://en.wikipedia.org/wiki/Dependency_inversion_principle), [Dynamic Module Import with Stimulus](https://dev.to/adrienpoly/dynamic-module-import-with-stimulus-js-297g)
