#!/bin/bash

# Tandoor API Error Monitoring Script
# Monitors Tandoor API for errors over a 24-hour period
# Logs errors, response times, and API health

set -e

MONITOR_DIR="${MONITOR_DIR:-$HOME/.meal-planner/monitoring}"
TANDOOR_URL="http://localhost:8000"
TANDOOR_API="http://localhost:8000/api"
LOG_FILE="${MONITOR_DIR}/tandoor-errors.log"
STATS_FILE="${MONITOR_DIR}/tandoor-stats.json"
HEALTH_CHECK_INTERVAL=300  # 5 minutes
MONITOR_DURATION=86400     # 24 hours

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize
mkdir -p "$MONITOR_DIR"
touch "$LOG_FILE"
touch "$STATS_FILE"

# Initialize stats JSON
cat > "$STATS_FILE" << 'EOF'
{
  "start_time": "2025-12-12T00:00:00Z",
  "monitoring_duration_seconds": 86400,
  "total_checks": 0,
  "successful_checks": 0,
  "failed_checks": 0,
  "errors": [],
  "response_times_ms": [],
  "avg_response_time_ms": 0,
  "error_summary": {}
}
EOF

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$LOG_FILE"

    case $level in
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${message}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${message}"
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} ${message}"
            ;;
    esac
}

check_tandoor_health() {
    local start_time=$(date +%s%N | cut -b1-13)
    local http_code
    local response_time
    local response

    # Check API health endpoint
    response=$(curl -s -w "\n%{http_code}" "$TANDOOR_URL/health" 2>&1 || echo "000")
    http_code=$(echo "$response" | tail -n1)

    local end_time=$(date +%s%N | cut -b1-13)
    response_time=$((end_time - start_time))

    # Log response time
    local times_json=$(cat "$STATS_FILE" | jq ".response_times_ms += [$response_time]" 2>/dev/null || echo "{}")

    if [ "$http_code" == "200" ]; then
        log_message "SUCCESS" "Tandoor health check passed (HTTP $http_code, ${response_time}ms)"
        return 0
    elif [ "$http_code" == "000" ]; then
        log_message "ERROR" "Tandoor unreachable - Connection failed"
        return 1
    else
        log_message "ERROR" "Tandoor health check failed (HTTP $http_code)"
        return 1
    fi
}

check_tandoor_api() {
    local endpoint=$1
    local start_time=$(date +%s%N | cut -b1-13)
    local http_code
    local response

    # Test API endpoint with HEAD request
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -I "$TANDOOR_API$endpoint" 2>&1 || echo "000")

    local end_time=$(date +%s%N | cut -b1-13)
    local response_time=$((end_time - start_time))

    if [ "$http_code" == "404" ] || [ "$http_code" == "200" ] || [ "$http_code" == "201" ]; then
        log_message "SUCCESS" "API endpoint $endpoint responded (HTTP $http_code, ${response_time}ms)"
        return 0
    elif [ "$http_code" == "000" ]; then
        log_message "ERROR" "API endpoint $endpoint unreachable"
        return 1
    elif [[ "$http_code" =~ ^5 ]]; then
        log_message "ERROR" "API endpoint $endpoint server error (HTTP $http_code)"
        return 1
    else
        log_message "WARN" "API endpoint $endpoint returned HTTP $http_code"
        return 0
    fi
}

monitor_system_resources() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_usage=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100)}')
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')

    log_message "INFO" "System Resources - CPU: ${cpu_usage}%, MEM: ${mem_usage}%, DISK: ${disk_usage}"
}

generate_report() {
    local error_count=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo 0)
    local warning_count=$(grep -c "WARN" "$LOG_FILE" 2>/dev/null || echo 0)
    local check_count=$(grep -c "\[" "$LOG_FILE" 2>/dev/null || echo 0)

    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Tandoor API Monitoring Report${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Log File: $LOG_FILE"
    echo -e "Duration: 24 hours"
    echo -e "Start Time: $(date)"
    echo -e "Total Checks: $check_count"
    echo -e "${RED}Errors: $error_count${NC}"
    echo -e "${YELLOW}Warnings: $warning_count${NC}"
    echo -e "Success Rate: $([ $check_count -gt 0 ] && echo "$(( (check_count - error_count) * 100 / check_count ))%" || echo "N/A")"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Main monitoring loop
run_monitoring() {
    local start_epoch=$(date +%s)
    local check_count=0

    log_message "INFO" "Starting Tandoor API monitoring (24 hours)"
    log_message "INFO" "Checking every ${HEALTH_CHECK_INTERVAL} seconds"

    while true; do
        local current_epoch=$(date +%s)
        local elapsed=$((current_epoch - start_epoch))

        if [ $elapsed -ge $MONITOR_DURATION ]; then
            log_message "INFO" "Monitoring period complete (${elapsed}s elapsed)"
            break
        fi

        # Perform health checks
        check_tandoor_health
        check_tandoor_api "/v1"
        check_tandoor_api "/recipes"

        # Monitor system resources
        monitor_system_resources

        check_count=$((check_count + 1))

        # Wait before next check
        sleep $HEALTH_CHECK_INTERVAL
    done

    generate_report
}

# Cleanup function
cleanup() {
    log_message "INFO" "Monitoring stopped"
    echo ""
    echo "Final error count: $(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Log file: $LOG_FILE"
}

# Install signal handlers
trap cleanup EXIT INT TERM

# Run monitoring
run_monitoring
