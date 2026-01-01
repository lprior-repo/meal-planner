# shellcheck shell=bash
# Get FatSecret weight month summary
# Arguments: fatsecret (resource), access_token (string), access_secret (string), date_int (integer)

fatsecret="$1"
access_token="$2"
access_secret="$3"
date_int="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson date_int "$date_int" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, date_int: $date_int}')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_weight_month_summary >./result.json
