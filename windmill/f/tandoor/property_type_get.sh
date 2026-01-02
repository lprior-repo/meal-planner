# shellcheck shell=bash
# Get a property type from Tandoor
# Arguments: tandoor (resource), property_type_id (integer)

tandoor="$1"
property_type_id="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson property_type_id "$property_type_id" \
	'{tandoor: $tandoor, property_type_id: $property_type_id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_type_get >./result.json
