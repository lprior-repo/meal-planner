# shellcheck shell=bash
# Get FatSecret recently eaten foods
# Arguments: fatsecret (resource), access_token (string), access_secret (string), meal (string, optional)

fatsecret="$1"
access_token="$2"
access_secret="$3"
meal="$4"

# Build input JSON with optional meal filter
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg meal "$meal" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret}
	| if $meal != "" then . + {meal: $meal} else . end')

echo "$input" | /usr/local/bin/fatsecret_foods_recently_eaten >./result.json
