# Helpers Reference

Complete API reference for all 11 Ruby helper modules in maquina_components. These helpers provide ergonomic shortcuts — prefer them over multi-partial composition for complex interactive components.

---

## When to Use Helpers vs Partials

| Approach | Best For | Example |
|----------|----------|---------|
| **Helpers** | Complex interactive components with builder patterns | Combobox, Dropdown Menu, Toggle Group, Table, Toast |
| **Partials** | Structural/layout components you compose freely | Card, Alert, Badge, Sidebar, Empty |

**Rule of thumb:** If the component has a `_simple` helper, use it for data-driven cases. Use the block form for custom content.

---

## BreadcrumbsHelper

Generates breadcrumb navigation from a hash of links.

### `breadcrumbs(links = {}, current_page = nil, css_classes: "")`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `links` | Hash | `{}` | `{ "Label" => path }` pairs |
| `current_page` | String | `nil` | Current page label (not a link) |
| `css_classes` | String | `""` | Additional CSS classes |

```erb
<%= breadcrumbs({ "Home" => root_path, "Users" => users_path }, @user.name) %>
```

### `responsive_breadcrumbs(links = {}, current_page = nil, css_classes: "", collapse_after: 0)`

Same API as `breadcrumbs` but collapses middle items into a dropdown on overflow. When `collapse_after` is set, also forces collapse by item count regardless of overflow.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `links` | Hash | `{}` | `{ "Label" => path }` pairs |
| `current_page` | String | `nil` | Current page label (not a link) |
| `css_classes` | String | `""` | Additional CSS classes |
| `collapse_after` | Integer | `0` | Max visible items (first + last count). `0` = pure overflow detection. `2` = show first + last only. `3` = first + one middle + last. |

```erb
<%# Pure overflow detection (default) %>
<%= responsive_breadcrumbs(
  { "Home" => root_path, "Settings" => settings_path, "Team" => team_path },
  "Members"
) %>

<%# Force collapse — always show first + last, collapse middle %>
<%= responsive_breadcrumbs(
  { "Home" => root_path, "Settings" => settings_path, "Team" => team_path },
  "Members",
  collapse_after: 2
) %>
```

---

## CalendarHelper

Utilities for building calendar UIs and date pickers. Mostly used internally by Calendar/DatePicker partials, but available for custom implementations.

### `calendar_month_data(date, week_starts_on = :sunday)`

Returns array of week arrays for the given month, including padding days from adjacent months.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `date` | Date | required | Any date in the target month |
| `week_starts_on` | Symbol | `:sunday` | `:sunday` or `:monday` |

### `calendar_month_name(date, format = :long)`

Returns localized month name with year.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `date` | Date | required | Target date |
| `format` | Symbol | `:long` | `:long` or `:short` |

### `calendar_date_in_range?(date, start_date, end_date)`

Returns boolean — whether date falls within the range (inclusive).

### `calendar_data_attrs(mode: :single, selected: nil, selected_end: nil, month: nil, year: nil)`

Returns data attributes hash for calendar Stimulus controller.

### `calendar_weekday_names(week_starts_on = :sunday, format = :short)`

Returns array of localized weekday names starting from the given day.

### `date_picker_data_attrs(mode: :single, selected: nil, selected_end: nil)`

Returns data attributes hash for date-picker Stimulus controller.

### `date_picker_format(date, format = :long)`

Formats a date for display in the date picker trigger.

### `date_picker_format_range(start_date, end_date, format = :short)`

Formats a date range for display.

---

## ComboboxHelper

Searchable select with autocomplete. Provides both a simple data-driven API and a block-based builder for full control.

### `combobox_simple(options:, placeholder: "Select...", search_placeholder: "Search...", empty_text: "No results found.", value: nil, name: nil, trigger_options: {}, content_options: {})`

