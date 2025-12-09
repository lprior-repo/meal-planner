#!/usr/bin/env bash
# =============================================================================
# Agent Coordinator - Worktree Pool + Agent Mail Integration
# =============================================================================
# Orchestrates multi-agent parallel execution with Agent Mail coordination
#
# Features:
# - Agent Mail registration and messaging
# - Worktree pool integration
# - File reservation coordination
# - Beads track assignment
# - Resource monitoring
# - Conflict resolution
#
# Usage:
#   ./agent-coordinator.sh init                           # Initialize system
#   ./agent-coordinator.sh spawn <count> <track-filter>   # Spawn agents for tracks
#   ./agent-coordinator.sh status                         # Show system status
#   ./agent-coordinator.sh assign <agent> <track>         # Manual assignment
#   ./agent-coordinator.sh monitor                        # Start monitoring
#   ./agent-coordinator.sh cleanup                        # Cleanup resources
# =============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="/home/lewis/src/meal-planner"
readonly POOL_MANAGER="${SCRIPT_DIR}/worktree-pool-manager.sh"
readonly TRACK_ANALYZER="${SCRIPT_DIR}/beads-track-analyzer.sh"
readonly RESOURCE_MONITOR="${SCRIPT_DIR}/resource-monitor.sh"
readonly COORDINATION_STATE="/tmp/agent-coordination-state.json"

# Agent Mail settings
readonly AGENT_MAIL_PROJECT="$PROJECT_ROOT"
readonly AGENT_MAIL_PROGRAM="claude-code"
readonly AGENT_MAIL_MODEL="claude-sonnet-4-5"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# =============================================================================
# Logging
# =============================================================================

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_agent() {
    local agent_name="$1"
    local message="$2"
    echo -e "${CYAN}[${agent_name}]${NC} ${message}"
}

# =============================================================================
# State Management
# =============================================================================

init_coordination_state() {
    if [[ ! -f "$COORDINATION_STATE" ]]; then
        cat > "$COORDINATION_STATE" << 'EOF'
{
  "agents": [],
  "track_assignments": {},
  "file_reservations": {},
  "messages": [],
  "started_at": ""
}
EOF
        jq ".started_at = \"$(date -Iseconds)\"" "$COORDINATION_STATE" > "${COORDINATION_STATE}.tmp"
        mv "${COORDINATION_STATE}.tmp" "$COORDINATION_STATE"
    fi
}

get_state() {
    init_coordination_state
    cat "$COORDINATION_STATE"
}

update_state() {
    echo "$1" | jq '.' > "$COORDINATION_STATE"
}

# =============================================================================
# Agent Mail Integration
# =============================================================================

register_agent() {
    local agent_name="$1"
    local task_description="$2"

    log_info "Registering agent: ${agent_name}"

    # Note: This would call the MCP Agent Mail server
    # For now, we'll simulate the registration
    local state
    state=$(get_state)

    state=$(echo "$state" | jq \
        --arg name "$agent_name" \
        --arg task "$task_description" \
        --arg ts "$(date -Iseconds)" \
        '.agents += [{
            "name": $name,
            "task": $task,
            "registered_at": $ts,
            "status": "idle",
            "worktree": null,
            "track_id": null
        }]')

    update_state "$state"
    log_success "Agent ${agent_name} registered"
}

send_coordination_message() {
    local from_agent="$1"
    local to_agent="$2"
    local subject="$3"
    local body="$4"
    local thread_id="${5:-}"

    log_agent "$from_agent" "→ ${to_agent}: ${subject}"

    local state
    state=$(get_state)

    state=$(echo "$state" | jq \
        --arg from "$from_agent" \
        --arg to "$to_agent" \
        --arg subj "$subject" \
        --arg body "$body" \
        --arg thread "$thread_id" \
        --arg ts "$(date -Iseconds)" \
        '.messages += [{
            "from": $from,
            "to": $to,
            "subject": $subj,
            "body": $body,
            "thread_id": $thread,
            "sent_at": $ts
        }]')

    update_state "$state"
}

