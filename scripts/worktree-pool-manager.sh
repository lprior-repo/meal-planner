#!/usr/bin/env bash
# =============================================================================
# Worktree Pool Manager
# =============================================================================
# Manages a dynamic pool of 3-10 git worktrees for parallel agent execution
#
# Features:
# - Pool initialization (3 worktrees by default)
# - Agent queueing with priority
# - Dynamic scaling (3→10 based on load)
# - Resource monitoring integration
# - Beads isolation per worktree
#
# Usage:
#   ./worktree-pool-manager.sh init [--size=3]
#   ./worktree-pool-manager.sh acquire <agent-name> <task-id> [--priority=1]
#   ./worktree-pool-manager.sh release <wt-id> <agent-name>
#   ./worktree-pool-manager.sh status
#   ./worktree-pool-manager.sh scale-up
#   ./worktree-pool-manager.sh scale-down
# =============================================================================

set -euo pipefail

# Configuration
readonly POOL_STATE_FILE="/tmp/pool-state.json"
readonly POOL_LOCK_FILE="/tmp/pool-state.lock"
readonly WORKTREE_BASE_DIR=".agent-worktrees"
readonly MIN_POOL_SIZE=3
readonly MAX_POOL_SIZE=10
readonly SCALE_CHECK_INTERVAL=60  # seconds
readonly QUEUE_WAIT_THRESHOLD=3   # agents waiting before scale-up
readonly LOCK_TIMEOUT=30          # seconds to wait for lock

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# =============================================================================
# State Management
# =============================================================================

init_pool_state() {
    if [[ ! -f "$POOL_STATE_FILE" ]]; then
        cat > "$POOL_STATE_FILE" << 'EOF'
{
  "worktrees": [],
  "queue": [],
  "metrics": {
    "total_tasks_completed": 0,
    "avg_wait_time_sec": 0,
    "created_at": ""
  }
}
EOF
        jq ".metrics.created_at = \"$(date -Iseconds)\"" "$POOL_STATE_FILE" > "${POOL_STATE_FILE}.tmp"
        mv "${POOL_STATE_FILE}.tmp" "$POOL_STATE_FILE"
        log_info "Pool state initialized"
    fi
}

get_pool_state() {
    if [[ ! -f "$POOL_STATE_FILE" ]]; then
        init_pool_state
    fi
    cat "$POOL_STATE_FILE"
}

update_pool_state() {
    local new_state="$1"
    echo "$new_state" | jq '.' > "$POOL_STATE_FILE"
}

# =============================================================================
# Worktree Management
# =============================================================================

create_worktree() {
    local wt_id="$1"
    local wt_path="${WORKTREE_BASE_DIR}/pool-${wt_id}"
    local wt_branch="pool-${wt_id}/work"
    local db_name="meal_planner_${wt_id}"

    log_info "Creating worktree: ${wt_id}"

    # Create worktree directory
    mkdir -p "$WORKTREE_BASE_DIR"

    # Create git worktree
    if git worktree add -b "$wt_branch" "$wt_path" integration 2>/dev/null; then
        log_info "  ✓ Git worktree created at ${wt_path}"
    else
        log_warn "  Branch ${wt_branch} already exists, using existing branch"
        git worktree add "$wt_path" "$wt_branch"
    fi

    # Initialize beads in worktree
    (
        cd "$wt_path"

        # Update beads config with unique prefix
        if [[ -f ".beads/config.yaml" ]]; then
            # Update existing config
            if command -v yq &> /dev/null; then
                yq eval ".issue-prefix = \"meal-planner-${wt_id}\"" -i .beads/config.yaml
                yq eval ".sync-branch = \"integration\"" -i .beads/config.yaml
            else
                # Fallback: sed replacement
                sed -i "s/issue-prefix:.*/issue-prefix: meal-planner-${wt_id}/" .beads/config.yaml || true
                sed -i "s/sync-branch:.*/sync-branch: integration/" .beads/config.yaml || true
            fi
        fi

        # Create environment file
        cat > .env.worktree << EOF
DATABASE_NAME=${db_name}
WORKTREE_ID=${wt_id}
POOL_STATE_FILE=${POOL_STATE_FILE}
EOF

        log_info "  ✓ Beads configured with prefix: meal-planner-${wt_id}"
        log_info "  ✓ Environment configured for database: ${db_name}"
    )

    # Add worktree to pool state
    local state
    state=$(get_pool_state)
    state=$(echo "$state" | jq \
        --arg id "$wt_id" \
        --arg path "$wt_path" \
        --arg db "$db_name" \
        '.worktrees += [{
            "id": $id,
            "path": $path,
            "status": "available",
            "current_agent": null,
            "track_id": null,
            "db_name": $db,
            "task_count": 0,
            "created_at": (now | todate)
        }]')
    update_pool_state "$state"

    log_info "  ✓ Worktree ${wt_id} added to pool"
}

