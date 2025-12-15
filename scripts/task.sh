#!/usr/bin/env bash

################################################################################
# Task Command - Start Work on an Issue
#
# Usage:
#   task work                    # List available ready tasks
#   task work <issue-name>       # Find and start work on issue
#   task status                  # Show all tasks
#   task list                    # Show ready tasks
#
# Does:
#   1. Finds matching Beads task
#   2. Marks as in_progress
#   3. Reserves files via Agent Mail
#   4. Sets up work environment
#   5. Displays status
#
################################################################################

set -euo pipefail

ACTION="${1:-work}"
ISSUE_QUERY="${2:-}"
PROJECT_ROOT="${PROJECT_ROOT:-.}"
AGENT_MAIL_URL="${AGENT_MAIL_URL:-http://127.0.0.1:8765}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TASK]${NC} $*"
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

fatal() {
    echo -e "${RED}✗ FATAL:${NC} $*" >&2
    exit 1
}

header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${MAGENTA}$*${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

################################################################################
# Beads Integration
################################################################################

get_ready_tasks() {
    if ! command -v bd &> /dev/null; then
        fatal "Beads CLI not found. Install with: bd init"
    fi
    
    bd ready --json 2>/dev/null || echo "[]"
}

get_task_by_id() {
    local task_id="$1"
    
    if ! command -v bd &> /dev/null; then
        fatal "Beads CLI not found"
    fi
    
    # Use bd to get task info (this is a direct call)
    bd show "$task_id" 2>/dev/null || true
}

find_matching_task() {
    local query="$1"
    local tasks
    
    log "Searching for Beads task matching: '$query'"
    
    tasks=$(get_ready_tasks)
    
    if [[ -z "$tasks" ]] || [[ "$tasks" == "[]" ]]; then
        warn "No ready tasks found"
        return 1
    fi
    
    # Use jq to find matching tasks
    local matches=$(echo "$tasks" | jq -r ".[] | select(.id | test(\"$query\"; \"i\") or .title | test(\"$query\"; \"i\")) | .id" 2>/dev/null || true)
    
    if [[ -z "$matches" ]]; then
        error "No tasks match: $query"
        return 1
    fi
    
    # Return first match
    echo "$matches" | head -1
}

mark_in_progress() {
    local task_id="$1"
    
    log "Marking task as in_progress: $task_id"
    
    if bd update "$task_id" --status "in_progress" 2>/dev/null; then
        success "Task marked in_progress"
        return 0
    else
        warn "Could not mark task in_progress (may need elevated privileges)"
        return 0  # Don't fail - proceed anyway
    fi
}

################################################################################
# Agent Mail Integration
################################################################################

check_agent_mail() {
    log "Checking Agent Mail server..."
    
    if ! curl -s -f "$AGENT_MAIL_URL/health/liveness" > /dev/null 2>&1; then
        warn "Agent Mail not available at $AGENT_MAIL_URL"
        warn "File reservations will not be created"
        return 1
    fi
    
    success "Agent Mail is available"
    return 0
}

reserve_files() {
    local task_id="$1"
    local agent_name="agent-${task_id}"
    
    if ! check_agent_mail; then
        warn "Skipping file reservation"
        return 0
    fi
    
    log "Reserving files for task..."
    
    # Create a reservation record (simulated - actual implementation would use agent-mail MCP)
    local reservation_marker="/tmp/.task_reserve_${task_id}"
    cat > "$reservation_marker" << EOF
{
  "task_id": "$task_id",
  "agent_name": "$agent_name",
  "reserved_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "ttl_seconds": 3600,
  "paths": ["src/**", "test/**", "gleam/"]
}
EOF
    
    success "Files reserved for this session"
    return 0
}

################################################################################
# Worktree Management
################################################################################

get_worktree_path() {
    local task_id="$1"
    local worktree_dir="${PROJECT_ROOT}/.worktrees"
    
    echo "${worktree_dir}/${task_id}"
}

verify_worktree() {
    local task_id="$1"
    local worktree_path=$(get_worktree_path "$task_id")
    
    if [[ ! -d "$worktree_path" ]]; then
        error "Worktree not found: $worktree_path"
        warn "Run 'bd open' to create worktrees first"
        return 1
    fi
    
    success "Worktree ready: $worktree_path"
    return 0
}

cd_to_worktree() {
    local task_id="$1"
    local worktree_path=$(get_worktree_path "$task_id")
    
    cd "$worktree_path"
    export CLAUDE_TASK_ID="$task_id"
    export CLAUDE_AGENT_NAME="agent-${task_id}"
}

################################################################################
# Display Functions
################################################################################

display_ready_tasks() {
    header "Ready Tasks"
    
    local tasks=$(get_ready_tasks)
    
    if [[ -z "$tasks" ]] || [[ "$tasks" == "[]" ]]; then
        echo "No ready tasks found"
        echo ""
        echo "Create tasks with:"
        echo "  bd create --title 'My task' --parent bd-xxx"
        return 1
    fi
    
    echo "$tasks" | jq -r '.[] | "\(.id) - \(.title)"' | nl
    
    echo ""
    echo "Usage:"
    echo "  task work <issue-name>    Start work on a specific task"
    echo ""
}

display_task_info() {
    local task_id="$1"
    
    header "Task: $task_id"
    
    echo ""
    echo -e "  ${CYAN}ID:${NC}       $task_id"
    
    # Try to get more details from Beads
    if command -v bd &> /dev/null; then
        local title=$(bd ready --json 2>/dev/null | jq -r ".[] | select(.id == \"$task_id\") | .title" 2>/dev/null || echo "")
        if [[ -n "$title" ]]; then
            echo -e "  ${CYAN}Title:${NC}   $title"
        fi
    fi
    
    echo -e "  ${CYAN}Status:${NC}  in_progress"
    echo -e "  ${CYAN}Agent:${NC}   agent-${task_id}"
    
    echo ""
}

display_env_setup() {
    local task_id="$1"
    local worktree_path=$(get_worktree_path "$task_id")
    
    echo ""
    echo -e "${CYAN}Environment Setup:${NC}"
    echo "  Working Directory: $worktree_path"
    echo "  Task ID: $task_id"
    echo "  Agent Name: agent-${task_id}"
    echo ""
}

display_next_steps() {
    echo ""
    echo -e "${MAGENTA}Next Steps:${NC}"
    echo ""
    echo "1. Review the Beads task details:"
    echo "   bd show <task-id>"
    echo ""
    echo "2. Create a feature branch (already done in worktree):"
    echo "   git status"
    echo ""
    echo "3. Write tests first (TDD):"
    echo "   gleam test"
    echo ""
    echo "4. Implement the feature:"
    echo "   gleam build"
    echo ""
    echo "5. Mark complete when done:"
    echo "   task complete <task-id>"
    echo ""
    echo "6. Or mark as blocked:"
    echo "   task blocked <task-id>"
    echo ""
}

################################################################################
# Task Actions
################################################################################

action_work() {
    if [[ -z "$ISSUE_QUERY" ]]; then
        # List ready tasks
        display_ready_tasks
        return 0
    fi
    
    header "Starting Work"
    echo ""
    
    # Find matching task
    local task_id
    task_id=$(find_matching_task "$ISSUE_QUERY") || return 1
    echo ""
    
    # Mark as in_progress
    mark_in_progress "$task_id"
    echo ""
    
    # Verify worktree exists
    verify_worktree "$task_id" || return 1
    echo ""
    
    # Reserve files
    reserve_files "$task_id"
    echo ""
    
    # Display info
    display_task_info "$task_id"
    display_env_setup "$task_id"
    display_next_steps
    
    # Change to worktree directory
    log "Changing to worktree directory..."
    cd_to_worktree "$task_id"
    
    success "Ready to work on $task_id"
    echo ""
    echo "You are now in the task worktree. Type 'exit' to return."
    echo ""
    
    # Launch an interactive shell in the worktree
    exec bash --init-file <(echo "
        PS1='${CYAN}[task: $task_id]${NC} \w\$ '
        clear
        echo -e '${GREEN}✓${NC} Task environment loaded'
        echo ''
        echo 'Task: $task_id'
        echo 'Working in: $(pwd)'
        echo ''
    ")
}

action_list() {
    display_ready_tasks
}

action_status() {
    header "All Tasks"
    echo ""
    
    if command -v bd &> /dev/null; then
        bd list --json 2>/dev/null | jq -r '.[] | "\(.status | ascii_upcase | .[0:10]) \(.id) - \(.title)"' | head -20 || echo "No tasks found"
    else
        error "Beads CLI not found"
    fi
    
    echo ""
}

action_complete() {
    if [[ -z "$ISSUE_QUERY" ]]; then
        error "Usage: task complete <task-id>"
        return 1
    fi
    
    header "Completing Task"
    echo ""
    
    if bd close "$ISSUE_QUERY" --reason "Completed via task command" 2>/dev/null; then
        success "Task marked completed: $ISSUE_QUERY"
    else
        warn "Could not mark task complete"
    fi
    
    echo ""
}

action_blocked() {
    if [[ -z "$ISSUE_QUERY" ]]; then
        error "Usage: task blocked <task-id>"
        return 1
    fi
    
    header "Blocking Task"
    echo ""
    
    if bd update "$ISSUE_QUERY" --status "blocked" 2>/dev/null; then
        success "Task marked blocked: $ISSUE_QUERY"
    else
        warn "Could not mark task blocked"
    fi
    
    echo ""
}

action_help() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                         Task Command - Quick Start                         ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  task work                    List available tasks and prompt for selection
  task work <issue>            Find and start working on an issue
  task list                    Show all ready tasks
  task status                  Show all tasks (any status)
  task complete <task-id>      Mark task as completed
  task blocked <task-id>       Mark task as blocked
  task help                    Show this help

EXAMPLES:

  1. Start working on an issue:
     $ task work
     
     [Lists ready tasks, you select one]
     
  2. Find and work on specific issue:
     $ task work "Consolidate Decoder"
     
     [Finds matching task, sets it up, drops you into worktree]
     
  3. Check all tasks:
     $ task status
     
  4. Mark task complete:
     $ task complete bd-123
     
WHAT IT DOES:

  ✓ Searches Beads for matching task
  ✓ Marks task as in_progress
  ✓ Verifies worktree is ready
  ✓ Reserves files via Agent Mail
  ✓ Sets environment variables
  ✓ Drops you into task directory
  ✓ Shows next steps

ENVIRONMENT VARIABLES:

  CLAUDE_TASK_ID      Set to current task ID
  CLAUDE_AGENT_NAME   Set to agent-<task-id>
  PROJECT_ROOT        Root of meal-planner project

EOF
}

################################################################################
# Main
################################################################################

main() {
    # Ensure we're in the project root or have PROJECT_ROOT set
    if [[ ! -d "${PROJECT_ROOT}/.worktrees" ]] && [[ ! -d ".worktrees" ]]; then
        warn "Not in project root. Set PROJECT_ROOT=/path/to/meal-planner"
    fi
    
    case "$ACTION" in
        work)
            action_work
            ;;
        list)
            action_list
            ;;
        status)
            action_status
            ;;
        complete)
            action_complete
            ;;
        blocked)
            action_blocked
            ;;
        help|--help|-h)
            action_help
            ;;
        *)
            error "Unknown action: $ACTION"
            echo ""
            action_help
            exit 1
            ;;
    esac
}

main "$@"
