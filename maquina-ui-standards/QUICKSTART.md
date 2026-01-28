
# Maquina UI Standards - Quick Start

Build Rails UIs with maquina_components — server-rendered ERB partials with Tailwind CSS 4.

**Official Documentation:** https://maquina.app/documentation/components/

## Core Pattern

```erb
<%# Partial components %>
<%= render "components/card" do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: "My Title" %>
  <% end %>
  <%= render "components/card/content" do %>
    Content here
  <% end %>
<% end %>

<%# Form components via data attributes %>
<%= form_with model: @user, data: { component: "form" } do |f| %>
  <div data-form-part="group">
    <%= f.label :email, data: { component: "label" } %>
    <%= f.email_field :email, data: { component: "input" } %>
  </div>
  <%= f.submit "Save", data: { component: "button", variant: "primary" } %>
<% end %>
```

## Key Files

| File | Purpose |
|------|---------|
| `agents/maquina-ui-standards.md` | Core principles, decision framework |
| `references/component-catalog.md` | All components with props and examples |
| `references/form-patterns.md` | Forms, validation, field groups |
| `references/layout-patterns.md` | Grids, responsive, page structure |
| `references/turbo-integration.md` | Frames, Streams, Morph patterns |
| `references/spec-checklist.md` | UI review checklist |

## Component Categories

- **Layout:** Sidebar, Header
- **Content:** Card, Alert, Badge, Table, Empty, Separator, Stats
- **Navigation:** Breadcrumbs, Dropdown Menu, Pagination
- **Interactive:** Toggle Group, Calendar, Date Picker, Combobox, Toast
- **Forms:** Button, Input, Textarea, Select, Checkbox, Radio, Switch

## Quick Tips

1. **Compose, don't configure** — Build UIs from small parts
2. **Inline errors** — Show errors next to fields, not in lists
3. **Data attributes** — Components identify via `data-component="..."`
4. **Icons** — Use `icon_for :name, class: "size-4"`
5. **Theme** — Colors via CSS variables (`--primary`, `--destructive`, etc.)

Read the main skill file for complete guidelines.
