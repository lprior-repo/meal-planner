#!/usr/bin/env bash
# =============================================================================
# Resource Monitor for Worktree Pool
# =============================================================================
# Monitors and prevents resource exhaustion during parallel agent execution
#
# Features:
# - Database connection tracking (PostgreSQL limit: 50 for pool)
# - File descriptor monitoring (ulimit tracking)
# - Disk space monitoring (3GB max for worktree pool)
# - Leak detection (orphan DBs, zombie processes, stale locks)
# - Background monitoring daemon
# - Alert thresholds and notifications
#
# Usage:
#   ./resource-monitor.sh start           # Start background monitoring
#   ./resource-monitor.sh stop            # Stop background monitoring
#   ./resource-monitor.sh status          # Show current resource usage
#   ./resource-monitor.sh check           # Run checks once
#   ./resource-monitor.sh detect-leaks    # Find resource leaks
#   ./resource-monitor.sh cleanup-leaks   # Clean up leaks
#   ./resource-monitor.sh report          # Generate report
# =============================================================================

set -euo pipefail

# Configuration
readonly DB_CONN_WARNING=40
readonly DB_CONN_ERROR=50
readonly FD_WARNING_PCT=80  # 80% of ulimit
readonly DISK_WARNING_MB=2800  # 2.8GB
readonly DISK_ERROR_MB=3000    # 3GB
readonly CHECK_INTERVAL=30     # seconds
readonly POOL_STATE_FILE="/tmp/pool-state.json"
readonly MONITOR_STATE_FILE="/tmp/resource-monitor-state.json"
readonly MONITOR_PID_FILE="/tmp/resource-monitor.pid"
readonly WORKTREE_BASE_DIR=".agent-worktrees"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
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

log_metric() {
    local metric="$1"
    local value="$2"
    local status="${3:-INFO}"

    case "$status" in
        OK)
            echo -e "${GREEN}✓${NC} ${metric}: ${value}"
            ;;
        WARN)
            echo -e "${YELLOW}⚠${NC} ${metric}: ${value}"
            ;;
        ERROR)
            echo -e "${RED}✗${NC} ${metric}: ${value}"
            ;;
        *)
            echo -e "${CYAN}→${NC} ${metric}: ${value}"
            ;;
    esac
}

# =============================================================================
# State Management
# =============================================================================

init_monitor_state() {
    if [[ ! -f "$MONITOR_STATE_FILE" ]]; then
        cat > "$MONITOR_STATE_FILE" << 'EOF'
{
  "checks": {
    "db_connections": {
      "last_check": "",
      "current": 0,
      "max_seen": 0,
      "status": "OK"
    },
    "file_descriptors": {
      "last_check": "",
      "current": 0,
      "limit": 0,
      "percent_used": 0,
      "status": "OK"
    },
    "disk_usage": {
      "last_check": "",
      "current_mb": 0,
      "status": "OK"
    }
  },
  "leaks": {
    "orphan_databases": [],
    "zombie_processes": [],
    "stale_locks": []
  },
  "alerts": []
}
EOF
        log_info "Monitor state initialized"
    fi
}

get_monitor_state() {
    if [[ ! -f "$MONITOR_STATE_FILE" ]]; then
        init_monitor_state
    fi
    cat "$MONITOR_STATE_FILE"
}

update_monitor_state() {
    local new_state="$1"
    echo "$new_state" | jq '.' > "$MONITOR_STATE_FILE"
}

add_alert() {
    local level="$1"
    local message="$2"

    local state
    state=$(get_monitor_state)
    state=$(echo "$state" | jq \
        --arg level "$level" \
        --arg msg "$message" \
        --arg ts "$(date -Iseconds)" \
        '.alerts += [{
            "level": $level,
            "message": $msg,
            "timestamp": $ts
        }]')
    update_monitor_state "$state"
}

# =============================================================================
# Database Connection Monitoring
# =============================================================================

