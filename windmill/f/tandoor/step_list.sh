# shellcheck shell=bash
# List recipe steps from Tandoor with pagination
# Arguments: tandoor (resource), page (optional integer), page_size (optional integer)

tandoor="$1"
page="$2"
page_size="$3"

# Build JSON input for binary, including optional pagination params
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson page "${page:-null}" \
	--argjson page_size "${page_size:-null}" \
	'{tandoor: $tandoor} + (if $page then {page: $page} else {} end) + (if $page_size then {page_size: $page_size} else {} end)')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_step_list >./result.json
