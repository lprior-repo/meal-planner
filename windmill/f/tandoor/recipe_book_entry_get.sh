# shellcheck shell=bash
# Get a recipe book entry by ID

tandoor="$1"
entry_id="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson entry_id "$entry_id" \
	'{tandoor: $tandoor, entry_id: $entry_id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_entry_get >./result.json
