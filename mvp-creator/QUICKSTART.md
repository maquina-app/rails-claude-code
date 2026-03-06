# Quick Start: mvp-creator

## When to Use

Starting a new Rails app from an idea.

## Basic Workflow

```
1. Describe your app idea
2. Claude researches competitors (2-5)
3. Answer discovery questions
4. Generate 5 deliverables sequentially
5. (Optional) Create pitch materials
```

## Deliverables

| # | Document | Purpose |
|---|----------|---------|
| 1 | `RESEARCH_REPORT.md` | Competitor analysis |
| 2 | `MVP_BUSINESS_PLAN.md` | Vision, features, flows |
| 3 | `BRAND_GUIDE.md` | Logo, colors, typography |
| 4 | `TECHNICAL_GUIDE.md` | Architecture, models |
| 5 | `CLAUDE.md` | Project setup for Claude |

## Output Structure

```
your-app/
├── docs/
│   ├── RESEARCH_REPORT.md
│   ├── MVP_BUSINESS_PLAN.md
│   ├── BRAND_GUIDE.md
│   ├── TECHNICAL_GUIDE.md
│   └── assets/
│       └── logo.svg
├── CLAUDE.md
├── .mcp.json
└── .claude/commands/
```

## Discovery Questions (Be Ready For)

**Core:**
- App name and meaning
- Primary language/locale
- Target region
- Core differentiator
- Primary user persona

**Features:**
- Main app sections
- Critical UX flow
- Key data entities

**Brand:**
- Personality (playful/professional)
- Color preferences
- Logo concepts

## Tech Stack (Fixed)

- Rails 8 + Hotwire
- Tailwind CSS 4
- maquina_components
- SQLite/PostgreSQL
- Solid Queue (no Redis)
- Minitest + Fixtures

## Trigger Phrases

- "Help me plan an MVP for..."
- "Create a business plan for..."
- "Research competitors for..."
- "Design a brand for my app"
- "Set up Claude for my Rails project"

## Next Steps

After MVP docs are complete:
- Use `startup-pitch-creator` for investor deck
- Use `spec-driven-development` to build features
