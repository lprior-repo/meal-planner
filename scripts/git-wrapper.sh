#!/usr/bin/env bash
# =============================================================================
# Git Wrapper - Blocks --no-verify
# =============================================================================
# This wrapper intercepts git commands and blocks --no-verify usage
#
# Installation:
#   Add to your ~/.bashrc or ~/.zshrc:
#   alias git='/path/to/meal-planner/scripts/git-wrapper.sh'
#
# Or for this project only, run:
#   source scripts/git-wrapper.sh
# =============================================================================

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Get the real git binary
GIT_BINARY=$(which git | grep -v "alias" | head -1)
if [[ -z "$GIT_BINARY" ]]; then
    GIT_BINARY="/usr/bin/git"
fi

# Check if --no-verify is being used
if [[ "$*" == *"--no-verify"* ]] || [[ "$*" == *"-n"* ]]; then
    # Check if it's a commit or push command
    if [[ "$1" == "commit" ]] || [[ "$1" == "push" ]]; then
        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}${BOLD}  ✗ --no-verify IS BLOCKED IN THIS PROJECT${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}You tried to run:${NC}"
        echo "  git $*"
        echo ""
        echo -e "${BOLD}This is not allowed because:${NC}"
        echo "  • --no-verify bypasses quality checks"
        echo "  • It allows broken code to be committed"
        echo "  • It defeats the purpose of our hook system"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}If you need to commit work-in-progress:${NC}"
        echo ""
        echo "  1. Fix the errors first (even if partial)"
        echo "     cd gleam && gleam build"
        echo ""
        echo "  2. Or use a WIP branch instead:"
        echo "     git checkout -b wip/my-work"
        echo "     git commit -m 'WIP: partial implementation'"
        echo ""
        echo "  3. Or stash your changes:"
        echo "     git stash -u -m 'WIP: description'"
        echo ""
        echo -e "${BOLD}If the pre-commit hook is genuinely wrong:${NC}"
        echo "  1. Fix the hook instead of bypassing it"
        echo "  2. Ask the team to adjust hook rules"
        echo "  3. Report false positives"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${RED}Command blocked. Fix the issues and try again.${NC}"
        echo ""

        # Return error code
        return 1 2>/dev/null || exit 1
    fi
fi

# If not blocked, run the real git command
exec "$GIT_BINARY" "$@"
