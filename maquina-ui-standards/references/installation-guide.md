# Installation Guide

How to install and configure maquina_components in a Rails application.

---

## Prerequisites

- Ruby on Rails 7.1+
- [tailwindcss-rails](https://github.com/rails/tailwindcss-rails) gem installed with `app/assets/tailwind/application.css` present

---

## Installation

### 1. Add the Gem

```ruby
# Gemfile
gem "maquina-components"
```

```bash
bundle install
```

### 2. Run the Generator

```bash
bin/rails generate maquina_components:install
```

**Generator Options:**

| Option | Description |
|--------|-------------|
| `--skip-theme` | Skip adding theme CSS variables |
| `--skip-helper` | Skip creating the icon helper file |

### 3. What the Generator Creates

1. **CSS import** — Injects after `@import "tailwindcss"` in `app/assets/tailwind/application.css`:
   ```css
   @import "../builds/tailwind/maquina_components_engine.css";
   ```

2. **Theme variables** — Appends `:root` and `@theme` blocks with OKLCH color variables (unless `--skip-theme`)

3. **Icon helper** — Creates `app/helpers/maquina_components_helper.rb` with `main_icon_svg_for` override point (unless `--skip-helper`)

---

## CSS Architecture

maquina_components uses **data-attribute selectors** for all component styling:

```css
/* Component root */
[data-component="card"] { ... }

/* Component parts */
[data-card-part="header"] { ... }
[data-card-part="content"] { ... }

/* Variants */
[data-component="badge"][data-variant="success"] { ... }

/* States */
[data-component="sidebar"][data-state="expanded"] { ... }
```

**Key patterns:**
- `@apply` for spacing and typography utilities
- Explicit CSS for theme variable colors (not Tailwind utility classes)
- Data attributes for structure, variants, and state — not CSS classes
- No `dark:` prefixes — dark mode handled entirely via CSS variable switching

---

## Theme System

The theme follows [shadcn/ui](https://ui.shadcn.com/) conventions using OKLCH color space.

### Color Variables

Variables are defined in two places for Tailwind CSS 4 compatibility:

1. **`:root` block** — CSS custom properties for runtime use
2. **`@theme` block** — Tailwind theme bindings for utility class generation

**Core Variables:**

| Variable | Purpose | Tailwind Class |
|----------|---------|---------------|
| `--background` / `--foreground` | Page background and text | `bg-background`, `text-foreground` |
| `--card` / `--card-foreground` | Card surfaces | `bg-card`, `text-card-foreground` |
| `--popover` / `--popover-foreground` | Popover surfaces | `bg-popover` |
| `--primary` / `--primary-foreground` | Brand/CTA | `bg-primary`, `text-primary` |
| `--secondary` / `--secondary-foreground` | Secondary elements | `bg-secondary` |
| `--muted` / `--muted-foreground` | Subdued content | `bg-muted`, `text-muted-foreground` |
| `--accent` / `--accent-foreground` | Highlights | `bg-accent` |
| `--destructive` / `--destructive-foreground` | Dangerous actions | `bg-destructive` |
| `--success` / `--success-foreground` | Positive feedback | `bg-success` |
| `--warning` / `--warning-foreground` | Caution | `bg-warning` |
| `--border` | Default border color | `border-border` |
| `--input` | Input border color | `border-input` |
| `--ring` | Focus ring color | `ring-ring` |
| `--chart-1` through `--chart-5` | Chart colors | `bg-chart-1` |

**Layout Variables:**

| Variable | Default | Purpose |
|----------|---------|---------|
| `--header-height` | `3.5rem` | Top header height |
| `--sidebar-width` | `16rem` | Sidebar expanded width |
| `--sidebar-width-icon` | `3rem` | Sidebar icon-only width |

**Sidebar Variables:** `--sidebar`, `--sidebar-foreground`, `--sidebar-primary`, `--sidebar-primary-foreground`, `--sidebar-accent`, `--sidebar-accent-foreground`, `--sidebar-border`, `--sidebar-ring`

### Dark Mode

Dark mode is handled via CSS variables — switching the `.dark` class on `<html>` changes all variables automatically. No `dark:` Tailwind prefixes needed in your templates.

```css
:root {
  --background: oklch(1 0 0);        /* white */
  --foreground: oklch(0.145 0 0);    /* near-black */
}

.dark {
  --background: oklch(0.145 0 0);    /* near-black */
  --foreground: oklch(0.985 0 0);    /* near-white */
}
```

### Customizing Colors

Override in your `app/assets/tailwind/application.css`:

```css
:root {
  --primary: oklch(0.467 0.175 3.95);
  --primary-foreground: oklch(0.985 0 0);
}
```

---

## Stimulus Controllers

All Stimulus controllers are **auto-registered** via importmap. No manual registration or import needed. The engine handles:

1. Pin declarations in the engine's initializer
2. Controller registration through Stimulus autoload conventions

Controllers become available as `data-controller="sidebar"`, `data-controller="combobox"`, etc.

---

## Icon System

### Default: Built-in Icons

The gem includes 40+ built-in SVG icons (Lucide-style). Use `icon_for`:

```erb
<%= icon_for :check, class: "size-4" %>
```

### Custom Icon System

Override `main_icon_svg_for` in `app/helpers/maquina_components_helper.rb`:

```ruby
module MaquinaComponentsHelper
  def main_icon_svg_for(name)
    # Return SVG string for your icon system
    # Return nil to fall back to built-in icons

    # Example: Heroicons via heroicon gem
    heroicon(name.to_s)

    # Example: Lucide from node_modules
    File.read(Rails.root.join("node_modules/lucide-static/icons/#{name}.svg")).html_safe

    # Example: app/assets/icons directory
    file = Rails.root.join("app/assets/icons/#{name}.svg")
    file.exist? ? file.read.html_safe : nil
  end
end
```

### Sidebar State Helpers

The generated helper also re-exports sidebar state methods for convenience:

```ruby
def app_sidebar_state(cookie_name = "sidebar_state")
  sidebar_state(cookie_name)
end

def app_sidebar_open?(cookie_name = "sidebar_state")
  sidebar_open?(cookie_name)
end

def app_sidebar_closed?(cookie_name = "sidebar_state")
  sidebar_closed?(cookie_name)
end
```
