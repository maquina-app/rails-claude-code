# Component Catalog

Complete reference for all maquina_components. Each entry includes when to use, props, variants, and examples.

**Official Documentation:** https://maquina.app/documentation/components/

---

## Component Quick Reference

| Component | Variants | Sizes | Docs Link |
|-----------|----------|-------|-----------|
| Alert | default, success, warning, destructive | — | [docs](https://maquina.app/documentation/components/alert) |
| Badge | default, primary, secondary, success, warning, destructive, outline | sm, md, lg | [docs](https://maquina.app/documentation/components/badge) |
| Breadcrumbs | — | — | [docs](https://maquina.app/documentation/components/breadcrumbs) |
| Button | default, primary, secondary, destructive, outline, ghost, link | sm, md, lg, icon, icon-sm, icon-lg | [docs](https://maquina.app/documentation/components/button) |
| Calendar | — | — | [docs](https://maquina.app/documentation/components/calendar) |
| Card | — | — | [docs](https://maquina.app/documentation/components/card) |
| Combobox | — | — | [docs](https://maquina.app/documentation/components/combobox) |
| Date Picker | — | — | [docs](https://maquina.app/documentation/components/date-picker) |
| Dropdown Menu | — | — | [docs](https://maquina.app/documentation/components/dropdown-menu) |
| Empty State | — | — | [docs](https://maquina.app/documentation/components/empty) |
| Header | — | — | [docs](https://maquina.app/documentation/components/header) |
| Pagination | — | — | [docs](https://maquina.app/documentation/components/pagination) |
| Separator | horizontal, vertical | — | [docs](https://maquina.app/documentation/components/separator) |
| Sidebar | default, inset | — | [docs](https://maquina.app/documentation/components/sidebar) |
| Stats | — | — | [docs](https://maquina.app/documentation/components/stats) |
| Table | — | — | [docs](https://maquina.app/documentation/components/table) |
| Toast | default, success, warning, destructive | — | [docs](https://maquina.app/documentation/components/toast) |
| Toggle Group | default, outline | sm, md, lg | [docs](https://maquina.app/documentation/components/toggle-group) |

---

## Component Philosophy

All maquina_components are **composable building blocks**. You have three approaches:

1. **Use partials directly** — Render components as documented for standard patterns
2. **Compress complexity** — Wrap multiple partials into application-specific components that encode your conventions (e.g., `_booking_card.html.erb` that internally uses Card, Badge, etc.)
3. **Copy and customize** — Copy component partials into your app and adapt them for specific needs

Choose the approach that fits your use case. There's no "right" level of abstraction — prioritize consistency within your application.

```erb
<%# Direct usage - explicit composition %>
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: @booking.service.name %>
  <% end %>
<% end %>

<%# Application wrapper - compressed complexity %>
<%= render "bookings/card", booking: @booking %>
<%# Your partial handles the component composition internally %>
```

---

## Table of Contents

1. [Layout Components](#layout-components)
   - [Sidebar](#sidebar)
   - [Header](#header)
2. [Content Components](#content-components)
   - [Card](#card)
   - [Alert](#alert)
   - [Badge](#badge)
   - [Table](#table)
   - [Empty State](#empty-state)
   - [Separator](#separator)
   - [Stats](#stats)
3. [Navigation Components](#navigation-components)
   - [Breadcrumbs](#breadcrumbs)
   - [Dropdown Menu](#dropdown-menu)
   - [Pagination](#pagination)
4. [Interactive Components](#interactive-components)
   - [Toggle Group](#toggle-group)
   - [Calendar](#calendar)
   - [Date Picker](#date-picker)
   - [Combobox](#combobox)
   - [Toast](#toast)
5. [Form Components](#form-components)
   - [Button](#button)
   - [Input](#input)
   - [Textarea](#textarea)
   - [Select](#select)
   - [Checkbox](#checkbox)
   - [Radio](#radio)
   - [Switch](#switch)
   - [Form Layout](#form-layout)

---

## Layout Components

### Sidebar

Collapsible navigation sidebar with cookie-based persistence.

**When to Use:**
- Main application navigation
- Dashboard layouts
- Admin interfaces

**Structure:**
```erb
<%= render "components/sidebar/provider", default_open: sidebar_open? do %>
  <%= render "components/sidebar" do %>
    <%= render "components/sidebar/header" do %>...Logo...<% end %>
    <%= render "components/sidebar/content" do %>
      <%= render "components/sidebar/group", title: "Menu" do %>
        <%= render "components/sidebar/menu" do %>
          <%= render "components/sidebar/menu_item" do %>
            <%= render "components/sidebar/menu_button",
                title: "Dashboard",
                url: dashboard_path,
                icon_name: :home,
                active: current_page?(dashboard_path) %>
          <% end %>
        <% end %>
      <% end %>
    <% end %>
    <%= render "components/sidebar/footer" do %>...<% end %>
  <% end %>
  
  <%= render "components/sidebar/inset" do %>
    <%= render "components/header" do %>
      <%= render "components/sidebar/trigger", icon_name: :panel_left %>
    <% end %>
    <main><%= yield %></main>
  <% end %>
<% end %>
```

**Parts:**

| Part | Purpose |
|------|---------|
| `sidebar/provider` | Context wrapper, manages state |
| `sidebar` | Main sidebar container |
| `sidebar/header` | Logo/brand area |
| `sidebar/content` | Scrollable nav content |
| `sidebar/footer` | Bottom area (user menu) |
| `sidebar/group` | Navigation group with title |
| `sidebar/menu` | Menu container |
| `sidebar/menu_item` | Single menu item wrapper |
| `sidebar/menu_button` | Clickable nav item |
| `sidebar/menu_link` | Alternative link style |
| `sidebar/trigger` | Toggle button |
| `sidebar/inset` | Main content area |

**Provider Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `default_open` | Boolean | `true` | Initial state |
| `cookie_name` | String | `"sidebar_state"` | Cookie key |
| `variant` | Symbol | `:default` | `:default`, `:inset` |

**Menu Button Props:**

| Prop | Type | Description |
|------|------|-------------|
| `title` | String | Display text |
| `url` | String | Link path |
| `icon_name` | Symbol | Icon identifier |
| `active` | Boolean | Highlight current |
| `badge` | String | Optional badge text |

---

### Header

Top navigation bar, typically used with sidebar inset.

**When to Use:**
- Top of page header
- Contains sidebar trigger, breadcrumbs, actions

**Usage:**
```erb
<%= render "components/header" do %>
  <%= render "components/sidebar/trigger", icon_name: :panel_left %>
  
  <div class="flex-1">
    <%= render "components/breadcrumbs" do %>...breadcrumbs...<% end %>
  </div>
  
  <div class="flex items-center gap-2">
    <%# Header actions %>
  </div>
<% end %>
```

---

## Content Components

### Card

Versatile content container with header, content, and footer sections.

**When to Use:**
- Group related content
- Dashboard widgets
- Form containers
- List item containers

**Structure:**
```erb
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: "Title" %>
    <%= render "components/card/description", text: "Description" %>
  <% end %>
  <%= render "components/card/content" do %>
    <!-- Main content -->
  <% end %>
  <%= render "components/card/footer" do %>
    <!-- Actions -->
  <% end %>
<% end %>
```

**Parts:**

| Part | Props | Description |
|------|-------|-------------|
| `card` | `css_classes` | Main container |
| `card/header` | `layout: :column\|:row` | Header section |
| `card/title` | `text`, `size: :default\|:sm` | Title text |
| `card/description` | `text` | Subtitle/description |
| `card/action` | — | Action button area (in header) |
| `card/content` | `css_classes` | Main content area |
| `card/footer` | `align: :start\|:end\|:between` | Footer with actions |

**Row Header with Action:**
```erb
<%= render "components/card/header", layout: :row do %>
  <div>
    <%= render "components/card/title", text: "Users" %>
    <%= render "components/card/description", text: "Manage team members" %>
  </div>
  <%= render "components/card/action" do %>
    <%= link_to "Add User", new_user_path, 
        data: { component: "button", variant: "primary", size: "sm" } %>
  <% end %>
<% end %>
```

**Stats Card Pattern:**
```erb
<%= render "components/card" do %>
  <%= render "components/card/header", css_classes: "pb-2" do %>
    <%= render "components/card/title", text: "Revenue", size: :sm %>
  <% end %>
  <%= render "components/card/content", css_classes: "pt-0" do %>
    <div class="text-2xl font-bold">$12,500</div>
    <div class="flex items-center gap-1 text-sm text-emerald-600">
      <%= icon_for :trending_up, class: "size-4" %> +12.5%
    </div>
  <% end %>
<% end %>
```

---

### Alert

Callout messages for important information, warnings, or errors.

**When to Use:**
- System notifications
- Form submission feedback
- Important warnings
- Destructive action confirmations

**Variants:**

| Variant | Usage |
|---------|-------|
| `:default` | General information |
| `:success` | Positive confirmations |
| `:warning` | Caution needed |
| `:destructive` | Errors, critical warnings |

**Usage:**
```erb
<%= render "components/alert", variant: :default do %>
  <%= render "components/alert/title", text: "Information" %>
  <%= render "components/alert/description" do %>
    Your changes have been saved successfully.
  <% end %>
<% end %>

<%= render "components/alert", variant: :destructive do %>
  <%= render "components/alert/title", text: "Error" %>
  <%= render "components/alert/description", text: "Unable to save changes." %>
<% end %>
```

**Props:**

| Prop | Values | Default |
|------|--------|---------|
| `variant` | `:default`, `:success`, `:warning`, `:destructive` | `:default` |

---

### Badge

Compact status indicators and labels.

**When to Use:**
- Status indicators (active, pending, failed)
- Counts and labels
- Tags and categories
- Inline metadata

**Variants:**

| Variant | Usage | Example |
|---------|-------|---------|
| `:default` | Neutral | Tags, counts |
| `:primary` | Brand emphasis | Featured |
| `:secondary` | Low emphasis | Categories |
| `:success` | Positive | Active, Completed |
| `:warning` | Attention | Pending, In Progress |
| `:destructive` | Negative | Failed, Cancelled |
| `:outline` | Minimal | Subtle labels |

**Sizes:**

| Size | Usage |
|------|-------|
| `:sm` | Compact tables, tight spaces |
| `:md` | Default |
| `:lg` | Standalone emphasis |

**Usage:**
```erb
<%# Basic %>
<%= render "components/badge", variant: :success do %>Active<% end %>

<%# With icon %>
<%= render "components/badge", variant: :warning do %>
  <%= icon_for :clock, class: "size-3" %> Pending
<% end %>

<%# With count %>
<%= render "components/badge", variant: :primary do %>
  <%= @notifications.count %> new
<% end %>
```

**Dynamic Status Pattern:**
```erb
<% variant = case record.status
   when "active" then :success
   when "pending" then :warning
   when "inactive" then :secondary
   when "error" then :destructive
   else :default
   end %>
<%= render "components/badge", variant: variant, size: :sm do %>
  <%= record.status.humanize %>
<% end %>
```

---

### Table

Data tables with header, body, and optional sorting.

**When to Use:**
- Data listings
- Admin tables
- Comparison views
- Any tabular data

**Structure:**
```erb
<%= render "components/table" do %>
  <%= render "components/table/header" do %>
    <%= render "components/table/row" do %>
      <%= render "components/table/head" do %>Name<% end %>
      <%= render "components/table/head" do %>Status<% end %>
      <%= render "components/table/head", css_classes: "w-10" do %>
        <span class="sr-only">Actions</span>
      <% end %>
    <% end %>
  <% end %>
  <%= render "components/table/body" do %>
    <% @items.each do |item| %>
      <%= render "components/table/row" do %>
        <%= render "components/table/cell", css_classes: "font-medium" do %>
          <%= item.name %>
        <% end %>
        <%= render "components/table/cell" do %>
          <%= render "components/badge", variant: :success do %><%= item.status %><% end %>
        <% end %>
        <%= render "components/table/cell" do %>
          <%= render "shared/row_actions", item: item %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

**Props:**

| Component | Props |
|-----------|-------|
| `table` | `container: true\|false` (scroll wrapper) |
| `table/head` | `css_classes`, sortable support |
| `table/cell` | `css_classes` |

**Inside Card (no container):**
```erb
<%= render "components/card" do %>
  <%= render "components/card/content" do %>
    <%= render "components/table", container: false do %>
      ...
    <% end %>
  <% end %>
<% end %>
```

---

### Empty State

Placeholder for empty data states.

**When to Use:**
- Zero results
- No data yet
- Search with no matches
- First-time user onboarding

**Structure:**
```erb
<%= render "components/empty" do %>
  <%= render "components/empty/header" do %>
    <%= render "components/empty/media" do %>
      <div class="flex h-16 w-16 items-center justify-center rounded-full bg-muted">
        <%= icon_for :inbox, class: "size-8 text-muted-foreground" %>
      </div>
    <% end %>
    <%= render "components/empty/title", text: t(".empty.title") %>
    <%= render "components/empty/description", text: t(".empty.description") %>
  <% end %>
  <%= render "components/empty/content" do %>
    <%= link_to t(".empty.action"), new_path, 
        data: { component: "button", variant: "primary" } %>
  <% end %>
<% end %>
```

**Conditional Pattern:**
```erb
<% if @items.any? %>
  <%= render "components/table" do %>...table...<% end %>
<% else %>
  <%= render "components/empty" do %>...empty state...<% end %>
<% end %>
```

---

### Separator

Visual divider between content sections.

**Usage:**
```erb
<%= render "components/separator" %>

<%# With orientation %>
<%= render "components/separator", orientation: :vertical %>
```

---

### Stats

Statistics display cards for dashboards and overview pages.

**When to Use:**
- Dashboard KPIs
- Summary metrics
- Analytics displays
- Performance indicators

**Structure:**
```erb
<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
  <%= render "components/stats/card",
      title: "Total Revenue",
      value: "$45,231.89",
      description: "+20.1% from last month",
      icon: :dollar_sign %>
  
  <%= render "components/stats/card",
      title: "Subscriptions",
      value: "+2350",
      description: "+180.1% from last month",
      icon: :users %>
  
  <%= render "components/stats/card",
      title: "Sales",
      value: "+12,234",
      description: "+19% from last month",
      icon: :credit_card %>
  
  <%= render "components/stats/card",
      title: "Active Now",
      value: "+573",
      description: "+201 since last hour",
      icon: :activity %>
</div>
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | String | required | Metric label |
| `value` | String | required | Main value display |
| `description` | String | `nil` | Trend or comparison text |
| `icon` | Symbol | `nil` | Icon identifier |

---

## Navigation Components

### Breadcrumbs

Navigation trail showing page hierarchy.

**When to Use:**
- Deep navigation structures
- Multi-level pages
- Show user's location

**Structure:**
```erb
<%= render "components/breadcrumbs" do %>
  <%= render "components/breadcrumbs/list" do %>
    <%= render "components/breadcrumbs/item" do %>
      <%= render "components/breadcrumbs/link", href: root_path, label: "Home" %>
    <% end %>
    <%= render "components/breadcrumbs/separator" %>
    <%= render "components/breadcrumbs/item" do %>
      <%= render "components/breadcrumbs/link", href: users_path, label: "Users" %>
    <% end %>
    <%= render "components/breadcrumbs/separator" %>
    <%= render "components/breadcrumbs/item" do %>
      <%= render "components/breadcrumbs/page", label: @user.name %>
    <% end %>
  <% end %>
<% end %>
```

---

### Dropdown Menu

Accessible dropdown with keyboard navigation.

**When to Use:**
- Action menus
- User profile menus
- Row actions in tables
- Any multi-option trigger

**Structure:**
```erb
<%= render "components/dropdown_menu" do %>
  <%= render "components/dropdown_menu/trigger" do %>
    Options
  <% end %>
  <%= render "components/dropdown_menu/content", align: :end do %>
    <%= render "components/dropdown_menu/label", text: "Actions" %>
    <%= render "components/dropdown_menu/separator" %>
    
    <%= render "components/dropdown_menu/item", href: edit_path do %>
      <%= icon_for :edit, class: "size-4" %> Edit
    <% end %>
    
    <%= render "components/dropdown_menu/item", href: duplicate_path do %>
      <%= icon_for :copy, class: "size-4" %> Duplicate
      <%= render "components/dropdown_menu/shortcut", text: "⌘D" %>
    <% end %>
    
    <%= render "components/dropdown_menu/separator" %>
    
    <%= render "components/dropdown_menu/item", href: delete_path, method: :delete, variant: :destructive do %>
      <%= icon_for :trash, class: "size-4" %> Delete
    <% end %>
  <% end %>
<% end %>
```

**Content Props:**

| Prop | Values | Default |
|------|--------|---------|
| `align` | `:start`, `:center`, `:end` | `:start` |

**Item Props:**

| Prop | Description |
|------|-------------|
| `href` | Link path |
| `method` | HTTP method (`:delete`, etc.) |
| `variant` | `:default`, `:destructive` |

---

### Pagination

Page navigation integrated with Pagy.

**When to Use:**
- Paginated lists
- Search results
- Any large data set

**Full Pagination:**
```erb
<%= pagination_nav(@pagy, :users_path) %>

<%# With options %>
<%= pagination_nav(@pagy, :users_path, show_labels: false) %>
```

**Simple Previous/Next:**
```erb
<%= pagination_simple(@pagy, :users_path) %>
```

**Inside Card Footer:**
```erb
<%= render "components/card/footer", align: :between do %>
  <span class="text-sm text-muted-foreground">
    Showing <%= @pagy.from %>-<%= @pagy.to %> of <%= @pagy.count %>
  </span>
  <%= pagination_nav(@pagy, :users_path, show_labels: false) %>
<% end %>
```

---

## Interactive Components

### Toggle Group

Single or multiple selection button group.

**When to Use:**
- View mode switching (list/grid)
- Text formatting (bold/italic)
- Filter options
- Any exclusive/inclusive selection

**Single Selection:**
```erb
<%= render "components/toggle_group", type: :single, variant: :outline do %>
  <%= render "components/toggle_group/item", value: "list", pressed: true, aria_label: "List view" do %>
    <%= icon_for :list, class: "size-4" %>
  <% end %>
  <%= render "components/toggle_group/item", value: "grid", aria_label: "Grid view" do %>
    <%= icon_for :grid, class: "size-4" %>
  <% end %>
<% end %>
```

**Multiple Selection:**
```erb
<%= render "components/toggle_group", type: :multiple, variant: :default do %>
  <%= render "components/toggle_group/item", value: "bold", pressed: true do %>
    <%= icon_for :bold, class: "size-4" %>
  <% end %>
  <%= render "components/toggle_group/item", value: "italic" do %>
    <%= icon_for :italic, class: "size-4" %>
  <% end %>
<% end %>
```

**Props:**

| Prop | Values | Default |
|------|--------|---------|
| `type` | `:single`, `:multiple` | `:single` |
| `variant` | `:default`, `:outline` | `:default` |
| `size` | `:sm`, `:md`, `:lg` | `:md` |

---

### Calendar

Date picker calendar with single and range selection modes.

**When to Use:**
- Inline date selection (always visible)
- Booking/scheduling interfaces
- Dashboard date widgets
- Date range selection for reports

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `selected` | Date, String | `nil` | Currently selected date |
| `selected_end` | Date, String | `nil` | End date for range selection |
| `mode` | Symbol | `:single` | `:single` or `:range` |
| `min_date` | Date, String | `nil` | Minimum selectable date |
| `max_date` | Date, String | `nil` | Maximum selectable date |
| `disabled_dates` | Array | `[]` | Dates to disable |
| `show_outside_days` | Boolean | `true` | Show adjacent month days |
| `week_starts_on` | Symbol | `:sunday` | `:sunday` or `:monday` |
| `input_name` | String | `nil` | Hidden input name for forms |
| `input_name_end` | String | `nil` | End date hidden input name |

**Basic Usage:**
```erb
<%= render "components/calendar", selected: Date.current %>
```

**Range Selection:**
```erb
<%= render "components/calendar",
  mode: :range,
  selected: @booking.check_in,
  selected_end: @booking.check_out,
  min_date: Date.current %>
```

**Form Integration:**
```erb
<%= form_with model: @event do |f| %>
  <%= render "components/calendar",
    selected: @event.scheduled_at,
    input_name: "event[scheduled_at]",
    min_date: Date.current %>
  <%= f.submit "Save", data: { component: "button", variant: "primary" } %>
<% end %>
```

**With Disabled Dates:**
```erb
<%= render "components/calendar",
  min_date: Date.current,
  max_date: Date.current + 90.days,
  disabled_dates: @unavailable_dates %>
```

---

### Date Picker

Compact date picker with trigger button and popover calendar using native Popover API.

**When to Use:**
- Form date inputs
- Date filters
- Space-constrained UIs
- Any date selection that should be hidden until needed

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `selected` | Date, String | `nil` | Currently selected date |
| `selected_end` | Date, String | `nil` | End date for range selection |
| `mode` | Symbol | `:single` | `:single` or `:range` |
| `min_date` | Date, String | `nil` | Minimum selectable date |
| `max_date` | Date, String | `nil` | Maximum selectable date |
| `disabled_dates` | Array | `[]` | Dates to disable |
| `placeholder` | String | `nil` | Placeholder text |
| `input_name` | String | `nil` | Hidden input name for forms |
| `input_name_end` | String | `nil` | End date hidden input name |
| `disabled` | Boolean | `false` | Disable the trigger |
| `required` | Boolean | `false` | Mark input as required |

**Basic Usage:**
```erb
<%= render "components/date_picker",
  placeholder: "Pick a date" %>
```

**With Selected Date:**
```erb
<%= render "components/date_picker",
  selected: @event.date,
  placeholder: "Event date" %>
```

**Range Selection:**
```erb
<%= render "components/date_picker",
  mode: :range,
  selected: @booking.check_in,
  selected_end: @booking.check_out,
  placeholder: "Select dates" %>
```

**Form Integration:**
```erb
<%= form_with model: @event do |f| %>
  <div class="space-y-2">
    <%= f.label :scheduled_at, "Event Date" %>
    <%= render "components/date_picker",
      selected: @event.scheduled_at,
      input_name: "event[scheduled_at]",
      min_date: Date.current,
      required: true %>
  </div>
  <%= f.submit "Save", data: { component: "button", variant: "primary" } %>
<% end %>
```

**Calendar vs Date Picker:**

| Feature | Calendar | Date Picker |
|---------|----------|-------------|
| Display | Always visible | Hidden until triggered |
| Use case | Dashboards, scheduling | Form inputs, filters |
| Popover | No | Yes (native Popover API) |

---

### Combobox

Searchable select with autocomplete functionality.

**When to Use:**
- Large lists of options
- Type-ahead search
- Creating new options inline
- Filtered selection

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `options` | Array | `[]` | Array of `{value:, label:}` hashes |
| `selected` | String | `nil` | Currently selected value |
| `placeholder` | String | `"Select..."` | Placeholder text |
| `search_placeholder` | String | `"Search..."` | Search input placeholder |
| `empty_message` | String | `"No results found."` | Shown when no matches |
| `name` | String | `nil` | Form input name |
| `disabled` | Boolean | `false` | Disable the combobox |
| `required` | Boolean | `false` | Mark as required |

**Basic Usage:**
```erb
<%= render "components/combobox",
  options: [
    { value: "apple", label: "Apple" },
    { value: "banana", label: "Banana" },
    { value: "cherry", label: "Cherry" }
  ],
  placeholder: "Select a fruit..." %>
```

**Form Integration:**
```erb
<%= form_with model: @product do |f| %>
  <div data-form-part="group">
    <%= f.label :category_id, data: { component: "label" } %>
    <%= render "components/combobox",
      options: @categories.map { |c| { value: c.id, label: c.name } },
      selected: @product.category_id,
      name: "product[category_id]",
      placeholder: "Select category...",
      required: true %>
  </div>
<% end %>
```

**With Many Options:**
```erb
<%= render "components/combobox",
  options: Country.all.map { |c| { value: c.code, label: c.name } },
  selected: @user.country_code,
  name: "user[country_code]",
  placeholder: "Select country...",
  search_placeholder: "Search countries..." %>
```

---

### Toast

Temporary notification messages.

**When to Use:**
- Success confirmations
- Background task completion
- Non-blocking notifications
- Auto-dismissing messages

**Variants:**

| Variant | Usage |
|---------|-------|
| `:default` | General information |
| `:success` | Positive confirmations |
| `:warning` | Caution notices |
| `:destructive` | Error messages |

**Basic Usage (via Stimulus/Turbo):**
```erb
<%# In your layout, add the toaster container %>
<%= render "components/toaster" %>

<%# Trigger toasts from controller %>
<%# flash[:toast] = { variant: :success, title: "Saved!", description: "Your changes have been saved." } %>
```

**Manual Toast (for testing):**
```erb
<%= render "components/toast",
  variant: :success,
  title: "Success!",
  description: "Your changes have been saved." %>
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `variant` | Symbol | `:default` | Visual style |
| `title` | String | `nil` | Toast title |
| `description` | String | `nil` | Toast description |
| `duration` | Integer | `5000` | Auto-dismiss time in ms |
| `dismissible` | Boolean | `true` | Show close button |

---

## Form Components

Form components use data attributes with Rails form helpers. No partials needed.

### Button

**Variants:**

| Variant | Usage |
|---------|-------|
| `default` | Standard actions |
| `primary` | Primary CTA |
| `secondary` | Secondary actions |
| `destructive` | Delete, dangerous actions |
| `outline` | Subtle, bordered |
| `ghost` | Minimal, icon buttons |
| `link` | Text link style |

**Sizes:**

| Size | Usage |
|------|-------|
| `sm` | Compact UIs, table actions |
| `md` | Default |
| `lg` | Hero CTAs |
| `icon` | Square icon buttons |
| `icon-sm` | Small icon buttons |
| `icon-lg` | Large icon buttons |

**Usage:**
```erb
<%# Submit button %>
<%= f.submit "Save", data: { component: "button", variant: "primary" } %>

<%# Link styled as button %>
<%= link_to "Cancel", root_path, data: { component: "button", variant: "outline" } %>

<%# Destructive with confirmation %>
<%= button_to "Delete", resource_path, 
    method: :delete,
    data: { 
      component: "button", 
      variant: "destructive",
      turbo_confirm: t(".confirm_delete")
    } %>

<%# Icon button %>
<%= link_to settings_path, data: { component: "button", variant: "ghost", size: "icon" } do %>
  <%= icon_for :settings, class: "size-4" %>
<% end %>

<%# Button with icon %>
<%= link_to new_path, data: { component: "button", variant: "primary" } do %>
  <%= icon_for :plus, class: "size-4 mr-1" %> Add New
<% end %>
```

---

### Input

**Usage:**
```erb
<%= f.text_field :name, data: { component: "input" }, placeholder: "Name" %>
<%= f.email_field :email, data: { component: "input" } %>
<%= f.password_field :password, data: { component: "input" } %>
<%= f.number_field :quantity, data: { component: "input" } %>
<%= f.file_field :avatar, data: { component: "input" } %>

<%# With size %>
<%= f.text_field :name, data: { component: "input", size: "sm" } %>
<%= f.text_field :name, data: { component: "input", size: "lg" } %>

<%# Disabled %>
<%= f.text_field :name, data: { component: "input" }, disabled: true %>
```

---

### Textarea

```erb
<%= f.text_area :bio, data: { component: "textarea" }, rows: 4 %>
```

---

### Select

```erb
<%= f.select :country, country_options, {}, data: { component: "select" } %>
<%= f.collection_select :category_id, @categories, :id, :name, {}, data: { component: "select" } %>
```

---

### Checkbox

```erb
<%= f.check_box :terms, data: { component: "checkbox" } %>

<%# With inline label %>
<div data-form-part="group" data-layout="inline">
  <%= f.check_box :newsletter, data: { component: "checkbox" } %>
  <%= f.label :newsletter, t(".subscribe"), data: { component: "label" } %>
</div>
```

---

### Radio

```erb
<div data-form-part="group" data-layout="inline">
  <%= f.radio_button :plan, "basic", data: { component: "radio" } %>
  <%= f.label :plan_basic, "Basic", data: { component: "label" } %>
</div>
<div data-form-part="group" data-layout="inline">
  <%= f.radio_button :plan, "pro", data: { component: "radio" } %>
  <%= f.label :plan_pro, "Pro", data: { component: "label" } %>
</div>
```

---

### Switch

Toggle switch for boolean values.

```erb
<div data-form-part="group" data-layout="inline">
  <%= f.check_box :notifications, data: { component: "switch" } %>
  <%= f.label :notifications, t(".enable_notifications"), data: { component: "label" } %>
</div>
```

---

### Form Layout

**Form Container:**
```erb
<%= form_with model: @user, data: { component: "form" } do |f| %>
  ...
<% end %>
```

**Field Group:**
```erb
<div data-form-part="group">
  <%= f.label :email, data: { component: "label" } %>
  <%= f.email_field :email, data: { component: "input" } %>
  <p data-form-part="description">We'll never share your email.</p>
</div>

<%# With error %>
<div data-form-part="group">
  <%= f.label :email, data: { component: "label" } %>
  <%= f.email_field :email, data: { component: "input" } %>
  <% if @user.errors[:email].any? %>
    <p data-form-part="error"><%= @user.errors[:email].first %></p>
  <% end %>
</div>
```

**Inline Layout (checkbox/radio with label):**
```erb
<div data-form-part="group" data-layout="inline">
  <%= f.check_box :terms, data: { component: "checkbox" } %>
  <%= f.label :terms, data: { component: "label" } %>
</div>
```

**Actions:**
```erb
<div data-form-part="actions">
  <%= f.submit "Save", data: { component: "button", variant: "primary" } %>
  <%= link_to "Cancel", root_path, data: { component: "button", variant: "outline" } %>
</div>

<%# Right aligned %>
<div data-form-part="actions" data-align="end">
  <%= f.submit "Save", data: { component: "button", variant: "primary" } %>
</div>

<%# Space between %>
<div data-form-part="actions" data-align="between">
  <%= link_to "Back", root_path, data: { component: "button", variant: "ghost" } %>
  <%= f.submit "Continue", data: { component: "button", variant: "primary" } %>
</div>
```

**Fieldset:**
```erb
<fieldset data-component="fieldset">
  <legend data-component="legend">Account Information</legend>
  
  <div data-form-part="group">...</div>
  <div data-form-part="group">...</div>
</fieldset>
```

**Input Group (prefix/suffix):**
```erb
<div data-component="input-group">
  <span data-input-group-part="prefix">$</span>
  <%= f.number_field :price, data: { component: "input" } %>
</div>

<div data-component="input-group">
  <%= f.text_field :domain, data: { component: "input" } %>
  <span data-input-group-part="suffix">.com</span>
</div>
```
