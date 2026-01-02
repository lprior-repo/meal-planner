# shellcheck shell=bash
# Update an existing ingredient in Tandoor
# Arguments: tandoor (resource), id, food (optional), unit (optional), amount (optional)

tandoor="$1"
id="$2"
food="$3"
unit="$4"
amount="$5"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	--argjson food "${food:-null}" \
	--argjson unit "${unit:-null}" \
	--argjson amount "${amount:-null}" \
	'{tandoor: $tandoor, id: $id, food: $food, unit: $unit, amount: $amount}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_ingredient_update >./result.json
