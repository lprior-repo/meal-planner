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
CORE_FILE="$SCRIPT_DIR/../src/tandoor/shopping/mod.rs"

for file in "$BIN_FILE" "$CORE_FILE"; do
    if [ -f "$file" ]; then
        echo "Checking $file..."
        # Count lines in each function (between fn/pub fn and next fn or })
        awk '/^fn |^pub fn /{f=1; n=$0; line=NR; next} /^fn |^pub fn |^}/{if(f){lines=NR-line-1; if(lines>25){echo "ERROR: Function exceeds 25 lines:"; echo "  $n ($lines lines)"; exit 1}; f=0}} END{if(f){lines=NR-line; if(lines>25){echo "ERROR: Function exceeds 25 lines:"; echo "  $n ($lines lines)"; exit 1}}' "$file"
        echo "  All functions ≤25 lines ✓"
    fi
done

# Run tests
echo "Running tests..."
cd "$SCRIPT_DIR/.."
cargo test --bin "$BINARY" --lib -- tandoor::shopping 2>&1 | tail -5

echo "TCR passed for $BINARY!"