reserve_files_for_track() {
    local agent_name="$1"
    local track_id="$2"
    local file_patterns="$3"

    log_info "Reserving files for ${agent_name} on ${track_id}"
    log_info "  Patterns: ${file_patterns}"

    # Store reservation in state
    local state
    state=$(get_state)

    state=$(echo "$state" | jq \
        --arg agent "$agent_name" \
        --arg track "$track_id" \
        --arg patterns "$file_patterns" \
        --arg ts "$(date -Iseconds)" \
        ".file_reservations[\"$track_id\"] = {
            \"agent\": \$agent,
            \"patterns\": \$patterns,
            \"reserved_at\": \$ts,
            \"ttl_seconds\": 3600
        }")

    update_state "$state"

    # In production, this would call:
    # mcp__mcp_agent_mail__file_reservation_paths with the patterns
}

release_file_reservation() {
    local track_id="$1"

    log_info "Releasing file reservation for ${track_id}"

    local state
    state=$(get_state)

    state=$(echo "$state" | jq "del(.file_reservations[\"$track_id\"])")
    update_state "$state"
}

# =============================================================================
# Worktree Assignment
# =============================================================================

assign_agent_to_worktree() {
    local agent_name="$1"
    local track_id="$2"

    log_info "Assigning ${agent_name} to track ${track_id}"

    # Acquire worktree from pool
    local wt_id
    wt_id=$("$POOL_MANAGER" acquire "$agent_name" "$track_id" || echo "queued")

    if [[ "$wt_id" == "queued" ]]; then
        log_warn "No available worktrees - agent queued"
        return 1
    fi

    # Update coordination state
    local state
    state=$(get_state)

    state=$(echo "$state" | jq \
        --arg agent "$agent_name" \
        --arg wt "$wt_id" \
        --arg track "$track_id" \
        --arg ts "$(date -Iseconds)" \
        '(.agents[] | select(.name == $agent)) |= {
            name: $agent,
            status: "working",
            worktree: $wt,
            track_id: $track,
            assigned_at: $ts,
            task: .task,
            registered_at: .registered_at
        } |
        .track_assignments[$track] = {
            "agent": $agent,
            "worktree": $wt,
            "assigned_at": $ts
        }')

    update_state "$state"

    # Reserve files for this track
    local file_patterns
    file_patterns=$(infer_file_patterns "$track_id")
    reserve_files_for_track "$agent_name" "$track_id" "$file_patterns"

    # Send coordination message
    send_coordination_message \
        "coordinator" \
        "$agent_name" \
        "[${track_id}] Assignment" \
        "Assigned to worktree ${wt_id}. File patterns: ${file_patterns}" \
        "$track_id"

    log_success "Assigned ${agent_name} → ${wt_id} (${track_id})"
    echo "$wt_id"
}

infer_file_patterns() {
    local track_id="$1"

    # Get track details from beads
    local track_info
    track_info=$(bd show "$track_id" --format=json 2>/dev/null || echo '{"title":""}')

    local title
    title=$(echo "$track_info" | jq -r '.title // ""')

    local patterns=""

    # Infer from title keywords
    if echo "$title" | grep -qi "migration"; then
        patterns="${patterns}gleam/migrations_pg/*.sql "
    fi

    if echo "$title" | grep -qi "storage\|database"; then
        patterns="${patterns}gleam/src/meal_planner/storage*.gleam "
    fi

    if echo "$title" | grep -qi "web\|handler\|route"; then
        patterns="${patterns}gleam/src/meal_planner/web/**/*.gleam "
    fi

    if echo "$title" | grep -qi "ui\|component"; then
        patterns="${patterns}gleam/src/meal_planner/ui/**/*.gleam "
    fi

    if echo "$title" | grep -qi "test"; then
        patterns="${patterns}gleam/test/**/*.gleam "
    fi

    if echo "$title" | grep -qi "actor\|scheduler"; then
        patterns="${patterns}gleam/src/meal_planner/actors/*.gleam "
    fi

    if [[ -z "$patterns" ]]; then
        patterns="gleam/src/**/*.gleam"
    fi

    echo "$patterns"
}

