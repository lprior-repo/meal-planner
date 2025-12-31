# shellcheck shell=bash
# Add food to FatSecret favorites
# Arguments: fatsecret (resource), access_token, access_secret, food_id, serving_id (optional), number_of_units (optional)

fatsecret="$1"
access_token="$2"
access_secret="$3"
food_id="$4"
serving_id="$5"
number_of_units="$6"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg food_id "$food_id" \
	--arg serving_id "$serving_id" \
	--arg number_of_units "$number_of_units" \
	'{
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret,
		food_id: $food_id
	}
	| if $serving_id != "" then . + {serving_id: $serving_id} else . end
	| if $number_of_units != "" then . + {number_of_units: ($number_of_units | tonumber)} else . end')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_food_add_favorite >./result.json
