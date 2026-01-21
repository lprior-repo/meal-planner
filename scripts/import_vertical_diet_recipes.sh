#!/bin/bash
# Import Vertical Diet recipes into Tandoor
#
# Usage:
#   export TANDOOR_BASE_URL="http://localhost:8090"
#   export TANDOOR_API_TOKEN="your-token-here"
#   ./scripts/import_vertical_diet_recipes.sh
#
# This script reads data/vertical-diet/vertical_diet_recipes.json and creates each recipe in Tandoor
# using the tandoor_create_recipe binary.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RECIPES_FILE="$PROJECT_ROOT/data/vertical-diet/vertical_diet_recipes.json"
BINARY="$PROJECT_ROOT/target/debug/tandoor_create_recipe"

# Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo "Error: tandoor_create_recipe binary not found at $BINARY"
    echo "Run: cargo build --bin tandoor_create_recipe"
    exit 1
fi

# Check if recipes file exists
if [ ! -f "$RECIPES_FILE" ]; then
    echo "Error: Vertical Diet recipes file not found at $RECIPES_FILE"
    exit 1
fi

# Check environment variables
if [ -z "${TANDOOR_BASE_URL:-}" ]; then
    echo "Error: TANDOOR_BASE_URL environment variable not set"
    exit 1
fi

if [ -z "${TANDOOR_API_TOKEN:-}" ]; then
    echo "Error: TANDOOR_API_TOKEN environment variable not set"
    exit 1
fi

echo "=== Vertical Diet Recipe Importer ==="
echo "Tandoor URL: $TANDOOR_BASE_URL"
echo "Recipes file: $RECIPES_FILE"
echo ""

# Extract recipe count
RECIPE_COUNT=$(jq '.recipes | length' "$RECIPES_FILE")
echo "Found $RECIPE_COUNT recipes to import"
echo ""

# Create temporary directory for logs
LOG_DIR="$PROJECT_ROOT/logs/vertical-diet-import"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/import_${TIMESTAMP}.log"
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "Importing recipes..."
echo "Logs: $LOG_FILE"
echo ""

# Read recipes array and process each one
jq -c '.recipes[]' "$RECIPES_FILE" | while IFS= read -r recipe; do
    RECIPE_NAME=$(echo "$recipe" | jq -r '.name')
    echo -n "Importing: $RECIPE_NAME ... "

    # Build input JSON for tandoor_create_recipe
    INPUT=$(jq -n \
        --arg base_url "$TANDOOR_BASE_URL" \
        --arg api_token "$TANDOOR_API_TOKEN" \
        --argjson recipe "$recipe" \
        '{
            tandoor: {
                base_url: $base_url,
                api_token: $api_token
            },
            recipe: $recipe,
            additional_keywords: ["vertical-diet"]
        }')

    # Call tandoor_create_recipe binary
    if OUTPUT=$(echo "$INPUT" | "$BINARY" 2>&1); then
        RECIPE_ID=$(echo "$OUTPUT" | jq -r '.recipe_id // "unknown"')
        echo "SUCCESS (ID: $RECIPE_ID)"
        echo "$OUTPUT" >> "$LOG_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "FAILED"
        echo "Recipe: $RECIPE_NAME" >> "$LOG_FILE"
        echo "Error: $OUTPUT" >> "$LOG_FILE"
        echo "---" >> "$LOG_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Small delay to avoid overwhelming the API
    sleep 0.5
done

echo ""
echo "=== Import Complete ==="
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Total: $RECIPE_COUNT"
echo ""
echo "See full log at: $LOG_FILE"
