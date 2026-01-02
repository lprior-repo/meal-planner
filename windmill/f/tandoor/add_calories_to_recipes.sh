#!/bin/bash
set -e

# Add calories to all Tandoor recipes using FatSecret data

TANDOOR_BASE="http://172.19.0.1:8090"
TANDOOR_TOKEN="tda_dcb794d0_e494_46b7_a7cf_43200a1b336e"
FATSECRET_RESOURCE='$res:u/admin/fatsecret_oauth'

echo "Starting calorie lookup for all recipes..."

# Get all recipes
echo "Fetching all recipes..."
recipes_json=$(curl -s -H "Authorization: Bearer $TANDOOR_TOKEN" "$TANDOOR_BASE/api/recipe/" | jq '.')

recipe_count=$(echo "$recipes_json" | jq -r '.count | tonumber')
echo "Found $recipe_count recipes"

# Process each recipe
echo "$recipes_json" | jq -r '.results[] | "\(.id)|\(.name)"' | while IFS='|' read -r recipe_id recipe_name; do
	echo ""
	echo "Processing: $recipe_name (ID: $recipe_id)"

	# Get recipe details
	recipe_detail=$(curl -s -H "Authorization: Bearer $TANDOOR_TOKEN" "$TANDOOR_BASE/api/recipe/$recipe_id/" | jq '.')

	# Extract ingredients
	total_calories=0
	ingredient_count=0

	echo "$recipe_detail" | jq -r '.steps[].ingredients[]? | select(.food != null) | "\(.food.name)|\(.amount // 1)|\(.unit.name // "piece")"' 2>/dev/null | while IFS='|' read -r food_name amount unit; do
		[ -z "$food_name" ] && continue

		# Clean food name for search
		search_term=$(echo "$food_name" | sed 's/ (.*$//' | sed 's/,.*$//' | sed 's/ fresh$//' | sed 's/ s$//')

		# Search FatSecret
		search_result=$(wmill script run f/fatsecret/foods_search -d "{\"fatsecret\": \"$FATSECRET_RESOURCE\", \"search_expression\": \"$search_term\"}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

		# Get first result if available
		if echo "$search_result" | jq -e '.foods[0]' >/dev/null 2>&1; then
			food_id=$(echo "$search_result" | jq -r '.foods[0].food_id')

			# Get food details with nutrition
			food_detail=$(wmill script run f/fatsecret/food_get -d "{\"fatsecret\": \"$FATSECRET_RESOURCE\", \"food_id\": \"$food_id\"}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed '1,/^{/d')

			# Get calories per 100g
			if echo "$food_detail" | jq -e '.servings.serving[0].calories' >/dev/null 2>&1; then
				cals_per_100g=$(echo "$food_detail" | jq -r '.servings.serving[0].calories // 0')

				# Estimate calories for this ingredient
				# Assume 100g = 100 for most items, need to convert based on unit
				# This is a rough approximation
				ingredient_cals=$(echo "$amount * $cals_per_100g / 100" | bc -l | xargs printf '%.0f')

				total_calories=$(echo "$total_calories + $ingredient_cals" | bc -l | xargs printf '%.0f')
				ingredient_count=$((ingredient_count + 1))

				echo "  - $food_name: ~$ingredient_cals calories (based on $cals_per_100g cal/100g)"
			fi
		fi
	done

	echo "  Total calories: ~$total_calories for the recipe (~$(echo "$total_calories / $servings" | bc -l | xargs printf '%.0f') per serving)"

	# Update recipe with calorie info
	# Note: This would need a recipe_update API call with nutrition field
	# For now, just logging

	sleep 1 # Rate limiting
done

echo ""
echo "Completed calorie lookup for $recipe_count recipes"
