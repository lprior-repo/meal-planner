# shellcheck shell=bash
# Get a specific meal type from Tandoor
# Arguments: tandoor (resource), id (number)

tandoor="$1"
id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	'{tandoor: $tandoor, id: $id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_meal_type_get >./result.json
