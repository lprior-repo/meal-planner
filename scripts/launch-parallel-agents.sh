#!/usr/bin/env bash

################################################################################
# Parallel Agent Launcher
# 
# Automates:
# 1. Creating git worktrees per Beads task
# 2. Launching Claude Code sessions in parallel
# 3. Coordinating via Agent Mail MCP
# 4. Managing via single Zellij session
#
# Usage:
#   ./scripts/launch-parallel-agents.sh [--max-agents N] [--existing] [--cleanup]
#
# Options:
#   --max-agents N    Limit to N agents (default: 12)
#   --existing        Use existing worktrees instead of creating new ones
#   --cleanup         Remove all worktrees and exit
#   --dry-run         Show what would happen without doing it
################################################################################

set -euo pipefail

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_AGENTS=${MAX_AGENTS:-12}
AGENT_MAIL_URL="http://127.0.0.1:8765"
WORKTREE_DIR="${PROJECT_ROOT}/.worktrees"
LOG_DIR="${PROJECT_ROOT}/.agent-logs"
EXISTING_ONLY=false
CLEANUP_MODE=false
DRY_RUN=false
ZELLIJ_SESSION_NAME="meal-planner-agents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[LAUNCHER]${NC} $*"
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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --max-agents) MAX_AGENTS="$2"; shift 2 ;;
        --existing) EXISTING_ONLY=true; shift ;;
        --cleanup) CLEANUP_MODE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# Ensure we're in the project root
cd "$PROJECT_ROOT"

# Check if beads is installed
if ! command -v bd &> /dev/null; then
    error "beads not found. Install with: cargo install --git https://github.com/steveyegge/beads"
    exit 1
fi

# Check if zellij is installed
if ! command -v zellij &> /dev/null; then
    error "zellij not found. Install with: cargo install zellij"
    exit 1
fi

# Create necessary directories
mkdir -p "$WORKTREE_DIR" "$LOG_DIR"

################################################################################
# Helper Functions
################################################################################

# Check if agent-mail is running
check_agent_mail() {
    if curl -s -f "$AGENT_MAIL_URL/health" > /dev/null 2>&1; then
        success "Agent Mail is running on $AGENT_MAIL_URL"
        return 0
    else
        warn "Agent Mail not accessible at $AGENT_MAIL_URL"
        warn "Start it with: am server start"
        return 1
    fi
}

# Get ready beads tasks as JSON
get_ready_tasks() {
    bd ready --json 2>/dev/null | jq -r '.[] | @base64' || echo ""
}

# Decode base64-encoded task (used by get_ready_tasks)
decode_task() {
    echo "$1" | base64 -d
}

# Get task ID from task JSON
get_task_id() {
    echo "$1" | jq -r '.id' 2>/dev/null || echo ""
}

# Get task title from task JSON
get_task_title() {
    echo "$1" | jq -r '.title // .name // "unknown"' 2>/dev/null || echo ""
}

# Create or verify git worktree for a task
setup_worktree() {
    local task_id="$1"
    local worktree_path="${WORKTREE_DIR}/${task_id}"
    
    if [[ -d "$worktree_path" ]]; then
        log "Worktree exists: $worktree_path"
        if [[ "$DRY_RUN" != "true" ]]; then
            # Ensure it's up-to-date
            cd "$worktree_path"
            git fetch origin main 2>/dev/null || true
            git rebase origin/main 2>/dev/null || true
            cd "$PROJECT_ROOT"
        fi
    else
        log "Creating worktree for $task_id..."
        if [[ "$DRY_RUN" != "true" ]]; then
            git worktree add "$worktree_path" --detach origin/main || {
                error "Failed to create worktree for $task_id"
                return 1
            }
            success "Created worktree: $worktree_path"
        fi
    fi
    
    echo "$worktree_path"
}

