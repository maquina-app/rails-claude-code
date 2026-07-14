# recuerd0 CLI Reference

Command catalog, output format, flags, and mechanics for the `recuerd0` CLI. The decision logic (when to capture, dedup, routing, linking) lives in `../SKILL.md`; this file is the lookup layer — read it when you need an exact command or flag.

---

## Output Format

All commands output structured JSON:

```json
{
  "success": true,
  "data": { ... },
  "pagination": { "has_next": true, "next_url": "..." },
  "breadcrumbs": [
    { "action": "show", "cmd": "recuerd0 memory show --workspace 1 42", "description": "View memory" }
  ],
  "summary": "5 memory(ies)",
  "meta": { "timestamp": "2026-02-06T..." }
}
```

Errors:

```json
{
  "success": false,
  "error": { "code": "NOT_FOUND", "message": "...", "status": 404 }
}
```

**Always use `--pretty` when displaying output to the user** for readability.

---

## Commands

### Account Management

```bash
recuerd0 account add <name> --token TOKEN [--api-url URL]
recuerd0 account list
recuerd0 account select <name>
recuerd0 account remove <name>
```

### Workspaces

```bash
recuerd0 workspace list [--page N]
recuerd0 workspace show <id>
recuerd0 workspace create --name NAME [--description DESC]
recuerd0 workspace update <id> [--name NAME] [--description DESC]
recuerd0 workspace archive <id>
recuerd0 workspace unarchive <id>
recuerd0 workspace context <id> [--limit N] [--no-body] [--max-body-chars N]
```

### Memories

```bash
recuerd0 memory list [--workspace ID] [--page N] [--category CAT]
recuerd0 memory show [--workspace ID] <memory_id>
recuerd0 memory create [--workspace ID] [--title TITLE] [--content CONTENT | --content -] [--source SRC] [--tags tag1,tag2] [--category CAT]
recuerd0 memory update [--workspace ID] <memory_id> [--title T] [--content C | --content -] [--source S] [--tags T] [--category CAT]
recuerd0 memory delete [--workspace ID] <memory_id>
recuerd0 memory link list <memory_id> [--workspace ID]
recuerd0 memory link add <memory_id> --to <other_memory_id> [--workspace ID]
recuerd0 memory link remove <memory_id> --to <other_memory_id> [--workspace ID]
```

#### Memory content reading

```bash
recuerd0 memory read head <memory_id> --lines N                                  # First N lines of a memory's content
recuerd0 memory read tail <memory_id> --lines N                                  # Last N lines of a memory's content
recuerd0 memory read lines <memory_id> --start S --end E                         # A specific line window [S, E]
recuerd0 memory read grep <memory_id> <pattern> [--context N] [--before N] [--after N]  # Search inside a memory; returns matching lines with line numbers and surrounding context
```

- `--workspace` falls back to the workspace in `.recuerd0.yaml` or `RECUERD0_WORKSPACE`
- `--content -` reads content from stdin (supported in create, update, and version create)

### Memory Versions

```bash
recuerd0 memory version create [--workspace ID] <memory_id> [--title T] [--content C | --content -] [--source S] [--tags T] [--category CAT]
```

### Search

```bash
recuerd0 search <query> [--workspace ID] [--page N] [--category CAT]
```

Search is backed by SQLite FTS5 and supports operators:

```bash
recuerd0 search "auth*"                    # prefix matching
recuerd0 search "rails AND caching"        # both terms required
recuerd0 search "postgres OR sqlite"       # either term
recuerd0 search "deploy NOT heroku"        # exclude terms
recuerd0 search '"error handling"'         # phrase
recuerd0 search "title:authentication"     # field-specific
recuerd0 search "body:caching"
```

### Version

```bash
recuerd0 version
```

---

## Global Flags

| Flag | Description |
|------|-------------|
| `--account` | Account name to use |
| `--token` | API token override |
| `--api-url` | API URL override |
| `--workspace` | Workspace ID override |
| `--verbose` | Show HTTP request/response details |
| `--pretty` | Pretty-print JSON output |

---

## Breadcrumbs

Every response includes `breadcrumbs` — suggested next actions as CLI commands. Use these to discover workflows and suggest follow-up actions to the user:

```json
"breadcrumbs": [
  { "action": "show", "cmd": "recuerd0 workspace show 1", "description": "View workspace details" },
  { "action": "create", "cmd": "recuerd0 memory create --workspace 1 --title TITLE", "description": "Create a memory" }
]
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Authentication failure |
| 4 | Forbidden |
| 5 | Not found |
| 6 | Validation error |
| 7 | Network error |
| 8 | Rate limited |

---

## Usage Patterns

**Store a memory from an AI conversation:**

```bash
recuerd0 memory create --workspace 1 --title "Go error handling" --content "Always wrap errors with context..." --tags "go,patterns"
```

**Pipe content from stdin:**

```bash
cat notes.md | recuerd0 memory create --workspace 1 --title "Session Notes" --content -
```

**Search and retrieve:**

```bash
recuerd0 search "error handling" --workspace 1
recuerd0 memory show --workspace 1 42
```

**Version a memory:**

```bash
recuerd0 memory version create --workspace 1 42 --title "Updated patterns" --content "Revised content..."
```

### Reading large memories efficiently

For long memories (transcripts, long docs, anything past a screenful), don't load the whole body. Grep first to locate the relevant region, then fetch only that window — this keeps responses small and avoids pulling the entire body into context.

```bash
recuerd0 memory read grep 42 "TODO" --context 2 --pretty    # → notice match at line 47
recuerd0 memory read lines 42 --start 40 --end 55 --pretty   # fetch just that window
recuerd0 memory read tail 42 --lines 30 --pretty             # peek at the end of a long transcript
```

Reserve `memory show` for cases where you genuinely need the whole body.

---

## CLI Mechanics

- **Parse the JSON** — extract `data`, check `success`, use `breadcrumbs` to discover follow-up actions.
- **Handle pagination** — when `pagination.has_next` is true, fetch the next page or inform the user.
- **Prefer `--workspace` from context** — let the CLI resolve from `.recuerd0.yaml` when present.
- **Pipe long content via stdin** — use `--content -` with a heredoc or pipe for multi-line content.
- **Handle errors gracefully** — on failure, read the error code and message and suggest corrective action.
- **Read large memories in windows** — `memory read grep` to find the region, then `memory read lines` for the window (see above).
