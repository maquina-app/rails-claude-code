# Import Context Files as Memories

## Supported Files

Scan the current project for these context files (in priority order):

1. `CLAUDE.md` (root and nested like `src/CLAUDE.md`, `app/CLAUDE.md`)
2. `.claude/CLAUDE.md` and `.claude/settings.json`
3. `AGENTS.md` (root and nested)
4. `CURSORRULES` / `.cursorrules`
5. `COPILOT.md` / `.github/copilot-instructions.md`
6. `.windsurfrules`

## Workflow

1. **Scan** — use glob to locate context files. Report what was found.

2. **Analyze** — read each file, split into logical sections on `##` headers. Each major section is a candidate memory. Small files (under ~50 lines) become a single memory.

3. **Propose a memory plan** — present a table:

```
| # | Source File | Proposed Memory Title | Tags | Lines |
|---|-------------|-----------------------|------|-------|
| 1 | CLAUDE.md §Commands | Dev Commands & Scripts | commands,dev | 20 |
| 2 | CLAUDE.md §Architecture | Architecture Overview | architecture,design | 45 |
| 3 | .cursorrules | Cursor Rules & Conventions | conventions,editor | 30 |
```

4. **Check for duplicates** — before creating, search for similar titles:

```bash
recuerd0 search "title:Architecture Overview" --workspace ID
```

If a match exists, ask whether to **skip**, **create a new version**, or **replace**.

5. **Confirm with user** — let them select which memories to create (all, some, or none), adjust titles/tags/grouping, and choose the target workspace (check `.recuerd0.yaml` first).

6. **Create memories** — for each approved item, pipe content via stdin:

```bash
cat <<'MEMORY_CONTENT' | recuerd0 memory create --workspace ID --title "Title" --tags "tags" --source "import:filename" --content -
<section content>
MEMORY_CONTENT
```

Use `--source "import:<filename>"` so the user can later identify imported memories.

## Splitting Guidelines

- Split on `## ` (h2) headers as the primary boundary
- Keep closely related subsections (`###`) together under their parent `##`
- If a file has no headers, treat the entire file as one memory
- Strip meta-comments (`<!-- -->`) but preserve code blocks and examples
- Prefer multiple smaller memories over one giant one
- Use descriptive titles (e.g., "Rails Authentication Setup" not just "Authentication")

## Re-importing

When the user asks to re-import or sync, compare file modification times against the `--source` tag on existing memories. Propose new versions only for files that have changed.
