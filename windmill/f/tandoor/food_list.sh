# shellcheck shell=bash
# List foods from Tandoor
# Arguments: tandoor (resource), page (integer, optional), page_size (integer, optional)

tandoor="$1"
page="$2"
page_size="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg page "$page" \
	--arg page_size "$page_size" \
	'{tandoor: $tandoor} + (if $page != "" then {page: ($page | tonumber)} else {} end) + (if $page_size != "" then {page_size: ($page_size | tonumber)} else {} end)')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_food_list >./result.json
