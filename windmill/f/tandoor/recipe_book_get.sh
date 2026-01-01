# shellcheck shell=bash
# Get a recipe book by ID from Tandoor

tandoor="$1"
id="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	'{tandoor: $tandoor, id: $id}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_get >./result.json
