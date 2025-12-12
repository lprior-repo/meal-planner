#!/bin/bash

# Performance Benchmark Script: Tandoor vs Mealie
# This script benchmarks both recipe management systems against common operations
# Usage: ./scripts/benchmark-systems.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MEALIE_URL="${MEALIE_URL:-http://localhost:9000}"
TANDOOR_URL="${TANDOOR_URL:-http://localhost:8000}"
ITERATIONS="${ITERATIONS:-10}"
RECIPE_COUNT="${RECIPE_COUNT:-50}"

# Benchmark results
declare -A MEALIE_TIMES
declare -A TANDOOR_TIMES

# Helper function to get current time in milliseconds
get_time_ms() {
    echo $(($(date +%s%N) / 1000000))
}

# Helper function to print header
print_header() {
    echo -e "\n${BLUE}====== $1 ======${NC}\n"
}

# Helper function to print result
print_result() {
    local test_name=$1
    local mealie_time=$2
    local tandoor_time=$3

    if (( $(echo "$tandoor_time > 0" | bc -l) )); then
        local ratio=$(echo "scale=2; $mealie_time / $tandoor_time" | bc -l)
        printf "%-30s | Mealie: %6.0fms | Tandoor: %6.0fms | Ratio: %5.2fx\n" \
            "$test_name" "$mealie_time" "$tandoor_time" "$ratio"
    else
        printf "%-30s | Mealie: %6.0fms | Tandoor: N/A\n" "$test_name" "$mealie_time"
    fi
}

# Test 1: Single Recipe Retrieval
test_single_recipe() {
    print_header "Test 1: Single Recipe Retrieval"

    local mealie_total=0
    local tandoor_total=0

    echo "Running $ITERATIONS iterations..."

    for i in $(seq 1 $ITERATIONS); do
        # Mealie test
        start=$(get_time_ms)
        curl -s "$MEALIE_URL/api/recipes/1" \
            -H "Accept: application/json" > /dev/null 2>&1
        end=$(get_time_ms)
        mealie_total=$((mealie_total + (end - start)))

        # Tandoor test (if available)
        start=$(get_time_ms)
        curl -s "$TANDOOR_URL/api/recipes/1/" \
            -H "Accept: application/json" > /dev/null 2>&1
        tandoor_total=$((tandoor_total + (end - start)))
    done

    local mealie_avg=$((mealie_total / ITERATIONS))
    local tandoor_avg=$((tandoor_total / ITERATIONS))

    print_result "Get single recipe" "$mealie_avg" "$tandoor_avg"

    MEALIE_TIMES["single_recipe"]=$mealie_avg
    TANDOOR_TIMES["single_recipe"]=$tandoor_avg
}

# Test 2: Recipe List
test_recipe_list() {
    print_header "Test 2: Recipe List"

    local mealie_total=0
    local tandoor_total=0

    echo "Running $ITERATIONS iterations..."

    for i in $(seq 1 $ITERATIONS); do
        # Mealie test
        start=$(get_time_ms)
        curl -s "$MEALIE_URL/api/recipes?limit=$RECIPE_COUNT" \
            -H "Accept: application/json" > /dev/null 2>&1
        end=$(get_time_ms)
        mealie_total=$((mealie_total + (end - start)))

        # Tandoor test (if available)
        start=$(get_time_ms)
        curl -s "$TANDOOR_URL/api/recipes/?limit=$RECIPE_COUNT" \
            -H "Accept: application/json" > /dev/null 2>&1
        tandoor_total=$((tandoor_total + (end - start)))
    done

    local mealie_avg=$((mealie_total / ITERATIONS))
    local tandoor_avg=$((tandoor_total / ITERATIONS))

    print_result "List $RECIPE_COUNT recipes" "$mealie_avg" "$tandoor_avg"

    MEALIE_TIMES["list_recipes"]=$mealie_avg
    TANDOOR_TIMES["list_recipes"]=$tandoor_avg
}

