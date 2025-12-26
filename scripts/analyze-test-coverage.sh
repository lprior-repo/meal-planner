#!/usr/bin/env bash
# Test Coverage Analysis Script
# Analyzes test coverage across the meal-planner codebase

set -euo pipefail

PROJECT_ROOT="/home/lewis/src/meal-planner"
SRC_DIR="$PROJECT_ROOT/src/meal_planner"
TEST_DIR="$PROJECT_ROOT/test"

echo "========================================="
echo "TEST COVERAGE ANALYSIS"
echo "========================================="
echo ""

# Count total files
TOTAL_SRC_FILES=$(fd -e gleam . "$SRC_DIR" | wc -l)
TOTAL_TEST_FILES=$(fd -e gleam . "$TEST_DIR" | wc -l)

echo "Total source files: $TOTAL_SRC_FILES"
echo "Total test files: $TOTAL_TEST_FILES"
echo "Test file ratio: $(echo "scale=2; $TOTAL_TEST_FILES / $TOTAL_SRC_FILES * 100" | bc)%"
echo ""

# Analyze coverage by module
echo "========================================="
echo "COVERAGE BY MODULE"
echo "========================================="
echo ""

for module_dir in "$SRC_DIR"/*/ ; do
    module_name=$(basename "$module_dir")

    # Skip test_helpers (not production code)
    if [ "$module_name" = "test_helpers" ]; then
        continue
    fi

    src_count=$(fd -e gleam . "$module_dir" 2>/dev/null | wc -l || echo 0)
    test_count=$(fd -e gleam . "$TEST_DIR" --full-path "$module_name" 2>/dev/null | wc -l || echo 0)

    if [ "$src_count" -gt 0 ]; then
        coverage_pct=$(echo "scale=1; $test_count / $src_count * 100" | bc 2>/dev/null || echo "0")
        printf "%-20s Source: %3d  Tests: %3d  Coverage: %5.1f%%\n" "$module_name" "$src_count" "$test_count" "$coverage_pct"
    fi
done

echo ""
echo "========================================="
echo "UNTESTED MODULES"
echo "========================================="
echo ""

# Find source files without corresponding tests
fd -e gleam . "$SRC_DIR" | while read -r src_file; do
    # Get relative path from src/meal_planner
    rel_path="${src_file#$SRC_DIR/}"

    # Convert to test path
    test_file="$TEST_DIR/meal_planner/${rel_path%.gleam}_test.gleam"

    if [ ! -f "$test_file" ]; then
        echo "No test for: $rel_path"
    fi
done | head -50

echo ""
echo "========================================="
echo "LARGE TEST FILES (>500 lines)"
echo "========================================="
echo ""

fd -e gleam . "$TEST_DIR" -x wc -l {} + | sort -rn | awk '$1 > 500 {print $1, $2}' | head -20

echo ""
echo "Analysis complete."
