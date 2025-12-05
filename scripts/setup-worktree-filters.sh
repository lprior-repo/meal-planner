#!/usr/bin/env bash
# =============================================================================
# Setup Worktree File Filters
# =============================================================================
# Configures git sparse-checkout per worktree to prevent file conflicts
#
# This is the KEY script for preventing AI agents from trampling each other!
#
# How it works:
# 1. Each worktree gets its own sparse-checkout configuration
# 2. Based on the task/track assignment, we limit which files are visible
# 3. Git prevents modifications to files outside the sparse-checkout
# 4. Agents can't accidentally conflict on files they shouldn't touch
#
# Usage:
#   ./setup-worktree-filters.sh <worktree-path> <file-patterns>
#   ./setup-worktree-filters.sh .agent-worktrees/pool-wt-1 "gleam/src/meal_planner/web/**/*.gleam"
# =============================================================================

set -euo pipefail

readonly WORKTREE_PATH="$1"
readonly FILE_PATTERNS="$2"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# =============================================================================
# Main Setup
# =============================================================================

main() {
    if [[ ! -d "$WORKTREE_PATH" ]]; then
        echo "Error: Worktree path doesn't exist: $WORKTREE_PATH"
        exit 1
    fi

    log_info "Setting up file filters for worktree: $WORKTREE_PATH"
    log_info "Allowed patterns: $FILE_PATTERNS"

    cd "$WORKTREE_PATH"

    # Enable sparse-checkout
    git config core.sparseCheckout true

    # Create sparse-checkout file
    local sparse_file=".git/info/sparse-checkout"
    mkdir -p "$(dirname "$sparse_file")"

    # Start with essential files (always needed)
    cat > "$sparse_file" << 'EOF'
# Essential files (always included)
.beads/
.claude/
.env*
.gitignore
.gitattributes
gleam.toml
manifest.toml
README.md
scripts/

# Database migrations (always included for safety)
gleam/migrations_pg/

EOF

    # Add the specific file patterns for this worktree
    echo "# Task-specific files" >> "$sparse_file"
    for pattern in $FILE_PATTERNS; do
        echo "$pattern" >> "$sparse_file"
        log_info "  ✓ Added pattern: $pattern"
    done

    # Add related test files automatically
    echo "" >> "$sparse_file"
    echo "# Related test files" >> "$sparse_file"
    for pattern in $FILE_PATTERNS; do
        # Convert src patterns to test patterns
        if [[ "$pattern" == *"/src/"* ]]; then
            local test_pattern
            test_pattern=$(echo "$pattern" | sed 's|/src/|/test/|')
            echo "$test_pattern" >> "$sparse_file"
            log_info "  ✓ Added test pattern: $test_pattern"
        fi
    done

    # Apply the sparse-checkout
    git read-tree -mu HEAD

    log_info "Sparse-checkout configured!"
    echo ""
    echo -e "${CYAN}Files visible in this worktree:${NC}"
    git ls-files | head -20
    local total_files
    total_files=$(git ls-files | wc -l)
    echo "... ($total_files files total)"
    echo ""
    echo -e "${CYAN}Sparse-checkout configuration:${NC}"
    cat "$sparse_file"
}

main "$@"
