#!/usr/bin/env bash
# =============================================================================
# Install Git Wrapper
# =============================================================================
# Installs the git wrapper that blocks --no-verify
#
# Usage:
#   ./scripts/install-git-wrapper.sh
# =============================================================================

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Git Wrapper Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect shell
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    echo -e "${YELLOW}⚠ Unknown shell: $SHELL${NC}"
    echo "Please manually add the alias to your shell config."
    echo ""
    echo "Add this line:"
    echo "  alias git='$PROJECT_ROOT/scripts/git-wrapper.sh'"
    exit 1
fi

echo "Detected shell config: $SHELL_RC"
echo ""

# Check if alias already exists
if grep -q "git-wrapper.sh" "$SHELL_RC" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Git wrapper alias already installed"
    echo ""
else
    echo "Installing git wrapper alias..."

    # Add alias to shell config
    cat >> "$SHELL_RC" << EOF

# Git wrapper to block --no-verify (meal-planner project)
alias git='$PROJECT_ROOT/scripts/git-wrapper.sh'
EOF

    echo -e "${GREEN}✓${NC} Added alias to $SHELL_RC"
    echo ""
fi

# Source the config to activate immediately
echo "Activating wrapper in current shell..."
alias git="$PROJECT_ROOT/scripts/git-wrapper.sh"

echo -e "${GREEN}✓${NC} Git wrapper activated!"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}IMPORTANT:${NC}"
echo ""
echo "For NEW terminal sessions, run:"
echo "  source $SHELL_RC"
echo ""
echo "Or restart your terminal."
echo ""
echo -e "${BOLD}THIS session is already configured.${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Testing the wrapper:${NC}"
echo ""
echo "Try running (will be blocked):"
echo "  git commit --no-verify -m 'test'"
echo ""
echo "Normal git commands work fine:"
echo "  git status"
echo "  git commit -m 'test'"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
