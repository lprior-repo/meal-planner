# shellcheck shell=bash
# Update a property in Tandoor
# Arguments: tandoor (resource), property_id (integer), property_amount (optional), property_type (optional)

tandoor="$1"
property_id="$2"
property_amount="${3:-}"
property_type="${4:-}"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson property_id "$property_id" \
	'{tandoor: $tandoor, property_id: $property_id}')

[ -n "$property_amount" ] && input=$(echo "$input" | jq --argjson property_amount "$property_amount" '. + {property_amount: $property_amount}')
[ -n "$property_type" ] && input=$(echo "$input" | jq --argjson property_type "$property_type" '. + {property_type: $property_type}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_update >./result.json
