# shellcheck shell=bash
# Get a specific meal plan from Tandoor
# Arguments: tandoor (resource), meal_plan_id (number)

tandoor="$1"
meal_plan_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson meal_plan_id "$meal_plan_id" \
	'{tandoor: $tandoor, meal_plan_id: $meal_plan_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_meal_plan_get >./result.json
