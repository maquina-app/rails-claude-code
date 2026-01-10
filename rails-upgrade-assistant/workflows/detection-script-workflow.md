# Detection Script Workflow

**Purpose:** Generate executable bash scripts that find breaking changes in user's codebase

**When to use:** Every upgrade request OR when user specifically asks for detection script

---

## Prerequisites

- Target Rails version (e.g., "8.1", "7.2", "8.0")
- Pattern file available for target version
- Script template available

---

## Step-by-Step Workflow

### Step 1: Determine Target Version

Map target Rails version to pattern file:

```
Rails 7.2 → detection-scripts/patterns/rails-72-patterns.yml
Rails 8.0 → detection-scripts/patterns/rails-80-patterns.yml
Rails 8.1 → detection-scripts/patterns/rails-81-patterns.yml
```

---

### Step 2: Load Pattern File

Read the YAML pattern file:

```
railsMcpServer:get_file("detection-scripts/patterns/rails-{VERSION}-patterns.yml")
```

**Pattern File Structure:**
```yaml
version: "8.1"
description: "Breaking change patterns for Rails 8.0 → 8.1"

breaking_changes:
  high_priority:
    - name: "Pattern name"
      pattern: 'regex'
      exclude: "exclusion"
      search_paths:
        - "path/to/search"
      explanation: "What this means"
      fix: "How to fix it"
      variable_name: "BASH_VAR"
  
  medium_priority:
    - name: "Another pattern"
      # ... same structure
```

---

### Step 3: Load Script Template

Read the bash script template:

```
railsMcpServer:get_file("detection-scripts/templates/detection-script-template.sh")
```

**Template Placeholders:**
- `{VERSION}` - Full version (e.g., "8.1.1")
- `{VERSION_SLUG}` - Slugified (e.g., "81")
- `{VERSION_SHORT}` - Short (e.g., "8.1")
- `{HIGH_PRIORITY_CHECKS}` - Generated bash code
- `{MEDIUM_PRIORITY_CHECKS}` - Generated bash code
- `{TOTAL_CALCULATION}` - Sum calculation
- `{ISSUE_SUMMARY}` - List of issues
- `{FILE_LIST_GENERATION}` - File collection code

---

### Step 4: Generate Check Blocks

For each pattern in YAML, generate bash code:

**Input Pattern:**
```yaml
- name: "SSL configuration changes"
  pattern: 'force_ssl\s*=\s*true'
  exclude: "assume_ssl"
  search_paths:
    - "config/environments/production.rb"
  explanation: "Rails 8.1 changes SSL handling"
  fix: "Add config.assume_ssl = true alongside force_ssl"
  variable_name: "SSL_CONFIG"
```

**Generated Bash Check Block:**
```bash
echo "🔍 Checking: SSL configuration changes" | tee -a "$OUTPUT_FILE"
echo "   Rails 8.1 changes SSL handling" | tee -a "$OUTPUT_FILE"

SSL_CONFIG_RESULTS=$(grep -r 'force_ssl\s*=\s*true' config/environments/production.rb | grep -v 'assume_ssl' | grep -v '#' | wc -l | tr -d ' ')
SSL_CONFIG_FILES=$(grep -rl 'force_ssl\s*=\s*true' config/environments/production.rb | grep -v 'assume_ssl')

check_results $SSL_CONFIG_RESULTS "SSL configuration changes"

if [ "$SSL_CONFIG_RESULTS" -gt 0 ]; then
  echo "" | tee -a "$OUTPUT_FILE"
  echo "   Files affected:" | tee -a "$OUTPUT_FILE"
  echo "$SSL_CONFIG_FILES" | sed 's/^/   - /' | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"
  echo "   Fix: Add config.assume_ssl = true alongside force_ssl" | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"
fi
```

**Generation Template:**
```bash
echo "🔍 Checking: {name}" | tee -a "$OUTPUT_FILE"
echo "   {explanation}" | tee -a "$OUTPUT_FILE"

{VARIABLE_NAME}_RESULTS=$(grep -r '{pattern}' {search_paths} | grep -v '{exclude}' | grep -v '#' | wc -l | tr -d ' ')
{VARIABLE_NAME}_FILES=$(grep -rl '{pattern}' {search_paths} | grep -v '{exclude}')

check_results ${VARIABLE_NAME}_RESULTS "{name}"

if [ "${VARIABLE_NAME}_RESULTS" -gt 0 ]; then
  echo "" | tee -a "$OUTPUT_FILE"
  echo "   Files affected:" | tee -a "$OUTPUT_FILE"
  echo "${{VARIABLE_NAME}_FILES}" | sed 's/^/   - /' | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"
  echo "   Fix: {fix}" | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"
fi
```

