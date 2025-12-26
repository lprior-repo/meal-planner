#!/usr/bin/env bash
# Performance Tracking Script for meal-planner
# Measures test execution time and records to .perf-tracking/test-execution.csv
#
# Usage:
#   ./scripts/perf-track.sh [--force]
#
# Options:
#   --force    Force tracking even if not on 5-commit boundary

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PERF_DIR="$PROJECT_ROOT/.perf-tracking"
DATA_FILE="$PERF_DIR/test-execution.csv"
BASELINES_FILE="$PERF_DIR/baselines.json"
TEMP_DIR="${TMPDIR:-/tmp}/perf-tracking-$$"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

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

# Get current commit information
get_commit_hash() {
    git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown"
}

get_commit_number() {
    git -C "$PROJECT_ROOT" rev-list --count HEAD 2>/dev/null || echo "0"
}

get_short_hash() {
    git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

# Check if we should track (every 5 commits or --force)
should_track() {
    local commit_num="$1"
    local force="${2:-false}"

    if [[ "$force" == "true" ]]; then
        return 0
    fi

    # Track on every 5th commit (divisible by 5)
    if (( commit_num % 5 == 0 )); then
        return 0
    fi

    return 1
}

# Measure test execution time
measure_test_execution() {
    local test_type="$1"  # "fast" or "full"
    local output_file="$2"

    mkdir -p "$TEMP_DIR"

    log_info "Measuring ${test_type} test execution..."

    local start_ms end_ms duration_ms
    local test_output="$TEMP_DIR/test_output.txt"
    local test_cmd

    if [[ "$test_type" == "fast" ]]; then
        test_cmd="gleam run -m test_runner/fast"
    else
        test_cmd="gleam test"
    fi

    # Measure execution time in milliseconds
    start_ms=$(date +%s%3N)

    # Run tests and capture output
    if $test_cmd > "$test_output" 2>&1; then
        local exit_code=0
    else
        local exit_code=$?
    fi

    end_ms=$(date +%s%3N)
    duration_ms=$((end_ms - start_ms))

    # Parse test results from output
    local pass_count=0
    local fail_count=0
    local skip_count=0

    # Try to extract test counts from Gleam output
    # Format: "X tests, Y passed, Z failed"
    if grep -q "tests" "$test_output"; then
        pass_count=$(grep -oP '\d+(?= passed)' "$test_output" | head -1 || echo "0")
        fail_count=$(grep -oP '\d+(?= failed)' "$test_output" | head -1 || echo "0")
        # Gleam doesn't always report skipped, default to 0
        skip_count=0
    fi

    # Store results
    echo "$duration_ms|$pass_count|$fail_count|$skip_count|$exit_code" > "$output_file"

    if [[ $exit_code -ne 0 ]]; then
        log_warning "Tests failed with exit code $exit_code"
        cat "$test_output"
        return 1
    fi

    log_success "${test_type} tests completed in ${duration_ms}ms"
    return 0
}

# Record measurement to CSV
record_measurement() {
    local timestamp="$1"
    local commit_hash="$2"
    local commit_num="$3"
    local duration_ms="$4"
    local test_type="$5"
    local pass_count="$6"
    local fail_count="$7"
    local skip_count="$8"
    local notes="${9:-}"

    # Ensure CSV file exists with header
    if [[ ! -f "$DATA_FILE" ]]; then
        mkdir -p "$PERF_DIR"
        echo "timestamp,commit_hash,commit_number,test_duration_ms,test_type,pass_count,fail_count,skip_count,notes" > "$DATA_FILE"
    fi

    # Append measurement
    echo "$timestamp,$commit_hash,$commit_num,$duration_ms,$test_type,$pass_count,$fail_count,$skip_count,$notes" >> "$DATA_FILE"

    log_success "Recorded measurement to $DATA_FILE"
}

# Get baseline from baselines.json
get_baseline() {
    local test_type="$1"

    if [[ ! -f "$BASELINES_FILE" ]]; then
        echo "800"  # Default baseline
        return
    fi

    # Extract baseline_ms for test type
    local baseline
    if [[ "$test_type" == "fast" ]]; then
        baseline=$(jq -r '.test_execution.baseline_ms // 800' "$BASELINES_FILE" 2>/dev/null || echo "800")
    else
        baseline=$(jq -r '.full_test_execution.baseline_ms // 5200' "$BASELINES_FILE" 2>/dev/null || echo "5200")
    fi

    echo "$baseline"
}

# Compare against baseline and show status
check_regression() {
    local duration_ms="$1"
    local test_type="$2"

    local baseline
    baseline=$(get_baseline "$test_type")

    local diff_ms=$((duration_ms - baseline))
    local diff_percent=$(( (diff_ms * 100) / baseline ))

    if [[ $diff_percent -gt 50 ]]; then
        log_error "CRITICAL REGRESSION: ${duration_ms}ms vs baseline ${baseline}ms (+${diff_percent}%)"
        return 2
    elif [[ $diff_percent -gt 20 ]]; then
        log_warning "Performance degradation: ${duration_ms}ms vs baseline ${baseline}ms (+${diff_percent}%)"
        return 1
    elif [[ $diff_percent -lt -10 ]]; then
        log_success "Performance improvement: ${duration_ms}ms vs baseline ${baseline}ms (${diff_percent}%)"
        return 0
    else
        log_info "Performance within normal range: ${duration_ms}ms (baseline: ${baseline}ms, ${diff_percent:+$diff_percent}%)"
        return 0
    fi
}

# Main execution
main() {
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Usage: $0 [--force]"
                exit 1
                ;;
        esac
    done

    log_info "Performance Tracking - meal-planner"
    echo ""

    # Get commit information
    local commit_hash commit_num short_hash
    commit_hash=$(get_commit_hash)
    commit_num=$(get_commit_number)
    short_hash=$(get_short_hash)

    log_info "Commit: $short_hash (commit #$commit_num)"

    # Check if we should track
    if ! should_track "$commit_num" "$force"; then
        log_info "Skipping tracking (not on 5-commit boundary, use --force to override)"
        exit 0
    fi

    log_info "Triggering performance tracking (commit #$commit_num)"
    echo ""

    # Measure fast tests
    local result_file="$TEMP_DIR/fast_result.txt"
    if measure_test_execution "fast" "$result_file"; then
        IFS='|' read -r duration_ms pass_count fail_count skip_count exit_code < "$result_file"

        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Record measurement
        record_measurement "$timestamp" "$commit_hash" "$commit_num" "$duration_ms" "fast" \
            "$pass_count" "$fail_count" "$skip_count" ""

        # Check for regression
        echo ""
        check_regression "$duration_ms" "fast"

        echo ""
        log_success "Performance tracking completed successfully"
    else
        log_error "Test execution failed, skipping performance recording"
        exit 1
    fi
}

# Run main
main "$@"
