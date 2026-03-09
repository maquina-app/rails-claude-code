# Stimulus Controllers Reference

Reference for all Stimulus controllers provided by maquina_components. Controllers are auto-registered via importmap — no manual setup required.

---

## Quick Reference

| Controller | Targets | Values | Key Behavior |
|-----------|---------|--------|-------------|
| `breadcrumb` | item, ellipsis, ellipsisSeparator | collapseAfter | Responsive overflow, collapses middle items |
| `calendar` | day, input, inputEnd, prevButton, nextButton, grid, caption | month, year, selected, selectedEnd, minDate, maxDate, mode, weekStartsOn | Date selection, keyboard nav, range support |
| `combobox` | trigger, content, input, option, empty, label | value, name, placeholder | Popover API, type-ahead filtering |
| `date-picker` | trigger, popover, calendar, input, inputEnd, display | mode, selected, selectedEnd, format, placeholder, placeholderRange | Wraps calendar in popover |
| `dropdown-menu` | trigger, content, chevron | open, autoClose | Toggle, keyboard nav, focus management |
| `menu-button` | button, content | — | Minimal generic dropdown |
| `sidebar` | sidebar, container, backdrop | open, defaultOpen, cookieName, cookieMaxAge, keyboardShortcut | Responsive, cookie persistence |
| `sidebar-trigger` | — (uses outlet) | — | Outlet-based sidebar toggle |
| `toast` | — | duration, dismissible, actionCallback | Auto-dismiss, hover pause |
| `toaster` | container | maxVisible | Container management, global API |
| `toggle-group` | item | type, selected | Single/multiple selection |

---

## breadcrumb

Responsive breadcrumb that collapses middle items into a dropdown when the container overflows.

**Targets:** `item`, `ellipsis`, `ellipsisSeparator`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `collapseAfter` | Number | `0` | Force collapse when total items exceed this count. `0` = pure overflow detection. When set, first + last items always stay visible; excess middle items collapse into ellipsis. |

**Behavior:**
- When `collapseAfter > 0` and total items exceed the threshold, force-collapses middle items by count (keeps first + last visible, hides excess middle items from end backwards)
- When `collapseAfter` is `0` or omitted, uses pure overflow detection (`scrollWidth > clientWidth`)
- Both modes can work together — count-based collapse runs first, then overflow detection handles remaining items
- Hides items from the middle, keeping first and last visible
- Creates a dropdown menu of hidden items on ellipsis click
- Handles window resize dynamically
- Escape key closes dropdown, click outside closes dropdown

**`collapseAfter` semantics:**
- `2` — show first + last, collapse all middle into ellipsis
- `3` — show first + one middle + last, collapse the rest
- `0` or omitted — current behavior (pure overflow-based)

---

## calendar

Full calendar widget with single and range date selection.

**Targets:** `day`, `input`, `inputEnd`, `prevButton`, `nextButton`, `grid`, `caption`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `month` | Number | current | Display month |
| `year` | Number | current | Display year |
| `selected` | String | `""` | Selected date (ISO format) |
| `selectedEnd` | String | `""` | End date for range mode |
| `minDate` | String | `""` | Minimum selectable date |
| `maxDate` | String | `""` | Maximum selectable date |
| `mode` | String | `"single"` | `"single"` or `"range"` |
| `weekStartsOn` | String | `"sunday"` | `"sunday"` or `"monday"` |

**Key Methods:**
- `previousMonth()` / `nextMonth()` — Navigate months
- `selectDay(event)` — Handle day click
- `select(date)` — Programmatic selection
- `clear()` — Clear selection
- `getValue()` — Get current value(s)

**Keyboard Navigation:** Arrow keys move between days, Home/End jump to first/last day, auto-navigates to adjacent months.

**Events Dispatched:**
- `calendar:change` — `{ detail: { selected, selectedEnd } }`
- `calendar:navigate` — `{ detail: { month, year } }`

---

## combobox

Searchable select using the HTML5 Popover API.

**Targets:** `trigger`, `content`, `input`, `option`, `empty`, `label`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `value` | String | `""` | Selected value |
| `name` | String | required | Form field name |
| `placeholder` | String | `"Select..."` | Placeholder text |

**Key Methods:**
- `toggle(event)` — Toggle popover
- `filter()` — Filter options by input text
- `select(event)` — Select/deselect an option
- `positionPopover()` — Position relative to trigger

**Keyboard Navigation:** Arrow Up/Down navigates options, Enter selects, Escape closes, Home/End jump to first/last.

**Behavior Notes:**
- Uses Popover API for light-dismiss (click outside closes)
- Type-ahead: typing in input filters visible options
- Single selection with toggle (click selected item to deselect)
- Hidden input stores selected value for form submission

---

## date-picker

Wraps the calendar controller in a popover with display formatting.

**Targets:** `trigger`, `popover`, `calendar`, `input`, `inputEnd`, `display`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `mode` | String | `"single"` | `"single"` or `"range"` |
| `selected` | String | `""` | Selected date |
| `selectedEnd` | String | `""` | End date for range |
| `format` | String | `"long"` | Display format (`"long"` or `"short"`) |
| `placeholder` | String | `""` | Placeholder text |
| `placeholderRange` | String | `""` | Range placeholder |

