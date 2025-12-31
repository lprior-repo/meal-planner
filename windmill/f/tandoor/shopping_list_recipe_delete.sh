# shellcheck shell=bash
# Delete a recipe from the shopping list
# Arguments: tandoor (resource), mealplan_id (int), recipe_id (int)

tandoor="$1"
mealplan_id="$2"
recipe_id="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson mealplan_id "$mealplan_id" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, mealplan_id: $mealplan_id, recipe_id: $recipe_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_shopping_list_recipe_delete >./result.json
