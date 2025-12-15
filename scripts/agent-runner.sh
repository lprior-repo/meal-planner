#!/usr/bin/env bash

################################################################################
# Agent Runner - Executed in Zellij Pane
#
# Handles:
# 1. Registering agent with Agent Mail
# 2. Launching Claude Code in worktree
# 3. Coordinating via Beads task ID
# 4. Capturing output and syncing status
#
# Called by zellij with task_id as argument
################################################################################

set -euo pipefail

TASK_ID="${1:-}"
PROJECT_ROOT="${PROJECT_ROOT:-.}"
AGENT_MAIL_URL="${AGENT_MAIL_URL:-http://127.0.0.1:8765}"
LOG_DIR="${PROJECT_ROOT}/.agent-logs"
WORKTREE_DIR="${PROJECT_ROOT}/.worktrees"
WORKTREE_PATH="${WORKTREE_DIR}/${TASK_ID}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[${TASK_ID}]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
}

################################################################################
# Validation
################################################################################

if [[ -z "$TASK_ID" ]]; then
    error "Usage: agent-runner.sh <task_id>"
    exit 1
fi

if [[ ! -d "$WORKTREE_PATH" ]]; then
    error "Worktree not found: $WORKTREE_PATH"
    exit 1
fi

mkdir -p "$LOG_DIR"

################################################################################
# Agent Mail Registration
################################################################################

register_agent() {
    log "Registering agent with Agent Mail..."
    
    # Check if agent-mail is available
    if ! curl -s -f "$AGENT_MAIL_URL/health" > /dev/null 2>&1; then
        warn "Agent Mail not available at $AGENT_MAIL_URL"
        return 1
    fi
    
    # Generate agent name
    local agent_name="agent-${TASK_ID}"
    
    # Register via curl to agent-mail (mock for now)
    log "Agent name: $agent_name"
    log "Task ID: $TASK_ID"
    
    # Store agent info for later
    echo "$agent_name" > "${LOG_DIR}/.${TASK_ID}.agent"
    
    success "Agent registered"
    return 0
}

################################################################################
# File Reservation
################################################################################

reserve_files() {
    log "Reserving files for task $TASK_ID..."
    
    # Create a reservation marker file
    local reservation_file="${LOG_DIR}/.${TASK_ID}.reserved"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$reservation_file" << EOF
{
  "task_id": "$TASK_ID",
  "agent_name": "agent-${TASK_ID}",
  "reserved_at": "$timestamp",
  "ttl_seconds": 3600,
  "paths": ["src/**", "test/**"]
}
EOF
    
    log "File reservation marker created"
    return 0
}

################################################################################
# Claude Code Launch
################################################################################

launch_claude_code() {
    log "Launching Claude Code in worktree..."
    
    cd "$WORKTREE_PATH"
    
    # Set environment variables for claude-code
    export CLAUDE_TASK_ID="$TASK_ID"
    export CLAUDE_AGENT_NAME="agent-${TASK_ID}"
    
    # Check if claude-code command is available
    if command -v code &> /dev/null; then
        # Use VS Code
        log "Launching VS Code..."
        code "$WORKTREE_PATH"
    elif command -v claude-code &> /dev/null; then
        # Use claude-code CLI
        log "Launching claude-code CLI..."
        exec claude-code --project "$WORKTREE_PATH"
    else
        # Fallback: create an interactive shell
        warn "Claude Code not found, launching bash shell"
        exec bash
    fi
}

################################################################################
# Task Status Updates
################################################################################

update_task_status() {
    local status="$1"
    local message="$2"
    
    log "Updating task status: $status"
    
    if command -v bd &> /dev/null; then
        if [[ -n "$message" ]]; then
            bd update "$TASK_ID" --status "$status" -d "$message" 2>/dev/null || true
        else
            bd update "$TASK_ID" --status "$status" 2>/dev/null || true
        fi
    fi
}

################################################################################
# Main Flow
################################################################################

main() {
    log "=== Agent Runner Started ==="
    log "Worktree: $WORKTREE_PATH"
    echo ""
    
    # Register with agent-mail
    if ! register_agent; then
        warn "Proceeding without Agent Mail"
    fi
    echo ""
    
    # Reserve files
    if ! reserve_files; then
        warn "Could not create file reservations"
    fi
    echo ""
    
    # Update task to in_progress
    update_task_status "in_progress" "Started: $(date)"
    
    # Launch Claude Code
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    launch_claude_code
    
    # Cleanup on exit
    local exit_code=$?
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ $exit_code -eq 0 ]]; then
        success "Claude Code session completed"
        update_task_status "completed" "Completed: $(date)"
    else
        warn "Claude Code session ended with exit code: $exit_code"
        update_task_status "blocked" "Session ended with code: $exit_code"
    fi
    
    log "Cleaning up..."
    rm -f "${LOG_DIR}/.${TASK_ID}.reserved"
    
    log "=== Agent Runner Finished ==="
    
    exit $exit_code
}

# Trap signals for clean shutdown
trap 'log "Received interrupt"; exit 130' SIGINT SIGTERM

main "$@"
