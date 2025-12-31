# shellcheck shell=bash
# Create a shopping list entry
# Arguments: tandoor (resource), mealplan_id (int), entry (object)

tandoor="$1"
mealplan_id="$2"
entry="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	--argjson entry "$entry" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id, entry: $entry}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_shopping_list_entry_create >./result.json
