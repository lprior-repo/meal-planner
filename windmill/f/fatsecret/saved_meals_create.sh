# shellcheck shell=bash
# Create a new FatSecret saved meal
# Arguments: fatsecret (resource), access_token (string), access_secret (string), saved_meal_name (string), saved_meal_description (string), meals (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
saved_meal_name="$4"
saved_meal_description="$5"
meals="$6"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg saved_meal_name "$saved_meal_name" \
	--arg saved_meal_description "$saved_meal_description" \
	--arg meals "$meals" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, saved_meal_name: $saved_meal_name, saved_meal_description: (if $saved_meal_description == "" then null else $saved_meal_description end), meals: $meals}')

echo "$input" | /usr/local/bin/fatsecret_saved_meals_create >./result.json
