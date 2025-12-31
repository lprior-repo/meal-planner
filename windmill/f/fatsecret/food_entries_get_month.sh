# shellcheck shell=bash
# Get FatSecret monthly food diary summary
# Arguments: fatsecret (resource), access_token, access_secret, date_int

fatsecret="$1"
access_token="$2"
access_secret="$3"
date_int="$4"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson date_int "$date_int" \
	'{
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret,
		date_int: $date_int
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_food_entries_get_month >./result.json
