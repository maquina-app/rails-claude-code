# Rails UI Patterns

Dashboard UI patterns using Tailwind CSS v4, Hotwire, and maquina_components.

**Component Library:** [maquina_components](https://maquina.app/documentation/components/)

All component references (cards, tables, badges, buttons, forms) use maquina_components partials. Install with:

```ruby
# Gemfile
gem "maquina_components"
```

```bash
bin/rails maquina_components:install
```

---

## Core Principles

1. **Semantic Colors** — Use CSS variables, not hardcoded colors. Dark mode comes free.
2. **Data Attributes** — Use `data-component="button"` over utility class sprawl.
3. **Sensible Defaults** — Components work without customization; override with intent.
4. **Progressive Disclosure** — Show what's needed, hide complexity until requested.

---

## Color System

### Semantic Variables

| Purpose     | Background       | Text                      | Border           |
|-------------|------------------|---------------------------|------------------|
| Primary     | `bg-primary`     | `text-primary`            | `border-primary` |
| Muted       | `bg-muted`       | `text-muted-foreground`   | `border-muted`   |
| Success     | `bg-success`     | `text-success-foreground` | `border-success` |
| Warning     | `bg-warning`     | `text-warning-foreground` | `border-warning` |
| Destructive | `bg-destructive` | `text-destructive`        | `border-destructive` |

### Never Hardcode

```erb
<%# ❌ Bad - breaks in dark mode %>
<div class="bg-green-100 text-green-800">Active</div>

<%# ✅ Good - uses semantic tokens %>
<div class="bg-success text-success-foreground">Active</div>
```

---

## Typography

| Element      | Classes                                | Usage            |
|--------------|----------------------------------------|------------------|
| Page title   | `text-2xl font-bold text-foreground`   | Main heading     |
| Section      | `text-lg font-semibold text-foreground`| Card titles      |
| Body         | `text-sm text-foreground`              | Default content  |
| Muted        | `text-sm text-muted-foreground`        | Descriptions     |
| Small        | `text-xs text-muted-foreground`        | Timestamps       |
| Monospace    | `font-mono text-sm`                    | IDs, codes       |

---

## Page Layout

### Standard Structure

```erb
<div class="container mx-auto px-4 py-8 space-y-6">
  <%# 1. Header %>
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-foreground">Page Title</h1>
      <p class="mt-1 text-sm text-muted-foreground">Description.</p>
    </div>
    <%# Action buttons %>
  </div>

  <%# 2. Stats Grid (optional) %>
  <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
    <%# Stat cards %>
  </div>

  <%# 3. Filters (optional) %>

  <%# 4. Main Content %>
  <%= render "components/card" do %>
    <%# Table or content %>
  <% end %>

  <%# 5. Pagination %>
</div>
```

### Two-Column (Show Pages)

```erb
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
  <div class="lg:col-span-2 space-y-6">
    <%# Main content (2/3) %>
  </div>
  <div class="space-y-6">
    <%# Sidebar (1/3) %>
  </div>
</div>
```

---

## Card Component

### Basic

```erb
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: "Title" %>
    <%= render "components/card/description", text: "Description" %>
  <% end %>
  <%= render "components/card/content" do %>
    <%# Content %>
  <% end %>
<% end %>
```

### Stat Card (Row Layout)

```erb
<%= render "components/card" do %>
  <%= render "components/card/header", layout: :row, class: "pb-0" do %>
    <%= render "components/card/title", text: "Total", size: :md %>
    <%= render "components/card/action" do %>
      <div class="rounded-md bg-secondary p-2">
        <%= icon_for(:folder, class: "h-4 w-4 text-secondary-foreground") %>
      </div>
    <% end %>
  <% end %>
  <%= render "components/card/content" do %>
    <div class="text-3xl font-bold text-primary"><%= @count %></div>
    <p class="text-xs text-muted-foreground">Description</p>
  <% end %>
<% end %>
```

### Stat Card Colors

| Type    | Icon BG          | Number Color              | Icons                    |
|---------|------------------|---------------------------|--------------------------|
| Total   | `bg-secondary`   | `text-primary`            | `:folder`, `:building_2` |
| Active  | `bg-success`     | `text-success-foreground` | `:check`                 |
| Inactive| `bg-muted`       | `text-muted-foreground`   | `:minus`                 |
| Warning | `bg-warning`     | `text-warning-foreground` | `:alert_triangle`        |
| Error   | `bg-destructive` | `text-destructive`        | `:x`                     |

---

## Table Component

### Structure

```erb
<%= render "components/card", css_classes: "overflow-hidden" do %>
  <%= render "components/table" do %>
    <%= render "components/table/header", sticky: true do %>
      <%= render "components/table/row" do %>
        <%= render "components/table/head" do %>Column<% end %>
        <%= render "components/table/head" do %><span class="sr-only">Actions</span><% end %>
      <% end %>
    <% end %>
    <%= render "components/table/body" do %>
      <% @items.each do |item| %>
        <%= render "components/table/row" do %>
          <%= render "components/table/cell" do %><%= item.name %><% end %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

### Cell Patterns

```erb
<%# Primary cell %>
<%= render "components/table/cell" do %>
  <div class="text-sm font-medium text-foreground"><%= item.name %></div>
  <div class="text-xs text-muted-foreground"><%= item.subtitle %></div>
<% end %>

<%# Timestamp %>
<%= render "components/table/cell", css_classes: "text-sm text-muted-foreground" do %>
  <time datetime="<%= item.created_at.iso8601 %>">
    <%= time_ago_in_words(item.created_at) %> ago
  </time>
<% end %>

<%# Actions %>
<%= render "components/table/cell", css_classes: "text-right text-sm font-medium" do %>
  <%= link_to "View", item, class: "text-primary hover:text-primary/80" %>
<% end %>
```

### Empty State

```erb
<%= render "components/table/cell", colspan: 6, data: { empty: "true" } do %>
  <div class="flex flex-col items-center">
    <%= icon_for(:inbox, class: "h-12 w-12 text-muted-foreground/50") %>
    <h3 class="mt-2 text-sm font-medium text-foreground">No items found</h3>
    <p class="mt-1 text-sm text-muted-foreground">Get started by creating one.</p>
    <%= link_to new_item_path, data: { component: "button", variant: "primary" }, class: "mt-4" do %>
      <%= icon_for(:plus, class: "h-4 w-4") %> New Item
    <% end %>
  </div>
<% end %>
```

---

## Badges

```erb
<%# Variants: default, success, warning, destructive, outline %>
<%= render "components/badge", variant: :success, size: :sm do %>
  <%= icon_for(:check, class: "h-3 w-3") %> Active
<% end %>
```

| State      | Variant       | Icon            |
|------------|---------------|-----------------|
| Active     | `:success`    | `:check`        |
| Inactive   | `:default`    | `:minus`        |
| Pending    | `:warning`    | `:clock`        |
| Error      | `:destructive`| `:x`            |
| Info       | `:outline`    | `:info`         |

---

## Buttons

```erb
<%# Primary %>
<%= link_to path, data: { component: "button", variant: "primary" } do %>
  <%= icon_for(:plus, class: "h-4 w-4") %> Create
<% end %>

<%# Outline %>
<%= link_to path, data: { component: "button", variant: "outline" } do %>
  Cancel
<% end %>

<%# Destructive with confirmation %>
<%= button_to path, method: :delete,
    data: { component: "button", variant: "destructive", turbo_confirm: "Are you sure?" } do %>
  <%= icon_for(:trash, class: "h-4 w-4") %> Delete
<% end %>

<%# Ghost (minimal) %>
<%= link_to path, data: { component: "button", variant: "ghost", size: "sm" } do %>
  <%= icon_for(:eye, class: "h-4 w-4") %>
<% end %>
```

---

## Forms

### Structure

```erb
<%= form_with model: @resource, data: { component: "form" } do |form| %>
  <%# Error display %>
  <% if @resource.errors.any? %>
    <div class="rounded-md bg-destructive/10 p-4 mb-6">
      <div class="flex">
        <%= icon_for(:x, class: "h-5 w-5 text-destructive shrink-0") %>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-destructive">
            <%= pluralize(@resource.errors.count, "error") %> prohibited saving:
          </h3>
          <ul class="mt-2 text-sm text-destructive list-disc pl-5 space-y-1">
            <% @resource.errors.full_messages.each do |msg| %>
              <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
  <% end %>

  <div class="space-y-6">
    <%# Form fields %>
  </div>
<% end %>
```

### Field Group

```erb
<div data-form-part="group">
  <%= form.label :name, data: { component: "label" } %>
  <%= form.text_field :name, required: true, data: { component: "input" }, class: "w-full" %>
  <p data-form-part="description">Help text.</p>
  <% if @resource.errors[:name].any? %>
    <p data-form-part="error"><%= @resource.errors[:name].first %></p>
  <% end %>
</div>
```

### Form Elements

```erb
<%# Text input %>
<%= form.text_field :name, data: { component: "input" }, class: "w-full" %>

<%# Select %>
<%= form.select :category, options_for_select(@categories),
    { include_blank: "Select..." }, data: { component: "select" }, class: "w-full" %>

<%# Textarea %>
<%= form.text_area :description, rows: 3, data: { component: "textarea" }, class: "w-full" %>

<%# Checkbox %>
<div class="flex items-center gap-3">
  <%= form.check_box :active, data: { component: "checkbox" } %>
  <%= form.label :active, data: { component: "label" } do %>
    Active <span class="font-normal text-muted-foreground ml-1">— Enabled</span>
  <% end %>
</div>
```

### Form Actions

```erb
<div data-form-part="actions" data-align="between">
  <p class="text-sm text-muted-foreground">
    <%= icon_for(:info, class: "inline h-4 w-4") %> Changes apply on save.
  </p>
  <div class="flex gap-3">
    <%= link_to "Cancel", :back, data: { component: "button", variant: "outline" } %>
    <%= form.submit "Save", data: { component: "button", variant: "primary" } %>
  </div>
</div>
```

---

## Filters

```erb
<%= form_tag(items_path, method: :get,
    data: { turbo_frame: "_top", controller: "auto-submit", component: "form" }) do %>
  
  <%= hidden_field_tag :sort, params[:sort] if params[:sort].present? %>
  <% filter_active = params[:q].present? || params[:status].present? %>

  <div class="flex flex-wrap items-center gap-3">
    <%= text_field_tag :q, params[:q], placeholder: "Search...",
        data: { component: "input", action: "input->auto-submit#debounceSubmit" },
        class: "w-auto min-w-[200px]" %>

    <%= select_tag :status, options_for_select(@statuses, params[:status]),
        data: { component: "select", action: "change->auto-submit#submit" },
        class: "w-auto min-w-[120px]" %>

    <%= button_tag type: "submit",
        data: { component: "button", variant: filter_active ? "primary" : "outline" } do %>
      <%= icon_for(:filter) %> Filter
    <% end %>

    <% if filter_active %>
      <%= link_to items_path, data: { component: "button", variant: "outline" } do %>
        <%= icon_for(:x) %> Clear
      <% end %>
    <% end %>
  </div>
<% end %>
```

---

## Turbo Patterns

### Default: Morph + Broadcasts

```ruby
# Model
class Item < ApplicationRecord
  after_commit :broadcast_changes

  private

  def broadcast_changes
    broadcast_refresh_to "items"
  end
end
```

```erb
<%# View %>
<%= turbo_stream_from "items" %>
```

### Turbo Frames (Use Sparingly)

Only for:
- Inline editing
- Modal dialogs
- Quick-add forms

```erb
<%= turbo_frame_tag dom_id(item) do %>
  <%# Editable content %>
<% end %>
```

### Turbo Streams (Multi-Element Updates)

```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.update("stats", partial: "stats"),
      turbo_stream.prepend("items", partial: "item", locals: { item: @item })
    ]
  end
end
```

---

## Data Attributes Reference

| Attribute                  | Values                                        |
|----------------------------|-----------------------------------------------|
| `data-component="button"`  | `variant`: primary, outline, ghost, destructive |
| `data-component="input"`   | Text inputs                                   |
| `data-component="select"`  | Dropdowns                                     |
| `data-component="checkbox"`| Boolean toggle                                |
| `data-component="label"`   | Field labels                                  |
| `data-form-part="group"`   | Field container                               |
| `data-form-part="error"`   | Error message                                 |
| `data-form-part="actions"` | Form footer (`data-align="between"`)          |
| `data-empty="true"`        | Empty state cell                              |
| `data-sticky="true"`       | Sticky table header                           |
