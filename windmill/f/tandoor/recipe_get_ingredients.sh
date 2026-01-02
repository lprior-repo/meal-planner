# shellcheck shell=bash
# Get recipe details and extract ingredients for nutrition lookup
# Arguments: tandoor (resource), recipe_id (integer)

tandoor="$1"
recipe_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, recipe_id: $recipe_id}')

# Call binary and capture output
output=$(echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_get)

# Extract recipe info
recipe_name=$(echo "$output" | jq -r '.name')
recipe_servings=$(echo "$output" | jq -r '.servings')

# Extract ingredients with food names
ingredients_json=$(echo "$output" | jq '[.steps[].ingredients[] | select(.food != null) | {food_name: .food.name, amount, unit_name: .unit.name}]')

# Build output with recipe info and ingredients
result=$(jq -n \
	--argjson recipe_id "$recipe_id" \
	--arg recipe_name "$recipe_name" \
	--argjson servings "$recipe_servings" \
	--argjson ingredients "$ingredients_json" \
	'{
		recipe_id: $recipe_id,
		name: $recipe_name,
		servings: $servings,
		ingredients: $ingredients
	}')

echo "$result"
