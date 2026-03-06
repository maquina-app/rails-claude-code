# CLAUDE.md

Documentation-only plugin marketplace — no build system, test suite, linter, or CI. All content is Markdown, JSON, and YAML.

## Plugin structure

```
.claude-plugin/marketplace.json         ← Lists all plugins
<plugin-name>/.claude-plugin/plugin.json ← Plugin metadata
<plugin-name>/agents/<plugin-name>.md    ← Main skill (Markdown + YAML frontmatter)
```

Supporting files go in `references/`, `workflows/`, `examples/`, `templates/` within each plugin directory.

## Critical rules

### Version sync
Versions must match in TWO places — update both or you'll create drift:
1. `.claude-plugin/marketplace.json` → `version` field for the plugin
2. `<plugin-name>/.claude-plugin/plugin.json` → `version` field

### Editing agent files
- Preserve YAML frontmatter structure in `agents/*.md` — breaking it breaks the skill
- Breaking changes in version guides → update both the version guide AND `reference/breaking-changes-by-version.md`
- Detection script patterns (`detection-scripts/patterns/*.yml`) → match existing YAML schema exactly
- Component additions to maquina-ui-standards → add to `references/component-catalog.md` with ERB examples and all variant options
