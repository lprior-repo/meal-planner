# shellcheck shell=bash
# Delete food from FatSecret favorites
# Arguments: fatsecret (resource), access_token (string), access_secret (string), food_id (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
food_id="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg food_id "$food_id" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, food_id: $food_id}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_food_delete_favorite >./result.json
