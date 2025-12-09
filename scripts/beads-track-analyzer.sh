#!/usr/bin/env bash
# =============================================================================
# Beads Track Analyzer
# =============================================================================
# Analyzes beads dependency graph to identify parallel execution tracks
#
# Features:
# - Parse `bv --robot-plan` output
# - Assign tasks to parallel tracks
# - Check track independence (dependency analysis)
# - Recommend worktree assignments
# - Detect file conflicts between tracks
#
# Usage:
#   ./beads-track-analyzer.sh analyze           # Analyze current plan
#   ./beads-track-analyzer.sh recommend         # Recommend assignments
#   ./beads-track-analyzer.sh conflicts         # Detect file conflicts
#   ./beads-track-analyzer.sh assign <track>    # Assign track to agent
# =============================================================================

set -euo pipefail

# Configuration
readonly POOL_STATE_FILE="/tmp/pool-state.json"
readonly TRACK_STATE_FILE="/tmp/track-assignments.json"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
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

log_track() {
    local track_id="$1"
    local status="$2"
    local details="${3:-}"

    case "$status" in
        INDEPENDENT)
            echo -e "${GREEN}✓${NC} ${CYAN}${track_id}${NC}: ${details}"
            ;;
        DEPENDENT)
            echo -e "${YELLOW}→${NC} ${CYAN}${track_id}${NC}: ${details}"
            ;;
        BLOCKED)
            echo -e "${RED}✗${NC} ${CYAN}${track_id}${NC}: ${details}"
            ;;
        *)
            echo -e "${BLUE}•${NC} ${CYAN}${track_id}${NC}: ${details}"
            ;;
    esac
}

# =============================================================================
# Track Analysis
# =============================================================================

get_robot_plan() {
    log_debug "Fetching robot plan from beads..."
    bv --robot-plan 2>/dev/null || echo '{"plan": {"tracks": []}}'
}

analyze_tracks() {
    log_info "Analyzing beads dependency graph..."

    local plan
    plan=$(get_robot_plan)

    local track_count
    track_count=$(echo "$plan" | jq '.plan.tracks | length')

    if [[ $track_count -eq 0 ]]; then
        log_warn "No parallel tracks found"
        return 0
    fi

    echo ""
    echo "=== TRACK ANALYSIS ==="
    echo "Total Tracks: $track_count"
    echo ""

    # Analyze each track
    local i=0
    while [[ $i -lt $track_count ]]; do
        local track
        track=$(echo "$plan" | jq ".plan.tracks[$i]")

        local track_id
        track_id=$(echo "$track" | jq -r '.track_id')

        local item_count
        item_count=$(echo "$track" | jq '.items | length')

        local reason
        reason=$(echo "$track" | jq -r '.reason')

        # Check if track has dependencies
        local has_deps=false
        local dep_count=0

        local j=0
        while [[ $j -lt $item_count ]]; do
            local unblocks
            unblocks=$(echo "$track" | jq ".items[$j].unblocks")

            if [[ "$unblocks" != "null" ]]; then
                has_deps=true
                dep_count=$((dep_count + $(echo "$unblocks" | jq 'length')))
            fi

            j=$((j + 1))
        done

        # Determine status
        local status="INDEPENDENT"
        if [[ $has_deps == true ]]; then
            status="DEPENDENT"
        fi

        log_track "$track_id" "$status" "${item_count} items, ${dep_count} dependencies - ${reason}"

        # Show items in track
        local k=0
        while [[ $k -lt $item_count ]]; do
            local item_id
            item_id=$(echo "$track" | jq -r ".items[$k].id")
            local item_title
            item_title=$(echo "$track" | jq -r ".items[$k].title")

            echo "    - $item_id: $item_title"

            k=$((k + 1))
        done

        echo ""

        i=$((i + 1))
    done
}

# =============================================================================
# Worktree Assignment Recommendations
# =============================================================================

