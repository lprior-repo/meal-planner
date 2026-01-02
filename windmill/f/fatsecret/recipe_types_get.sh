# shellcheck shell=bash
# Get FatSecret recipe types
# Arguments: fatsecret (resource)

fatsecret="$1"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	'{fatsecret: $fatsecret}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_recipe_types_get >./result.json
