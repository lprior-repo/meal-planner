# shellcheck shell=bash
# Create a recipe book entry

tandoor="$1"
recipe_book_id="$2"
recipe_id="$3"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_book_id "$recipe_book_id" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, recipe_book_id: $recipe_book_id, recipe_id: $recipe_id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_entry_create >./result.json
