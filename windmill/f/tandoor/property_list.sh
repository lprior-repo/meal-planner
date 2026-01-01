# shellcheck shell=bash
# List properties from Tandoor
# Arguments: tandoor (resource), page (optional), page_size (optional)

tandoor="$1"
page="$2"
page_size="$3"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson page "${page:-null}" \
	--argjson page_size "${page_size:-null}" \
	'{tandoor: $tandoor, page: $page, page_size: $page_size}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_list >./result.json
