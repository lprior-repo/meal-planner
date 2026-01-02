# shellcheck shell=bash
# Get all recipes from Tandoor with ingredients
# Arguments: tandoor (resource), page_size (integer, optional)

tandoor="$1"
page_size="${2:-50}"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson page_size "$page_size" \
	'{tandoor: $tandoor, page_size: $page_size}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_get_all_ingredients >./result.json
