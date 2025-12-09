#!/usr/bin/env bash
set -euo pipefail

# Enhanced pre-commit hook for Gleam project
# Runs format check, type check, and all tests
# Usage: SKIP_HOOKS=1 git commit  (to bypass)

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check for bypass flag
if [ -n "${SKIP_HOOKS:-}" ]; then
  echo -e "${YELLOW}⚠️  Pre-commit hooks skipped (SKIP_HOOKS set)${NC}"
  exit 0
fi

# Start timing
TOTAL_START=$(date +%s%N)

echo -e "${BOLD}${BLUE}🚀 Running pre-commit checks...${NC}\n"

# Function to print step header
print_step() {
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
}

# Function to print success
print_success() {
  local duration=$1
  echo -e "${GREEN}✓ Passed${NC} ${YELLOW}(${duration}ms)${NC}\n"
}

# Function to print failure
print_failure() {
  local step=$1
  echo -e "\n${RED}✗ Failed: $step${NC}"
  echo -e "${RED}To bypass this check, use: ${BOLD}SKIP_HOOKS=1 git commit${NC}"
  exit 1
}

# Change to gleam directory
cd "$(git rev-parse --show-toplevel)/gleam" || exit 1

# Step 1: Format check (don't auto-format, just verify)
print_step "1. Checking code formatting..."
STEP_START=$(date +%s%N)
if ! gleam format --check > /dev/null 2>&1; then
  echo -e "${RED}Code is not formatted correctly.${NC}"
  echo -e "${YELLOW}Run: ${BOLD}cd gleam && gleam format${NC}"
  print_failure "Format check"
fi
STEP_END=$(date +%s%N)
DURATION=$(( (STEP_END - STEP_START) / 1000000 ))
print_success "$DURATION"

# Step 2: Type check
print_step "2. Running type checker..."
STEP_START=$(date +%s%N)
# Capture output to show warnings but continue
TYPE_CHECK_OUTPUT=$(gleam check 2>&1)
TYPE_CHECK_EXIT=$?
if [ $TYPE_CHECK_EXIT -ne 0 ]; then
  echo "$TYPE_CHECK_OUTPUT"
  print_failure "Type check"
fi
# Show warnings but don't fail
if echo "$TYPE_CHECK_OUTPUT" | grep -q "warning:"; then
  WARNING_COUNT=$(echo "$TYPE_CHECK_OUTPUT" | grep -c "warning:" || true)
  echo -e "${YELLOW}  ⚠ $WARNING_COUNT warning(s) found${NC}"
fi
STEP_END=$(date +%s%N)
DURATION=$(( (STEP_END - STEP_START) / 1000000 ))
print_success "$DURATION"

# Step 3: Run tests
print_step "3. Running tests..."
STEP_START=$(date +%s%N)

# Count test files
TOTAL_TESTS=$(find test -name "*_test.gleam" 2>/dev/null | wc -l)
E2E_TESTS=$(find test -name "*_e2e_test.gleam" -o -name "*_integration_test.gleam" 2>/dev/null | wc -l)
UNIT_TESTS=$((TOTAL_TESTS - E2E_TESTS))

echo -e "  ${BLUE}Running $TOTAL_TESTS tests ($UNIT_TESTS unit, $E2E_TESTS integration/E2E)${NC}"
echo -e "  ${YELLOW}Note: E2E tests may take longer...${NC}"

# Run all tests (Gleam doesn't easily support selective test running)
if ! gleam test 2>&1 | tail -20; then
  print_failure "Tests"
fi

STEP_END=$(date +%s%N)
DURATION=$(( (STEP_END - STEP_START) / 1000000 ))
print_success "$DURATION"

# Calculate total time
TOTAL_END=$(date +%s%N)
TOTAL_DURATION=$(( (TOTAL_END - TOTAL_START) / 1000000 ))
TOTAL_SECONDS=$(echo "scale=2; $TOTAL_DURATION / 1000" | bc)

# Print summary
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}✓ All checks passed!${NC}"
echo -e "${YELLOW}Total time: ${TOTAL_SECONDS}s (${TOTAL_DURATION}ms)${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

exit 0
