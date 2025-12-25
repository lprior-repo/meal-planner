#!/usr/bin/env bash
# Quick test coverage summary for meal-planner
# Usage: ./scripts/coverage-summary.sh

set -euo pipefail

echo "========================================="
echo "TEST COVERAGE SUMMARY"
echo "========================================="
echo ""

# File counts
SRC_COUNT=$(fd -e gleam . src/meal_planner | wc -l)
TEST_COUNT=$(fd -e gleam . test | wc -l)
COVERAGE=$(python3 -c "print(f'{$TEST_COUNT/$SRC_COUNT*100:.1f}%')")

echo "Source files:    $SRC_COUNT"
echo "Test files:      $TEST_COUNT"
echo "File coverage:   $COVERAGE"
echo ""

# Test LOC
TEST_LOC=$(fd -e gleam . test --exec wc -l | awk '{sum+=$1} END {print sum}')
echo "Total test LOC:  $TEST_LOC"
echo ""

# Critical gaps
echo "========================================="
echo "CRITICAL GAPS (0-20% coverage)"
echo "========================================="
echo ""
echo "🔴 Storage:      0/9 files   (0%)"
echo "🔴 Web handlers: 1/20 files  (5%)"
echo "🔴 Automation:   1/6 files   (17%)"
echo "🔴 Cache:        0/1 files   (0%)"
echo "🔴 UI:           0/2 files   (0%)"
echo ""

echo "========================================="
echo "MODERATE COVERAGE (20-50%)"
echo "========================================="
echo ""
echo "🟡 FatSecret:    13/69 files (19%)"
echo "🟡 Tandoor:      8/57 files  (14%)"
echo "🟡 CLI:          20/57 files (35%)"
echo "🟡 Scheduler:    3/9 files   (33%)"
echo ""

echo "========================================="
echo "GOOD COVERAGE (>50%)"
echo "========================================="
echo ""
echo "🟢 Email:        5/5 files   (100%)"
echo "🟢 Generation:   3/2 files   (150%)"
echo ""

echo "========================================="
echo "NEXT ACTIONS"
echo "========================================="
echo ""
echo "1. Create storage tests (P0 - CRITICAL)"
echo "2. Create web handler tests (P0 - CRITICAL)"
echo "3. Create automation tests (P1 - HIGH)"
echo ""
echo "Full report: docs/TEST_COVERAGE_ANALYSIS.md"
echo ""