Quick path for data-driven comboboxes.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `options` | Array | required | `[{ value:, label: }, ...]` |
| `placeholder` | String | `"Select..."` | Trigger placeholder |
| `search_placeholder` | String | `"Search..."` | Search input placeholder |
| `empty_text` | String | `"No results found."` | No-match message |
| `value` | String | `nil` | Pre-selected value |
| `name` | String | `nil` | Hidden input name for forms |
| `trigger_options` | Hash | `{}` | Extra options for trigger |
| `content_options` | Hash | `{}` | Extra options for content |

```erb
<%= combobox_simple(
  options: @categories.map { |c| { value: c.id, label: c.name } },
  value: @product.category_id,
  name: "product[category_id]",
  placeholder: "Select category..."
) %>
```

### `combobox(id: nil, name: nil, value: nil, placeholder: "Select...", css_classes: "", **html_options, &block)`

Block form with full builder control.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | String | auto-generated | Unique combobox ID |
| `name` | String | `nil` | Hidden input name |
| `value` | String | `nil` | Pre-selected value |
| `placeholder` | String | `"Select..."` | Placeholder text |
| `css_classes` | String | `""` | Additional CSS classes |

**Builder methods (ComboboxBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `trigger` | `variant: :outline, size: :default, **options` | Trigger button |
| `content` | `align: :start, width: :default, **options, &block` | Popover content |

**Content builder methods (ComboboxContentBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `input` | `placeholder: "Search...", **options` | Search input |
| `list` | `**options, &block` | Options list container |
| `empty` | `text: "No results found.", **options` | Empty state |

**List builder methods (ComboboxListBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `option` | `value:, selected: false, disabled: false, **options, &block` | Single option |
| `group` | `**options, &block` | Option group |
| `label` | `text = nil, **options, &block` | Group label |
| `separator` | `**options` | Visual separator |

```erb
<%= combobox(name: "user[role]", value: @user.role) do |c| %>
  <% c.content do |content| %>
    <% content.input(placeholder: "Search roles...") %>
    <% content.list do |list| %>
      <% list.label("Standard") %>
      <% list.option(value: "viewer") { "Viewer" } %>
      <% list.option(value: "editor") { "Editor" } %>
      <% list.separator %>
      <% list.label("Privileged") %>
      <% list.option(value: "admin") { "Admin" } %>
    <% end %>
    <% content.empty(text: "No roles found.") %>
  <% end %>
<% end %>
```

---

## DropdownMenuHelper

Accessible dropdown menus with keyboard navigation. Simple API for data-driven menus, block API for custom content.

### `dropdown_menu_simple(trigger_text, items:, trigger_options: {}, content_options: {})`

Quick path for data-driven menus.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `trigger_text` | String | required | Button label |
| `items` | Array | required | Array of item hashes (see below) |
| `trigger_options` | Hash | `{}` | Extra trigger options |
| `content_options` | Hash | `{}` | Extra content options |

**Item hash keys:** `label:`, `href:`, `method:`, `icon:`, `variant:` (`:default` or `:destructive`), `disabled:`

```erb
<%= dropdown_menu_simple "Actions", items: [
  { label: "Edit", href: edit_item_path(@item), icon: :pencil },
  { label: "Duplicate", href: duplicate_item_path(@item), icon: :copy },
  { label: "Delete", href: item_path(@item), method: :delete, variant: :destructive, icon: :trash }
] %>
```

### `dropdown_menu(css_classes: "", **html_options, &block)`

Block form with full builder control.

**Builder methods (DropdownMenuBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `trigger` | `variant: :outline, size: :default, as_child: false, **options, &block` | Trigger button |
| `content` | `align: :start, side: :bottom, width: :default, **options, &block` | Menu content |

**Content builder methods (DropdownMenuContentBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `item` | `label = nil, href: nil, method: nil, icon: nil, variant: :default, disabled: false, **options, &block` | Menu item |
| `label` | `text = nil, inset: false, **options, &block` | Section label |
| `separator` | `**options` | Visual separator |
| `group` | `**options, &block` | Item group |

**Item builder methods (DropdownMenuItemBuilder):**

| Method | Description |
|--------|-------------|
| `shortcut(text)` | Keyboard shortcut display |

```erb
<%= dropdown_menu do |menu| %>
  <% menu.trigger(variant: :outline) { "Options" } %>
  <% menu.content(align: :end) do |content| %>
    <% content.label("Actions") %>
    <% content.item("Edit", href: edit_path, icon: :pencil) %>
    <% content.item(href: duplicate_path, icon: :copy) do |item| %>
      Duplicate
      <% item.shortcut("⌘D") %>
    <% end %>
    <% content.separator %>
    <% content.item("Delete", href: delete_path, method: :delete, variant: :destructive, icon: :trash) %>
  <% end %>
<% end %>
```

---

## EmptyHelper

Convenience helpers for common empty state patterns.

### `empty_state(title:, description: nil, icon: nil, variant: :default, size: :default, css_classes: "", **html_options, &block)`

General-purpose empty state. Yields block for action content.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | String | required | Main heading |
| `description` | String | `nil` | Supporting text |
| `icon` | Symbol | `nil` | Icon name |
| `variant` | Symbol | `:default` | Visual variant |
| `size` | Symbol | `:default` | Size variant |
| `css_classes` | String | `""` | Additional CSS classes |

```erb
<%= empty_state(title: "No projects yet", description: "Create your first project to get started.", icon: :folder) do %>
  <%= link_to "New Project", new_project_path, data: { component: "button", variant: "primary" } %>
<% end %>
```

### `empty_search_state(query: nil, reset_path: nil, size: :default)`

Pre-built empty state for search results.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | String | `nil` | The search term (shown in message) |
| `reset_path` | String | `nil` | Path to clear search |
| `size` | Symbol | `:default` | Size variant |

```erb
<%= empty_search_state(query: params[:q], reset_path: users_path) %>
```

### `empty_list_state(resource_name:, new_path: nil, icon: :folder_open, size: :default)`

Pre-built empty state for empty collections.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `resource_name` | String | required | Pluralized resource name |
| `new_path` | String | `nil` | Path to create new |
| `icon` | Symbol | `:folder_open` | Icon name |
| `size` | Symbol | `:default` | Size variant |

```erb
<%= empty_list_state(resource_name: "invoices", new_path: new_invoice_path) %>
```

---

## IconsHelper

Icon rendering with support for custom icon systems.

### `icon_for(name, options = {})`

Primary icon method. Checks your app's `main_icon_svg_for` override first, falls back to built-in icons.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | Symbol/String | Icon identifier |
| `options` | Hash | HTML attributes (`class:`, `aria:`, etc.) |

```erb
<%= icon_for :check, class: "size-4" %>
<%= icon_for :chevron_right, class: "size-4 text-muted-foreground" %>
```

### `builtin_icon_for(name, options = {})`

Directly access engine's built-in icons, bypassing your app override.

### `main_icon_svg_for(name)`

Override point. Define this in `app/helpers/maquina_components_helper.rb` to use your own icon system:

```ruby
# app/helpers/maquina_components_helper.rb
module MaquinaComponentsHelper
  def main_icon_svg_for(name)
    # Return nil to fall back to built-in icons
    # Return SVG string for custom icons
    heroicon(name.to_s) # Example: using Heroicons
  end
end
```

### Built-in Icons

`dollar`, `users`, `credit_card`, `activity`, `trend_up`, `trend_down`, `clock`, `money`, `line_chart`, `piggy_bank`, `arrow_left`, `select_chevron`, `check`, `circle_alert`, `logout`, `chevron_up_down`, `chevron_right`, `chevron_left`, `left_panel`, `ellipsis`, `calendar`, `info`, `triangle_alert`, `check_circle`, `arrow_right`, `slash`, `inbox`, `folder`, `search`, `upload`, `user`, `log_out`, `more_horizontal`, `settings`, `mail`, `download`, `trash`, `pencil`, `home`, `layout_dashboard`, `align_left`, `align_center`, `align_right`, `bold`, `italic`, `underline`, `list`, `grid`

---

## PaginationHelper

Pagination navigation integrated with the [Pagy](https://github.com/ddnexus/pagy) gem.

### `pagination_nav(pagy, route_helper, params: {}, turbo: { action: :replace }, show_labels: true, css_classes: "", **html_options)`

Full pagination with page numbers.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pagy` | Pagy | required | Pagy instance |
| `route_helper` | Symbol | required | Route helper name (e.g., `:users_path`) |
| `params` | Hash | `{}` | Extra URL params |
| `turbo` | Hash | `{ action: :replace }` | Turbo data attributes |
| `show_labels` | Boolean | `true` | Show Previous/Next text |
| `css_classes` | String | `""` | Additional CSS classes |

```erb
<%= pagination_nav(@pagy, :users_path) %>
<%= pagination_nav(@pagy, :users_path, show_labels: false, params: { status: "active" }) %>
```

### `pagination_simple(pagy, route_helper, params: {}, turbo: { action: :replace }, css_classes: "", **html_options)`

Minimal previous/next navigation without page numbers.

```erb
<%= pagination_simple(@pagy, :users_path) %>
```

### `paginated_path(route_helper, pagy, page, extra_params = {})`

Generates a URL for a specific page. Useful for custom pagination UIs.

| Parameter | Type | Description |
|-----------|------|-------------|
| `route_helper` | Symbol | Route helper name |
| `pagy` | Pagy | Pagy instance |
| `page` | Integer | Target page number |
| `extra_params` | Hash | Additional URL params |

```erb
<%= link_to "Page 3", paginated_path(:users_path, @pagy, 3) %>
```

---

## SidebarHelper

Sidebar state management via cookies.

### `sidebar_state(cookie_name = "sidebar_state")`

Returns `:expanded` or `:collapsed`.

### `sidebar_open?(cookie_name = "sidebar_state")`

Returns `true` if sidebar is expanded.

### `sidebar_closed?(cookie_name = "sidebar_state")`

Returns `true` if sidebar is collapsed.

```erb
<%= render "components/sidebar/provider", default_open: sidebar_open? do %>
  ...
<% end %>
```

---

## TableHelper

Data table helper for simple, data-driven tables. For complex tables with custom cell content, use the partial-based approach.

### `simple_table(collection, columns:, caption: nil, variant: nil, table_variant: nil, empty_message: "No data available", row_id: nil, **html_options)`

Renders a complete table from a collection and column definitions.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `collection` | Array | required | Records to display |
| `columns` | Array | required | Column definitions (see below) |
| `caption` | String | `nil` | Table caption |
| `variant` | Symbol | `nil` | Container variant |
| `table_variant` | Symbol | `nil` | Table variant |
| `empty_message` | String | `"No data available"` | Shown when collection is empty |
| `row_id` | Proc/Lambda | `nil` | Row ID generator |

**Column definition:** Each column is a Hash with `header:`, `accessor:` (method name or proc), `align:`, and other options.

```erb
<%= simple_table(@users, columns: [
  { header: "Name", accessor: :name },
  { header: "Email", accessor: :email },
  { header: "Status", accessor: ->(u) { u.status.titleize } },
  { header: "Joined", accessor: ->(u) { l(u.created_at, format: :short) }, align: :right }
]) %>
```

### Data Attribute Helpers

These return hashes for use with the partial-based table approach:

| Method | Parameters | Returns |
|--------|-----------|---------|
| `table_data_attrs(variant: nil)` | `variant` | Data attrs for `<table>` |
| `table_container_data_attrs(variant: nil)` | `variant` | Data attrs for scroll container |
| `table_row_data_attrs(selected: false)` | `selected` | Data attrs for `<tr>` |
| `table_header_data_attrs(sticky: false)` | `sticky` | Data attrs for `<thead>` |
| `table_head_data_attrs` | — | Data attrs for `<th>` |
| `table_cell_data_attrs(empty: false)` | `empty` | Data attrs for `<td>` |
| `table_body_data_attrs` | — | Data attrs for `<tbody>` |
| `table_footer_data_attrs` | — | Data attrs for `<tfoot>` |
| `table_caption_data_attrs` | — | Data attrs for `<caption>` |

### `table_alignment_class(align)`

Returns CSS class for column alignment (`:left`, `:center`, `:right`).

---

## ToastHelper

Toast notifications tied to Rails flash messages.

### `toast_flash_messages(exclude: [])`

Renders toast notifications for all current flash messages. Place in your layout.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `exclude` | Array | `[]` | Flash keys to skip |

```erb
<%# In application layout, inside the toaster container %>
<%= render "components/toaster" %>
<%= toast_flash_messages %>

<%# Exclude specific flash types %>
<%= toast_flash_messages(exclude: [:timedout]) %>
```

### `toast(variant, title, description: nil, **options)`

Render a single toast notification.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `variant` | Symbol | required | `:default`, `:success`, `:error`, `:warning`, `:info` |
| `title` | String | required | Toast heading |
| `description` | String | `nil` | Supporting text |

### Convenience Methods

| Method | Variant |
|--------|---------|
| `toast_success(title, **options)` | `:success` |
| `toast_error(title, **options)` | `:error` |
| `toast_warning(title, **options)` | `:warning` |
| `toast_info(title, **options)` | `:info` |

```erb
<%= toast_success("Saved!", description: "Your changes have been saved.") %>
```

### FLASH_VARIANTS Constant

Maps Rails flash keys to toast variants:

```ruby
FLASH_VARIANTS = {
  notice: :success,
  success: :success,
  alert: :error,
  error: :error,
  warning: :warning,
  warn: :warning,
  info: :info
}.freeze
```

---

## ToggleGroupHelper

Button group for single or multiple selection.

### `toggle_group_simple(items:, type: :single, variant: :default, size: :default, value: nil, disabled: false, css_classes: "", **html_options)`

Quick path for data-driven toggle groups.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `items` | Array | required | `[{ value:, label:, icon:, disabled:, aria_label: }, ...]` |
| `type` | Symbol | `:single` | `:single` or `:multiple` |
| `variant` | Symbol | `:default` | `:default` or `:outline` |
| `size` | Symbol | `:default` | `:sm`, `:default`, `:lg` |
| `value` | String/Array | `nil` | Pre-selected value(s) |
| `disabled` | Boolean | `false` | Disable all items |
| `css_classes` | String | `""` | Additional CSS classes |

```erb
<%= toggle_group_simple(
  items: [
    { value: "list", icon: :list, aria_label: "List view" },
    { value: "grid", icon: :grid, aria_label: "Grid view" }
  ],
  value: "list"
) %>
```

### `toggle_group(type: :single, variant: :default, size: :default, value: nil, disabled: false, css_classes: "", **html_options, &block)`

Block form with builder.

**Builder methods (ToggleGroupBuilder):**

| Method | Parameters | Description |
|--------|-----------|-------------|
| `item` | `value:, label: nil, icon: nil, disabled: false, aria_label: nil, **options, &block` | Toggle item |

```erb
<%= toggle_group(type: :multiple, variant: :outline) do |group| %>
  <% group.item(value: "bold", icon: :bold, aria_label: "Bold") %>
  <% group.item(value: "italic", icon: :italic, aria_label: "Italic") %>
  <% group.item(value: "underline", icon: :underline, aria_label: "Underline") %>
<% end %>
```