# Update beads task status to in_progress
update_task_status() {
    local task_id="$1"
    log "Marking $task_id as in_progress..."
    
    if [[ "$DRY_RUN" != "true" ]]; then
        if bd update "$task_id" --status in_progress --json > /dev/null 2>&1; then
            success "Updated $task_id status"
        else
            warn "Could not update $task_id status"
        fi
    fi
}

# Generate zellij layout dynamically
generate_zellij_layout() {
    local num_agents=$1
    local layout_file="${PROJECT_ROOT}/.zellij-agents.kdl"
    
    cat > "$layout_file" << 'EOF'
layout {
    default_tab_template {
        pane size=1 borderless=true {
            text: "Meal Planner Multi-Agent Development"
        }
    }
    tab {
EOF

    # Create panes for each agent
    local per_row=3
    local row=0
    local col=0
    
    for ((i=1; i<=num_agents; i++)); do
        if [[ $col -eq 0 ]]; then
            echo "        pane {" >> "$layout_file"
        fi
        
        # Calculate pane dimensions (simplified - adjust as needed)
        local pane_height=$((100 / ((num_agents + per_row - 1) / per_row)))
        local pane_width=$((100 / per_row))
        
        if [[ $col -lt $((per_row - 1)) ]]; then
            echo "            pane size=1 {" >> "$layout_file"
            col=$((col + 1))
        else
            echo "            pane {" >> "$layout_file"
            col=0
            row=$((row + 1))
        fi
        
        echo "                command: \"$PROJECT_ROOT/scripts/agent-runner.sh\" \"agent-$i\"" >> "$layout_file"
        echo "            }" >> "$layout_file"
    done
    
    cat >> "$layout_file" << 'EOF'
        }
    }
}
EOF

    echo "$layout_file"
}

# Launch Claude Code in a worktree (for use in zellij pane)
launch_claude_code() {
    local task_id="$1"
    local worktree_path="$2"
    local agent_name="agent-${task_id}"
    
    log "Launching Claude Code for $task_id in $worktree_path..."
    
    if [[ "$DRY_RUN" != "true" ]]; then
        # Create agent runner script for this task
        local agent_script="${PROJECT_ROOT}/.agent-runners/${task_id}.sh"
        mkdir -p "${PROJECT_ROOT}/.agent-runners"
        
        cat > "$agent_script" << SCRIPT
#!/usr/bin/env bash
set -euo pipefail

export CLAUDE_CODE_AGENT_NAME="$agent_name"
export CLAUDE_CODE_TASK_ID="$task_id"
export PROJECT_ROOT="$PROJECT_ROOT"

# Log to file
exec > >(tee "$LOG_DIR/${task_id}.log")
exec 2>&1

echo "=== Agent Runner: $agent_name ==="
echo "Task ID: $task_id"
echo "Worktree: $worktree_path"
echo "Timestamp: \$(date)"
echo ""

# Register with agent-mail before starting
echo "Registering with Agent Mail..."
if curl -s -f "$AGENT_MAIL_URL/health" > /dev/null 2>&1; then
    echo "Agent Mail is available"
    # The agent-mail registration will happen when Claude Code connects
else
    echo "Warning: Agent Mail not available"
fi

# Launch Claude Code in the worktree
cd "$worktree_path"
pwd
echo "Starting Claude Code session..."
exec code . --wait || sleep infinity
SCRIPT
        
        chmod +x "$agent_script"
        
        # Launch in background (zellij will manage the pane)
        "$agent_script" &
        
        success "Launched Claude Code for $task_id (PID: $!)"
    fi
}

