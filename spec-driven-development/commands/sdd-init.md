Initialize Spec-Driven Development for this Rails project.

Run the bootstrap script shipped with the spec-driven-development plugin:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init_sdd.sh
```

(If `$CLAUDE_PLUGIN_ROOT` is not set, locate `init_sdd.sh` inside the installed `spec-driven-development` plugin directory and run it from the project root.)

This creates the `sdd/` directory structure with:
- Pre-built Rails standards files (global, backend, frontend, testing)
- `sdd/standards/index.yml` catalog
- `sdd/progress.yml` tracker

The `/sdd-*` slash commands are provided by the plugin itself — no per-project install needed.

After running, confirm the structure was created and suggest running `/sdd-plan` next.
