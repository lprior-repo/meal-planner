# shellcheck shell=bash
# Delete a food from Tandoor
# Arguments: tandoor (resource), food_id (integer)

tandoor="$1"
food_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson food_id "$food_id" \
	'{tandoor: $tandoor, food_id: $food_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_food_delete >./result.json