---

### Step 5: Generate HIGH Priority Checks

Process all `high_priority` patterns:

```
For each pattern in breaking_changes.high_priority:
  1. Extract: name, pattern, exclude, search_paths, explanation, fix, variable_name
  2. Generate check block using template above
  3. Append to HIGH_PRIORITY_CHECKS variable
```

**Example Result:**
```bash
# All HIGH priority check blocks concatenated
echo "🔍 Checking: SSL configuration changes" | tee -a "$OUTPUT_FILE"
...

echo "🔍 Checking: bundler-audit integration" | tee -a "$OUTPUT_FILE"
...
```

---

### Step 6: Generate MEDIUM Priority Checks

Process all `medium_priority` patterns:

```
For each pattern in breaking_changes.medium_priority:
  1. Extract: name, pattern, exclude, search_paths, explanation, fix, variable_name
  2. Generate check block using template above
  3. Append to MEDIUM_PRIORITY_CHECKS variable
```

---

### Step 7: Generate Total Calculation

Create bash code to sum all findings:

```bash
TOTAL_ISSUES=0

# Add all HIGH priority results
TOTAL_ISSUES=$((TOTAL_ISSUES + SSL_CONFIG_RESULTS))
TOTAL_ISSUES=$((TOTAL_ISSUES + BUNDLER_AUDIT_RESULTS))

# Add all MEDIUM priority results
TOTAL_ISSUES=$((TOTAL_ISSUES + CACHE_CONFIG_RESULTS))

echo "Total issues found: $TOTAL_ISSUES"
```

---

### Step 8: Generate Issue Summary

Create bash code to list each issue found:

```bash
if [ "$SSL_CONFIG_RESULTS" -gt 0 ]; then
  echo "   - SSL configuration: $SSL_CONFIG_RESULTS occurrence(s)" | tee -a "$OUTPUT_FILE"
fi

if [ "$BUNDLER_AUDIT_RESULTS" -gt 0 ]; then
  echo "   - bundler-audit: $BUNDLER_AUDIT_RESULTS occurrence(s)" | tee -a "$OUTPUT_FILE"
fi

if [ "$CACHE_CONFIG_RESULTS" -gt 0 ]; then
  echo "   - Cache configuration: $CACHE_CONFIG_RESULTS occurrence(s)" | tee -a "$OUTPUT_FILE"
fi
```

---

### Step 9: Generate File List Collection

Create bash code to collect all affected files:

```bash
ALL_FILES=""

# Collect from all check results
for file in $SSL_CONFIG_FILES $BUNDLER_AUDIT_FILES $CACHE_CONFIG_FILES; do
  if [ -f "$file" ]; then
    ALL_FILES="$ALL_FILES $file"
  fi
done

if [ -n "$ALL_FILES" ]; then
  echo "$ALL_FILES" | tr ' ' '\n' | sort -u | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"
  echo "Neovim command:" | tee -a "$OUTPUT_FILE"
  echo "nvim $ALL_FILES" | tee -a "$OUTPUT_FILE"
fi
```

---

### Step 10: Populate Template

Replace all placeholders in script template:

| Placeholder | Replacement | Example |
|-------------|-------------|---------|
| `{VERSION}` | Full target version | "8.1.1" |
| `{VERSION_SLUG}` | Slugified version | "81" |
| `{VERSION_SHORT}` | Short version | "8.1" |
| `{HIGH_PRIORITY_CHECKS}` | All high check blocks | (generated code) |
| `{MEDIUM_PRIORITY_CHECKS}` | All medium check blocks | (generated code) |
| `{TOTAL_CALCULATION}` | Sum calculation code | (generated code) |
| `{ISSUE_SUMMARY}` | Issue listing code | (generated code) |
| `{FILE_LIST_GENERATION}` | File collection code | (generated code) |

---

### Step 11: Validate Script

Before delivering, check:

- [ ] All variable names are uppercase
- [ ] All variable names are unique
- [ ] No spaces in variable names
- [ ] All quotes properly escaped
- [ ] All grep patterns valid
- [ ] Script starts with `#!/bin/bash`
- [ ] All placeholders replaced

---

### Step 12: Deliver Script

Present the complete bash script with instructions:

```markdown
# Breaking Changes Detection Script for Rails {VERSION}

Run this script in your Rails project root to find breaking changes:

\```bash
chmod +x detect_rails_{VERSION_SLUG}_changes.sh
./detect_rails_{VERSION_SLUG}_changes.sh
\```

## What This Script Does

1. ✅ Searches for all breaking change patterns
2. ✅ Shows file:line references for each issue
3. ✅ Generates a findings report (TXT file)
4. ✅ Lists affected files for Neovim
5. ✅ Provides fix instructions for each issue
6. ✅ Completes in < 30 seconds

## Script Contents

\```bash
#!/bin/bash

# Rails {VERSION} Upgrade Detection Script
# Generated by Rails Upgrade Assistant

[COMPLETE GENERATED SCRIPT HERE]
\```

## Expected Output

After running, you'll get:

- `rails_{VERSION_SLUG}_upgrade_findings.txt` - Full report with findings
- Console output with color-coded results
- List of affected files
- Neovim command to open all files

## If Issues Found

Share the `rails_{VERSION_SLUG}_upgrade_findings.txt` file with me for interactive help fixing each issue!
```

---

## Pattern Processing Reference

### YAML Field Meanings

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Human-readable check name | "SSL configuration changes" |
| `pattern` | Regex to search for | `'force_ssl\s*=\s*true'` |
| `exclude` | Exclude false positives | `"assume_ssl"` |
| `search_paths` | Where to search | `["config/environments/"]` |
| `explanation` | Why this is breaking | "Rails 8.1 changes SSL handling" |
| `fix` | How to fix it | "Add config.assume_ssl = true" |
| `variable_name` | Bash variable name | "SSL_CONFIG" |

### Variable Naming Rules

- **Must be:** UPPERCASE
- **No:** Spaces, hyphens, or special chars
- **Format:** `DESCRIPTIVE_NAME` 
- **Example:** `SSL_CONFIG`, `BUNDLER_AUDIT`, `CACHE_CONFIG`

---

## Common Issues

### Issue: Syntax Errors in Generated Script

**Cause:** Special characters not escaped

**Fix:**
```bash
# Bad
pattern: 'config.force_ssl = true'

# Good  
pattern: 'config\.force_ssl\s*=\s*true'
```

### Issue: Empty Check Blocks

**Cause:** Pattern file not loaded

**Fix:**
```
Verify pattern file exists and is valid YAML
Check file path matches version number
```

### Issue: Duplicate Variable Names

**Cause:** Multiple patterns using same variable_name

**Fix:**
```yaml
# Each pattern needs unique variable_name
- variable_name: "SSL_CONFIG_1"
- variable_name: "SSL_CONFIG_2"
```

---

## Script Output Format

The generated script produces:

**Console Output:**
```
================================================
Rails 8.1 Upgrade - Breaking Changes Detection
Project: my-rails-app
Date: November 2, 2025
================================================

🔴 HIGH PRIORITY - BREAKING CHANGES
===================================

🔍 Checking: SSL configuration changes
   Rails 8.1 changes SSL handling
   ⚠️  Found: 1 occurrences

   Files affected:
   - config/environments/production.rb

   Fix: Add config.assume_ssl = true alongside force_ssl

...

📊 SUMMARY
==========

⚠️  Found 3 breaking change(s) that need fixing:
   - SSL configuration: 1 occurrence(s)
   - bundler-audit: 2 occurrence(s)
   - Cache configuration: 1 occurrence(s)

📋 AFFECTED FILES (for Neovim)
==============================

config/environments/production.rb
Gemfile
config/environments/development.rb

Neovim command:
nvim config/environments/production.rb Gemfile config/environments/development.rb
```

**TXT File Output:**
Same content saved to `rails_81_upgrade_findings.txt`

---

**Related Files:**
- Template: `detection-scripts/templates/detection-script-template.sh`
- Patterns: `detection-scripts/patterns/rails-{VERSION}-patterns.yml`
- Guide: `reference/pattern-file-guide.md`
- Examples: `examples/detection-script-only.md`