**Key Methods:**
- `toggle()` — Toggle popover
- `clear()` — Clear selection and sync calendar
- `getValue()` — Get current value(s)
- `setValue(selected, selectedEnd)` — Programmatic set

**Behavior Notes:**
- Auto-closes after selection (single: immediately, range: after both dates)
- Syncs display text with formatted date
- Handles Turbo cache cleanup (`turbo:before-cache`)
- Auto-focuses calendar grid on open

---

## dropdown-menu

Accessible dropdown with full keyboard navigation and focus management.

**Targets:** `trigger`, `content`, `chevron`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `open` | Boolean | `false` | Current open state |
| `autoClose` | Boolean | `false` | Close on item click |

**Key Methods:**
- `toggle(event)` — Toggle menu
- `open()` / `close()` — Explicit control

**Keyboard Navigation:** Arrow Up/Down navigates items, Home/End jump to first/last, Escape closes and returns focus to trigger, Tab closes menu.

**Behavior Notes:**
- 100ms close animation before hiding
- Disabled items skipped in keyboard navigation
- Focus returns to trigger on close
- Turbo cache cleanup (`turbo:before-cache`)

---

## menu-button

Minimal controller for simple dropdown-style button groups.

**Targets:** `button`, `content`

**Key Methods:**
- `toggle()` — Toggle open/closed

**Behavior Notes:**
- Click outside to close
- State tracked via `button.dataset.state` (`"open"` / `"closed"`)
- Uses `hidden` class for visibility

---

## sidebar

Responsive sidebar with cookie-based state persistence.

**Targets:** `sidebar`, `container`, `backdrop`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `open` | Boolean | `true` | Current state |
| `defaultOpen` | Boolean | `true` | Initial state |
| `cookieName` | String | `"sidebar_state"` | Cookie name |
| `cookieMaxAge` | Number | `31536000` | Cookie max age (1 year) |
| `keyboardShortcut` | String | `"b"` | Keyboard shortcut key |

**Key Methods:**
- `toggle()` — Toggle sidebar
- `open()` / `close()` — Explicit control

**Behavior Notes:**
- **Desktop (≥768px):** Remembers state via cookie, keyboard shortcut (Cmd/Ctrl+B by default)
- **Mobile (<768px):** Closes by default, opens as overlay with backdrop, scroll lock when open
- Persists state to cookie on desktop only
- Handles Turbo cache and morph events
- Resize listener with 150ms debounce for responsive transitions

---

## sidebar-trigger

Simple outlet-based trigger for sidebar toggle.

**Outlets:** `sidebar`

**Key Methods:**
- `triggerClick()` — Calls `toggle()` on all connected sidebar outlets

**Usage:** Place anywhere on the page. Connect via outlet selector.

---

## toast

Manages individual toast notification lifecycle.

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `duration` | Number | `5000` | Auto-dismiss time (ms) |
| `dismissible` | Boolean | `true` | Show close button |
| `actionCallback` | Boolean | `false` | Has action callback |

**Key Methods:**
- `dismiss()` — Dismiss with animation
- `pauseTimer()` — Pause on hover
- `resumeTimer()` — Resume on mouse leave

**Behavior Notes:**
- Auto-dismiss after `duration` milliseconds
- Pauses timer on hover, resumes with remaining time on leave
- Fade animation: 200ms enter, 150ms exit
- Dispatches `toast:action` event with toast ID

---

## toaster

Container that manages multiple toast notifications and exposes a global JavaScript API.

**Targets:** `container`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `maxVisible` | Number | `5` | Maximum visible toasts |

**Global JavaScript API (`window.Toast`):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `Toast.success(options)` | `{ title, description, duration }` | Success toast |
| `Toast.error(options)` | `{ title, description, duration }` | Error toast |
| `Toast.warning(options)` | `{ title, description, duration }` | Warning toast |
| `Toast.info(options)` | `{ title, description, duration }` | Info toast |
| `Toast.show(options)` | `{ variant, title, description, duration, dismissible }` | Custom toast |
| `Toast.dismiss(id)` | Toast ID | Dismiss specific toast |
| `Toast.dismissAll()` | — | Dismiss all toasts |

**Usage from JavaScript:**
```javascript
Toast.success({ title: "Saved!", description: "Your changes were saved." })
Toast.error({ title: "Error", description: "Something went wrong." })
```

---

## toggle-group

Button group supporting single or multiple selection.

**Targets:** `item`

**Values:**

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | String | `"single"` | `"single"` or `"multiple"` |
| `selected` | Array | `[]` | Currently selected values |

**Key Methods:**
- `toggle(event)` — Toggle item selection
- `select(value)` — Programmatic select
- `deselect(value)` — Programmatic deselect
- `clear()` — Clear all selections
- `getValue()` — Get current value(s)

**Keyboard Navigation:** Arrow Right/Left/Up/Down navigates between items, Home/End jump to first/last.

**Events Dispatched:**
- `toggle-group:change` — `{ detail: { selected, value, type } }`

**Behavior Notes:**
- Single mode: selecting one deselects others
- Multiple mode: toggle each independently
- Updates `data-state` (`"on"` / `"off"`) and `aria-pressed` attributes