remove_worktree() {
    local wt_id="$1"
    local wt_path="${WORKTREE_BASE_DIR}/pool-${wt_id}"

    log_info "Removing worktree: ${wt_id}"

    # Remove git worktree
    if git worktree remove "$wt_path" --force 2>/dev/null; then
        log_info "  ✓ Git worktree removed"
    else
        log_warn "  Failed to remove worktree (may not exist)"
    fi

    # Remove from pool state
    local state
    state=$(get_pool_state)
    state=$(echo "$state" | jq --arg id "$wt_id" '.worktrees = (.worktrees | map(select(.id != $id)))')
    update_pool_state "$state"

    log_info "  ✓ Worktree ${wt_id} removed from pool"
}

# =============================================================================
# Pool Operations
# =============================================================================

pool_init() {
    local size="${1:-$MIN_POOL_SIZE}"

    log_info "Initializing pool with ${size} worktrees"

    init_pool_state

    # Create worktrees
    for i in $(seq 1 "$size"); do
        local wt_id="wt-${i}"
        create_worktree "$wt_id"
    done

    log_info "Pool initialization complete!"
    pool_status
}

pool_acquire() {
    local agent_name="$1"
    local task_id="$2"
    local priority="${3:-1}"

    log_info "Agent ${agent_name} requesting worktree for task ${task_id} (priority: ${priority})"

    # CRITICAL: Use file locking to prevent race conditions
    (
        flock -x -w "$LOCK_TIMEOUT" 200 || {
            log_error "Failed to acquire pool lock after ${LOCK_TIMEOUT}s"
            return 1
        }

        local state
        state=$(get_pool_state)

        # Check for available worktree
        local available_wt
        available_wt=$(echo "$state" | jq -r '.worktrees[] | select(.status == "available") | .id' | head -1)

        if [[ -n "$available_wt" ]]; then
            # Assign worktree
            state=$(echo "$state" | jq \
                --arg id "$available_wt" \
                --arg agent "$agent_name" \
                --arg task "$task_id" \
                '.worktrees = (.worktrees | map(
                    if .id == $id then
                        .status = "in_use" |
                        .current_agent = $agent |
                        .current_task = $task |
                        .task_count += 1 |
                        .last_used = (now | todate)
                    else . end
                ))')
            update_pool_state "$state"

            log_info "✓ Assigned worktree ${available_wt} to agent ${agent_name}"
            echo "$available_wt"
            return 0
        else
            # Queue the agent
            state=$(echo "$state" | jq \
                --arg agent "$agent_name" \
                --arg task "$task_id" \
                --argjson priority "$priority" \
                '.queue += [{
                    "agent_id": $agent,
                    "task_id": $task,
                    "priority": $priority,
                    "queued_at": (now | todate)
                }] | .queue |= sort_by(.priority) | reverse')
            update_pool_state "$state"

            log_warn "No available worktrees - agent ${agent_name} queued (position: $(echo "$state" | jq '.queue | length'))"

            echo "queued"
            return 1
        fi
    ) 200>"$POOL_LOCK_FILE"

    # Scale-up outside lock to prevent deadlock
    local result=$?
    if [[ $result -eq 1 ]]; then
        local state
        state=$(get_pool_state)
        local queue_size
        queue_size=$(echo "$state" | jq '.queue | length')
        if [[ $queue_size -ge $QUEUE_WAIT_THRESHOLD ]]; then
            log_info "Queue threshold reached ($queue_size >= $QUEUE_WAIT_THRESHOLD), attempting scale-up"
            pool_scale_up || log_warn "Scale-up failed or not possible"
        fi
    fi
    return $result
}


pool_release() {
    local wt_id="$1"
    local agent_name="$2"

    log_info "Releasing worktree ${wt_id} from agent ${agent_name}"

    # CRITICAL: Use file locking for atomic release
    (
        flock -x -w "$LOCK_TIMEOUT" 200 || {
            log_error "Failed to acquire pool lock after ${LOCK_TIMEOUT}s"
            return 1
        }

        local state
        state=$(get_pool_state)

        # Mark worktree as available
        state=$(echo "$state" | jq \
            --arg id "$wt_id" \
            '.worktrees = (.worktrees | map(
                if .id == $id then
                    .status = "available" |
                    .current_agent = null |
                    .current_task = null
                else . end
            )) | .metrics.total_tasks_completed += 1')
        update_pool_state "$state"

        log_info "✓ Worktree ${wt_id} released"
    ) 200>"$POOL_LOCK_FILE"

    # Process queue outside lock to prevent deadlock
    process_queue
}


