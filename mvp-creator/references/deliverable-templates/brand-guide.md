# Brand Guide Template

Use this structure when generating the brand guide deliverable.

---

# [APP_NAME] Brand Guide

---

## Brand Overview

### Brand Essence

One sentence capturing what [APP_NAME] represents.

### Brand Values

1. **[Value 1]** — Description
2. **[Value 2]** — Description
3. **[Value 3]** — Description

### Brand Personality

- Adjective 1
- Adjective 2
- Adjective 3

---

## Logo

### Concept

The logo represents [concept]. It symbolizes [meaning].

### Logo Variations

**Primary Logo:**
- Description of primary logo
- When to use

**Icon/Mark:**
- Description of icon
- When to use (app icon, favicon, small spaces)

**Wordmark:**
- Description of wordmark
- When to use

### Logo Specifications

| Element | Value |
|---------|-------|
| Minimum size | Xpx |
| Clear space | X% of logo height |
| Background | Light/Dark requirements |

### Logo Don'ts

- Don't stretch or distort
- Don't change colors outside palette
- Don't add effects (shadows, gradients)
- Don't place on busy backgrounds

### SVG Logo Code

```svg
<!-- Primary Logo SVG -->
<svg viewBox="0 0 [width] [height]" xmlns="http://www.w3.org/2000/svg">
  <!-- Logo paths here -->
</svg>
```

```svg
<!-- Icon/Mark SVG -->
<svg viewBox="0 0 [width] [height]" xmlns="http://www.w3.org/2000/svg">
  <!-- Icon paths here -->
</svg>
```

---

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Primary | #XXXXXX | rgb(X, X, X) | Main brand color, CTAs |
| Primary Dark | #XXXXXX | rgb(X, X, X) | Hover states, emphasis |
| Primary Light | #XXXXXX | rgb(X, X, X) | Backgrounds, highlights |

### Secondary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Secondary | #XXXXXX | rgb(X, X, X) | Supporting elements |
| Accent | #XXXXXX | rgb(X, X, X) | Highlights, badges |

### Neutral Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Foreground | #XXXXXX | rgb(X, X, X) | Primary text |
| Muted | #XXXXXX | rgb(X, X, X) | Secondary text |
| Background | #XXXXXX | rgb(X, X, X) | Page background |
| Card | #XXXXXX | rgb(X, X, X) | Card backgrounds |
| Border | #XXXXXX | rgb(X, X, X) | Borders, dividers |

### Semantic Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | #XXXXXX | Positive states, confirmations |
| Warning | #XXXXXX | Caution, attention needed |
| Destructive | #XXXXXX | Errors, delete actions |
| Info | #XXXXXX | Information, tips |

### Dark Mode Colors

[If applicable]

| Name | Light | Dark |
|------|-------|------|
| Background | #FFFFFF | #1A1A1A |
| Foreground | #1A1A1A | #FAFAFA |
| [etc.] | | |

---

## Typography

### Font Stack

**Primary Font:** [Font Name]
- Source: [Google Fonts / System / Custom]
- Weights: 400 (Regular), 500 (Medium), 600 (Semibold), 700 (Bold)

**Monospace Font:** [Font Name]
- Source: [Google Fonts / System]
- Usage: Code, IDs, technical values

### Type Scale

| Name | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Display | 2.5rem (40px) | Bold | 1.2 | Hero headlines |
| H1 | 2rem (32px) | Bold | 1.25 | Page titles |
| H2 | 1.5rem (24px) | Semibold | 1.3 | Section headers |
| H3 | 1.25rem (20px) | Semibold | 1.4 | Card titles |
| Body | 1rem (16px) | Regular | 1.5 | Default text |
| Small | 0.875rem (14px) | Regular | 1.5 | Secondary text |
| XS | 0.75rem (12px) | Regular | 1.5 | Captions, labels |

### Typography Guidelines

- Use sentence case for headings
- Maximum line length: 65-75 characters
- Paragraph spacing: 1.5em

---

## Spacing System

### Base Unit

Base: 4px (0.25rem)

### Spacing Scale

| Name | Value | Usage |
|------|-------|-------|
| xs | 4px (0.25rem) | Tight spacing |
| sm | 8px (0.5rem) | Small gaps |
| md | 16px (1rem) | Default spacing |
| lg | 24px (1.5rem) | Section spacing |
| xl | 32px (2rem) | Large sections |
| 2xl | 48px (3rem) | Page sections |

### Border Radius

| Name | Value | Usage |
|------|-------|-------|
| sm | 4px | Buttons, inputs |
| md | 8px | Cards |
| lg | 12px | Modals, large cards |
| full | 9999px | Pills, avatars |

---

## Component Patterns

### Buttons

**Primary Button:**
- Background: Primary color
- Text: White
- Padding: 12px 24px
- Border radius: sm
- Hover: Darken 10%

