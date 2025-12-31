# shellcheck shell=bash
# Get a recipe book by ID from Tandoor

tandoor="$1"
recipe_book_id="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_book_id "$recipe_book_id" \
	'{tandoor: $tandoor, recipe_book_id: $recipe_book_id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_get >./result.json
