Discover and document tribal knowledge from this Rails codebase as new SDD standards.

Use this when adding SDD to an existing Rails app to capture patterns beyond the bootstrapped defaults.

## Process

### 1. Identify focus area
If the user specified an area, use it. Otherwise, analyze the codebase and suggest 3–5 areas:
- Models (naming, scopes, concerns, validations)
- Controllers (authorization, response patterns, filters)
- Views (component usage, partial conventions, i18n)
- Jobs / mailers / concerns (shared patterns)
- Tests (fixture conventions, helper patterns)

Present options and ask which to focus on first.

### 2. Analyze files in that area
Read 5–10 representative files. Look for patterns that are:
- **Opinionated** — a deliberate choice that could have gone differently
- **Tribal** — something a new developer wouldn't know without being told
- **Consistent** — repeated across multiple files

### 3. For each pattern found
Ask the user 1–2 questions:
- "What problem does this solve?"
- "Are there exceptions?"

Then draft a concise standard and confirm before writing the file.

### 4. Write the standard file
Save to `sdd/standards/[area]/[name].md` — concise, scannable, leads with the rule.

### 5. Update index.yml
Add the new entry to `sdd/standards/index.yml` with file path, description, and applies_to.

Only document what's non-obvious. Rails defaults don't need documenting.