**Outline Button:**
- Background: Transparent
- Border: 1px solid border color
- Text: Foreground
- Hover: Subtle background

**Ghost Button:**
- Background: Transparent
- Text: Muted
- Hover: Subtle background

**Destructive Button:**
- Background: Destructive
- Text: White
- Use for: Delete actions

### Cards

- Background: Card color
- Border: 1px solid border color
- Border radius: md
- Padding: 24px
- Shadow: subtle or none

### Form Inputs

- Height: 40px
- Border: 1px solid border color
- Border radius: sm
- Padding: 0 12px
- Focus: Primary color ring

### Badges

**Variants:**
- Default (muted background)
- Success (green)
- Warning (yellow/orange)
- Destructive (red)
- Outline (border only)

### Empty States

- Centered layout
- Muted icon (48px)
- Title (semibold)
- Description (muted text)
- Optional CTA button

---

## Icon Strategy

### Primary Icon Set

**Library:** Lucide Icons (https://lucide.dev)
- Consistent with shadcn/ui ecosystem
- 24x24 default size
- 1.5px stroke width

### Common Icons

| Purpose | Icon Name |
|---------|-----------|
| Add | `plus` |
| Edit | `pencil` |
| Delete | `trash-2` |
| Settings | `settings` |
| User | `user` |
| Search | `search` |
| Close | `x` |
| Menu | `menu` |
| Check | `check` |
| Warning | `alert-triangle` |
| Info | `info` |
| [Domain-specific] | [icon] |

### Emoji Usage

[If applicable]

| Context | Emoji | Usage |
|---------|-------|-------|
| [Context 1] | 🎯 | [When to use] |
| [Context 2] | ✨ | [When to use] |

---

## Voice & Tone

### Voice Characteristics

1. **[Characteristic 1]** — Description
2. **[Characteristic 2]** — Description
3. **[Characteristic 3]** — Description

### Tone by Context

| Context | Tone | Example |
|---------|------|---------|
| Success | Celebratory | "Great job! You've..." |
| Error | Helpful | "Something went wrong. Try..." |
| Empty State | Encouraging | "Get started by..." |
| Onboarding | Warm | "Welcome! Let's..." |

### Writing Guidelines

**Do:**
- Use active voice
- Be concise
- Use simple words
- Address user directly ("you")

**Don't:**
- Use jargon
- Be condescending
- Use passive voice
- Use filler words

### Bilingual Examples

[If applicable - e.g., Spanish/English]

| Context | Spanish | English |
|---------|---------|---------|
| Welcome | "¡Bienvenido!" | "Welcome!" |
| Success | "¡Listo!" | "Done!" |
| Error | "Algo salió mal" | "Something went wrong" |
| Empty | "Aún no hay..." | "No... yet" |
| CTA | "Crear nuevo" | "Create new" |

---

## Tailwind CSS Configuration

### CSS Variables (Tailwind v4)

```css
@theme {
  /* Colors */
  --color-primary: #XXXXXX;
  --color-primary-dark: #XXXXXX;
  --color-primary-light: #XXXXXX;
  
  --color-secondary: #XXXXXX;
  --color-accent: #XXXXXX;
  
  --color-background: #XXXXXX;
  --color-foreground: #XXXXXX;
  --color-muted: #XXXXXX;
  --color-muted-foreground: #XXXXXX;
  --color-card: #XXXXXX;
  --color-border: #XXXXXX;
  
  --color-success: #XXXXXX;
  --color-success-foreground: #XXXXXX;
  --color-warning: #XXXXXX;
  --color-warning-foreground: #XXXXXX;
  --color-destructive: #XXXXXX;
  --color-destructive-foreground: #XXXXXX;
  
  /* Typography */
  --font-family-sans: "[Font Name]", system-ui, sans-serif;
  --font-family-mono: "[Mono Font]", monospace;
  
  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

### Dark Mode Variables

```css
@media (prefers-color-scheme: dark) {
  @theme {
    --color-background: #XXXXXX;
    --color-foreground: #XXXXXX;
    /* ... other dark mode overrides */
  }
}
```

---

## Assets Checklist

- [ ] Logo SVG (primary)
- [ ] Logo SVG (icon/mark)
- [ ] Favicon (favicon.ico, 32x32)
- [ ] Apple Touch Icon (180x180)
- [ ] Open Graph Image (1200x630)
- [ ] App Icon (512x512 for PWA)

---

## Quick Reference

### Primary Palette

| | Primary | Success | Warning | Destructive |
|-|---------|---------|---------|-------------|
| **Hex** | #XXXXXX | #XXXXXX | #XXXXXX | #XXXXXX |

### Type Scale

| Display | H1 | H2 | H3 | Body | Small |
|---------|----|----|----|----|-------|
| 40px | 32px | 24px | 20px | 16px | 14px |

### Spacing

| xs | sm | md | lg | xl |
|----|----|----|----|----|
| 4px | 8px | 16px | 24px | 32px |
