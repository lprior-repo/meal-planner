# shellcheck shell=bash
# Get FatSecret favorite recipes
# Arguments: fatsecret (resource), access_token (string), access_secret (string), max_results (int, optional), page_number (int, optional)

fatsecret="$1"
access_token="$2"
access_secret="$3"
max_results="$4"
page_number="$5"

# Build input JSON, conditionally including optional fields
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson max_results "${max_results:-null}" \
	--argjson page_number "${page_number:-null}" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret} + (if $max_results != null then {max_results: $max_results} else {} end) + (if $page_number != null then {page_number: $page_number} else {} end)')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_recipes_get_favorites >./result.json
