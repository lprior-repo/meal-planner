# shellcheck shell=bash
# Search FatSecret foods database
# Arguments: fatsecret (resource), query (string), page (int), max_results (int)

fatsecret="$1"
query="$2"
page="${3:-0}"
max_results="${4:-20}"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg query "$query" \
	--argjson page "$page" \
	--argjson max_results "$max_results" \
	'{fatsecret: $fatsecret, query: $query, page: $page, max_results: $max_results}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_foods_search >./result.json
