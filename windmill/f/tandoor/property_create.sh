# shellcheck shell=bash
# Create a property in Tandoor
# Arguments: tandoor (resource), property_amount (number), property_type (integer)

tandoor="$1"
property_amount="$2"
property_type="$3"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson property_amount "$property_amount" \
	--argjson property_type "$property_type" \
	'{tandoor: $tandoor, property_amount: $property_amount, property_type: $property_type}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_create >./result.json
