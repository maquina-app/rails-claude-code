# Memory Templates

Use these templates when the user asks to "document this feature", "analyze the auth system", "create a memory for the API", or similar. Read the relevant source code, analyze it, and produce a well-structured memory.

## Workflow

1. **Identify scope** — ask clarifying questions if ambiguous.
2. **Read source code** — explore models, controllers, views, routes, tests, and migrations.
3. **Select template** — match the request to the table below.
4. **Draft the memory** — be specific: include actual method names, file paths, column names, and code snippets.
5. **Check for duplicates** — search recuerd0 for existing memories on the same topic. Offer to create a new version if one exists.
6. **Present for review** — show draft with proposed title, tags, and workspace. Let the user adjust before saving.
7. **Save** — pipe via stdin with `--source "analysis:feature-name"`.

## Template Selection

| User says... | Template | Suggested tags |
|-------------|----------|----------------|
| "document the auth system", "explain how X works" | Feature Guide | `feature,guide,<domain>` |
| "why did we choose SQLite?", "document the decision to..." | Architecture Decision | `architecture,decision,<domain>` |
| "document the API", "API reference for memories" | API Endpoint Reference | `api,endpoints,<resource>` |
| "document our coding patterns", "our Rails conventions" | Coding Conventions | `conventions,patterns,<domain>` |
| "how to debug search issues", "common errors in..." | Debugging & Troubleshooting | `debugging,troubleshooting,<domain>` |
| "getting started guide", "onboarding doc for..." | Onboarding Guide | `onboarding,setup,guide` |

When in doubt, ask the user which template fits best.

## Template Structures

Each template follows a standard pattern. Use the sections below as guidance — adapt structure and depth to the actual content rather than forcing rigid compliance.

### Architecture Decision

Sections: Context → Decision (with code references) → Alternatives Considered → Consequences → Key Files table.

### Feature Guide

Sections: Overview → Data Model (tables, associations) → How It Works (core logic, controller actions, key methods) → Edge Cases & Constraints → Key Files table.

### API Endpoint Reference

Sections: Authentication → Endpoints (method, path, params, request/response examples) → Error Codes → Notes (pagination, rate limits).

### Coding Conventions

Sections: Overview → Rules (each with Do/Don't code examples and Why) → Gotchas → References.

### Debugging & Troubleshooting

Sections: Common Issues (each with Symptom/Cause/Fix) → Diagnostic Commands → Logs & Error Messages table.

### Onboarding Guide

Sections: Prerequisites → Setup → Project Structure (directory tree) → Development Workflow → Key Concepts → Where to Find Things table.
