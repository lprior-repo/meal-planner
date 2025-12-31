# shellcheck shell=bash
# Get FatSecret exercise month summary
# Arguments: fatsecret (resource), access_token (string), access_secret (string), year (number), month (number)

fatsecret="$1"
access_token="$2"
access_secret="$3"
year="$4"
month="$5"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson year "$year" \
	--argjson month "$month" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, year: $year, month: $month}')

echo "$input" | /usr/local/bin/fatsecret_exercise_month_summary >./result.json
