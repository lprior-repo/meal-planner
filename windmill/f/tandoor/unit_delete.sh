# shellcheck shell=bash
# Delete a unit from Tandoor
# Arguments: tandoor (resource), id (integer)

tandoor="$1"
id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	'{tandoor: $tandoor, id: $id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_unit_delete >./result.json