# Cleanup all worktrees
cleanup_worktrees() {
    log "Cleaning up worktrees..."
    
    if [[ ! -d "$WORKTREE_DIR" ]]; then
        warn "No worktrees directory found"
        return 0
    fi
    
    local count=0
    for worktree in "$WORKTREE_DIR"/*; do
        if [[ -d "$worktree" ]]; then
            if [[ "$DRY_RUN" != "true" ]]; then
                git worktree remove "$worktree" --force 2>/dev/null || true
            fi
            count=$((count + 1))
            log "Removed: $(basename "$worktree")"
        fi
    done
    
    if [[ "$DRY_RUN" != "true" ]]; then
        rm -rf "$WORKTREE_DIR" "$PROJECT_ROOT/.agent-runners"
    fi
    
    success "Cleaned up $count worktrees"
}

################################################################################
# Main Workflow
################################################################################

main() {
    log "Starting Parallel Agent Launcher"
    log "Project: $PROJECT_ROOT"
    log "Max agents: $MAX_AGENTS"
    echo ""
    
    # Cleanup mode
    if [[ "$CLEANUP_MODE" == "true" ]]; then
        cleanup_worktrees
        log "Cleanup complete"
        return 0
    fi
    
    # Check Agent Mail
    if ! check_agent_mail; then
        warn "Continuing without Agent Mail coordination"
    fi
    echo ""
    
    # Get ready tasks from beads
    log "Fetching ready tasks from Beads..."
    local tasks_json=$(get_ready_tasks)
    
    if [[ -z "$tasks_json" ]]; then
        error "No ready tasks found"
        log "Run: bd ready"
        exit 1
    fi
    
    # Count and limit tasks
    local task_count=0
    local agent_count=0
    local agents=()
    
    while IFS= read -r task_b64; do
        if [[ -z "$task_b64" ]]; then
            continue
        fi
        
        if [[ $agent_count -ge $MAX_AGENTS ]]; then
            break
        fi
        
        task_count=$((task_count + 1))
        agents+=("$task_b64")
        agent_count=$((agent_count + 1))
    done <<< "$tasks_json"
    
    if [[ $agent_count -eq 0 ]]; then
        error "No ready tasks to process"
        exit 1
    fi
    
    success "Found $agent_count ready tasks (max: $MAX_AGENTS)"
    echo ""
    
    # Setup worktrees and tasks
    log "Setting up worktrees and task state..."
    local worktree_paths=()
    
    for task_b64 in "${agents[@]}"; do
        local task=$(decode_task "$task_b64")
        local task_id=$(get_task_id "$task")
        local task_title=$(get_task_title "$task")
        
        if [[ -z "$task_id" ]]; then
            warn "Invalid task, skipping"
            continue
        fi
        
        log "Processing: $task_id - $task_title"
        
        # Setup worktree
        local worktree_path=$(setup_worktree "$task_id")
        if [[ -z "$worktree_path" ]]; then
            continue
        fi
        worktree_paths+=("$worktree_path")
        
        # Update task status
        update_task_status "$task_id"
    done
    
    echo ""
    success "Setup complete: ${#worktree_paths[@]} worktrees ready"
    echo ""
    
    # Show summary
    log "Agent Summary:"
    for ((i=0; i<${#agents[@]}; i++)); do
        local task=$(decode_task "${agents[$i]}")
        local task_id=$(get_task_id "$task")
        local task_title=$(get_task_title "$task")
        echo "  [$((i+1))] $task_id - $task_title"
        echo "       Worktree: ${worktree_paths[$i]}"
    done
    echo ""
    
    # Generate zellij layout
    log "Generating Zellij layout..."
    local layout_file=$(generate_zellij_layout "${#agents[@]}")
    success "Layout: $layout_file"
    echo ""
    
    # Instructions for launching
    log "Next steps:"
    echo ""
    echo "  1. Review the worktrees:"
    echo "     git worktree list"
    echo ""
    echo "  2. Launch Zellij with agents:"
    echo "     zellij -s $ZELLIJ_SESSION_NAME --layout $layout_file"
    echo ""
    echo "  3. Monitor agent logs:"
    echo "     tail -f $LOG_DIR/*.log"
    echo ""
    echo "  4. Check Agent Mail in separate terminal:"
    echo "     am inbox   # Check messages"
    echo ""
    echo "  5. Update Beads status:"
    echo "     bd status  # See current status"
    echo ""
    echo "  6. Cleanup when done:"
    echo "     ./scripts/launch-parallel-agents.sh --cleanup"
    echo ""
}

main "$@"