check_db_connections() {
    log_debug "Checking database connections..."

    # Count connections for all worktree databases
    local total_conn=0
    local db_list=""

    for i in {1..10}; do
        local db_name="meal_planner_wt${i}"

        # Check if database exists
        if psql -lqt | cut -d \| -f 1 | grep -qw "$db_name" 2>/dev/null; then
            local conn_count
            conn_count=$(psql -d "$db_name" -t -c \
                "SELECT count(*) FROM pg_stat_activity WHERE datname = '$db_name';" \
                2>/dev/null | xargs || echo "0")

            total_conn=$((total_conn + conn_count))

            if [[ $conn_count -gt 0 ]]; then
                db_list="${db_list}${db_name}:${conn_count} "
            fi
        fi
    done

    # Update state
    local state
    state=$(get_monitor_state)
    local status="OK"

    if [[ $total_conn -ge $DB_CONN_ERROR ]]; then
        status="ERROR"
        log_metric "DB Connections" "${total_conn} / ${DB_CONN_ERROR} (CRITICAL)" "ERROR"
        add_alert "ERROR" "Database connections at critical level: ${total_conn}"
    elif [[ $total_conn -ge $DB_CONN_WARNING ]]; then
        status="WARN"
        log_metric "DB Connections" "${total_conn} / ${DB_CONN_ERROR} (WARNING)" "WARN"
        add_alert "WARN" "Database connections approaching limit: ${total_conn}"
    else
        log_metric "DB Connections" "${total_conn} / ${DB_CONN_ERROR}" "OK"
    fi

    # Update monitor state
    state=$(echo "$state" | jq \
        --argjson current "$total_conn" \
        --arg status "$status" \
        --arg ts "$(date -Iseconds)" \
        '.checks.db_connections = {
            "last_check": $ts,
            "current": $current,
            "max_seen": (if $current > .checks.db_connections.max_seen then $current else .checks.db_connections.max_seen end),
            "status": $status,
            "by_database": $ARGS.positional
        }' \
        --args $db_list)
    update_monitor_state "$state"

    return $([ "$status" = "ERROR" ] && echo 1 || echo 0)
}

# =============================================================================
# File Descriptor Monitoring
# =============================================================================

check_fd_limit() {
    log_debug "Checking file descriptors..."

    # Get current fd count for this process tree
    local current_fds
    current_fds=$(find /proc/$$/fd -type l 2>/dev/null | wc -l)

    # Get ulimit
    local fd_limit
    fd_limit=$(ulimit -n)

    # Calculate percentage
    local percent_used=$((current_fds * 100 / fd_limit))

    # Determine status
    local status="OK"
    if [[ $percent_used -ge $FD_WARNING_PCT ]]; then
        status="WARN"
        log_metric "File Descriptors" "${current_fds} / ${fd_limit} (${percent_used}%)" "WARN"
        add_alert "WARN" "File descriptors at ${percent_used}% of limit"
    else
        log_metric "File Descriptors" "${current_fds} / ${fd_limit} (${percent_used}%)" "OK"
    fi

    # Update state
    local state
    state=$(get_monitor_state)
    state=$(echo "$state" | jq \
        --argjson current "$current_fds" \
        --argjson limit "$fd_limit" \
        --argjson percent "$percent_used" \
        --arg status "$status" \
        --arg ts "$(date -Iseconds)" \
        '.checks.file_descriptors = {
            "last_check": $ts,
            "current": $current,
            "limit": $limit,
            "percent_used": $percent,
            "status": $status
        }')
    update_monitor_state "$state"
}

# =============================================================================
# Disk Usage Monitoring
# =============================================================================

check_disk_usage() {
    log_debug "Checking disk usage..."

    # Calculate total size of worktree pool
    local total_mb=0

    if [[ -d "$WORKTREE_BASE_DIR" ]]; then
        # Get size in MB
        total_mb=$(du -sm "$WORKTREE_BASE_DIR" 2>/dev/null | cut -f1 || echo "0")
    fi

    # Determine status
    local status="OK"
    if [[ $total_mb -ge $DISK_ERROR_MB ]]; then
        status="ERROR"
        log_metric "Disk Usage" "${total_mb}MB / ${DISK_ERROR_MB}MB (CRITICAL)" "ERROR"
        add_alert "ERROR" "Disk usage critical: ${total_mb}MB"
    elif [[ $total_mb -ge $DISK_WARNING_MB ]]; then
        status="WARN"
        log_metric "Disk Usage" "${total_mb}MB / ${DISK_ERROR_MB}MB (WARNING)" "WARN"
        add_alert "WARN" "Disk usage high: ${total_mb}MB"
    else
        log_metric "Disk Usage" "${total_mb}MB / ${DISK_ERROR_MB}MB" "OK"
    fi

    # Update state
    local state
    state=$(get_monitor_state)
    state=$(echo "$state" | jq \
        --argjson mb "$total_mb" \
        --arg status "$status" \
        --arg ts "$(date -Iseconds)" \
        '.checks.disk_usage = {
            "last_check": $ts,
            "current_mb": $mb,
            "status": $status
        }')
    update_monitor_state "$state"
}

# =============================================================================
# Leak Detection
# =============================================================================

