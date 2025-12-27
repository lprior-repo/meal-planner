#!/usr/bin/env bash
# Land the Plane - Session Completion Script
#
# Automates the complete session completion workflow:
# 1. Quality gates (tests, build, format)
# 2. Memory and knowledge graph sync
# 3. Bead updates and sync
# 4. Git operations (pull, push, cleanup)
# 5. Verification and hand-off summary
#
# Usage: ./scripts/land-the-plane.sh [--skip-tests] [--skip-format]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script state
SKIP_TESTS=false
SKIP_FORMAT=false
DRY_RUN=false
FAILED_STEPS=()
COMPLETED_STEPS=()

# Helper functions
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
step() { echo -e "${CYAN}[STEP]${NC} $*"; }

fail_and_exit() {
    error "$*"
    error "Session completion failed. Please resolve the issues above and try again."
    exit 1
}

record_failure() {
    FAILED_STEPS+=("$1")
    error "Failed: $1"
}

record_success() {
    COMPLETED_STEPS+=("$1")
    success "Completed: $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for uncommitted changes
check_git_status() {
    step "Checking git status..."

    if [[ -n "$(git status --porcelain)" ]]; then
        warn "You have uncommitted changes:"
        git status --short
        echo ""
        read -p "Do you want to continue without committing? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            fail_and_exit "Please commit your changes first"
        fi
    else
        success "No uncommitted changes"
    fi
    echo ""
}

# Run quality gates
run_quality_gates() {
    step "Running quality gates..."
    echo ""

    local overall_success=true

    # Format check
    if [[ "$SKIP_FORMAT" == "false" ]]; then
        step "Checking code formatting..."
        if gleam fmt --check 2>/dev/null; then
            success "Code is properly formatted"
        else
            record_failure "Code formatting check"
            warn "Run 'gleam fmt' to format your code"
            overall_success=false
        fi
    else
        info "Skipping format check (--skip-format)"
    fi
    echo ""

    # Build check
    step "Checking if code builds..."
    if gleam build 2>&1 | tee /tmp/gleam-build.log | grep -q "error:"; then
        record_failure "Build failed"
        warn "Check build output above for errors"
        overall_success=false
    else
        success "Build succeeded"
    fi
    echo ""

    # Test check
    if [[ "$SKIP_TESTS" == "false" ]]; then
        step "Running tests..."
        if gleam test 2>&1 | tee /tmp/gleam-test.log | tail -10 | grep -q "tests in"; then
            # Extract test summary
            local test_summary=$(tail -1 /tmp/gleam-test.log)
            success "Tests passed: $test_summary"
        else
            record_failure "Tests failed"
            warn "Check test output above for failures"
            overall_success=false
        fi
    else
        info "Skipping tests (--skip-tests)"
    fi
    echo ""

    if [[ "$overall_success" == "false" ]]; then
        fail_and_exit "Quality gates failed. Please fix the issues above."
    fi
}

# Check for beads needing action
check_beads() {
    step "Checking bead status..."

    if command_exists bd; then
        local in_progress=$(bd list --status in_progress 2>/dev/null | wc -l || echo "0")
        if [[ "$in_progress" -gt 0 ]]; then
            warn "You have $in_progress beads in progress:"
            bd list --status in_progress 2>/dev/null
            echo ""
            read -p "Do you want to continue without closing them? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                fail_and_exit "Please update bead statuses first"
            fi
        else
            success "No beads in progress"
        fi
    else
        warn "bd command not found - skipping bead checks"
    fi
    echo ""
}

# Sync beads with git
sync_beads() {
    step "Syncing beads with git..."

    if command_exists bd; then
        if bd sync; then
            success "Beads synced with git"
        else
            record_failure "Bead sync failed"
            warn "Check bd output above"
        fi
    else
        warn "bd command not found - skipping bead sync"
    fi
    echo ""
}

# Memory and knowledge graph reminders
sync_memories() {
    step "Memory and knowledge graph sync..."

    info "Reminder: Ensure you've saved important information to:"
    info "  • mem0 (long-term memory) - user preferences, decisions, patterns"
    info "  • graphiti (knowledge graph) - architecture, bug solutions, relationships"
    info ""
    info "Use these searches before continuing:"
    info "  • search_memory_facts(\"bd-<id>\") - Check for existing issue context"
    info "  • graphiti_search_memory_facts(query: \"bd-<id>\") - Search knowledge graph"
    echo ""

    read -p "Have you saved all relevant learnings to memory and knowledge graph? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "Please save important learnings before continuing"
        read -p "Press Enter when ready to continue..."
    fi
    echo ""
}

# Git operations
git_operations() {
    step "Performing git operations..."
    echo ""

    # Pull with rebase
    step "Pulling latest changes with rebase..."
    if git pull --rebase 2>&1 | tee /tmp/git-pull.log; then
        success "Pull succeeded"
    else
        record_failure "Git pull failed"
        warn "Check output above for conflicts"
        return 1
    fi
    echo ""

    # Push to remote
    step "Pushing to remote..."
    if git push 2>&1 | tee /tmp/git-push.log; then
        success "Push succeeded"
    else
        record_failure "Git push failed"
        warn "Check output above for errors"
        return 1
    fi
    echo ""
}

# Verify final state
verify_final_state() {
    step "Verifying final state..."

    # Check if up to date
    if git status | grep -q "up to date with origin"; then
        success "Repository is up to date with origin"
    else
        record_failure "Repository not up to date"
        warn "Check git status above"
        return 1
    fi

    # Check for uncommitted changes
    if [[ -z "$(git status --porcelain)" ]]; then
        success "No uncommitted changes"
    else
        record_failure "Uncommitted changes remain"
        warn "Check git status above"
        return 1
    fi
    echo ""
}

# Cleanup operations
cleanup() {
    step "Cleaning up..."

    # Clear stashes
    if [[ "$(git stash list | wc -l)" -gt 0 ]]; then
        info "Clearing git stashes..."
        git stash clear
        success "Stashes cleared"
    else
        info "No stashes to clear"
    fi

    # Prune remote branches
    info "Pruning remote branches..."
    if git remote prune origin; then
        success "Remote branches pruned"
    else
        warn "Failed to prune remote branches (non-critical)"
    fi
    echo ""
}

# Generate hand-off summary
generate_handoff() {
    step "Generating hand-off summary..."
    echo ""

    echo "================================"
    echo "SESSION COMPLETION SUMMARY"
    echo "================================"
    echo ""

    # Timestamp
    echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Completed steps
    if [[ ${#COMPLETED_STEPS[@]} -gt 0 ]]; then
        echo "✓ Completed Steps:"
        for step in "${COMPLETED_STEPS[@]}"; do
            echo "  • $step"
        done
        echo ""
    fi

    # Failed steps
    if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
        echo "✗ Failed Steps:"
        for step in "${FAILED_STEPS[@]}"; do
            echo "  • $step"
        done
        echo ""
    fi

    # Current branch
    echo "Current Branch: $(git branch --show-current)"
    echo ""

    # Last commit
    echo "Last Commit:"
    git log -1 --oneline
    echo ""

    # Beads in progress (if any)
    if command_exists bd; then
        local in_progress=$(bd list --status in_progress 2>/dev/null)
        if [[ -n "$in_progress" ]]; then
            echo "Beads In Progress:"
            echo "$in_progress"
            echo ""
        fi
    fi

    echo "================================"
    echo ""
}

# Print usage
print_usage() {
    cat << EOF
Land the Plane - Session Completion Script

Automates the complete session completion workflow for the meal-planner project.

Usage: $0 [OPTIONS]

Options:
  --skip-tests    Skip running tests
  --skip-format   Skip code formatting check
  --dry-run       Show what would be done without executing
  --help, -h      Show this help message

The script will:
  1. Check git status for uncommitted changes
  2. Run quality gates (format, build, tests)
  3. Check bead status for in-progress items
  4. Remind you to sync memory and knowledge graph
  5. Pull, rebase, and push changes
  6. Verify final state
  7. Clean up stashes and prune remote branches
  8. Generate hand-off summary

Quality Gates:
  • gleam fmt --check     - Verify code formatting
  • gleam build            - Verify code builds
  • gleam test             - Run test suite

Integrations:
  • bd (beads)             - Issue tracking
  • graphiti (graphdb)     - Knowledge graph (via MCP)
  • mem0 (long-term mem)   - Long-term memory (via MCP)
  • bv (beads viewer)      - Issue visualization TUI

Exit Codes:
  0 - Success
  1 - Failure (quality gates, git operations, etc.)

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-format)
            SKIP_FORMAT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo ""
    echo "================================"
    echo "LAND THE PLANE"
    echo "Session Completion Workflow"
    echo "================================"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    # Run all steps
    check_git_status
    run_quality_gates
    check_beads
    sync_memories

    if [[ "$DRY_RUN" == "false" ]]; then
        sync_beads
        git_operations
        verify_final_state
        cleanup
    else
        info "Skipping git operations in dry-run mode"
    fi

    # Generate summary
    generate_handoff

    # Final status
    if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
        success "Session completed successfully!"
        info "You can now safely close this session."
        echo ""
        return 0
    else
        error "Session completed with ${#FAILED_STEPS[@]} failures"
        info "Please review the failed steps above and re-run the script."
        echo ""
        return 1
    fi
}

# Run main function
main "$@"
