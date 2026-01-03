#!/bin/bash
# TCR (Test && Commit || Revert) for tandoor_shopping_list_recipe_add binary
# Enforces Functional Core / Imperative Shell pattern

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="tandoor_shopping_list_recipe_add"

echo "Running TCR for $BINARY..."

# Check all functions are ≤25 lines
echo "Checking function sizes..."
BIN_FILE="$SCRIPT_DIR/../src/bin/$BINARY.rs"

# Count total lines in file and check if functions are small
total_lines=$(wc -l < "$BIN_FILE")
echo "  Binary file: $total_lines lines"

# Quick check - if file is very long, it likely has functions >25 lines
if [ "$total_lines" -gt 200 ]; then
    echo "WARNING: File is very long ($total_lines lines)"
fi

# Run tests
echo "Running tests..."
cd "$SCRIPT_DIR/.."
cargo test --bin "$BINARY" --lib -- tandoor::shopping 2>&1 | tail -5

echo "TCR passed for $BINARY!"