detect_orphan_databases() {
    log_debug "Detecting orphan databases..."

    # Find test databases not associated with active worktrees
    local orphans=()

    # Get list of databases matching pattern
    local db_list
    db_list=$(psql -lqt | cut -d \| -f 1 | grep -E 'meal_planner_wt[0-9]+' | xargs || echo "")

    for db_name in $db_list; do
        # Extract worktree ID
        local wt_id="${db_name#meal_planner_}"

        # Check if worktree exists
        if [[ ! -d "${WORKTREE_BASE_DIR}/pool-${wt_id}" ]]; then
            orphans+=("$db_name")
            log_warn "Found orphan database: $db_name"
        fi
    done

    # Update state
    local state
    state=$(get_monitor_state)
    local orphan_json
    orphan_json=$(printf '%s\n' "${orphans[@]}" | jq -R . | jq -s .)
    state=$(echo "$state" | jq \
        --argjson orphans "$orphan_json" \
        '.leaks.orphan_databases = $orphans')
    update_monitor_state "$state"

    echo "${#orphans[@]}"
}

detect_zombie_processes() {
    log_debug "Detecting zombie processes..."

    # Find gleam/beam processes without parent
    local zombies=()

    # Check for gleam processes
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            zombies+=("$line")
            log_warn "Found zombie process: $line"
        fi
    done < <(ps aux | grep -E 'gleam|beam' | grep -v grep | awk '$8 ~ /Z/ {print $2":"$11}' || true)

    # Update state
    local state
    state=$(get_monitor_state)
    local zombie_json
    zombie_json=$(printf '%s\n' "${zombies[@]}" | jq -R . | jq -s .)
    state=$(echo "$state" | jq \
        --argjson zombies "$zombie_json" \
        '.leaks.zombie_processes = $zombies')
    update_monitor_state "$state"

    echo "${#zombies[@]}"
}

detect_stale_locks() {
    log_debug "Detecting stale locks..."

    # Find lock files older than 60 minutes
    local stale_locks=()

    if [[ -d "$WORKTREE_BASE_DIR" ]]; then
        while IFS= read -r lock_file; do
            if [[ -n "$lock_file" ]]; then
                stale_locks+=("$lock_file")
                log_warn "Found stale lock: $lock_file"
            fi
        done < <(find "$WORKTREE_BASE_DIR" -name "*.lock" -mmin +60 2>/dev/null || true)
    fi

    # Update state
    local state
    state=$(get_monitor_state)
    local lock_json
    lock_json=$(printf '%s\n' "${stale_locks[@]}" | jq -R . | jq -s .)
    state=$(echo "$state" | jq \
        --argjson locks "$lock_json" \
        '.leaks.stale_locks = $locks')
    update_monitor_state "$state"

    echo "${#stale_locks[@]}"
}

cleanup_leaks() {
    log_info "Cleaning up detected leaks..."

    local state
    state=$(get_monitor_state)

    # Clean up orphan databases
    local orphan_dbs
    orphan_dbs=$(echo "$state" | jq -r '.leaks.orphan_databases[]' || echo "")
    for db_name in $orphan_dbs; do
        log_info "Dropping orphan database: $db_name"
        dropdb "$db_name" 2>/dev/null || log_warn "Failed to drop $db_name"
    done

    # Clean up stale locks
    local stale_locks
    stale_locks=$(echo "$state" | jq -r '.leaks.stale_locks[]' || echo "")
    for lock_file in $stale_locks; do
        log_info "Removing stale lock: $lock_file"
        rm -f "$lock_file"
    done

    # Note: We don't auto-kill zombie processes for safety
    # User should review and manually handle these

    log_info "Leak cleanup complete"
}

# =============================================================================
# Monitoring Commands
# =============================================================================

run_checks() {
    echo ""
    echo "=== RESOURCE MONITOR CHECKS ==="
    echo ""

    check_db_connections
    check_fd_limit
    check_disk_usage

    echo ""
}

show_status() {
    local state
    state=$(get_monitor_state)

    echo ""
    echo "=== RESOURCE MONITOR STATUS ==="
    echo ""

    # Database connections
    local db_current
    db_current=$(echo "$state" | jq -r '.checks.db_connections.current')
    local db_status
    db_status=$(echo "$state" | jq -r '.checks.db_connections.status')
    log_metric "Database Connections" "${db_current} / ${DB_CONN_ERROR}" "$db_status"

    # File descriptors
    local fd_current
    fd_current=$(echo "$state" | jq -r '.checks.file_descriptors.current')
    local fd_limit
    fd_limit=$(echo "$state" | jq -r '.checks.file_descriptors.limit')
    local fd_percent
    fd_percent=$(echo "$state" | jq -r '.checks.file_descriptors.percent_used')
    local fd_status
    fd_status=$(echo "$state" | jq -r '.checks.file_descriptors.status')
    log_metric "File Descriptors" "${fd_current} / ${fd_limit} (${fd_percent}%)" "$fd_status"

    # Disk usage
    local disk_mb
    disk_mb=$(echo "$state" | jq -r '.checks.disk_usage.current_mb')
    local disk_status
    disk_status=$(echo "$state" | jq -r '.checks.disk_usage.status')
    log_metric "Disk Usage" "${disk_mb}MB / ${DISK_ERROR_MB}MB" "$disk_status"

    echo ""

    # Show alerts if any
    local alert_count
    alert_count=$(echo "$state" | jq '.alerts | length')
    if [[ $alert_count -gt 0 ]]; then
        echo "=== RECENT ALERTS ==="
        echo "$state" | jq -r '.alerts[-5:] | .[] | "[\(.level)] \(.timestamp): \(.message)"'
        echo ""
    fi
}

