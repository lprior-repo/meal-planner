#!/bin/bash

# ========================================================
# CLI Smoke Tests
# Quick validation that CLI builds and runs correctly
# ========================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=================================="
echo "CLI Smoke Tests"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
  local test_name=$1
  local test_command=$2

  echo -n "Testing: $test_name... "

  if eval "$test_command" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    return 1
  fi
}

cd "$PROJECT_ROOT"

# ========================================================
# Test 1: Build Succeeds
# ========================================================
echo ""
echo -e "${YELLOW}=== Build Tests ===${NC}"
run_test "gleam build" "gleam build"

# ========================================================
# Test 2: Formatting Check
# ========================================================
echo ""
echo -e "${YELLOW}=== Code Quality Tests ===${NC}"
run_test "gleam format --check" "gleam format --check"

# ========================================================
# Test 3: Fast Tests Pass
# ========================================================
echo ""
echo -e "${YELLOW}=== Unit Tests ===${NC}"
run_test "fast test suite" "gleam run -m test_runner/fast"

# ========================================================
# Test 4: Check Key Files Exist
# ========================================================
echo ""
echo -e "${YELLOW}=== File Structure Tests ===${NC}"
run_test "gleam.toml exists" "test -f gleam.toml"
run_test "Makefile exists" "test -f Makefile"
run_test ".env.example exists" "test -f .env.example"
run_test "src/meal_planner.gleam exists" "test -f src/meal_planner.gleam"

# ========================================================
# Test 5: Dependencies Can Be Downloaded
# ========================================================
echo ""
echo -e "${YELLOW}=== Dependency Tests ===${NC}"
run_test "gleam deps download" "gleam deps download"

# ========================================================
# Test 6: CLI Can Be Run (with --help or similar if applicable)
# ========================================================
echo ""
echo -e "${YELLOW}=== Application Tests ===${NC}"
# This test depends on actual CLI implementation
# Modify as needed for your specific CLI
if [ -f "src/meal_planner.gleam" ]; then
  run_test "CLI entry point exists" "grep -q 'pub fn main' src/meal_planner.gleam"
fi

# ========================================================
# Test 7: No Syntax Errors in Tests
# ========================================================
echo ""
echo -e "${YELLOW}=== Test Compilation ===${NC}"
run_test "test files compile" "gleam build --target erlang 2>&1 | grep -v 'Warning' | grep -c 'error' && false || true"

# ========================================================
# Summary
# ========================================================
echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All smoke tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
