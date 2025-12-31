# shellcheck shell=bash
# Get FatSecret food by ID
# Arguments: fatsecret (resource), food_id (string)

fatsecret="$1"
food_id="$2"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg food_id "$food_id" \
	'{fatsecret: $fatsecret, food_id: $food_id}')

echo "$input" | /usr/local/bin/fatsecret_food_get >./result.json
