# CLAUDE.md

Documentation-only plugin marketplace — no build system, test suite, linter, or CI. All content is Markdown, JSON, and YAML.

## Plugin structure

```
.claude-plugin/marketplace.json          ← Lists all plugins
<plugin-name>/.claude-plugin/plugin.json ← Plugin metadata
<plugin-name>/agents/<plugin-name>.md    ← Capability as a single-file agent (most plugins)
<plugin-name>/skills/<name>/SKILL.md     ← Capability as a skill bundle (+ scripts/) — e.g. rails-hotwire-driver
```

Supporting files go in `references/`, `workflows/`, `examples/`, `templates/` within each plugin directory; a skill's helper scripts go in `skills/<name>/scripts/` (keep `.sh` files executable — `git ls-files -s` should show mode `100755`).

A capability can ship as either a single-file `agents/*.md` (the common convention here) or a `skills/<name>/SKILL.md` bundle. Both are valid.

## Critical rules

### Validate before committing
This repo has no traditional test suite, but `claude plugin validate <plugin-dir>` (and `claude plugin validate .` for the marketplace) IS the check — run it after any manifest/frontmatter change. Add `--strict` to catch unrecognized fields, missing metadata, and version mismatches. Bump a plugin's `version` whenever its content changes, or installed users won't receive the update (an unset version falls back to the git SHA).

### Version sync
Versions must match in THREE places — update all or you'll create drift:
1. `.claude-plugin/marketplace.json` → `version` field for the plugin
2. `<plugin-name>/.claude-plugin/plugin.json` → `version` field
3. The root `README.md` Plugins table version column (and confirm the install/`enabledPlugins` blocks list the plugin)

### Install commands
The marketplace `name` is `maquina`, so install commands use the `@maquina` suffix (`/plugin install <plugin>@maquina`) — NOT `@rails`. The marketplace is added with the GitHub owner/repo: `/plugin marketplace add maquina-app/rails-claude-code` (owner is `maquina-app`, matching the git remote — not `maquina`). Keep these consistent across the root README and any per-plugin docs.

### Editing agent files
- Preserve YAML frontmatter structure in `agents/*.md` — breaking it breaks the skill
- Don't "fix" valid frontmatter: `name:` is the invocation/skill name and intentionally differs from the plugin/dir name (e.g. `simplify`, `ui`, `audit-security`); `effort` (`low`/`medium`/`high`) and `model` aliases (`sonnet`/`opus`) are valid fields — leave them
- Hook `timeout` (e.g. `recuerd0/hooks/hooks.json`) is in SECONDS; quote plugin-root paths in hook commands: `bash "${CLAUDE_PLUGIN_ROOT}/..."`
- Breaking changes in version guides → update both the version guide AND `reference/breaking-changes-by-version.md`
- Detection script patterns (`detection-scripts/patterns/*.yml`) → match existing YAML schema exactly
- Component additions to maquina-ui-standards → add to `references/component-catalog.md` with ERB examples and all variant options