recommend_assignments() {
    log_info "Generating worktree assignment recommendations..."

    local plan
    plan=$(get_robot_plan)

    local track_count
    track_count=$(echo "$plan" | jq '.plan.tracks | length')

    if [[ $track_count -eq 0 ]]; then
        log_warn "No tracks to assign"
        return 0
    fi

    # Get available worktrees from pool
    local available_count=0
    if [[ -f "$POOL_STATE_FILE" ]]; then
        available_count=$(jq '[.worktrees[] | select(.status == "available")] | length' "$POOL_STATE_FILE")
    fi

    echo ""
    echo "=== ASSIGNMENT RECOMMENDATIONS ==="
    echo "Available Worktrees: $available_count"
    echo "Parallel Tracks: $track_count"
    echo ""

    if [[ $available_count -eq 0 ]]; then
        log_error "No available worktrees - all agents queued"
        echo ""
        echo "Recommendation: Wait for worktree release or scale up pool"
        return 1
    fi

    # Calculate how many tracks can run in parallel
    local parallel_count=$((available_count < track_count ? available_count : track_count))

    echo "Can Run in Parallel: $parallel_count tracks"
    echo ""

    # Sort tracks by priority and independence
    # Independent tracks first, then by total priority of items
    local sorted_tracks
    sorted_tracks=$(echo "$plan" | jq -r '
        .plan.tracks
        | map(. + {
            "total_priority": ([.items[].priority] | add // 0),
            "is_independent": ([.items[].unblocks] | all(. == null))
        })
        | sort_by([.is_independent | not, -.total_priority])
        | to_entries[]
        | "\(.key)|\(.value.track_id)|\(.value.is_independent)|\(.value.total_priority)"
    ')

    echo "Recommended Assignment Order:"
    echo ""

    local assignment_num=1
    while IFS='|' read -r idx track_id is_independent priority; do
        if [[ $assignment_num -le $parallel_count ]]; then
            local status_icon="✓"
            local status_color="$GREEN"
            local assignment="Assign to worktree $assignment_num"
        else
            local status_icon="⏸"
            local status_color="$YELLOW"
            local assignment="Queue (wait for slot)"
        fi

        local independence_label="Independent"
        if [[ "$is_independent" == "false" ]]; then
            independence_label="Has dependencies"
        fi

        echo -e "${status_color}${status_icon}${NC} ${CYAN}${track_id}${NC} → ${assignment} (${independence_label}, priority: ${priority})"

        assignment_num=$((assignment_num + 1))
    done <<< "$sorted_tracks"

    echo ""

    # Estimate completion time
    if [[ $track_count -gt $parallel_count ]]; then
        local queue_depth=$((track_count - parallel_count))
        log_warn "Queue depth: $queue_depth tracks"
        echo "   Estimate: ~$((queue_depth * 30))s wait for queued tracks (30s avg per track)"
        echo ""
    fi
}

# =============================================================================
# File Conflict Detection
# =============================================================================

detect_file_conflicts() {
    log_info "Detecting potential file conflicts between tracks..."

    local plan
    plan=$(get_robot_plan)

    local track_count
    track_count=$(echo "$plan" | jq '.plan.tracks | length')

    if [[ $track_count -eq 0 ]]; then
        log_warn "No tracks to analyze"
        return 0
    fi

    echo ""
    echo "=== FILE CONFLICT ANALYSIS ==="
    echo ""

    # For each track, estimate which files it might touch
    # Based on issue title keywords
    local i=0
    declare -A track_files

    while [[ $i -lt $track_count ]]; do
        local track
        track=$(echo "$plan" | jq ".plan.tracks[$i]")

        local track_id
        track_id=$(echo "$track" | jq -r '.track_id')

        # Extract file patterns from titles
        local files=""

        local item_count
        item_count=$(echo "$track" | jq '.items | length')

        local j=0
        while [[ $j -lt $item_count ]]; do
            local title
            title=$(echo "$track" | jq -r ".items[$j].title")

            # Infer file patterns from title keywords
            if echo "$title" | grep -qi "migration"; then
                files="${files}gleam/migrations_pg/*.sql "
            fi

            if echo "$title" | grep -qi "storage\|database"; then
                files="${files}gleam/src/meal_planner/storage.gleam "
            fi

            if echo "$title" | grep -qi "web\|handler\|route"; then
                files="${files}gleam/src/meal_planner/web/*.gleam "
            fi

            if echo "$title" | grep -qi "ui\|component\|template"; then
                files="${files}gleam/src/meal_planner/ui/*.gleam "
            fi

            if echo "$title" | grep -qi "test"; then
                files="${files}gleam/test/**/*.gleam "
            fi

            if echo "$title" | grep -qi "actor\|scheduler"; then
                files="${files}gleam/src/meal_planner/actors/*.gleam "
            fi

            j=$((j + 1))
        done

        if [[ -n "$files" ]]; then
            track_files["$track_id"]="$files"
        else
            track_files["$track_id"]="(unknown)"
        fi

        i=$((i + 1))
    done

    # Check for overlaps
    local conflicts_found=false

    for track_id_a in "${!track_files[@]}"; do
        local files_a="${track_files[$track_id_a]}"

        for track_id_b in "${!track_files[@]}"; do
            if [[ "$track_id_a" == "$track_id_b" ]]; then
                continue
            fi

            # Skip if we've already checked this pair
            if [[ "$track_id_a" > "$track_id_b" ]]; then
                continue
            fi

            local files_b="${track_files[$track_id_b]}"

            # Check for common patterns
            local overlap=""
            for pattern_a in $files_a; do
                for pattern_b in $files_b; do
                    if [[ "$pattern_a" == "$pattern_b" ]]; then
                        overlap="${overlap}${pattern_a} "
                    fi
                done
            done

            if [[ -n "$overlap" ]]; then
                conflicts_found=true
                log_warn "Potential conflict: ${track_id_a} ↔ ${track_id_b}"
                echo "   Overlapping files: ${overlap}"
                echo ""
            fi
        done
    done

    if [[ $conflicts_found == false ]]; then
        log_info "No obvious file conflicts detected"
        echo ""
    else
        echo "Recommendation: Use file reservations to coordinate overlapping tracks"
        echo ""
    fi

    # Show file patterns per track
    echo "=== ESTIMATED FILE PATTERNS PER TRACK ==="
    echo ""

    for track_id in $(echo "${!track_files[@]}" | tr ' ' '\n' | sort); do
        local files="${track_files[$track_id]}"
        echo -e "${CYAN}${track_id}${NC}: ${files}"
    done

    echo ""
}

# =============================================================================
# Track Assignment Management
# =============================================================================

init_track_state() {
    if [[ ! -f "$TRACK_STATE_FILE" ]]; then
        cat > "$TRACK_STATE_FILE" << 'EOF'
{
  "assignments": []
}
EOF
    fi
}

assign_track() {
    local track_id="$1"
    local agent_name="${2:-}"
    local worktree_id="${3:-}"

    init_track_state

    if [[ -z "$agent_name" ]] || [[ -z "$worktree_id" ]]; then
        log_error "Usage: assign <track-id> <agent-name> <worktree-id>"
        return 1
    fi

    local state
    state=$(cat "$TRACK_STATE_FILE")

    # Add assignment
    state=$(echo "$state" | jq \
        --arg track "$track_id" \
        --arg agent "$agent_name" \
        --arg wt "$worktree_id" \
        --arg ts "$(date -Iseconds)" \
        '.assignments += [{
            "track_id": $track,
            "agent": $agent,
            "worktree": $wt,
            "assigned_at": $ts
        }]')

    echo "$state" > "$TRACK_STATE_FILE"

    log_info "Assigned $track_id to $agent_name (worktree: $worktree_id)"
}

show_assignments() {
    init_track_state

    local state
    state=$(cat "$TRACK_STATE_FILE")

    local count
    count=$(echo "$state" | jq '.assignments | length')

    echo ""
    echo "=== CURRENT TRACK ASSIGNMENTS ==="
    echo "Total: $count"
    echo ""

    if [[ $count -eq 0 ]]; then
        log_info "No active assignments"
        echo ""
        return 0
    fi

    echo "$state" | jq -r '.assignments[] | "\(.track_id) → \(.agent) @ \(.worktree) (since \(.assigned_at))"'
    echo ""
}

# =============================================================================
# Main Command Dispatcher
# =============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        analyze)
            analyze_tracks
            ;;
        recommend)
            recommend_assignments
            ;;
        conflicts)
            detect_file_conflicts
            ;;
        assign)
            shift
            assign_track "$@"
            ;;
        assignments)
            show_assignments
            ;;
        full)
            # Full analysis report
            analyze_tracks
            echo ""
            detect_file_conflicts
            echo ""
            recommend_assignments
            ;;
        *)
            echo "Beads Track Analyzer"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  analyze             Analyze dependency tracks"
            echo "  recommend           Recommend worktree assignments"
            echo "  conflicts           Detect file conflicts between tracks"
            echo "  assign <track> <agent> <worktree>  Assign track to agent"
            echo "  assignments         Show current assignments"
            echo "  full                Full analysis report (all above)"
            echo ""
            exit 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
