# Rails Upgrade Report: {FROM_VERSION} → {TO_VERSION}

**Project:** {PROJECT_NAME}
**Date:** {GENERATION_DATE}

---

## Summary

| Field | Value |
|-------|-------|
| **Current Version** | Rails {FROM_VERSION} |
| **Target Version** | Rails {TO_VERSION} |
| **Difficulty** | {DIFFICULTY_RATING} |
| **Breaking Changes** | {BREAKING_CHANGES_COUNT} ({HIGH_COUNT} high, {MEDIUM_COUNT} medium, {LOW_COUNT} low) |
| **Custom Code Warnings** | {CUSTOM_WARNINGS_COUNT} |
| **Files Affected** | {FILES_COUNT} |

---

## Breaking Changes

{BREAKING_CHANGES_SECTION}

<!-- For each breaking change, use this format:

### {CHANGE_NUMBER}. {CHANGE_TITLE}

**Priority:** {HIGH|MEDIUM|LOW} | **Component:** {COMPONENT_NAME}

**What changed:** {DESCRIPTION}

**Before:**
```ruby
{OLD_CODE}
```

**After:**
```ruby
{NEW_CODE}
```

**Migration steps:**
1. {STEP_1}
2. {STEP_2}

**Affected files:**
- `{FILE_PATH}:{LINE_NUMBER}`

-->

---

## Custom Code Warnings

{CUSTOM_WARNINGS_SECTION}

<!-- For each warning, use this format:

### {WARNING_NUMBER}. {WARNING_TITLE}

**Location:** `{FILE_PATH}:{LINE_NUMBER}`
**What was found:** {DESCRIPTION}
**Recommendation:** {ACTION}

-->

---

## Configuration Changes (app:update preview)

### Modified Files

| File | Impact | Changes |
|------|--------|---------|
{MODIFIED_FILES_TABLE}

{MODIFIED_FILES_DIFFS}

### New Files

{NEW_FILES_SECTION}

### Removed Files

{REMOVED_FILES_SECTION}

---

## Migration Checklist

### Preparation

- [ ] Backup database
- [ ] Create feature branch
- [ ] Ensure all tests pass on current version
- [ ] Review breaking changes and custom code warnings above

### Dependencies

- [ ] Update `rails` gem to {TO_VERSION} in Gemfile
- [ ] Run `bundle update rails`
- [ ] Update related gems as needed
- [ ] Resolve dependency conflicts

### Configuration

- [ ] Run `rails app:update` (review each conflict)
- [ ] Apply configuration changes from Section 4
- [ ] Update framework defaults
- [ ] Verify environment-specific configs

### Breaking Changes

- [ ] Address all HIGH priority changes
- [ ] Address all MEDIUM priority changes
- [ ] Address LOW priority changes

### Testing

- [ ] Run full test suite
- [ ] Test critical user flows manually
- [ ] Verify API endpoints (if applicable)
- [ ] Check background jobs
- [ ] Review deprecation warnings

### Deploy

- [ ] Deploy to staging
- [ ] Smoke test staging environment
- [ ] Deploy to production
- [ ] Monitor logs and error rates

---

## Rollback

1. Revert the upgrade branch: `git revert --no-commit HEAD~{COMMIT_COUNT}..HEAD && git commit -m "Rollback Rails upgrade"`
2. Run `bundle install` to restore previous gems
3. Restore database backup if migrations were run
4. Deploy the reverted code

---

## Resources

{RESOURCES_SECTION}
