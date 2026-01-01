# shellcheck shell=bash
# Delete FatSecret food diary entry
# Arguments: fatsecret (resource), access_token (string), access_secret (string), food_entry_id (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
food_entry_id="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg food_entry_id "$food_entry_id" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, food_entry_id: $food_entry_id}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_food_entry_delete >./result.json
