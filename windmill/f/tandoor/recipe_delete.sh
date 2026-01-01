# shellcheck shell=bash
# Delete a recipe from Tandoor
# Arguments: tandoor (resource), recipe_id (integer)

tandoor="$1"
recipe_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, recipe_id: $recipe_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_delete >./result.json
