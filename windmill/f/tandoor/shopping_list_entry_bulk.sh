# shellcheck shell=bash
# Bulk create/update shopping list entries
# Arguments: tandoor (resource), mealplan_id (int), entries (array)

tandoor="$1"
mealplan_id="$2"
entries="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	--argjson entries "$entries" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id, entries: $entries}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_shopping_list_entry_bulk >./result.json
