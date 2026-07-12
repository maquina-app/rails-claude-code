---
name: ui
description: Build consistent, accessible UIs in Rails using maquina_components. Use this skill whenever implementing UI for features, creating views, building forms, designing layouts, or reviewing UI specs. Triggers on view creation, UI implementation, form building, layout design, or mentions of maquina_components.
---

# Maquina UI Standards

Build production-quality Rails UIs with maquina_components — ERB partials styled with Tailwind CSS 4 and data attributes, inspired by shadcn/ui.

**Official documentation:** https://maquina.app/documentation/components/

## Core Rules

1. **Composition first** — build screens from component partials and helpers; wrap repeated compositions into app-specific partials that encode your conventions.
2. **Data-attribute styling** — components style through `data-component` / `data-*-part` attributes; the engine CSS handles appearance. Tailwind utilities in views are for layout (grids, spacing), never for restyling components.
3. **Semantic variants** — map meaning to variants (`:success`, `:warning`, `:destructive`), one mapping per status domain. The danger variant is `:destructive` everywhere; sizes are `:sm` / `:default` / `:lg` (badge's middle size is `:md`; both accept the other's name as an alias).
4. **Helpers for interactive components** — `dropdown_menu`, `combobox`, `toggle_group`, `simple_table`, `pagination_nav` (Pagy), `empty_state`, `toast_flash_messages`, `breadcrumbs`. Use `_simple` variants for data-driven one-liners, block builders for custom content, partials for structural components (Card, Alert, Badge, Sidebar, Drawer).
5. **Inline errors** — field errors render next to their input (`data-form-part="error"`), with a brief flash summary. Complete inputs: every field carries `type`, `required`, `maxlength`, `autocomplete`, and `inputmode` where they apply.
6. **Handle the zero state** — every list renders an `empty_state` (or `empty_search_state` / `empty_list_state`) when the collection is empty.
7. **Icons via `icon_for`** — one icon system, delegating to the app's `main_icon_svg_for` override with built-in SVG fallbacks.
8. **Theme variables carry color** — `var(--primary)`, `var(--muted-foreground)`, etc. (shadcn/ui convention). One accent color moment per screen; neutrals elsewhere.

## Component Selection

| Need | Component | Helper |
|------|-----------|--------|
| Container with header/content/footer | Card | — |
| Important message | Alert | — |
| Status indicator | Badge | — |
| Data display | Table | `simple_table` |
| Zero-data state | Empty | `empty_state` |
| Actions menu | Dropdown Menu | `dropdown_menu` / `dropdown_menu_simple` |
| Option selection | Toggle Group | `toggle_group_simple` |
| Page location | Breadcrumbs | `breadcrumbs` / `responsive_breadcrumbs` |
| Paginated collections | Pagination | `pagination_nav` (Pagy) |
| App navigation | Sidebar | — |
| Slide-out panel | Drawer | `drawer_state` / `drawer_open?` |
| Form inputs | Form components (data attributes) | — |
| Inline date selection | Calendar | — |
| Date input field | Date Picker | — |
| Searchable selection | Combobox | `combobox` / `combobox_simple` |
| Temporary feedback | Toast | `toast_flash_messages`, `toast_success` … |
| Dashboard metrics | Stats | — |
| Content divider | Separator | — |

## Universal Component API

Every partial accepts `css_classes:` (additional classes) and `**html_options` (id, aria, data, title — any HTML attribute).

- **Container partials** (card, table, drawer, …) take a block. **Leaf partials** (titles, descriptions, cells, …) take `text:` for strings or `content:` for captured HTML, with a block as fallback.
- **Your `data:` merges with the component's.** Identity keys (component, variant, size) keep the component's values; `controller` and `action` **concatenate**, so `data: { controller: "analytics" }` on a combobox renders `data-controller="combobox analytics"` — attach behavior freely.
- Components generate **deterministic ids** (derived from name/side/title), safe under Turbo morphs.

```erb
<%= render "components/card", id: "profile", data: { controller: "collapsible" } do %>
  <%= render "components/card/header" do %>
    <%= render "components/card/title", text: @user.name %>
  <% end %>
<% end %>

<%= f.email_field :email, data: { component: "input" },
      required: true, maxlength: 254, autocomplete: "email" %>
<%= f.submit "Save", data: { component: "button", variant: "primary" } %>
```

## Quality Bar

Before marking a screen complete: intentional spacing rhythm (`space-y-*`, `gap-*` on a consistent scale), hover/focus/active states visible on every interactive element, empty/loading/error states rendered, layouts responsive without overflow, WCAG AA contrast with semantic HTML and keyboard access, primary/secondary hierarchy in every action group, link text that names its destination.

## Workflow

1. **Map the spec to components** using the selection table above.
2. **Plan layout structure** (grid, stacking, breakpoints) before writing components — read [layout-patterns.md](../../references/layout-patterns.md) when the page has more than one region.
3. **Build**, reaching for references as needed (below).
4. **Verify** against [spec-checklist.md](../../references/spec-checklist.md).

## References — read when the task touches them

| Read | When |
|------|------|
| [component-catalog.md](../../references/component-catalog.md) | Rendering any component — props, variants, composition examples |
| [helpers-reference.md](../../references/helpers-reference.md) | Using builder helpers or `_simple` methods |
| [form-patterns.md](../../references/form-patterns.md) | Building or reviewing forms |
| [layout-patterns.md](../../references/layout-patterns.md) | Page structure, grids, responsive design |
| [turbo-integration.md](../../references/turbo-integration.md) | Frames, Streams, or morph interacting with components |
| [stimulus-controllers.md](../../references/stimulus-controllers.md) | Extending or debugging component JavaScript |
| [installation-guide.md](../../references/installation-guide.md) | Setup, theme variables, icon overrides |
| [spec-checklist.md](../../references/spec-checklist.md) | Final verification before completion |
