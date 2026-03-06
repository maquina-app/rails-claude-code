#!/bin/bash

# Spec-Driven Development - Status Script
# Usage: bash status.sh

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
echo -e "${BLUE}║     Spec-Driven Development Status         ║${NC}"
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
PROD_STATUS=$(grep -A4 "^product_planning:" "$PROGRESS_FILE" | grep "status:" | sed 's/.*status: *//')
MISSION=$(grep -A4 "^product_planning:" "$PROGRESS_FILE" | grep "mission:" | sed 's/.*mission: *//')
ROADMAP=$(grep -A4 "^product_planning:" "$PROGRESS_FILE" | grep "roadmap:" | sed 's/.*roadmap: *//')
TECH=$(grep -A4 "^product_planning:" "$PROGRESS_FILE" | grep "tech_stack:" | sed 's/.*tech_stack: *//')

case $PROD_STATUS in
    "complete") echo -e "  Status: ${GREEN}✓ Complete${NC}" ;;
    "in_progress") echo -e "  Status: ${YELLOW}◐ In Progress${NC}" ;;
    *) echo -e "  Status: ${RED}○ Not Started${NC}" ;;
esac

[ "$MISSION" = "true" ] && echo -e "  Mission:    ${GREEN}✓${NC}" || echo -e "  Mission:    ${RED}○${NC}"
[ "$ROADMAP" = "true" ] && echo -e "  Roadmap:    ${GREEN}✓${NC}" || echo -e "  Roadmap:    ${RED}○${NC}"
[ "$TECH" = "true" ] && echo -e "  Tech Stack: ${GREEN}✓${NC}" || echo -e "  Tech Stack: ${RED}○${NC}"
echo ""

# Current Spec Status
echo -e "${YELLOW}━━━ Current Spec ━━━${NC}"
SPEC_NAME=$(grep -A2 "^current_spec:" "$PROGRESS_FILE" | grep "name:" | sed 's/.*name: *//')
SPEC_PATH=$(grep -A3 "^current_spec:" "$PROGRESS_FILE" | grep "path:" | sed 's/.*path: *//')

if [ "$SPEC_NAME" = "null" ] || [ -z "$SPEC_NAME" ]; then
    echo -e "  ${CYAN}No active spec${NC}"
    echo "  Run: new_spec.sh <spec-name> to start a new feature"
else
    echo -e "  Name: ${CYAN}$SPEC_NAME${NC}"
    echo -e "  Path: $SPEC_PATH"
    echo ""
    
    # Phase statuses
    echo "  Phases:"
    
    # Shape Spec
    SHAPE_STATUS=$(grep -A3 "shape_spec:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
    case $SHAPE_STATUS in
        "complete") echo -e "    Shape Spec:    ${GREEN}✓ Complete${NC}" ;;
        "in_progress") echo -e "    Shape Spec:    ${YELLOW}◐ In Progress${NC}" ;;
        *) echo -e "    Shape Spec:    ${RED}○ Not Started${NC}" ;;
    esac
    
    # Write Spec
    WRITE_STATUS=$(grep -A2 "write_spec:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
    case $WRITE_STATUS in
        "complete") echo -e "    Write Spec:    ${GREEN}✓ Complete${NC}" ;;
        "in_progress") echo -e "    Write Spec:    ${YELLOW}◐ In Progress${NC}" ;;
        *) echo -e "    Write Spec:    ${RED}○ Not Started${NC}" ;;
    esac
    
    # Create Tasks
    TASKS_STATUS=$(grep -A3 "create_tasks:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
    TASK_COUNT=$(grep -A3 "create_tasks:" "$PROGRESS_FILE" | grep "task_count:" | sed 's/.*task_count: *//')
    case $TASKS_STATUS in
        "complete") echo -e "    Create Tasks:  ${GREEN}✓ Complete${NC} ($TASK_COUNT tasks)" ;;
        "in_progress") echo -e "    Create Tasks:  ${YELLOW}◐ In Progress${NC}" ;;
        *) echo -e "    Create Tasks:  ${RED}○ Not Started${NC}" ;;
    esac
    
    # Implement
    IMPL_STATUS=$(grep -A4 "implement:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
    IMPL_MODE=$(grep -A4 "implement:" "$PROGRESS_FILE" | grep "mode:" | sed 's/.*mode: *//')
    IMPL_DONE=$(grep -A4 "implement:" "$PROGRESS_FILE" | grep "tasks_completed:" | sed 's/.*tasks_completed: *//')
    IMPL_TOTAL=$(grep -A4 "implement:" "$PROGRESS_FILE" | grep "tasks_total:" | sed 's/.*tasks_total: *//')
    case $IMPL_STATUS in
        "complete") echo -e "    Implement:     ${GREEN}✓ Complete${NC} ($IMPL_DONE/$IMPL_TOTAL tasks, $IMPL_MODE mode)" ;;
        "in_progress") echo -e "    Implement:     ${YELLOW}◐ In Progress${NC} ($IMPL_DONE/$IMPL_TOTAL tasks)" ;;
        *) echo -e "    Implement:     ${RED}○ Not Started${NC}" ;;
    esac
    
    # Verify
    VERIFY_STATUS=$(grep -A3 "verify:" "$PROGRESS_FILE" | grep "status:" | head -1 | sed 's/.*status: *//')
    case $VERIFY_STATUS in
        "complete") echo -e "    Verify:        ${GREEN}✓ Complete${NC}" ;;
        "in_progress") echo -e "    Verify:        ${YELLOW}◐ In Progress${NC}" ;;
        *) echo -e "    Verify:        ${RED}○ Not Started${NC}" ;;
    esac
fi

echo ""

# Completed Specs
echo -e "${YELLOW}━━━ Completed Specs ━━━${NC}"
COMPLETED=$(grep -A100 "^completed_specs:" "$PROGRESS_FILE" | grep -E "^\s+-\s+name:" | sed 's/.*name: *//' | head -5)
if [ -z "$COMPLETED" ]; then
    echo -e "  ${CYAN}No completed specs yet${NC}"
else
    echo "$COMPLETED" | while read spec; do
        echo -e "  ${GREEN}✓${NC} $spec"
    done
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
