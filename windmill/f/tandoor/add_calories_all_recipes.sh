# shellcheck shell=bash
# Add calories to all Tandoor recipes from FatSecret
# Uses Windmill to orchestrate the process

set -e

# Resources
TANDOOR_RES="\$res:u/admin/tandoor_api"
FATSECRET_RES="\$res:u/admin/fatsecret_api"

echo "=== Adding Calories to All Tandoor Recipes ==="

# Get FatSecret credentials from pass
CONSUMER_KEY=$(pass show meal-planner/fatsecret/consumer_key 2>&1)
CONSUMER_SECRET=$(pass show meal-planner/fatsecret/consumer_secret 2>&1)
OAUTH_TOKEN=$(pass show meal-planner/fatsecret/oauth_token 2>&1)
OAUTH_SECRET=$(pass show meal-planner/fatsecret/oauth_token_secret 2>&1)

# Build FatSecret config
FATSECRET_CONFIG=$(jq -n \
	--argjson tandoor "{\"base_url\": \"http://172.19.0.1:8090\", \"api_token\": \"tda_dcb794d0_e494_46b7_a7cf_43200a1b336e\"}" \
	--arg consumer_key "$CONSUMER_KEY" \
	--arg consumer_secret "$CONSUMER_SECRET" \
	--arg oauth_token "$OAUTH_TOKEN" \
	--arg oauth_token_secret "$OAUTH_SECRET" \
	'{
        "fatsecret": {
            "consumer_key": $consumer_key,
            "consumer_secret": $consumer_secret,
            "oauth_token": $oauth_token,
            "oauth_token_secret": $oauth_token_secret
        }
    }')

# Get all recipes (first batch)
echo ""
echo "Fetching recipes..."
RECIPES=$(wmill script run f/tandoor/recipe_list -d "{\"tandoor\": \"$TANDOOR_RES\", \"page_size\": 100}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

RECIPE_COUNT=$(echo "$RECIPES" | jq -r '.count')
echo "Found $RECIPE_COUNT recipes"

# Process each recipe
PROCESSED=0
SKIPPED=0
FAILED=0

for i in $(seq 0 $((RECIPE_COUNT - 1))); do
	RECIPE_INFO=$(echo "$RECIPES" | jq -c ".recipes[$i]")
	RECIPE_ID=$(echo "$RECIPE_INFO" | jq -r '.id')
	RECIPE_NAME=$(echo "$RECIPE_INFO" | jq -r '.name')

	echo ""
	echo "[$((PROCESSED + 1))/$RECIPE_COUNT] Processing: $RECIPE_NAME (ID: $RECIPE_ID)"

	# Get recipe details
	RECIPE_DETAIL=$(wmill script run f/tandoor/recipe_get -d "{\"tandoor\": \"$TANDOOR_RES\", \"id\": $RECIPE_ID}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

	if ! echo "$RECIPE_DETAIL" | jq -e '.recipe' >/dev/null 2>&1; then
		echo "  ✗ Failed to get recipe details"
		((FAILED++))
		continue
	fi

	# Extract unique food names
	FOODS=$(echo "$RECIPE_DETAIL" | jq -r '[.recipe.steps[].ingredients[]?.food.name] | unique | .[]')

	if [ -z "$FOODS" ]; then
		echo "  ! No ingredients found, skipping"
		((SKIPPED++))
		continue
	fi

	# Calculate calories for each ingredient
	TOTAL_CALORIES=0
	FOOD_COUNT=0

	while IFS= read -r FOOD; do
		[ -z "$FOOD" ] && continue

		# Clean food name for search
		SEARCH_TERM=$(echo "$FOOD" | sed 's/ (.*)$//' | sed 's/,.*$//' | sed 's/ fresh$//' | sed 's/ s$//')

		echo "    Looking up: $SEARCH_TERM"

		# Search FatSecret
		SEARCH_RESULT=$(wmill script run f/fatsecret/foods_search -d "{\"fatsecret\": \"$FATSECRET_RES\", \"query\": \"$SEARCH_TERM\", \"max_results\": 1}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$SEARCH_RESULT" | jq -e '.foods.food[0]' >/dev/null 2>&1; then
			echo "      ✗ Not found in FatSecret"
			continue
		fi

		FOOD_ID=$(echo "$SEARCH_RESULT" | jq -r '.foods.food[0].food_id')

		# Get food details
		FOOD_DETAIL=$(wmill script run f/fatsecret/food_get -d "{\"fatsecret\": \"$FATSECRET_RES\", \"food_id\": $FOOD_ID}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		if ! echo "$FOOD_DETAIL" | jq -e '.food' >/dev/null 2>&1; then
			echo "      ✗ Failed to get food details"
			continue
		fi

		# Get calories per 100g
		CALS_PER_100G=$(echo "$FOOD_DETAIL" | jq -r '.food.servings.serving[0].calories // 0')

		if [ "$CALS_PER_100G" = "0" ] || [ "$CALS_PER_100G" = "null" ]; then
			echo "      ! No calorie data"
			continue
		fi

		FOOD_COUNT=$((FOOD_COUNT + 1))

		# Get ingredient amount from recipe
		ING_AMOUNT=$(echo "$RECIPE_DETAIL" | jq -r ".recipe.steps[].ingredients[]? | select(.food.name == \"$FOOD\") | .amount // 1")

		# Estimate calories (assume 100g per unit as approximation)
		ING_CALS=$(echo "$ING_AMOUNT * $CALS_PER_100G / 100" | bc -l 2>/dev/null || echo "0")
		ING_CALS=$(printf "%.0f" "$ING_CALS")

		TOTAL_CALORIES=$((TOTAL_CALORIES + ING_CALS))

		echo "      +$ING_CALS cal (Food: $FOOD, Amount: $ING_AMOUNT, Cal/100g: $CALS_PER_100G)"
	done <<<"$FOODS"

	if [ $FOOD_COUNT -eq 0 ]; then
		echo "  ! No valid foods found"
		((SKIPPED++))
		continue
	fi

	# Get servings
	SERVINGS=$(echo "$RECIPE_DETAIL" | jq -r '.recipe.servings')
	CALS_PER_SERVING=$((TOTAL_CALORIES / SERVINGS))

	echo "  ✓ Total: $TOTAL_CALORIES calories (~$CALS_PER_SERVING per serving, $SERVINGS servings)"

	# Update recipe with calorie info
	# Note: Tandoor doesn't have a simple calorie field, so we'd add it to description
	UPDATED_DESC=$(echo "$RECIPE_DETAIL" | jq -r '.recipe.description // ""' | sed "s/$/\\n\\nCalories: ~$TOTAL_CALORIES ($CALS_PER_SERVING per serving)/")

	# Would update recipe here, but for now just tracking
	echo "  -> Would update description with calorie info"

	((PROCESSED++))

	sleep 0.5 # Rate limiting
done

# Summary
echo ""
echo "=== Summary ==="
echo "Processed: $PROCESSED"
echo "Skipped: $SKIPPED"
echo "Failed: $FAILED"
echo ""

echo "Calorie lookup complete!"
