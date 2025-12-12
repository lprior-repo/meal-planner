#!/bin/bash

# Tandoor API Error Alert System
# Sends alerts when errors exceed thresholds

set -e

MONITOR_DIR="${MONITOR_DIR:-$HOME/.meal-planner/monitoring}"
LOG_FILE="${MONITOR_DIR}/tandoor-errors.log"
ALERT_LOG="${MONITOR_DIR}/tandoor-alerts.log"
CONFIG_FILE="${MONITOR_DIR}/alert-config.json"

# Default thresholds (can be overridden in config)
ERROR_THRESHOLD=5
ERROR_WINDOW=3600  # 1 hour
ALERT_COOLDOWN=1800  # 30 minutes
MEMORY_THRESHOLD=85
CPU_THRESHOLD=80

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize
mkdir -p "$MONITOR_DIR"
touch "$ALERT_LOG"

# Load configuration if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        ERROR_THRESHOLD=$(jq -r '.error_threshold // 5' "$CONFIG_FILE" 2>/dev/null || echo 5)
        ERROR_WINDOW=$(jq -r '.error_window_seconds // 3600' "$CONFIG_FILE" 2>/dev/null || echo 3600)
        ALERT_COOLDOWN=$(jq -r '.alert_cooldown_seconds // 1800' "$CONFIG_FILE" 2>/dev/null || echo 1800)
        MEMORY_THRESHOLD=$(jq -r '.memory_threshold // 85' "$CONFIG_FILE" 2>/dev/null || echo 85)
        CPU_THRESHOLD=$(jq -r '.cpu_threshold // 80' "$CONFIG_FILE" 2>/dev/null || echo 80)
    fi
}

# Create default config
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
{
  "error_threshold": 5,
  "error_window_seconds": 3600,
  "alert_cooldown_seconds": 1800,
  "memory_threshold": 85,
  "cpu_threshold": 80,
  "enabled_alerts": {
    "errors": true,
    "system_resources": true,
    "api_unavailable": true
  }
}
EOF
    echo -e "${GREEN}Created default config: $CONFIG_FILE${NC}"
}

log_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} [${severity}] ${message}" >> "$ALERT_LOG"

    case $severity in
        CRITICAL)
            echo -e "${RED}[CRITICAL ALERT]${NC} ${message}"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING ALERT]${NC} ${message}"
            ;;
        INFO)
            echo -e "${BLUE}[INFO ALERT]${NC} ${message}"
            ;;
    esac
}

check_error_rate() {
    if [ ! -f "$LOG_FILE" ]; then
        return
    fi

    local current_time=$(date +%s)
    local cutoff_time=$((current_time - ERROR_WINDOW))

    # Count errors in the time window (simplified - assumes timestamps in log)
    local recent_errors=$(grep "ERROR" "$LOG_FILE" | wc -l)

    if [ "$recent_errors" -ge "$ERROR_THRESHOLD" ]; then
        log_alert "CRITICAL" "Error threshold exceeded: $recent_errors errors in last $((ERROR_WINDOW / 60)) minutes (threshold: $ERROR_THRESHOLD)"
        return 1
    fi

    return 0
}

check_api_availability() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/health" 2>&1 || echo "000")

    if [ "$http_code" != "200" ]; then
        log_alert "CRITICAL" "Tandoor API unavailable - HTTP $http_code"
        return 1
    fi

    return 0
}

check_system_resources() {
    local mem_usage=$(free | grep Mem | awk '{printf("%d", ($3/$2) * 100)}')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | awk '{printf("%d", $1)}')

    if [ "$mem_usage" -ge "$MEMORY_THRESHOLD" ]; then
        log_alert "WARNING" "High memory usage: ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
    fi

    if [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; then
        log_alert "WARNING" "High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
    fi
}

generate_alert_summary() {
    if [ ! -f "$ALERT_LOG" ]; then
        echo "No alerts have been generated"
        return
    fi

    local critical_count=$(grep -c "CRITICAL" "$ALERT_LOG" 2>/dev/null || echo 0)
    local warning_count=$(grep -c "WARNING" "$ALERT_LOG" 2>/dev/null || echo 0)
    local info_count=$(grep -c "INFO" "$ALERT_LOG" 2>/dev/null || echo 0)

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Tandoor Alert Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "Alert Log: $ALERT_LOG"
    echo -e "Generated: $(date)"
    echo ""
    echo -e "Alert Statistics:"
    echo -e "  ${RED}Critical: $critical_count${NC}"
    echo -e "  ${YELLOW}Warnings: $warning_count${NC}"
    echo -e "  ${BLUE}Info: $info_count${NC}"
    echo ""

    if [ "$critical_count" -gt 0 ]; then
        echo -e "${RED}Recent Critical Alerts:${NC}"
        grep "CRITICAL" "$ALERT_LOG" | tail -5 | while read line; do
            echo "  $line"
        done
        echo ""
    fi

    if [ "$warning_count" -gt 0 ]; then
        echo -e "${YELLOW}Recent Warnings:${NC}"
        grep "WARNING" "$ALERT_LOG" | tail -5 | while read line; do
            echo "  $line"
        done
        echo ""
    fi

    echo -e "${BLUE}========================================${NC}"
    echo ""
}

run_all_checks() {
    load_config

    echo -e "${BLUE}Running Tandoor Alert Checks...${NC}"
    echo ""

    check_api_availability || true
    check_error_rate || true
    check_system_resources || true

    generate_alert_summary
}

# Main
case "${1:-check}" in
    check)
        run_all_checks
        ;;
    init-config)
        create_default_config
        ;;
    summary)
        generate_alert_summary
        ;;
    *)
        echo "Usage: $0 {check|init-config|summary}"
        echo ""
        echo "  check - Run all alert checks"
        echo "  init-config - Create default alert configuration"
        echo "  summary - Show alert summary"
        exit 1
        ;;
esac
