# shellcheck shell=bash
# List shopping list entries for a meal plan
# Arguments: tandoor (resource), mealplan_id (int)

tandoor="$1"
mealplan_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_shopping_list_entry_list >./result.json
