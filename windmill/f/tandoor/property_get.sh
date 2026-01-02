# shellcheck shell=bash
# Get a property from Tandoor
# Arguments: tandoor (resource), property_id (integer)

tandoor="$1"
property_id="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson property_id "$property_id" \
	'{tandoor: $tandoor, property_id: $property_id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_get >./result.json
