# shellcheck shell=bash
# Create a new ingredient in Tandoor
# Arguments: tandoor (resource), food (integer), unit (integer, optional), amount (number, optional)

tandoor="$1"
food="$2"
unit="$3"
amount="$4"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson food "$food" \
	--argjson unit "${unit:-null}" \
	--argjson amount "${amount:-null}" \
	'{tandoor: $tandoor, food: $food, unit: $unit, amount: $amount}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_ingredient_create >./result.json
