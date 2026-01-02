# shellcheck shell=bash
# Get FatSecret saved meals
# Arguments: fatsecret (resource), access_token (string), access_secret (string), meal (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
meal="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg meal "$meal" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, meal: (if $meal == "" then null else $meal end)}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_saved_meals_get >./result.json
