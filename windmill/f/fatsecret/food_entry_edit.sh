# shellcheck shell=bash
# Edit FatSecret food diary entry
# Arguments: fatsecret (resource), access_token, access_secret, food_entry_id, number_of_units (optional), meal (optional)

fatsecret="$1"
access_token="$2"
access_secret="$3"
food_entry_id="$4"
number_of_units="$5"
meal="$6"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg food_entry_id "$food_entry_id" \
	--arg number_of_units "$number_of_units" \
	--arg meal "$meal" \
	'{
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret,
		food_entry_id: $food_entry_id
	}
	| if $number_of_units != "" then . + {number_of_units: ($number_of_units | tonumber)} else . end
	| if $meal != "" then . + {meal: $meal} else . end')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_food_entry_edit >./result.json
