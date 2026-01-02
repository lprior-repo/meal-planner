# shellcheck shell=bash
# Create a property type in Tandoor
# Arguments: tandoor (resource), name (string), unit (optional), description (optional), order (optional)

tandoor="$1"
name="$2"
unit="${3:-}"
description="${4:-}"
order="${5:-}"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg name "$name" \
	'{tandoor: $tandoor, name: $name}')

[ -n "$unit" ] && input=$(echo "$input" | jq --arg unit "$unit" '. + {unit: $unit}')
[ -n "$description" ] && input=$(echo "$input" | jq --arg description "$description" '. + {description: $description}')
[ -n "$order" ] && input=$(echo "$input" | jq --argjson order "$order" '. + {order: $order}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_property_type_create >./result.json
