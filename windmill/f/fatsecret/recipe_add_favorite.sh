# shellcheck shell=bash
# Add FatSecret recipe to favorites
# Arguments: fatsecret (resource), access_token (string), access_secret (string), recipe_id (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
recipe_id="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg recipe_id "$recipe_id" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, recipe_id: $recipe_id}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_recipe_add_favorite >./result.json
