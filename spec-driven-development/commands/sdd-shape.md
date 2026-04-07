Shape a feature spec for this Rails project using the spec-driven-development skill.

## Process

### 1. Create the spec folder
Create `sdd/specs/YYYY-MM-DD-[feature-name]/` using today's date and a descriptive kebab-case name.

### 2. Ask focused discovery questions (4–6 max)
- What is the user trying to accomplish? What is the happy path?
- Are there edge cases that need handling in v1?
- What does success look like? (redirect destination, flash message, UI change)
- Are there existing models, controllers, or views to reuse or extend?

### 3. Search the codebase for existing patterns
Before writing anything, search for related code:
```
grep -r "class.*ApplicationRecord" app/models/
ls app/controllers/
find app/views -name "*.html.erb" | head -30
```
Write findings to `sdd/specs/[folder]/references.md`.

### 4. Check for visuals
Ask if mockups or wireframes exist. If none and the feature has meaningful UI, use the `frontend-design` skill to create an HTML mockup.

### 5. Inject relevant standards
Read `sdd/standards/index.yml`. Based on what the feature touches, present the applicable standards to the user for confirmation. Then write the **full file content** of each confirmed standard into `sdd/specs/[folder]/standards.md`.

### 6. Write spec.md
Create `sdd/specs/[folder]/spec.md` with:
- **Goal** — one sentence
- **User Stories** — As a [user], I want [action] so that [outcome]
- **Requirements** — functional only, no implementation details
- **Visual Design** — mockup link or layout description
- **Out of Scope** — explicitly what is NOT in v1

Update `sdd/progress.yml` when complete. Suggest running /sdd-tasks next.
