#!/bin/bash

# Spec-Driven Development - Status Script
# Usage: bash status.sh
#
# Reads the simple sdd/progress.yml schema written by init_sdd.sh:
#   project, updated, product_planning.status, current_spec.{name,status},
#   completed_specs[]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SDD_DIR="sdd"
PROGRESS_FILE="$SDD_DIR/progress.yml"

# Check if progress file exists
if [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}Error: progress.yml not found${NC}"
    echo "Run init_sdd.sh first to initialize the project"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Spec-Driven Development Status          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Extract values using grep/sed (portable without yq)
PROJECT=$(grep "^project:" "$PROGRESS_FILE" | sed 's/project: *//')
UPDATED=$(grep "^updated:" "$PROGRESS_FILE" | sed 's/updated: *//')

echo -e "${CYAN}Project:${NC} $PROJECT"
echo -e "${CYAN}Last Updated:${NC} $UPDATED"
echo ""

# Product Planning Status
echo -e "${YELLOW}━━━ Product Planning ━━━${NC}"
PROD_STATUS=$(grep -A2 "^product_planning:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
case $PROD_STATUS in
    "complete") echo -e "  Status: ${GREEN}✓ Complete${NC}" ;;
    "in_progress") echo -e "  Status: ${YELLOW}◐ In Progress${NC}" ;;
    *) echo -e "  Status: ${RED}○ Not Started${NC}" ;;
esac
echo ""

# Current Spec Status
echo -e "${YELLOW}━━━ Current Spec ━━━${NC}"
SPEC_NAME=$(grep -A2 "^current_spec:" "$PROGRESS_FILE" | grep "name:" | head -1 | sed 's/.*name: *//')
SPEC_STATUS=$(grep -A2 "^current_spec:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')

if [ "$SPEC_NAME" = "null" ] || [ -z "$SPEC_NAME" ]; then
    echo -e "  ${CYAN}No active spec${NC}"
    echo "  Run: new_spec.sh <spec-name> (or /sdd-shape) to start a new feature"
else
    echo -e "  Name: ${CYAN}$SPEC_NAME${NC}"
    case $SPEC_STATUS in
        "complete")     echo -e "  Status: ${GREEN}✓ Complete${NC}" ;;
        "implementing") echo -e "  Status: ${YELLOW}◐ Implementing${NC}" ;;
        "tasks")        echo -e "  Status: ${YELLOW}◐ Tasks created${NC}" ;;
        "shaping")      echo -e "  Status: ${YELLOW}◐ Shaping${NC}" ;;
        *)              echo -e "  Status: ${CYAN}$SPEC_STATUS${NC}" ;;
    esac
fi
echo ""

# Completed Specs
echo -e "${YELLOW}━━━ Completed Specs ━━━${NC}"
COMPLETED=$(grep -A100 "^completed_specs:" "$PROGRESS_FILE" | grep -E "^\s+-\s+name:" | sed 's/.*name: *//' | head -10)
if [ -z "$COMPLETED" ]; then
    echo -e "  ${CYAN}No completed specs yet${NC}"
else
    echo "$COMPLETED" | while read spec; do
        echo -e "  ${GREEN}✓${NC} $spec"
    done
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
