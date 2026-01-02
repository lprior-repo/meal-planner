#!/bin/bash
# ATDD Four-Layer Architecture - TCR (Test && Commit || Revert) Script
#
# Dave Farley: "TCR enforces that you never leave broken tests in your codebase."
#
# Usage: ./scripts/tcr.sh [message]
#
# GATE-6: TCR Enforcement
# - Run tests
# - If all pass: commit changes
# - If any fail: revert to previous commit

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMMIT_MSG="${1:-$(git log -1 --pretty=%B | head -1)}"
GIT_HOOKS_DIR=".githooks"
PASS_COUNT=0
FAIL_COUNT=0

echo "=============================================="
echo "ATDD TCR Enforcement (GATE-6)"
echo "=============================================="
echo ""

# Get current commit hash before any changes
BEFORE_COMMIT=$(git rev-parse HEAD)
echo "Before commit: $BEFORE_COMMIT"
echo ""

# Step 1: Run all tests via Moon
echo -e "${YELLOW}Step 1: Running tests via Moon...${NC}"
echo ""

if moon run :test; then
	echo -e "${GREEN}✓ All tests passed${NC}"
	PASS_COUNT=$((PASS_COUNT + 1))
else
	echo -e "${RED}✗ Tests failed${NC}"
	FAIL_COUNT=$((FAIL_COUNT + 1))
	echo ""
	echo "=============================================="
	echo -e "${RED}TCR: Tests failed - REVERTING${NC}"
	echo "=============================================="
	echo ""
	echo "Reverting to commit: $BEFORE_COMMIT"
	git reset --hard "$BEFORE_COMMIT"
	echo ""
	echo -e "${RED}Reverted! Changes discarded.${NC}"
	echo ""
	echo "Fix your tests and run TCR again."
	exit 1
fi

echo ""

# Step 2: Validate line counts (GATE-4)
echo -e "${YELLOW}Step 2: Validating function line counts (GATE-4)...${NC}"
echo ""

VIOLATIONS=$(find tests/atdd -name "*.rs" -exec awk '
    /^fn [a-z_]+\([^)]*\)\s*(-> [^=]+)?\s*\{/ {
        start=NR
    }
    /^}/ && start > 0 {
        lines=NR-start+1
        if (lines > 25) {
            print FILENAME ":" start ": Function exceeds 25 lines (" lines " lines)"
        }
        start=0
    }
' {} \;)

if [ -n "$VIOLATIONS" ]; then
	echo -e "${RED}✗ Line count violations found:${NC}"
	echo "$VIOLATIONS"
	FAIL_COUNT=$((FAIL_COUNT + 1))
	echo ""
	echo "=============================================="
	echo -e "${RED}TCR: Line count violations - REVERTING${NC}"
	echo "=============================================="
	echo ""
	git reset --hard "$BEFORE_COMMIT"
	echo -e "${RED}Reverted!${NC}"
	echo ""
	echo "Refactor functions to be ≤25 lines."
	exit 1
else
	echo -e "${GREEN}✓ All functions ≤25 lines${NC}"
	PASS_COUNT=$((PASS_COUNT + 1))
fi

echo ""

# Step 3: Validate Layer separation (GATE-1, GATE-2, GATE-3)
echo -e "${YELLOW}Step 3: Validating Layer separation...${NC}"
echo ""

LAYER_VIOLATIONS=0

# Check Layer 1 (acceptance tests) - should NOT contain HTTP/SQL implementation
if grep -r "http://\|https://\|sqlx\|reqwest::" tests/atdd/layer1*.rs 2>/dev/null; then
	echo -e "${RED}✗ Layer 1 contains implementation details${NC}"
	LAYER_VIOLATIONS=$((LAYER_VIOLATIONS + 1))
fi

# Check Layer 3 (protocol drivers) - SHOULD contain I/O
if ! grep -r "reqwest\|Command\|spawn" tests/atdd/layer3*.rs 2>/dev/null; then
	echo -e "${YELLOW}⚠ Layer 3 missing protocol implementation${NC}"
fi

if [ $LAYER_VIOLATIONS -gt 0 ]; then
	FAIL_COUNT=$((FAIL_COUNT + 1))
	echo ""
	echo "=============================================="
	echo -e "${RED}TCR: Layer violations - REVERTING${NC}"
	echo "=============================================="
	git reset --hard "$BEFORE_COMMIT"
	exit 1
else
	echo -e "${GREEN}✓ Layer separation valid${NC}"
	PASS_COUNT=$((PASS_COUNT + 1))
fi

echo ""

# Step 4: Run clippy (GATE-2, GATE-3)
echo -e "${YELLOW}Step 4: Running Clippy lints...${NC}"
echo ""

if cargo clippy --all-targets --all-features -- -D warnings 2>&1 | grep -q "error"; then
	echo -e "${RED}✗ Clippy errors found${NC}"
	FAIL_COUNT=$((FAIL_COUNT + 1))
	echo ""
	echo "=============================================="
	echo -e "${RED}TCR: Clippy errors - REVERTING${NC}"
	echo "=============================================="
	git reset --hard "$BEFORE_COMMIT"
	exit 1
else
	echo -e "${GREEN}✓ Clippy passed${NC}"
	PASS_COUNT=$((PASS_COUNT + 1))
fi

echo ""

# Step 5: Commit changes
echo -e "${YELLOW}Step 5: Committing changes...${NC}"
echo ""

git add -A
git commit -m "[ATDD] $COMMIT_MSG"

AFTER_COMMIT=$(git rev-parse HEAD)
echo -e "${GREEN}✓ Committed: $AFTER_COMMIT${NC}"
PASS_COUNT=$((PASS_COUNT + 1))

echo ""
echo "=============================================="
echo -e "${GREEN}TCR: ALL GATES PASSED${NC}"
echo "=============================================="
echo ""
echo "Summary:"
echo "  - Tests: ${PASS_COUNT} checks passed, ${FAIL_COUNT} failed"
echo "  - Commit: $AFTER_COMMIT"
echo ""
echo "Gates validated:"
echo "  ✓ GATE-1: Domain language tests"
echo "  ✓ GATE-2: DSL implementation tests"
echo "  ✓ GATE-3: Protocol drivers pure"
echo "  ✓ GATE-4: Functions ≤25 lines"
echo "  ✓ GATE-5: All layers GREEN"
echo "  ✓ GATE-6: TCR enforcement"
echo ""

exit 0