generate_report() {
    local state
    state=$(get_monitor_state)

    echo ""
    echo "=== RESOURCE MONITOR REPORT ==="
    echo "Generated: $(date -Iseconds)"
    echo ""

    # Current Status
    show_status

    # Leak Detection
    echo "=== LEAK DETECTION ==="
    local orphan_count
    orphan_count=$(echo "$state" | jq '.leaks.orphan_databases | length')
    local zombie_count
    zombie_count=$(echo "$state" | jq '.leaks.zombie_processes | length')
    local lock_count
    lock_count=$(echo "$state" | jq '.leaks.stale_locks | length')

    log_metric "Orphan Databases" "$orphan_count" "$([ $orphan_count -gt 0 ] && echo WARN || echo OK)"
    log_metric "Zombie Processes" "$zombie_count" "$([ $zombie_count -gt 0 ] && echo WARN || echo OK)"
    log_metric "Stale Locks" "$lock_count" "$([ $lock_count -gt 0 ] && echo WARN || echo OK)"

    echo ""
}

# =============================================================================
# Background Monitoring Daemon
# =============================================================================

start_monitor_daemon() {
    if [[ -f "$MONITOR_PID_FILE" ]]; then
        local pid
        pid=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Monitor daemon already running (PID: $pid)"
            return 0
        fi
    fi

    log_info "Starting resource monitor daemon..."

    # Run in background
    (
        while true; do
            run_checks > /dev/null 2>&1
            sleep "$CHECK_INTERVAL"
        done
    ) &

    local daemon_pid=$!
    echo "$daemon_pid" > "$MONITOR_PID_FILE"

    log_info "Monitor daemon started (PID: $daemon_pid)"
    log_info "Check interval: ${CHECK_INTERVAL}s"
}

stop_monitor_daemon() {
    if [[ ! -f "$MONITOR_PID_FILE" ]]; then
        log_warn "Monitor daemon not running"
        return 0
    fi

    local pid
    pid=$(cat "$MONITOR_PID_FILE")

    log_info "Stopping monitor daemon (PID: $pid)..."
    kill "$pid" 2>/dev/null || log_warn "Failed to kill process $pid"
    rm -f "$MONITOR_PID_FILE"
    log_info "Monitor daemon stopped"
}

# =============================================================================
# Main Command Dispatcher
# =============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        start)
            init_monitor_state
            start_monitor_daemon
            ;;
        stop)
            stop_monitor_daemon
            ;;
        status)
            show_status
            ;;
        check)
            init_monitor_state
            run_checks
            ;;
        detect-leaks)
            init_monitor_state
            log_info "Running leak detection..."
            local orphan_count zombie_count lock_count
            orphan_count=$(detect_orphan_databases)
            zombie_count=$(detect_zombie_processes)
            lock_count=$(detect_stale_locks)

            echo ""
            log_metric "Orphan Databases" "$orphan_count" "$([ $orphan_count -gt 0 ] && echo WARN || echo OK)"
            log_metric "Zombie Processes" "$zombie_count" "$([ $zombie_count -gt 0 ] && echo WARN || echo OK)"
            log_metric "Stale Locks" "$lock_count" "$([ $lock_count -gt 0 ] && echo WARN || echo OK)"
            echo ""
            ;;
        cleanup-leaks)
            init_monitor_state
            detect_orphan_databases > /dev/null
            detect_zombie_processes > /dev/null
            detect_stale_locks > /dev/null
            cleanup_leaks
            ;;
        report)
            init_monitor_state
            generate_report
            ;;
        *)
            echo "Resource Monitor for Worktree Pool"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  start          Start background monitoring daemon"
            echo "  stop           Stop background monitoring daemon"
            echo "  status         Show current resource usage"
            echo "  check          Run checks once and exit"
            echo "  detect-leaks   Detect resource leaks"
            echo "  cleanup-leaks  Clean up detected leaks"
            echo "  report         Generate comprehensive report"
            echo ""
            exit 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