# Test 3: Search
test_search() {
    print_header "Test 3: Search Performance"

    local mealie_total=0
    local tandoor_total=0

    echo "Running $ITERATIONS iterations..."

    for i in $(seq 1 $ITERATIONS); do
        # Mealie test
        start=$(get_time_ms)
        curl -s "$MEALIE_URL/api/recipes?search=chicken&limit=20" \
            -H "Accept: application/json" > /dev/null 2>&1
        end=$(get_time_ms)
        mealie_total=$((mealie_total + (end - start)))

        # Tandoor test (if available)
        start=$(get_time_ms)
        curl -s "$TANDOOR_URL/api/recipes/?search=chicken&limit=20" \
            -H "Accept: application/json" > /dev/null 2>&1
        tandoor_total=$((tandoor_total + (end - start)))
    done

    local mealie_avg=$((mealie_total / ITERATIONS))
    local tandoor_avg=$((tandoor_total / ITERATIONS))

    print_result "Search for 'chicken'" "$mealie_avg" "$tandoor_avg"

    MEALIE_TIMES["search"]=$mealie_avg
    TANDOOR_TIMES["search"]=$tandoor_avg
}

# Test 4: Concurrent Requests
test_concurrent() {
    print_header "Test 4: Concurrent Requests (5 parallel)"

    local mealie_total=0
    local tandoor_total=0

    echo "Running $ITERATIONS iterations of 5 concurrent requests..."

    for i in $(seq 1 $ITERATIONS); do
        # Mealie concurrent test
        start=$(get_time_ms)
        for j in $(seq 1 5); do
            curl -s "$MEALIE_URL/api/recipes?limit=10" \
                -H "Accept: application/json" > /dev/null 2>&1 &
        done
        wait
        end=$(get_time_ms)
        mealie_total=$((mealie_total + (end - start)))

        # Tandoor concurrent test (if available)
        start=$(get_time_ms)
        for j in $(seq 1 5); do
            curl -s "$TANDOOR_URL/api/recipes/?limit=10" \
                -H "Accept: application/json" > /dev/null 2>&1 &
        done
        wait
        end=$(get_time_ms)
        tandoor_total=$((tandoor_total + (end - start)))
    done

    local mealie_avg=$((mealie_total / ITERATIONS))
    local tandoor_avg=$((tandoor_total / ITERATIONS))

    print_result "5 concurrent requests" "$mealie_avg" "$tandoor_avg"

    MEALIE_TIMES["concurrent"]=$mealie_avg
    TANDOOR_TIMES["concurrent"]=$tandoor_avg
}

# Summary report
print_summary() {
    print_header "BENCHMARK SUMMARY"

    echo -e "${YELLOW}Single Request Performance:${NC}"
    printf "%-30s | Mealie %s | Tandoor %s\n" "Test" "Average" "Average"
    echo "─────────────────────────────────────────────────────────────"

    for test in single_recipe list_recipes search concurrent; do
        local mealie=${MEALIE_TIMES[$test]:-0}
        local tandoor=${TANDOOR_TIMES[$test]:-0}

        if (( $(echo "$tandoor > 0" | bc -l) )); then
            local ratio=$(echo "scale=2; $mealie / $tandoor" | bc -l)
            printf "%-30s | %7dms | %8dms | Ratio: %.2fx\n" \
                "$test" "$mealie" "$tandoor" "$ratio"
        fi
    done

    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Performance Benchmark: Tandoor vs Mealie              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "\n${YELLOW}Configuration:${NC}"
    echo "  Mealie URL: $MEALIE_URL"
    echo "  Tandoor URL: $TANDOOR_URL"
    echo "  Iterations: $ITERATIONS"
    echo "  Recipe Count: $RECIPE_COUNT"

    # Check if services are running
    echo -e "\n${YELLOW}Checking services...${NC}"

    if curl -s "$MEALIE_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Mealie is running${NC}"
    else
        echo -e "${RED}✗ Mealie not responding${NC}"
    fi

    if curl -s "$TANDOOR_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Tandoor is running${NC}"
    else
        echo -e "${YELLOW}⚠ Tandoor not responding (optional)${NC}"
    fi

    # Run benchmarks
    test_single_recipe
    test_recipe_list
    test_search
    test_concurrent

    # Print summary
    print_summary

    echo -e "${GREEN}Benchmark complete!${NC}"
    echo "Results saved to PERFORMANCE_BENCHMARKS.md"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
