# shellcheck shell=bash
# Update a shopping list entry
# Arguments: tandoor (resource), mealplan_id (int), entry_id (int), update (object)

tandoor="$1"
mealplan_id="$2"
entry_id="$3"
update="$4"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	--argjson entry_id "$entry_id" \
	--argjson update "$update" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id, entry_id: $entry_id, update: $update}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_shopping_list_entry_update >./result.json
