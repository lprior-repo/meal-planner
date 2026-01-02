#!/bin/bash
set -e

echo "=== Adding Calories to All Tandoor Recipes ==="

# Resources
TANDOOR_RES='$res:u/admin/tandoor_api'
FATSECRET_RES='$res:u/admin/fatsecret_api'

# Get all recipes
echo ""
echo "Fetching all recipes..."
ALL_RECIPES=$(wmill script run f/tandoor/recipe_get_all_ingredients -d "{\"tandoor\": \"$TANDOOR_RES\", \"page_size\": 100}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

if ! echo "$ALL_RECIPES" | jq -e '.recipes' >/dev/null 2>&1; then
	echo "Error: Failed to get recipes"
	exit 1
fi

RECIPE_COUNT=$(echo "$ALL_RECIPES" | jq -r '.count | tonumber')
echo "Found $RECIPE_COUNT recipes"

# Process each recipe
for i in $(seq 0 $((RECIPE_COUNT - 1))); do
	RECIPE_INFO=$(echo "$ALL_RECIPES" | jq -c ".recipes[$i]")
	RECIPE_ID=$(echo "$RECIPE_INFO" | jq -r '.id')
	RECIPE_NAME=$(echo "$RECIPE_INFO" | jq -r '.name')
	SERVINGS=$(echo "$RECIPE_INFO" | jq -r '.servings')

	echo ""
	echo "[$((i + 1))/$RECIPE_COUNT] $RECIPE_NAME (ID: $RECIPE_ID, $SERVINGS servings)"

	# Process each ingredient
	TOTAL_CALORIES=0
	VALID_FOODS=0

	echo "$RECIPE_INFO" | jq -r '.ingredients[] | .food_name' | while read -r FOOD; do
		[ -z "$FOOD" ] && continue

		# Clean food name for search
		SEARCH_TERM=$(echo "$FOOD" | sed 's/ (.*$//' | sed 's/,.*$//' | sed 's/ fresh$//' | sed 's/ s$//')

		# Search FatSecret
		SEARCH_RESULT=$(wmill script run f/fatsecret/foods_search -d "{\"fatsecret\": \"$FATSECRET_RES\", \"query\": \"$SEARCH_TERM\", \"max_results\": 1}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$SEARCH_RESULT" | jq -e '.foods.food[0]' >/dev/null 2>&1; then
			echo "    ✗ $FOOD - Not found in FatSecret"
			continue
		fi

		FOOD_ID=$(echo "$SEARCH_RESULT" | jq -r '.foods.food[0].food_id')

		# Get food details
		FOOD_DETAIL=$(wmill script run f/fatsecret/food_get -d "{\"fatsecret\": \"$FATSECRET_RES\", \"food_id\": $FOOD_ID}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$FOOD_DETAIL" | jq -e '.food.servings.serving[0].calories' >/dev/null 2>&1; then
			echo "    ✗ $FOOD - No calorie data"
			continue
		fi

		CALS_PER_100G=$(echo "$FOOD_DETAIL" | jq -r '.food.servings.serving[0].calories')

		# Get ingredient amount from recipe
		ING_AMOUNT=$(echo "$RECIPE_INFO" | jq -r ".ingredients[] | select(.food_name == \"$FOOD\") | .amount // 1")

		# Estimate calories (assume 100g per unit as approximation)
		if command -v bc >/dev/null 2>&1; then
			ING_CALS=$(echo "$ING_AMOUNT * $CALS_PER_100G / 100" | bc -l)
			ING_CALS=$(printf "%.0f" "$ING_CALS")
		else
			ING_CALS=0
		fi

		TOTAL_CALORIES=$((TOTAL_CALORIES + ING_CALS))
		VALID_FOODS=$((VALID_FOODS + 1))

		echo "    +$ING_CALS cal ($SEARCH_TERM: $CALS_PER_100G cal/100g, amount: $ING_AMOUNT)"
	done

	if [ $VALID_FOODS -eq 0 ]; then
		echo "  ! No valid foods with nutrition data"
		continue
	fi

	# Calculate per serving
	CALS_PER_SERVING=$((TOTAL_CALORIES / SERVINGS))

	echo "  ✓ Total: $TOTAL_CALORIES calories ($CALS_PER_SERVING per serving, $SERVINGS servings)"

	sleep 0.3 # Rate limiting
done

echo ""
echo "=== Complete ==="
echo "Processed $RECIPE_COUNT recipes"
