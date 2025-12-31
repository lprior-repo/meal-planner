# shellcheck shell=bash
# Delete a FatSecret saved meal
# Arguments: fatsecret (resource), access_token (string), access_secret (string), saved_meal_id (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
saved_meal_id="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg saved_meal_id "$saved_meal_id" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, saved_meal_id: $saved_meal_id}')

echo "$input" | /usr/local/bin/fatsecret_saved_meals_delete >./result.json