release_agent_assignment() {
    local agent_name="$1"
    local wt_id="$2"
    local track_id="$3"

    log_info "Releasing ${agent_name} from ${wt_id}"

    # Release worktree back to pool
    "$POOL_MANAGER" release "$wt_id" "$agent_name"

    # Release file reservation
    release_file_reservation "$track_id"

    # Update state
    local state
    state=$(get_state)

    state=$(echo "$state" | jq \
        --arg agent "$agent_name" \
        '(.agents[] | select(.name == $agent)) |= {
            name: $agent,
            status: "idle",
            worktree: null,
            track_id: null,
            task: .task,
            registered_at: .registered_at
        }')

    update_state "$state"

    # Send completion message
    send_coordination_message \
        "$agent_name" \
        "coordinator" \
        "[${track_id}] Complete" \
        "Work completed on ${track_id}" \
        "$track_id"

    log_success "Released ${agent_name}"
}

# =============================================================================
# Track Selection
# =============================================================================

get_available_tracks() {
    local filter="${1:-independent}"

    log_info "Finding ${filter} tracks..."

    # Get tracks from beads analyzer
    local tracks_json
    tracks_json=$("$TRACK_ANALYZER" analyze 2>&1 | \
        grep -E "^track-" | \
        awk '{
            gsub(/\x1B\[[0-9;]*[mK]/, "");  # Strip ANSI codes
            print $2 " " $3 " " $4
        }' || echo "")

    local available_tracks=()

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi

        local track_name status
        track_name=$(echo "$line" | awk '{print $1}' | tr -d ':')
        status=$(echo "$line" | awk '{print $2}')

        # Filter based on criteria
        if [[ "$filter" == "independent" && "$status" =~ "INDEPENDENT" ]]; then
            available_tracks+=("$track_name")
        elif [[ "$filter" == "all" ]]; then
            available_tracks+=("$track_name")
        fi
    done <<< "$tracks_json"

    # If no tracks from analyzer, get from bd ready
    if [[ ${#available_tracks[@]} -eq 0 ]]; then
        log_warn "No tracks from analyzer, using bd ready"
        local ready_issues
        ready_issues=$(bd ready --json | jq -r '.[].id')

        for issue_id in $ready_issues; do
            available_tracks+=("$issue_id")
        done
    fi

    printf '%s\n' "${available_tracks[@]}"
}

# =============================================================================
# Orchestration Commands
# =============================================================================

cmd_init() {
    log_info "Initializing agent coordination system..."

    # Initialize worktree pool
    if [[ ! -f "/tmp/pool-state.json" ]]; then
        log_info "Initializing worktree pool with 4 worktrees"
        "$POOL_MANAGER" init 4
    else
        log_info "Worktree pool already initialized"
        "$POOL_MANAGER" status
    fi

    # Initialize resource monitor
    log_info "Initializing resource monitor"
    "$RESOURCE_MONITOR" check || true

    # Initialize coordination state
    init_coordination_state

    log_success "System initialized!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./agent-coordinator.sh spawn 4 independent"
    echo "  2. Monitor: ./agent-coordinator.sh status"
    echo "  3. Watch: ./agent-coordinator.sh monitor"
}

cmd_spawn() {
    local count="${1:-4}"
    local filter="${2:-independent}"

    log_info "Spawning ${count} agents for ${filter} tracks..."

    # Get available tracks
    local tracks
    mapfile -t tracks < <(get_available_tracks "$filter" | head -n "$count")

    if [[ ${#tracks[@]} -eq 0 ]]; then
        log_error "No available tracks found"
        return 1
    fi

    log_info "Found ${#tracks[@]} tracks to assign"

    # Register and assign agents
    local i=1
    for track_id in "${tracks[@]}"; do
        local agent_name="Agent-${i}"

        # Get track title for task description
        local task_desc
        task_desc=$(bd show "$track_id" --format=json 2>/dev/null | jq -r '.title // "Task execution"')

        # Register agent
        register_agent "$agent_name" "$task_desc"

        # Assign to worktree
        local wt_id
        if wt_id=$(assign_agent_to_worktree "$agent_name" "$track_id"); then
            log_success "${agent_name} → ${wt_id} → ${track_id}"

            # Print instructions for the agent
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${CYAN}${agent_name}${NC} - ${track_id}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Worktree: .agent-worktrees/pool-${wt_id#wt-}"
            echo "Task: ${task_desc}"
            echo ""
            echo "To execute:"
            echo "  cd .agent-worktrees/pool-${wt_id#wt-}"
            echo "  bd update ${track_id} --status=in_progress"
            echo "  # ... do work ..."
            echo "  bd close ${track_id}"
            echo "  git push"
            echo ""
        else
            log_warn "${agent_name} queued (no available worktree)"
        fi

        i=$((i + 1))
    done

    echo ""
    cmd_status
}

cmd_status() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  AGENT COORDINATION STATUS"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Worktree pool status
    "$POOL_MANAGER" status

    # Agent status
    local state
    state=$(get_state)

    local agent_count
    agent_count=$(echo "$state" | jq '.agents | length')

    if [[ $agent_count -gt 0 ]]; then
        echo "═══ AGENTS ═══"
        echo "$state" | jq -r '.agents[] |
            "\(.name): \(.status) | WT: \(.worktree // "none") | Track: \(.track_id // "none")"'
        echo ""
    fi

    # File reservations
    local res_count
    res_count=$(echo "$state" | jq '.file_reservations | length')

    if [[ $res_count -gt 0 ]]; then
        echo "═══ FILE RESERVATIONS ═══"
        echo "$state" | jq -r '.file_reservations | to_entries[] |
            "\(.key): \(.value.agent) | Patterns: \(.value.patterns)"'
        echo ""
    fi

    # Resource status
    echo "═══ RESOURCES ═══"
    "$RESOURCE_MONITOR" status
}

cmd_monitor() {
    log_info "Starting continuous monitoring (Ctrl+C to stop)..."

    # Start resource monitor daemon
    "$RESOURCE_MONITOR" start

    # Monitor loop
    while true; do
        clear
        cmd_status
        sleep 10
    done
}

cmd_cleanup() {
    log_info "Cleaning up coordination system..."

    # Stop resource monitor
    "$RESOURCE_MONITOR" stop || true

    # Release all agents
    local state
    state=$(get_state)

    local working_agents
    working_agents=$(echo "$state" | jq -r '.agents[] | select(.status == "working") | .name')

    for agent in $working_agents; do
        local wt_id track_id
        wt_id=$(echo "$state" | jq -r ".agents[] | select(.name == \"$agent\") | .worktree")
        track_id=$(echo "$state" | jq -r ".agents[] | select(.name == \"$agent\") | .track_id")

        if [[ -n "$wt_id" && "$wt_id" != "null" ]]; then
            release_agent_assignment "$agent" "$wt_id" "$track_id"
        fi
    done

    # Clean up state files
    rm -f "$COORDINATION_STATE"

    # Detect and cleanup resource leaks
    "$RESOURCE_MONITOR" detect-leaks
    "$RESOURCE_MONITOR" cleanup-leaks

    log_success "Cleanup complete"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        init)
            cmd_init
            ;;
        spawn)
            shift
            cmd_spawn "$@"
            ;;
        status)
            cmd_status
            ;;
        monitor)
            cmd_monitor
            ;;
        cleanup)
            cmd_cleanup
            ;;
        assign)
            local agent="${2:-}"
            local track="${3:-}"
            if [[ -z "$agent" || -z "$track" ]]; then
                log_error "Usage: $0 assign <agent-name> <track-id>"
                exit 1
            fi
            register_agent "$agent" "Manual assignment to $track"
            assign_agent_to_worktree "$agent" "$track"
            ;;
        *)
            cat << 'EOF'
Agent Coordinator - Worktree Pool + Agent Mail Integration

Usage: ./agent-coordinator.sh <command> [options]

Commands:
  init                              Initialize coordination system
  spawn <count> [filter]           Spawn N agents (filter: independent|all)
  status                            Show system status
  assign <agent> <track>           Manually assign agent to track
  monitor                           Continuous monitoring (Ctrl+C to stop)
  cleanup                           Cleanup all resources

Examples:
  ./agent-coordinator.sh init
  ./agent-coordinator.sh spawn 4 independent
  ./agent-coordinator.sh status
  ./agent-coordinator.sh monitor

EOF
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
