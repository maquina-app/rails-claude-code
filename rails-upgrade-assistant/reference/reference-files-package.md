# Reference Files Package

This file contains three reference documents.

---

# 1. Pattern File Guide

## Purpose
Pattern files define breaking change patterns to search for in user code.

## Location
`detection-scripts/patterns/rails-{VERSION}-patterns.yml`

## Structure
```yaml
version: "8.1"
description: "Breaking change patterns for Rails 8.0 → 8.1"

breaking_changes:
  high_priority:
    - name: "Human-readable name"
      pattern: 'regex_pattern'
      exclude: "exclusion_pattern"
      search_paths:
        - "directory/to/search"
      explanation: "What this means"
      fix: "How to fix it"
      variable_name: "BASH_VAR_NAME"
```

## Field Meanings

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Check description | "SSL configuration changes" |
| `pattern` | Regex to search | `'force_ssl\s*=\s*true'` |
| `exclude` | Exclude pattern | `"assume_ssl"` |
| `search_paths` | Directories | `["config/environments/"]` |
| `explanation` | Why breaking | "Rails 8.1 changes SSL" |
| `fix` | How to fix | "Add assume_ssl" |
| `variable_name` | Bash variable | "SSL_CONFIG" |

## Variable Naming Rules

- Must be UPPERCASE
- No spaces or special chars
- Format: `DESCRIPTIVE_NAME`
- Must be unique within file

---

# 2. Quality Checklist

## Before Delivering ANY Output

### Upgrade Report Checklist

- [ ] All {PLACEHOLDERS} replaced
- [ ] Breaking changes have OLD vs NEW code
- [ ] Used user's actual code (not generic)
- [ ] Custom code flagged with ⚠️
- [ ] Step-by-step migration guide included
- [ ] Testing checklist included
- [ ] Rollback plan included
- [ ] Resources section completed

### Detection Script Checklist

- [ ] All patterns from YAML processed
- [ ] Check blocks generated for each
- [ ] Variable names unique and valid
- [ ] File list generation included
- [ ] Total calculation included
- [ ] Script starts with #!/bin/bash
- [ ] All placeholders replaced
- [ ] No syntax errors

### app:update Preview Checklist

- [ ] User's actual config files read
- [ ] OLD vs NEW diffs shown
- [ ] New files listed (if any)
- [ ] Neovim file list generated
- [ ] Impact levels assigned
- [ ] Custom warnings included
- [ ] All files accounted for

### Overall Delivery Checklist

- [ ] Generated requested deliverables
- [ ] Sequential path explained (if multi-hop)
- [ ] Next steps clearly outlined
- [ ] Offer interactive help (if Neovim available)
- [ ] No generic code examples
- [ ] Quality verified

---

# 3. Troubleshooting Guide

## Common Issues & Solutions

### Issue 1: Pattern file not found

**Symptom:** Can't read `rails-XX-patterns.yml`

**Cause:** Invalid version number or file doesn't exist

**Solution:**
- Verify version: 72, 80, or 81
- Check file exists: `detection-scripts/patterns/rails-{VERSION}-patterns.yml`
- Use existing patterns as reference for other versions

---

### Issue 2: Empty detection script

**Symptom:** Script has no checks, just skeleton

**Cause:** Pattern file not loaded or processing failed

**Solution:**
- Verify pattern file loaded successfully
- Check YAML is valid
- Ensure {HIGH_PRIORITY_CHECKS} placeholder was replaced
- Review workflow: `workflows/detection-script-workflow.md`

---

### Issue 3: Generic config diffs

**Symptom:** OLD code shows generic examples, not user's actual code

**Cause:** Didn't read user's actual files

**Solution:**
- Must call: `railsMcpServer:get_file("config/application.rb")`
- Must call: `railsMcpServer:get_file("config/environments/production.rb")`
- Extract their actual code
- Show THEIR code in OLD section, not generic

---

### Issue 4: Script syntax errors

**Symptom:** Generated bash script has errors when run

**Cause:** Special characters not escaped or invalid variable names

**Solution:**
- Check variable names (UPPERCASE, no spaces)
- Verify all quotes escaped properly
- Test grep patterns are valid regex
- Ensure all template sections replaced
- Check for: `\`, `"`, `$` that need escaping

---

### Issue 5: Missing custom code warnings

**Symptom:** No ⚠️ warnings in report

**Cause:** Didn't scan for custom code

**Solution:**
- Search pattern: `"use "` in config files (middleware)
- Search pattern: `"Redis.new"` (manual Redis)
- List: `config/initializers/` (custom initializers)
- Check: `config.api_only` (API-only patterns)
- Flag everything found with ⚠️

---

### Issue 6: Wrong deliverables generated

**Symptom:** Generated all 3 when user asked for specific one

**Cause:** Didn't check user's specific request

**Solution:**
- If user says "detection script": Generate ONLY script
- If user says "preview": Generate ONLY preview
- If user says "upgrade": Generate ALL THREE
- Read request carefully

---

### Issue 7: Multi-hop not explained

**Symptom:** Generated single report for multi-version jump

**Cause:** Didn't check for version skipping

**Solution:**
- Check if FROM → TO skips versions
- Example: 7.0 → 8.0 skips 7.1 and 7.2
- Must explain sequential requirement
- Reference: `examples/multi-hop-upgrade.md`

---

### Issue 8: Can't access MCP tools

**Symptom:** MCP tool calls fail

**Cause:** Tool not available or project not connected

**Solution:**
- Verify Rails MCP server connected
- Check project switched correctly
- Ensure files exist at specified paths
- Read error message for details

---

### Issue 9: Placeholders still in output

**Symptom:** Final output contains {PLACEHOLDER} text

**Cause:** Forgot to replace template variables

**Solution:**
- Review all {PLACEHOLDERS} in template
- Replace EVERY ONE with actual value
- Search output for `{` and `}` characters
- If can't determine value, use "Unknown" or similar

---

### Issue 10: Report too generic

**Symptom:** Report doesn't feel personalized to user's project

**Cause:** Used generic examples instead of user's actual code

**Solution:**
- Always read user's actual files
- Extract their specific code
- Show THEIR custom configurations
- Reference THEIR project structure
- Use THEIR gem names
- Make it feel like it was written for their exact project

---

## Getting Help

If issue not listed:
1. Review relevant workflow in `workflows/`
2. Check example in `examples/`
3. Verify pattern file structure
4. Re-read SKILL.md instructions

---

**End of Reference Files Package**
