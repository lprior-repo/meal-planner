# shellcheck shell=bash
# Update a property type in Tandoor
# Arguments: tandoor (resource), property_type_id (integer), name (optional), unit (optional), description (optional), order (optional)

tandoor="$1"
property_type_id="$2"
name="${3:-}"
unit="${4:-}"
description="${5:-}"
order="${6:-}"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson property_type_id "$property_type_id" \
	'{tandoor: $tandoor, property_type_id: $property_type_id}')

[ -n "$name" ] && input=$(echo "$input" | jq --arg name "$name" '. + {name: $name}')
[ -n "$unit" ] && input=$(echo "$input" | jq --arg unit "$unit" '. + {unit: $unit}')
[ -n "$description" ] && input=$(echo "$input" | jq --arg description "$description" '. + {description: $description}')
[ -n "$order" ] && input=$(echo "$input" | jq --argjson order "$order" '. + {order: $order}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_type_update >./result.json
