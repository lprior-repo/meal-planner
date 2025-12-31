# shellcheck shell=bash
# Delete a shopping list entry
# Arguments: tandoor (resource), mealplan_id (int), entry_id (int)

tandoor="$1"
mealplan_id="$2"
entry_id="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	--argjson entry_id "$entry_id" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id, entry_id: $entry_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_shopping_list_entry_delete >./result.json
