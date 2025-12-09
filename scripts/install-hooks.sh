#!/usr/bin/env bash
# Install git hooks for meal-planner project
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}Installing Git Hooks for Meal Planner${NC}\n"

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts"
HOOKS_DIR="$REPO_ROOT/gleam/.git/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo -e "${BLUE}Installing pre-commit hook...${NC}"
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  echo -e "${YELLOW}  Existing pre-commit hook found, backing up...${NC}"
  mv "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup.$(date +%s)"
fi

# Create symlink to versioned script
ln -sf "../../scripts/pre-commit.sh" "$HOOKS_DIR/pre-commit"
chmod +x "$SCRIPTS_DIR/pre-commit.sh"

echo -e "${GREEN}  ✓ Pre-commit hook installed${NC}"
echo -e "${BLUE}    Location: $HOOKS_DIR/pre-commit${NC}"
echo -e "${BLUE}    Points to: $SCRIPTS_DIR/pre-commit.sh${NC}"

echo -e "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}✓ Git hooks installed successfully!${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Features:${NC}"
echo -e "  • Format checking"
echo -e "  • Type checking"
echo -e "  • Full test suite execution"
echo -e "  • ${BOLD}Truth Score calculation (blocks commits < 95%)${NC}"
echo -e ""
echo -e "${YELLOW}To bypass hooks when needed:${NC}"
echo -e "  ${BOLD}SKIP_HOOKS=1 git commit${NC}"
echo -e ""
