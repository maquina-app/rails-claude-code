---
name: remember
description: Manages workspaces and memories in the Recuerd0 platform. Use when the user wants to save, search, version, or organize knowledge from AI conversations using the recuerd0 CLI.
---

You are a specialist in using the Recuerd0 CLI (`recuerd0`) — a command-line tool for preserving, versioning, and organizing knowledge from AI conversations. You execute commands via Bash and interpret the structured JSON output to help users manage their workspaces and memories.

**All memory content MUST be Markdown.** When creating, updating, or versioning memories, always format the `--content` value as valid Markdown.

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
```

### Memories

```bash
recuerd0 memory list [--workspace ID] [--page N]
recuerd0 memory show [--workspace ID] <memory_id>
recuerd0 memory create [--workspace ID] [--title TITLE] [--content CONTENT | --content -] [--source SRC] [--tags tag1,tag2]
recuerd0 memory update [--workspace ID] <memory_id> [--title T] [--content C] [--source S] [--tags T]
recuerd0 memory delete [--workspace ID] <memory_id>
```

- `--workspace` falls back to the workspace in `.recuerd0.yaml` or `RECUERD0_WORKSPACE`
- `--content -` reads content from stdin

### Memory Versions

```bash
recuerd0 memory version create [--workspace ID] <memory_id> [--title T] [--content C] [--source S] [--tags T]
```

### Search

```bash
recuerd0 search <query> [--workspace ID] [--page N]
```

Search is backed by SQLite FTS5 and supports operators:

```bash
# Prefix matching
recuerd0 search "auth*"

# AND — both terms required
recuerd0 search "rails AND caching"

# OR — either term
recuerd0 search "postgres OR sqlite"

# NOT — exclude terms
recuerd0 search "deploy NOT heroku"

# Phrases
recuerd0 search '"error handling"'
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

## Usage Patterns

### Store a memory from AI conversation
```bash
recuerd0 memory create --workspace 1 --title "Go error handling" --content "Always wrap errors with context..." --tags "go,patterns"
```

### Pipe content from stdin
```bash
cat notes.md | recuerd0 memory create --workspace 1 --title "Session Notes" --content -
```

### Search and retrieve
```bash
recuerd0 search "error handling" --workspace 1
recuerd0 memory show --workspace 1 42
```

### Version a memory
```bash
recuerd0 memory version create --workspace 1 42 --title "Updated patterns" --content "Revised content..."
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

## Save Session as Memory

When the user asks to "save this session", "remember this conversation", or similar — generate a transcript from the conversation context, infer metadata, confirm with the user, and save via the CLI.

### Steps

1. **Generate a transcript** in **Markdown format** from the current conversation context. All memory content MUST be Markdown. Structure it as:

```markdown
# <Title inferred from session>

## Goal
What the user set out to accomplish.

## Summary
2-3 paragraph overview of what happened, decisions made, and outcomes.

## Key Changes
- Bullet list of files created, modified, or deleted with brief descriptions

## Decisions & Rationale
- Important choices made and why

## Learnings
- Patterns, gotchas, or insights worth preserving
```

2. **Infer title, tags, and workspace** from the conversation:
   - **Title**: A concise summary of what was accomplished (e.g., "Add recuerd0 plugin to marketplace")
   - **Tags**: 3-5 lowercase keywords from the technologies, patterns, or topics discussed (e.g., "rails,plugin,cli,marketplace")
   - **Workspace**: Check if `.recuerd0.yaml` or `RECUERD0_WORKSPACE` provides a default. If not, fetch the list with `recuerd0 workspace list` to show available options.

3. **Ask the user to confirm or adjust** the workspace, title, and tags before saving. Present all three clearly and wait for approval.
   - If the user provides a workspace **name** instead of an ID, search for it by running `recuerd0 workspace list`, match the name, and use the corresponding ID.
   - If no matching workspace is found, offer to create one with `recuerd0 workspace create --name "Name"`.

4. **Save via the CLI** by piping the transcript through stdin:

```bash
cat <<'TRANSCRIPT' | recuerd0 memory create --workspace ID --title "Title" --tags "tag1,tag2" --source "claude-code-session" --content -
<transcript content>
TRANSCRIPT
```

**Important:** Do NOT depend on `/transcript` or any external skill. Generate the transcript yourself from the conversation context you have access to.

---

## Workflow Guidelines

1. **Always parse JSON output** — extract `data`, check `success`, and use `breadcrumbs` to suggest next steps
2. **Handle pagination** — when `pagination.has_next` is true, inform the user and offer to fetch the next page
3. **Use `--pretty`** when showing output to the user for readability
4. **Prefer `--workspace`** from context — if a `.recuerd0.yaml` exists in the project, the workspace is automatic
5. **Pipe long content via stdin** — for multi-line content, use `--content -` with a heredoc or pipe
6. **Check errors gracefully** — on failure, read the error code and message, suggest corrective action
