#!/bin/bash

# Spec-Driven Development - New Spec Initialization Script
# Usage: bash new_spec.sh <spec-name>
#
# Creates a self-contained spec folder matching the canonical SDD structure:
#   sdd/specs/YYYY-MM-DD-<name>/{spec.md, references.md, standards.md, tasks.md}
# and points current_spec at it in sdd/progress.yml.

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a spec name${NC}"
    echo "Usage: bash new_spec.sh <spec-name>"
    echo "Example: bash new_spec.sh user-authentication"
    exit 1
fi

SPEC_NAME="$1"
DATE=$(date +"%Y-%m-%d")
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SPEC_FOLDER="${DATE}-${SPEC_NAME}"
SDD_DIR="sdd"
SPEC_PATH="$SDD_DIR/specs/$SPEC_FOLDER"

# Check if sdd directory exists
if [ ! -d "$SDD_DIR" ]; then
    echo -e "${RED}Error: sdd/ directory not found${NC}"
    echo "Run init_sdd.sh first to initialize the project"
    exit 1
fi

# Check if spec already exists
if [ -d "$SPEC_PATH" ]; then
    echo -e "${YELLOW}Warning: Spec folder already exists: $SPEC_PATH${NC}"
    read -p "Overwrite? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf "$SPEC_PATH"
fi

echo -e "${BLUE}Creating new spec: $SPEC_FOLDER${NC}"
echo ""

# Create the self-contained spec folder with placeholder files
echo -e "${YELLOW}Creating spec folder...${NC}"
mkdir -p "$SPEC_PATH"

cat > "$SPEC_PATH/spec.md" << EOF
# Spec: ${SPEC_NAME}

## Goal
[One sentence — filled during /sdd-shape]

## User Stories
- As a [user], I want [action] so that [outcome]

## Requirements
[Functional only — no implementation details]

## Visual Design
[Mockup link or layout description]

## Out of Scope
[What we're explicitly NOT building in v1]
EOF

cat > "$SPEC_PATH/references.md" << EOF
# References: ${SPEC_NAME}

[Existing models, controllers, views, and partials to reuse or follow —
filled during /sdd-shape after searching the codebase]
EOF

cat > "$SPEC_PATH/standards.md" << EOF
# Standards: ${SPEC_NAME}

[Full text of the standards that apply to THIS feature — injected from
sdd/standards/index.yml during /sdd-shape so the spec folder is self-contained]
EOF

cat > "$SPEC_PATH/tasks.md" << EOF
# Tasks: ${SPEC_NAME}

[Task groups (Database -> Backend -> Frontend -> Integration), each a
self-contained Claude Code prompt — filled during /sdd-tasks]
EOF

echo "  ✓ spec.md"
echo "  ✓ references.md"
echo "  ✓ standards.md"
echo "  ✓ tasks.md"

# Update progress.yml — point current_spec at this spec (simple schema)
echo -e "${YELLOW}Updating progress tracker...${NC}"

if command -v yq &> /dev/null; then
    yq -i ".current_spec.name = \"$SPEC_FOLDER\"" "$SDD_DIR/progress.yml"
    yq -i ".current_spec.status = \"shaping\"" "$SDD_DIR/progress.yml"
    yq -i ".updated = \"$DATETIME\"" "$SDD_DIR/progress.yml"
    echo "  ✓ Updated progress.yml"
else
    # Portable fallback: the simple schema has unique `name: null`/`status: null`
    # lines under current_spec, and a single top-level `updated:` line.
    sed -i.bak \
        -e "s|^  name: null|  name: $SPEC_FOLDER|" \
        -e "s|^  status: null|  status: shaping|" \
        -e "s|^updated: .*|updated: $DATETIME|" \
        "$SDD_DIR/progress.yml"
    rm -f "$SDD_DIR/progress.yml.bak"
    echo "  ✓ Updated progress.yml"
fi

echo ""
echo -e "${GREEN}✓ Spec initialized successfully!${NC}"
echo ""
echo "Spec location: $SPEC_PATH"
echo ""
echo "Next steps:"
echo "  1. /sdd-shape — gather requirements, search the codebase, inject standards"
echo "  2. /sdd-tasks — break the spec into self-contained task groups"
echo "  3. Hand the spec folder to Claude Code to implement"
echo ""
