# shellcheck shell=bash
# Get FatSecret recipe by ID
# Arguments: fatsecret (resource), recipe_id (string)

fatsecret="$1"
recipe_id="$2"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg recipe_id "$recipe_id" \
	'{fatsecret: $fatsecret, recipe_id: $recipe_id}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_recipe_get >./result.json
