# Better Stimulus Cookbook Patterns

Ready-to-use controller implementations from betterstimulus.com.

---

## Faceted Search (Turbo Frames + Stimulus)

Wire a form to a Turbo Frame — update the frame `src` whenever inputs change.

```html
<div data-controller="faceted-search">
  <form data-faceted-search-target="form" action="/search">
    <input type="text" data-action="input->faceted-search#perform">
    <select data-action="change->faceted-search#perform">...</select>
  </form>
  <turbo-frame id="results" data-faceted-search-target="frame" src="/search">
  </turbo-frame>
</div>
```

```js
// faceted_search_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ["frame", "form"];

  // Optionally debounce: this.perform = debounce(this.#perform.bind(this), 200)
  connect() {}

  #perform() {
    this.searchParams = new URLSearchParams(
      new FormData(this.formTarget),
    ).toString();
    this.frameTarget.src = `${this.formTarget.action}?${this.searchParams}`;
  }
}
```

**Key point:** Debounce the `perform` action so every keystroke doesn't fire a request.

---

## Refresh When Visible (Page Visibility API + Turbo)

Refresh content only when the tab/PWA becomes visible again.

```html
<section data-controller="visible-refresh"
         data-action="visibilitychange@document->visible-refresh#trigger">
</section>
```

```js
// visible_refresh_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // Optional polling (uncomment):
  // static values = { interval: { type: Number, default: 60000 } };
  // connect() { this.interval = setInterval(this.appendRefresh, this.intervalValue); }
  // disconnect() { clearInterval(this.interval); }

  trigger() {
    this.appendRefresh();
  }

  appendRefresh = () => {
    if (!document.hidden) {
      document.body.insertAdjacentHTML(
        "beforeend",
        '<turbo-stream action="refresh"></turbo-stream>',
      );
    }
  };
}
```

Uses the [Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API). If Turbo's refresh method is `morph`, it will morph instead of replace.

---

## Auto Sort (MutationObserver)

Sort child DOM elements by a data attribute whenever children change (e.g., from Turbo Streams).

```html
<ul data-controller="sort"
    data-sort-attribute-name-value="position"
    data-sort-attribute-type-value="number">
  <li data-position="3">C</li>
  <li data-position="1">A</li>
  <li data-position="2">B</li>
</ul>
```

```js
// sort_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    attributeName: String,
    attributeType: { type: String, default: 'number' },
  };

  connect() {
    this.observer = new MutationObserver(this.#sortChildren.bind(this));
    this.observer.observe(this.element, { childList: true, subtree: true });
  }

  disconnect() {
    this.observer.disconnect();
  }

  #sortChildren(_mutationList, observer) {
    observer.disconnect();
    const { children } = this;
    this.element.innerHTML = '';
    children
      .sort((a, b) => {
        if (this.attributeTypeValue === 'string') {
          return a.dataset[this.attributeNameValue]
            .localeCompare(b.dataset[this.attributeNameValue]);
        }
        return Number(a.dataset[this.attributeNameValue]) -
               Number(b.dataset[this.attributeNameValue]);
      })
      .forEach(child => this.element.append(child));
    observer.observe(this.element, { childList: true, subtree: true });
  }

  get children() {
    return Array.from(this.element.children);
  }
}
```

---

## Dark Mode (localStorage + CSS Classes)

```js
// dark_mode_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static classes = ['light', 'dark'];
  static values = { colorScheme: String };

  initialize() {
    if ('colorScheme' in localStorage) {
      this.colorSchemeValue = localStorage.colorScheme;
    }
    window.matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', this.#dispatchChange);
  }

  toggle(event) {
    this.colorSchemeValue = event.target.value;
  }

  async colorSchemeValueChanged() {
    localStorage.colorScheme = this.colorSchemeValue;
    await new Promise(requestAnimationFrame);
    this.#dispatchChange();
  }

  updateColorScheme(event) {
    const { colorScheme } = event.detail;
    this.darkClasses.forEach(c =>
      document.documentElement.classList.toggle(c, this.#isDark(colorScheme))
    );
    this.lightClasses.forEach(c =>
      document.documentElement.classList.toggle(c, !this.#isDark(colorScheme))
    );
  }

  #isDark(colorScheme) {
    if (colorScheme === 'auto') {
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return colorScheme === 'dark';
  }

  #dispatchChange = () => {
    this.dispatch('change', { detail: { colorScheme: this.colorSchemeValue } });
  };
}
```

**Wire on `<body>`:**
```html
<body data-controller="dark-mode"
      data-dark-mode-light-class="sl-theme-light"
      data-dark-mode-dark-class="sl-theme-dark"
      data-action="dark-mode:change->dark-mode#updateColorScheme">
```

**Flash of white fix** — add this blocking script to `<head>`:
```js
function isDark(cs) {
  return cs === 'auto' ? window.matchMedia('(prefers-color-scheme: dark)').matches : cs === 'dark';
}
if ('colorScheme' in localStorage) {
  document.documentElement.classList.toggle('sl-theme-dark', isDark(localStorage.colorScheme));
  document.documentElement.classList.toggle('sl-theme-light', !isDark(localStorage.colorScheme));
}
```

---

## Radio Dropdown

A dropdown that acts like a radio group — tracks selection, updates label, dispatches change event.

```js
// radio_dropdown_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['label'];
  static values = { itemSelector: String };

  updateSelection(event) {
    const value = event.detail.item.value;
    this.items.forEach(item => {
      item.checked = item.getAttribute('value') === value;
    });
    this.labelTarget.textContent = this.items.find(i => i.checked).textContent;
    this.dispatch('change', { detail: { value } });
  }

  get items() {
    return [...this.element.querySelectorAll(this.itemSelectorValue)];
  }
}
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `data-radio-dropdown-item-selector-value` | yes | Selector for dropdown items (e.g. `sl-menu-item`) |

Emits `radio-dropdown:change` with `{ detail: { value } }`.
