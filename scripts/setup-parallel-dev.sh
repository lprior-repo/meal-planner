#!/usr/bin/env bash

################################################################################
# Parallel Agent Development Environment Setup
#
# Complete orchestration for:
# 1. Verifying Agent Mail is running
# 2. Creating git worktrees per Beads task
# 3. Launching Claude Code sessions in Zellij
# 4. Managing coordination and status
#
# Usage:
#   ./scripts/setup-parallel-dev.sh [start|stop|status|cleanup|reset]
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/parallel-agents-config.env"

# Source configuration
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# Defaults if not in config
PROJECT_ROOT="${PROJECT_ROOT:-.}"
MAX_AGENTS="${MAX_AGENTS:-12}"
AGENT_MAIL_URL="${AGENT_MAIL_URL:-http://127.0.0.1:8765}"
ZELLIJ_SESSION_NAME="${ZELLIJ_SESSION_NAME:-meal-planner-agents}"
LOG_DIR="${LOG_DIR:-.agent-logs}"
WORKTREE_BASE="${WORKTREE_BASE:-.worktrees}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() { echo -e "${BLUE}[setup]${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
info() { echo -e "${CYAN}ℹ${NC} $*"; }

################################################################################
# Health Checks
################################################################################

check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing=()
    
    # Check git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    # Check beads
    if ! command -v bd &> /dev/null; then
        missing+=("beads (bd)")
    fi
    
    # Check zellij
    if ! command -v zellij &> /dev/null; then
        missing+=("zellij")
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing prerequisites: ${missing[*]}"
        echo ""
        echo "Installation guide:"
        echo "  git     - comes with OS"
        echo "  beads   - cargo install --git https://github.com/steveyegge/beads"
        echo "  zellij  - cargo install zellij"
        echo "  jq      - apt/brew install jq"
        return 1
    fi
    
    success "All prerequisites installed"
    return 0
}

check_agent_mail() {
    log "Checking Agent Mail..."
    
    if curl -s -f "$AGENT_MAIL_URL/health" > /dev/null 2>&1; then
        success "Agent Mail is running"
        return 0
    else
        error "Agent Mail not accessible at $AGENT_MAIL_URL"
        echo ""
        echo "Start Agent Mail with:"
        echo "  am server start"
        echo ""
        echo "In a separate terminal:"
        echo "  am inbox"
        return 1
    fi
}

check_beads() {
    log "Checking Beads..."
    
    if ! bd status --json > /dev/null 2>&1; then
        error "Beads not initialized or error accessing it"
        return 1
    fi
    
    # Count ready tasks
    local ready_count=$(bd ready --json 2>/dev/null | jq 'length' || echo "0")
    
    if [[ "$ready_count" -eq 0 ]]; then
        warn "No ready tasks in Beads"
        return 1
    fi
    
    success "Beads initialized with $ready_count ready tasks"
    return 0
}

check_git_state() {
    log "Checking git state..."
    
    if ! git status > /dev/null 2>&1; then
        error "Not in a git repository"
        return 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        warn "Uncommitted changes in working directory"
        warn "Commit or stash before launching agents"
        return 1
    fi
    
    success "Git repository is clean"
    return 0
}

################################################################################
# Core Operations
################################################################################

show_status() {
    log "System Status"
    echo ""
    
    # Check each component
    echo -n "  Agent Mail:      "
    if curl -s -f "$AGENT_MAIL_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Not running${NC}"
    fi
    
    echo -n "  Beads:           "
    if bd status --json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ready${NC}"
    else
        echo -e "${RED}✗ Error${NC}"
    fi
    
    echo -n "  Git:             "
    if git status > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Clean${NC}"
    else
        echo -e "${RED}✗ Error${NC}"
    fi
    
    echo -n "  Zellij:          "
    if command -v zellij &> /dev/null; then
        echo -e "${GREEN}✓ Installed${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
    fi
    
    # Active worktrees
    echo -n "  Active Worktrees: "
    local count=$(git worktree list 2>/dev/null | wc -l)
    echo -e "${CYAN}$count${NC}"
    
    # Ready tasks
    echo -n "  Ready Tasks:     "
    local ready=$(bd ready --json 2>/dev/null | jq 'length' || echo "0")
    echo -e "${CYAN}$ready${NC}"
    
    echo ""
}