process_queue() {
    # CRITICAL: Use file locking for atomic queue processing
    (
        flock -x -w "$LOCK_TIMEOUT" 200 || {
            log_error "Failed to acquire pool lock after ${LOCK_TIMEOUT}s"
            return 1
        }

        local state
        state=$(get_pool_state)

        local queue_size
        queue_size=$(echo "$state" | jq '.queue | length')

        if [[ $queue_size -eq 0 ]]; then
            log_debug "Queue is empty, nothing to process"
            return 0
        fi

        log_info "Processing queue (${queue_size} agents waiting)"

        # Get next agent from queue (highest priority)
        local next_agent
        next_agent=$(echo "$state" | jq -r '.queue[0].agent_id')
        local next_task
        next_task=$(echo "$state" | jq -r '.queue[0].task_id')

        # Try to acquire worktree for queued agent
        local available_wt
        available_wt=$(echo "$state" | jq -r '.worktrees[] | select(.status == "available") | .id' | head -1)

        if [[ -n "$available_wt" ]]; then
            # Assign worktree and remove from queue
            state=$(echo "$state" | jq \
                --arg id "$available_wt" \
                --arg agent "$next_agent" \
                --arg task "$next_task" \
                '.worktrees = (.worktrees | map(
                    if .id == $id then
                        .status = "in_use" |
                        .current_agent = $agent |
                        .current_task = $task |
                        .task_count += 1 |
                        .last_used = (now | todate)
                    else . end
                )) | .queue = .queue[1:]')
            update_pool_state "$state"

            log_info "✓ Assigned worktree ${available_wt} to queued agent ${next_agent}"
        fi
    ) 200>"$POOL_LOCK_FILE"
}


pool_scale_up() {
    local state
    state=$(get_pool_state)

    local current_size
    current_size=$(echo "$state" | jq '.worktrees | length')

    if [[ $current_size -ge $MAX_POOL_SIZE ]]; then
        log_warn "Cannot scale up - already at max pool size ($MAX_POOL_SIZE)"
        return 1
    fi

    local new_id=$((current_size + 1))
    local wt_id="wt-${new_id}"

    log_info "Scaling up pool: ${current_size} → ${new_id}"
    create_worktree "$wt_id"

    # Process queue with new worktree
    process_queue

    return 0
}

pool_scale_down() {
    local state
    state=$(get_pool_state)

    local current_size
    current_size=$(echo "$state" | jq '.worktrees | length')

    if [[ $current_size -le $MIN_POOL_SIZE ]]; then
        log_warn "Cannot scale down - already at min pool size ($MIN_POOL_SIZE)"
        return 1
    fi

    # Find idle worktree (available for > 10 minutes)
    local idle_wt
    idle_wt=$(echo "$state" | jq -r \
        --arg threshold "$(date -d '10 minutes ago' -Iseconds)" \
        '.worktrees[] | select(.status == "available" and .last_used < $threshold) | .id' | head -1)

    if [[ -n "$idle_wt" ]]; then
        log_info "Scaling down pool - removing idle worktree: ${idle_wt}"
        remove_worktree "$idle_wt"
        return 0
    else
        log_debug "No idle worktrees found for scale-down"
        return 1
    fi
}

pool_status() {
    local state
    state=$(get_pool_state)

    local total
    total=$(echo "$state" | jq '.worktrees | length')
    local available
    available=$(echo "$state" | jq '[.worktrees[] | select(.status == "available")] | length')
    local in_use
    in_use=$(echo "$state" | jq '[.worktrees[] | select(.status == "in_use")] | length')
    local queue_size
    queue_size=$(echo "$state" | jq '.queue | length')

    echo ""
    echo "=== WORKTREE POOL STATUS ==="
    echo "Pool Size: ${in_use}/${total} (max: ${MAX_POOL_SIZE})"
    echo "Available: ${available} worktrees"
    echo "In Use: ${in_use} worktrees"
    echo "Queue: ${queue_size} agents waiting"
    echo ""

    if [[ $in_use -gt 0 ]]; then
        echo "Active Worktrees:"
        echo "$state" | jq -r '.worktrees[] | select(.status == "in_use") | "  - \(.id): \(.current_agent) (task: \(.current_task))"'
        echo ""
    fi

    if [[ $queue_size -gt 0 ]]; then
        echo "Queued Agents:"
        echo "$state" | jq -r '.queue[] | "  - \(.agent_id) (task: \(.task_id), priority: \(.priority))"'
        echo ""
    fi
}

# =============================================================================
# Main Command Dispatcher
# =============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        init)
            local size="${2:-$MIN_POOL_SIZE}"
            size="${size#--size=}"
            pool_init "$size"
            ;;
        acquire)
            local agent="${2:-}"
            local task="${3:-}"
            local priority="${4:-1}"
            priority="${priority#--priority=}"

            if [[ -z "$agent" ]] || [[ -z "$task" ]]; then
                log_error "Usage: $0 acquire <agent-name> <task-id> [--priority=1]"
                exit 1
            fi

            pool_acquire "$agent" "$task" "$priority"
            ;;
        release)
            local wt_id="${2:-}"
            local agent="${3:-}"

            if [[ -z "$wt_id" ]] || [[ -z "$agent" ]]; then
                log_error "Usage: $0 release <wt-id> <agent-name>"
                exit 1
            fi

            pool_release "$wt_id" "$agent"
            ;;
        status)
            pool_status
            ;;
        scale-up)
            pool_scale_up
            ;;
        scale-down)
            pool_scale_down
            ;;
        *)
            echo "Worktree Pool Manager"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init [--size=3]                      Initialize pool with N worktrees"
            echo "  acquire <agent> <task> [--priority]  Acquire worktree for agent"
            echo "  release <wt-id> <agent>              Release worktree"
            echo "  status                                Show pool status"
            echo "  scale-up                              Add worktree to pool"
            echo "  scale-down                            Remove idle worktree"
            echo ""
            exit 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
