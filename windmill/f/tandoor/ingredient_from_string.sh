# shellcheck shell=bash
# Parse ingredient from string

tandoor="$1"
text="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg text "$text" \
	'{tandoor: $tandoor, text: $text}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_ingredient_from_string >./result.json