start_environment() {
    log "Starting parallel agent environment..."
    echo ""
    
    # Run health checks
    check_prerequisites || return 1
    echo ""
    
    check_agent_mail || {
        warn "Continuing without Agent Mail (not critical for this phase)"
    }
    echo ""
    
    check_beads || return 1
    echo ""
    
    check_git_state || return 1
    echo ""
    
    # Create directories
    mkdir -p "$LOG_DIR" "$WORKTREE_BASE"
    success "Created directories"
    echo ""
    
    # Run the launcher
    log "Launching worktrees and agents..."
    if [[ -x "$SCRIPT_DIR/launch-parallel-agents.sh" ]]; then
        "$SCRIPT_DIR/launch-parallel-agents.sh" --max-agents "$MAX_AGENTS"
    else
        error "launch-parallel-agents.sh not found or not executable"
        return 1
    fi
    
    echo ""
    success "Environment started"
    
    # Show next steps
    echo ""
    log "Next Steps:"
    echo ""
    echo "  1. Launch Zellij session:"
    echo "     zellij -s $ZELLIJ_SESSION_NAME"
    echo ""
    echo "  2. In another terminal, monitor Agent Mail:"
    echo "     am inbox"
    echo ""
    echo "  3. Monitor Beads status:"
    echo "     watch bd status"
    echo ""
    echo "  4. Check agent logs:"
    echo "     tail -f $LOG_DIR/*.log"
    echo ""
}

stop_environment() {
    log "Stopping parallel agent environment..."
    
    # Kill zellij session if running
    if zellij ls 2>/dev/null | grep -q "$ZELLIJ_SESSION_NAME"; then
        log "Killing Zellij session: $ZELLIJ_SESSION_NAME"
        zellij kill-session -s "$ZELLIJ_SESSION_NAME" 2>/dev/null || true
    fi
    
    # Don't auto-cleanup worktrees
    warn "Worktrees preserved. Run 'cleanup' to remove them."
    
    success "Environment stopped"
}

cleanup_environment() {
    log "Cleaning up all worktrees and sessions..."
    
    # Kill zellij
    if zellij ls 2>/dev/null | grep -q "$ZELLIJ_SESSION_NAME"; then
        log "Killing Zellij session..."
        zellij kill-session -s "$ZELLIJ_SESSION_NAME" 2>/dev/null || true
    fi
    
    # Remove worktrees
    if [[ -d "$WORKTREE_BASE" ]]; then
        log "Removing worktrees..."
        for worktree in "$WORKTREE_BASE"/*; do
            if [[ -d "$worktree" ]]; then
                git worktree remove "$worktree" --force 2>/dev/null || true
            fi
        done
        rmdir "$WORKTREE_BASE" 2>/dev/null || true
    fi
    
    # Clean logs
    if [[ -d "$LOG_DIR" ]]; then
        log "Cleaning logs..."
        rm -rf "$LOG_DIR"
    fi
    
    success "Cleanup complete"
}

################################################################################
# Main
################################################################################

main() {
    cd "$PROJECT_ROOT"
    
    local command="${1:-status}"
    
    case "$command" in
        start)
            start_environment
            ;;
        stop)
            stop_environment
            ;;
        status)
            show_status
            ;;
        cleanup)
            cleanup_environment
            ;;
        reset)
            stop_environment
            cleanup_environment
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            echo "Usage: $0 {start|stop|status|cleanup|reset}"
            exit 1
            ;;
    esac
}

main "$@"
