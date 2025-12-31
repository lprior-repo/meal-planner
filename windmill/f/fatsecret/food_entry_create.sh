# shellcheck shell=bash
# Create FatSecret food diary entry
# Arguments: fatsecret (resource), access_token, access_secret, food_id, food_entry_name, serving_id, number_of_units, meal, date_int

fatsecret="$1"
access_token="$2"
access_secret="$3"
food_id="$4"
food_entry_name="$5"
serving_id="$6"
number_of_units="$7"
meal="$8"
date_int="$9"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg food_id "$food_id" \
	--arg food_entry_name "$food_entry_name" \
	--arg serving_id "$serving_id" \
	--argjson number_of_units "$number_of_units" \
	--arg meal "$meal" \
	--argjson date_int "$date_int" \
	'{
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret,
		food_id: $food_id,
		food_entry_name: $food_entry_name,
		serving_id: $serving_id,
		number_of_units: $number_of_units,
		meal: $meal,
		date_int: $date_int
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_food_entry_create >./result.json
