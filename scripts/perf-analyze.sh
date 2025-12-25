#!/usr/bin/env bash
# Performance Analysis Script for meal-planner
# Analyzes historical performance data and detects regressions
#
# Usage:
#   ./scripts/perf-analyze.sh [--report] [--last N]
#
# Options:
#   --report       Generate detailed report
#   --last N       Analyze last N measurements (default: 10)
#   --all          Analyze all historical data

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PERF_DIR="$PROJECT_ROOT/.perf-tracking"
DATA_FILE="$PERF_DIR/test-execution.csv"
BASELINES_FILE="$PERF_DIR/baselines.json"
REPORT_DIR="$PERF_DIR/reports"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

print_header() {
    echo -e "${BOLD}${CYAN}$*${NC}"
}

# Check if data file exists
check_data_file() {
    if [[ ! -f "$DATA_FILE" ]]; then
        log_error "No performance data found at $DATA_FILE"
        log_info "Run './scripts/perf-track.sh --force' to collect initial data"
        exit 1
    fi

    # Check if file has data (more than just header)
    local line_count
    line_count=$(wc -l < "$DATA_FILE")
    if [[ $line_count -lt 2 ]]; then
        log_error "No performance measurements recorded yet"
        log_info "Run './scripts/perf-track.sh --force' to collect initial data"
        exit 1
    fi
}

# Get baseline from baselines.json
get_baseline() {
    local metric="$1"

    if [[ ! -f "$BASELINES_FILE" ]]; then
        echo "800"  # Default
        return
    fi

    local baseline
    case "$metric" in
        "fast_test")
            baseline=$(jq -r '.test_execution.baseline_ms // 800' "$BASELINES_FILE" 2>/dev/null || echo "800")
            ;;
        "full_test")
            baseline=$(jq -r '.full_test_execution.baseline_ms // 5200' "$BASELINES_FILE" 2>/dev/null || echo "5200")
            ;;
        "build")
            baseline=$(jq -r '.build_execution.baseline_ms // 150' "$BASELINES_FILE" 2>/dev/null || echo "150")
            ;;
        *)
            baseline="0"
            ;;
    esac

    echo "$baseline"
}

# Calculate statistics
calculate_stats() {
    local data_column="$1"  # Column number (1-indexed)
    local last_n="${2:-10}"

    # Extract column, skip header, take last N, calculate stats
    local values
    values=$(tail -n "+2" "$DATA_FILE" | tail -n "$last_n" | cut -d',' -f"$data_column")

    if [[ -z "$values" ]]; then
        echo "0|0|0|0|0"
        return
    fi

    # Calculate min, max, mean, median using awk
    echo "$values" | awk '
    {
        sum += $1
        values[NR] = $1
        if (NR == 1 || $1 < min) min = $1
        if (NR == 1 || $1 > max) max = $1
    }
    END {
        mean = sum / NR

        # Sort for median
        asort(values)
        if (NR % 2 == 0) {
            median = (values[NR/2] + values[NR/2+1]) / 2
        } else {
            median = values[(NR+1)/2]
        }

        # Calculate standard deviation
        variance = 0
        for (i = 1; i <= NR; i++) {
            variance += (values[i] - mean) ^ 2
        }
        stddev = sqrt(variance / NR)

        printf "%.0f|%.0f|%.0f|%.0f|%.0f", min, max, mean, median, stddev
    }'
}

# Detect trend (improving, degrading, stable)
detect_trend() {
    local last_n="${1:-10}"

    # Get last N measurements
    local measurements
    measurements=$(tail -n "+2" "$DATA_FILE" | tail -n "$last_n" | cut -d',' -f4)

    if [[ -z "$measurements" ]]; then
        echo "unknown"
        return
    fi

    # Calculate linear regression slope
    echo "$measurements" | awk '
    {
        x[NR] = NR
        y[NR] = $1
        sum_x += NR
        sum_y += $1
        sum_xy += NR * $1
        sum_x2 += NR * NR
    }
    END {
        n = NR
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)

        # Classify trend
        if (slope > 50) print "degrading"
        else if (slope < -50) print "improving"
        else print "stable"
    }'
}

# Show summary statistics
show_summary() {
    local last_n="${1:-10}"

    print_header "Performance Summary (last $last_n measurements)"
    echo ""

    # Fast tests stats
    local stats
    stats=$(calculate_stats 4 "$last_n")
    IFS='|' read -r min max mean median stddev <<< "$stats"

    local baseline
    baseline=$(get_baseline "fast_test")
    local mean_diff_percent=$(( (mean - baseline) * 100 / baseline ))

    echo "Fast Tests (gleam run -m test_runner/fast):"
    echo "  Baseline:     ${baseline}ms"
    echo "  Min:          ${min}ms"
    echo "  Max:          ${max}ms"
    echo "  Mean:         ${mean}ms (${mean_diff_percent:+$mean_diff_percent}% from baseline)"
    echo "  Median:       ${median}ms"
    echo "  Std Dev:      ${stddev}ms"
    echo ""

    # Trend analysis
    local trend
    trend=$(detect_trend "$last_n")

    case "$trend" in
        "improving")
            log_success "Trend: IMPROVING (performance getting better)"
            ;;
        "degrading")
            log_warning "Trend: DEGRADING (performance getting worse)"
            ;;
        "stable")
            log_info "Trend: STABLE (performance consistent)"
            ;;
        *)
            log_info "Trend: UNKNOWN (insufficient data)"
            ;;
    esac
    echo ""
}

