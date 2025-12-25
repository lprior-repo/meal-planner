#!/usr/bin/env bash
# Compilation Time Tracking Script for meal-planner
# Measures compilation time (clean build and incremental) and records metrics
#
# Usage:
#   ./scripts/compile-time-track.sh [--baseline|--incremental|--both]
#
# Options:
#   --baseline      Measure clean build (after gleam clean)
#   --incremental   Measure incremental build (no clean)
#   --both          Measure both clean and incremental (default)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PERF_DIR="$PROJECT_ROOT/.perf-tracking"
DATA_FILE="$PERF_DIR/compile-time.csv"
BASELINES_FILE="$PERF_DIR/baselines.json"
TEMP_DIR="${TMPDIR:-/tmp}/compile-tracking-$$"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_metric() {
    echo -e "${CYAN}[METRIC]${NC} $*"
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

get_branch_name() {
    git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

# Measure compilation time
measure_compilation() {
    local build_type="$1"  # "clean" or "incremental"
    local target="${2:-erlang}"  # "erlang" or "javascript"

    mkdir -p "$TEMP_DIR"

    log_info "Measuring ${build_type} compilation for target: ${target}..."

    # Clean if this is a clean build
    if [[ "$build_type" == "clean" ]]; then
        log_info "Cleaning build artifacts..."
        gleam clean >/dev/null 2>&1
    fi

    local start_ns end_ns duration_ms
    local build_output="$TEMP_DIR/build_output.txt"

    # Use nanosecond precision if available, otherwise milliseconds
    if date --version 2>/dev/null | grep -q GNU; then
        start_ns=$(date +%s%N)
    else
        start_ns=$(( $(date +%s) * 1000000000 ))
    fi

    # Run build and capture output
    if gleam build --target "$target" > "$build_output" 2>&1; then
        local exit_code=0
    else
        local exit_code=$?
    fi

    if date --version 2>/dev/null | grep -q GNU; then
        end_ns=$(date +%s%N)
    else
        end_ns=$(( $(date +%s) * 1000000000 ))
    fi

    duration_ms=$(( (end_ns - start_ns) / 1000000 ))

    # Count modules compiled (from Gleam output)
    local modules_compiled=0
    if grep -q "Compiling" "$build_output"; then
        modules_compiled=$(grep -c "Compiling" "$build_output" || echo "0")
    fi

    # Check for warnings/errors
    local warning_count=0
    local error_count=0

    if grep -q "warning:" "$build_output"; then
        warning_count=$(grep -c "warning:" "$build_output" || echo "0")
    fi

    if grep -q "error:" "$build_output"; then
        error_count=$(grep -c "error:" "$build_output" || echo "0")
    fi

    # Store results
    echo "$duration_ms|$modules_compiled|$warning_count|$error_count|$exit_code" > "$TEMP_DIR/${build_type}_${target}_result.txt"

    if [[ $exit_code -ne 0 ]]; then
        log_error "Build failed with exit code $exit_code"
        cat "$build_output"
        return 1
    fi

    log_success "${build_type} build (${target}) completed in ${duration_ms}ms"
    log_metric "  Modules compiled: $modules_compiled"
    if [[ $warning_count -gt 0 ]]; then
        log_warning "  Warnings: $warning_count"
    fi

    echo "$duration_ms|$modules_compiled|$warning_count|$error_count"
    return 0
}

# Record measurement to CSV
record_measurement() {
    local timestamp="$1"
    local commit_hash="$2"
    local commit_num="$3"
    local branch="$4"
    local build_type="$5"
    local target="$6"
    local duration_ms="$7"
    local modules_compiled="$8"
    local warning_count="$9"
    local error_count="${10}"
    local notes="${11:-}"

    # Ensure CSV file exists with header
    if [[ ! -f "$DATA_FILE" ]]; then
        mkdir -p "$PERF_DIR"
        echo "timestamp,commit_hash,commit_number,branch,build_type,target,duration_ms,modules_compiled,warning_count,error_count,notes" > "$DATA_FILE"
    fi

    # Append measurement
    echo "$timestamp,$commit_hash,$commit_num,$branch,$build_type,$target,$duration_ms,$modules_compiled,$warning_count,$error_count,$notes" >> "$DATA_FILE"

    log_success "Recorded measurement to $DATA_FILE"
}

# Get baseline from baselines.json
get_baseline() {
    local build_type="$1"
    local target="${2:-erlang}"

    if [[ ! -f "$BASELINES_FILE" ]]; then
        if [[ "$build_type" == "clean" ]]; then
            echo "3000"  # Default clean build baseline
        else
            echo "150"   # Default incremental build baseline
        fi
        return
    fi

    # Extract baseline_ms for build type
    local baseline
    local key="${build_type}_build_${target}"

    if [[ "$build_type" == "clean" ]]; then
        baseline=$(jq -r ".clean_build_${target}.baseline_ms // 3000" "$BASELINES_FILE" 2>/dev/null || echo "3000")
    else
        baseline=$(jq -r ".incremental_build_${target}.baseline_ms // 150" "$BASELINES_FILE" 2>/dev/null || echo "150")
    fi

    echo "$baseline"
}

# Compare against baseline and show status
check_regression() {
    local duration_ms="$1"
    local build_type="$2"
    local target="$3"

    local baseline
    baseline=$(get_baseline "$build_type" "$target")

    local diff_ms=$((duration_ms - baseline))
    local diff_percent=0

    if [[ $baseline -gt 0 ]]; then
        diff_percent=$(( (diff_ms * 100) / baseline ))
    fi

    if [[ $diff_percent -gt 100 ]]; then
        log_error "CRITICAL REGRESSION: ${duration_ms}ms vs baseline ${baseline}ms (+${diff_percent}%)"
        return 2
    elif [[ $diff_percent -gt 50 ]]; then
        log_warning "Performance degradation: ${duration_ms}ms vs baseline ${baseline}ms (+${diff_percent}%)"
        return 1
    elif [[ $diff_percent -lt -20 ]]; then
        log_success "Performance improvement: ${duration_ms}ms vs baseline ${baseline}ms (${diff_percent}%)"
        return 0
    else
        log_info "Performance within normal range: ${duration_ms}ms (baseline: ${baseline}ms, ${diff_percent:+$diff_percent}%)"
        return 0
    fi
}

# Update baselines file with new measurement
update_baseline() {
    local build_type="$1"
    local target="$2"
    local duration_ms="$3"

    if [[ ! -f "$BASELINES_FILE" ]]; then
        cat > "$BASELINES_FILE" <<EOF
{
  "clean_build_erlang": {
    "baseline_ms": $duration_ms,
    "warning_threshold_percent": 50,
    "critical_threshold_percent": 100,
    "description": "Clean build baseline (gleam clean && gleam build --target erlang)"
  },
  "incremental_build_erlang": {
    "baseline_ms": 150,
    "warning_threshold_percent": 50,
    "critical_threshold_percent": 100,
    "description": "Incremental build baseline (gleam build --target erlang)"
  },
  "version": "1.0.0",
  "last_updated": "$(date +%Y-%m-%d)"
}
EOF
    else
        # Update existing baselines
        local key="${build_type}_build_${target}"
        local temp_file="$TEMP_DIR/baselines_updated.json"

        jq ".\"${key}\".baseline_ms = $duration_ms | .last_updated = \"$(date +%Y-%m-%d)\"" \
            "$BASELINES_FILE" > "$temp_file"

        mv "$temp_file" "$BASELINES_FILE"
    fi

    log_success "Updated baseline for ${build_type} build (${target}) to ${duration_ms}ms"
}

# Main execution
main() {
    local mode="both"
    local update_baselines=false
    local target="erlang"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --baseline)
                mode="clean"
                shift
                ;;
            --incremental)
                mode="incremental"
                shift
                ;;
            --both)
                mode="both"
                shift
                ;;
            --update-baselines)
                update_baselines=true
                shift
                ;;
            --target)
                target="$2"
                shift 2
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Usage: $0 [--baseline|--incremental|--both] [--update-baselines] [--target erlang|javascript]"
                exit 1
                ;;
        esac
    done

    log_info "Compilation Time Tracking - meal-planner"
    echo ""

    # Get commit information
    local commit_hash commit_num short_hash branch
    commit_hash=$(get_commit_hash)
    commit_num=$(get_commit_number)
    short_hash=$(get_short_hash)
    branch=$(get_branch_name)

    log_info "Commit: $short_hash (commit #$commit_num) on branch: $branch"
    echo ""

    # Get timestamp
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local regression_detected=false

    # Measure clean build
    if [[ "$mode" == "clean" ]] || [[ "$mode" == "both" ]]; then
        log_info "=== Clean Build Measurement ==="

        if result=$(measure_compilation "clean" "$target"); then
            IFS='|' read -r duration_ms modules_compiled warning_count error_count <<< "$result"

            # Record measurement
            record_measurement "$timestamp" "$commit_hash" "$commit_num" "$branch" "clean" "$target" \
                "$duration_ms" "$modules_compiled" "$warning_count" "$error_count" ""

            # Check for regression
            echo ""
            if ! check_regression "$duration_ms" "clean" "$target"; then
                regression_detected=true
            fi

            # Update baseline if requested
            if [[ "$update_baselines" == true ]]; then
                update_baseline "clean" "$target" "$duration_ms"
            fi

            echo ""
        else
            log_error "Clean build measurement failed"
            exit 1
        fi
    fi

    # Measure incremental build
    if [[ "$mode" == "incremental" ]] || [[ "$mode" == "both" ]]; then
        log_info "=== Incremental Build Measurement ==="

        if result=$(measure_compilation "incremental" "$target"); then
            IFS='|' read -r duration_ms modules_compiled warning_count error_count <<< "$result"

            # Record measurement
            record_measurement "$timestamp" "$commit_hash" "$commit_num" "$branch" "incremental" "$target" \
                "$duration_ms" "$modules_compiled" "$warning_count" "$error_count" ""

            # Check for regression
            echo ""
            if ! check_regression "$duration_ms" "incremental" "$target"; then
                regression_detected=true
            fi

            # Update baseline if requested
            if [[ "$update_baselines" == true ]]; then
                update_baseline "incremental" "$target" "$duration_ms"
            fi

            echo ""
        else
            log_error "Incremental build measurement failed"
            exit 1
        fi
    fi

    log_success "Compilation time tracking completed successfully"

    if [[ "$regression_detected" == true ]]; then
        exit 1
    fi
}

# Run main
main "$@"
