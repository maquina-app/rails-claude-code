#!/bin/bash

# Spec-Driven Development - New Spec Initialization Script
# Usage: bash new_spec.sh <spec-name>

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

# Create directory structure
echo -e "${YELLOW}Creating spec directory structure...${NC}"

mkdir -p "$SPEC_PATH/planning/visuals"
mkdir -p "$SPEC_PATH/verification/screenshots"

echo "  ✓ Created $SPEC_PATH/"
echo "  ✓ Created $SPEC_PATH/planning/"
echo "  ✓ Created $SPEC_PATH/planning/visuals/"
echo "  ✓ Created $SPEC_PATH/verification/"
echo "  ✓ Created $SPEC_PATH/verification/screenshots/"

# Create placeholder files
touch "$SPEC_PATH/planning/visuals/.gitkeep"
touch "$SPEC_PATH/verification/screenshots/.gitkeep"

# Create initial requirements placeholder
cat > "$SPEC_PATH/planning/requirements.md" << EOF
# Spec Requirements: ${SPEC_NAME}

## Initial Description

[Describe your feature here or this will be filled during shape-spec phase]

## Requirements Discussion

[To be completed during shape-spec phase]

## Visual Assets

[Add mockups/wireframes to planning/visuals/ folder]

## Requirements Summary

[To be completed during shape-spec phase]
EOF

echo "  ✓ Created placeholder requirements.md"

# Update progress.yml
echo -e "${YELLOW}Updating progress tracker...${NC}"

# Check if yq is available, otherwise use sed
if command -v yq &> /dev/null; then
    yq -i ".current_spec.name = \"$SPEC_FOLDER\"" "$SDD_DIR/progress.yml"
    yq -i ".current_spec.path = \"$SPEC_PATH\"" "$SDD_DIR/progress.yml"
    yq -i ".current_spec.phases.shape_spec.status = \"not_started\"" "$SDD_DIR/progress.yml"
    yq -i ".updated = \"$DATETIME\"" "$SDD_DIR/progress.yml"
else
    # Fallback: just note that manual update is needed
    echo "  ⚠ Please update progress.yml manually:"
    echo "    current_spec.name: $SPEC_FOLDER"
    echo "    current_spec.path: $SPEC_PATH"
fi

echo "  ✓ Updated progress.yml"

echo ""
echo -e "${GREEN}✓ Spec initialized successfully!${NC}"
echo ""
echo "Spec location: $SPEC_PATH"
echo ""
echo "Next steps:"
echo "  1. Add visual assets to: $SPEC_PATH/planning/visuals/"
echo "  2. Run shape-spec to gather requirements"
echo "  3. Run write-spec to create formal specification"
echo ""
