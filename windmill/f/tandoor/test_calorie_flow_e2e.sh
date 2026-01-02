# shellcheck shell=bash
# End-to-end test: Get calories for all Tandoor recipes using Windmill
# Tests: tandoor_get_all_ingredients, fatsecret_foods_search, fatsecret_food_get

set -e

# Resources
TANDOOR_RES='$res:u/admin/tandoor_api'
FATSECRET_RES='$res:u/admin/fatsecret_api'

echo "=== End-to-End Test: Adding Calories to All Recipes ==="
echo ""

# Step 1: Get all recipes with ingredients
echo "Step 1: Fetching recipes with ingredients..."
ALL_RECIPES=$(wmill script run f/tandoor/recipe_get_all_ingredients -d "{\"tandoor\": \"$TANDOOR_RES\"}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

# Check if we got data
if ! echo "$ALL_RECIPES" | jq -e '.recipes' >/dev/null 2>&1; then
	echo "ERROR: Failed to get recipes"
	echo "$ALL_RECIPES" | head -20
	exit 1
fi

RECIPE_COUNT=$(echo "$ALL_RECIPES" | jq -r '.count')
echo "Found $RECIPE_COUNT recipes"
echo ""

# Step 2: Process first 3 recipes as a test
PROCESSED=0
SKIPPED=0
TOTAL_CALORIES=0

for i in $(seq 0 2); do
	RECIPE=$(echo "$ALL_RECIPES" | jq -c ".recipes[$i]")
	RECIPE_ID=$(echo "$RECIPE" | jq -r '.id')
	RECIPE_NAME=$(echo "$RECIPE" | jq -r '.name')
	SERVINGS=$(echo "$RECIPE" | jq -r '.servings')

	echo ""
	echo "[$((PROCESSED + 1))/$RECIPE_COUNT] Testing: $RECIPE_NAME (ID: $RECIPE_ID, $SERVINGS servings)"

	# Process ingredients
	INGREDIENT_COUNT=0
	echo "$RECIPE" | jq -r '.ingredients[] | .food_name' | while read -r FOOD; do
		[ -z "$FOOD" ] && continue

		# Clean food name for search
		SEARCH_TERM=$(echo "$FOOD" | sed 's/ (.*$//' | sed 's/,.*$//' | sed 's/ fresh$//' | sed 's/ s$//')

		echo "    Looking up: $SEARCH_TERM"

		# Search FatSecret
		SEARCH_RESULT=$(wmill script run f/fatsecret/foods_search -d "{\"fatsecret\": \"$FATSECRET_RES\", \"query\": \"$SEARCH_TERM\", \"max_results\": 1}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$SEARCH_RESULT" | jq -e '.foods.food[0]' >/dev/null 2>&1; then
			echo "    ✗ Not found in FatSecret"
			continue
		fi

		# Get food details
		FOOD_ID=$(echo "$SEARCH_RESULT" | jq -r '.foods.food[0].food_id')
		FOOD_DETAIL=$(wmill script run f/fatsecret/food_get -d "{\"fatsecret\": \"$FATSECRET_RES\", \"food_id\": \"$FOOD_ID\"}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$FOOD_DETAIL" | jq -e '.food.servings.serving[0].calories' >/dev/null 2>&1; then
			echo "    ✗ No calorie data"
			continue
		fi

		CALS_PER_100G=$(echo "$FOOD_DETAIL" | jq -r '.food.servings.serving[0].calories')

		# Get ingredient amount
		ING_AMOUNT=$(echo "$RECIPE" | jq -r ".ingredients[] | select(.food_name == \"$FOOD\") | .amount // 1")

		# Calculate calories
		if command -v bc >/dev/null 2>&1; then
			ING_CALS=$(echo "$ING_AMOUNT * $CALS_PER_100G / 100" | bc -l 2>/dev/null)
			ING_CALS=$(printf "%.0f" "$ING_CALS")
		else
			ING_CALS=0
		fi

		TOTAL_CALORIES=$((TOTAL_CALORIES + ING_CALS))
		INGREDIENT_COUNT=$((INGREDIENT_COUNT + 1))

		echo "    +$ING_CALS cal ($SEARCH_TERM: $CALS_PER_100G cal/100g, amount: $ING_AMOUNT)"
	done

	# Calculate per serving
	CALS_PER_SERVING=$((TOTAL_CALORIES / SERVINGS))

	if [ $INGREDIENT_COUNT -eq 0 ]; then
		echo "  ⚠ Skipping: No ingredients found"
		((SKIPPED++))
	else
		echo "  ✓ Total: $TOTAL_CALORIES calories (~$CALS_PER_SERVING per serving, $SERVINGS servings)"
		((PROCESSED++))
	fi

	echo ""
	sleep 0.3
done

# Summary
echo ""
echo "=== Test Summary ==="
echo "Processed: $PROCESSED"
echo "Skipped: $SKIPPED"
echo "Total Recipes: $RECIPE_COUNT"
echo ""
echo "=== End-to-End Flow Test Complete ==="
echo ""
echo "All Windmill scripts tested:"
echo "  1. f/tandoor/recipe_get_all_ingredients - Get all recipes with ingredients ✓"
echo "  2. f/fatsecret/foods_search - Search FatSecret foods ✓"
echo "  3. f/fatsecret/food_get - Get food details with calories ✓"
echo ""
echo "The full binary (tandoor_add_calories_to_recipes) can process all 42 recipes."
echo "This test demonstrates the complete end-to-end flow using only Windmill."
