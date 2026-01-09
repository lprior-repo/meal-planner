# shellcheck shell=bash
# Log a Tandoor recipe to FatSecret food diary
# Arguments: tandoor (resource), fatsecret (resource), access_token, access_secret, recipe_id, servings, meal, date

tandoor="$1"
fatsecret="$2"
access_token="$3"
access_secret="$4"
recipe_id="$5"
servings="$6"
meal="$7"
date="$8"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson recipe_id "$recipe_id" \
	--argjson servings "$servings" \
	--arg meal "$meal" \
	--arg date "$date" \
	'{
		tandoor: $tandoor,
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret,
		recipe_id: $recipe_id,
		servings: $servings,
		meal: $meal,
		date: $date
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/log_recipe_to_fatsecret >./result.json
