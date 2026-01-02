# shellcheck shell=bash
# Delete a meal plan from Tandoor
# Arguments: tandoor (resource), meal_plan_id

tandoor="$1"
meal_plan_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson meal_plan_id "$meal_plan_id" \
	'{tandoor: $tandoor, meal_plan_id: $meal_plan_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_meal_plan_delete >./result.json
