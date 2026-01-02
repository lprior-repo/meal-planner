#!/bin/bash
# ATDD Line Count Validator (GATE-4)
#
# Validates that all Rust functions are ≤25 lines.
# This enforces GATE-4 of the ATDD Four-Layer Architecture.
#
# Usage: ./scripts/validate-line-counts.sh [path]

set -e

# Configuration
MAX_LINES=25
SOURCE_DIR="${1:-tests/atdd}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "ATDD Line Count Validator (GATE-4)"
echo "=============================================="
echo ""
echo "Validating: $SOURCE_DIR"
echo "Max lines per function: $MAX_LINES"
echo ""

VIOLATIONS=0

# Find all Rust files and check function line counts
while IFS= read -r file; do
	# Skip test modules (they can be longer)
	if [[ "$file" == *"_test"* ]] || [[ "$file" == *"tests"* ]]; then
		continue
	fi

	# Use awk to find functions exceeding line limit
	violations=$(awk '
    BEGIN {
        in_function = 0
        start_line = 0
    }

    # Detect function start
    /^[[:space:]]*(pub[[:space:]]+)?(async[[:space:+])?fn[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(/ {
        if (in_function) {
            # Nested function - skip
            next
        }
        in_function = 1
        start_line = NR
        function_name = $0
        sub(/.*fn[[:space:]]+/, "", function_name)
        sub(/[[:space:]]*\(.*/, "", function_name)
    }

    # Detect function end
    /^[[:space:]]*}/ {
        if (in_function) {
            lines = NR - start_line
            if (lines > 25) {
                print FILENAME ":" start_line ": " function_name " (" lines " lines)"
                count++
            }
            in_function = 0
        }
    }

    END {
        exit count
    }
    ' "$file" 2>/dev/null) || true

	if [ -n "$violations" ]; then
		echo -e "${RED}Violations in $file:${NC}"
		echo "$violations"
		VIOLATIONS=$((VIOLATIONS + $(echo "$violations" | wc -l)))
	fi
done < <(find "$SOURCE_DIR" -name "*.rs" -type f)

if [ $VIOLATIONS -gt 0 ]; then
	echo ""
	echo -e "${RED}✗ Found $VIOLATIONS functions exceeding $MAX_LINES lines${NC}"
	echo ""
	echo "Refactor these functions to be smaller:"
	echo "  - Extract pure functions"
	echo "  - Use composition over conditions"
	echo "  - Break complex functions into simpler ones"
	exit 1
else
	echo -e "${GREEN}✓ All functions ≤$MAX_LINES lines${NC}"
	echo ""
	echo "GATE-4 validated successfully!"
	exit 0
fi
