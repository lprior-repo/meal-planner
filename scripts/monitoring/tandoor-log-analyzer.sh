#!/bin/bash

# Tandoor API Error Log Analyzer
# Analyzes error logs and provides detailed error summaries

set -e

MONITOR_DIR="${MONITOR_DIR:-$HOME/.meal-planner/monitoring}"
LOG_FILE="${MONITOR_DIR}/tandoor-errors.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

analyze_errors() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}Error log not found: $LOG_FILE${NC}"
        return 1
    fi

    local total_errors=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo 0)
    local total_warnings=$(grep -c "WARN" "$LOG_FILE" 2>/dev/null || echo 0)
    local total_successes=$(grep -c "SUCCESS" "$LOG_FILE" 2>/dev/null || echo 0)

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Tandoor API Error Analysis Report${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "Log File: $LOG_FILE"
    echo -e "Generated: $(date)"
    echo ""
    echo -e "Summary Statistics:"
    echo -e "  ${GREEN}Successes: $total_successes${NC}"
    echo -e "  ${YELLOW}Warnings: $total_warnings${NC}"
    echo -e "  ${RED}Errors: $total_errors${NC}"
    echo ""

    if [ $total_errors -gt 0 ]; then
        echo -e "${RED}Error Details:${NC}"
        grep "ERROR" "$LOG_FILE" | sort | uniq -c | sort -rn | while read count error_msg; do
            echo -e "  ${RED}[$count occurrences]${NC} $(echo $error_msg | cut -d']' -f2-)"
        done
        echo ""
    fi

    if [ $total_warnings -gt 0 ]; then
        echo -e "${YELLOW}Warning Details:${NC}"
        grep "WARN" "$LOG_FILE" | sort | uniq -c | sort -rn | while read count warn_msg; do
            echo -e "  ${YELLOW}[$count occurrences]${NC} $(echo $warn_msg | cut -d']' -f2-)"
        done
        echo ""
    fi

    # Timeline of errors
    if [ $total_errors -gt 0 ]; then
        echo -e "${RED}Error Timeline:${NC}"
        grep "ERROR" "$LOG_FILE" | head -10 | while read line; do
            echo -e "  $line"
        done
        if [ $total_errors -gt 10 ]; then
            echo -e "  ... and $((total_errors - 10)) more errors"
        fi
        echo ""
    fi

    # Performance metrics
    local response_times=$(grep -oP 'response_time[ms]*=\K[0-9]+' "$LOG_FILE" 2>/dev/null | sort -n)
    if [ ! -z "$response_times" ]; then
        local count=$(echo "$response_times" | wc -l)
        local avg=$(echo "$response_times" | awk '{sum+=$1} END {print int(sum/NR)}')
        local max=$(echo "$response_times" | tail -1)
        local min=$(echo "$response_times" | head -1)

        echo -e "${BLUE}Response Time Metrics:${NC}"
        echo -e "  Min: ${min}ms"
        echo -e "  Max: ${max}ms"
        echo -e "  Avg: ${avg}ms"
        echo ""
    fi

    # System resource usage
    if grep -q "CPU:" "$LOG_FILE"; then
        echo -e "${BLUE}System Resource Usage:${NC}"
        local cpu_avg=$(grep "CPU:" "$LOG_FILE" | grep -oP 'CPU: \K[0-9.]+' | awk '{sum+=$1; count++} END {if (count > 0) printf "%.1f", sum/count}')
        local mem_avg=$(grep "MEM:" "$LOG_FILE" | grep -oP 'MEM: \K[0-9.]+' | awk '{sum+=$1; count++} END {if (count > 0) printf "%.1f", sum/count}')

        [ ! -z "$cpu_avg" ] && echo -e "  Avg CPU: ${cpu_avg}%"
        [ ! -z "$mem_avg" ] && echo -e "  Avg Memory: ${mem_avg}%"
        echo ""
    fi

    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Return appropriate exit code
    if [ $total_errors -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Show last N errors
show_recent_errors() {
    local count=${1:-20}

    if [ ! -f "$LOG_FILE" ]; then
        echo "Error log not found: $LOG_FILE"
        return 1
    fi

    echo ""
    echo -e "${RED}Last $count errors:${NC}"
    echo ""
    grep "ERROR" "$LOG_FILE" | tail -n $count || true
    echo ""
}

# Watch log in real-time
watch_log() {
    echo -e "${BLUE}Watching log file (Ctrl+C to exit):${NC}"
    tail -f "$LOG_FILE"
}

# Main
case "${1:-analyze}" in
    analyze)
        analyze_errors
        ;;
    recent)
        show_recent_errors "${2:-20}"
        ;;
    watch)
        watch_log
        ;;
    *)
        echo "Usage: $0 {analyze|recent|watch} [count]"
        echo ""
        echo "  analyze - Generate error analysis report"
        echo "  recent [N] - Show last N errors (default: 20)"
        echo "  watch - Watch log file in real-time"
        exit 1
        ;;
esac