# Show recent measurements
show_recent() {
    local last_n="${1:-5}"

    print_header "Recent Measurements (last $last_n)"
    echo ""

    # Print header
    printf "%-20s %-10s %-12s %-10s %-8s\n" "Timestamp" "Commit" "Duration" "Type" "Status"
    printf "%s\n" "--------------------------------------------------------------------------------"

    # Print recent measurements
    tail -n "+2" "$DATA_FILE" | tail -n "$last_n" | while IFS=',' read -r timestamp commit_hash commit_num duration test_type pass fail skip notes; do
        local short_hash="${commit_hash:0:8}"
        local status="✓"

        if [[ $fail -gt 0 ]]; then
            status="✗"
        fi

        # Color code based on performance
        local baseline
        if [[ "$test_type" == "fast" ]]; then
            baseline=$(get_baseline "fast_test")
        else
            baseline=$(get_baseline "full_test")
        fi

        local diff_percent=$(( (duration - baseline) * 100 / baseline ))
        local duration_colored

        if [[ $diff_percent -gt 50 ]]; then
            duration_colored="${RED}${duration}ms${NC}"
        elif [[ $diff_percent -gt 20 ]]; then
            duration_colored="${YELLOW}${duration}ms${NC}"
        elif [[ $diff_percent -lt -10 ]]; then
            duration_colored="${GREEN}${duration}ms${NC}"
        else
            duration_colored="${duration}ms"
        fi

        printf "%-20s %-10s %-20s %-10s %-8s\n" \
            "${timestamp:0:19}" \
            "$short_hash" \
            "$duration_colored" \
            "$test_type" \
            "$status"
    done
    echo ""
}

# Generate detailed report
generate_report() {
    local report_file="$REPORT_DIR/perf-report-$(date +%Y%m%d-%H%M%S).txt"

    mkdir -p "$REPORT_DIR"

    log_info "Generating detailed performance report..."

    {
        echo "=========================================="
        echo "Performance Analysis Report"
        echo "Generated: $(date)"
        echo "Project: meal-planner"
        echo "=========================================="
        echo ""

        # Summary stats
        echo "SUMMARY (last 10 measurements)"
        echo "----------------------------------------"
        local stats
        stats=$(calculate_stats 4 10)
        IFS='|' read -r min max mean median stddev <<< "$stats"

        echo "Duration (ms):"
        echo "  Min:     $min"
        echo "  Max:     $max"
        echo "  Mean:    $mean"
        echo "  Median:  $median"
        echo "  StdDev:  $stddev"
        echo ""

        # Trend
        local trend
        trend=$(detect_trend 10)
        echo "Trend: $trend"
        echo ""

        # All measurements
        echo "ALL MEASUREMENTS"
        echo "----------------------------------------"
        cat "$DATA_FILE"
        echo ""

        # Regressions detected
        echo "REGRESSION ANALYSIS"
        echo "----------------------------------------"
        local baseline
        baseline=$(get_baseline "fast_test")

        tail -n "+2" "$DATA_FILE" | while IFS=',' read -r timestamp commit_hash commit_num duration test_type pass fail skip notes; do
            if [[ "$test_type" != "fast" ]]; then
                continue
            fi

            local diff_percent=$(( (duration - baseline) * 100 / baseline ))

            if [[ $diff_percent -gt 50 ]]; then
                echo "CRITICAL: $commit_hash ($timestamp) - ${duration}ms (+${diff_percent}%)"
            elif [[ $diff_percent -gt 20 ]]; then
                echo "WARNING:  $commit_hash ($timestamp) - ${duration}ms (+${diff_percent}%)"
            fi
        done
        echo ""

    } > "$report_file"

    log_success "Report saved to: $report_file"
    echo ""
    cat "$report_file"
}

# Main execution
main() {
    local generate_report=false
    local last_n=10
    local show_all=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --report)
                generate_report=true
                shift
                ;;
            --last)
                last_n="$2"
                shift 2
                ;;
            --all)
                show_all=true
                last_n=999999
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Usage: $0 [--report] [--last N] [--all]"
                exit 1
                ;;
        esac
    done

    print_header "Performance Analysis - meal-planner"
    echo ""

    # Check data availability
    check_data_file

    # Show summary
    show_summary "$last_n"

    # Show recent measurements
    show_recent 5

    # Generate report if requested
    if [[ "$generate_report" == "true" ]]; then
        generate_report
    fi

    log_success "Analysis complete"
}

# Run main
main "$@"
