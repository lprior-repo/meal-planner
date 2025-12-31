# shellcheck shell=bash
# Get recipes related to a given recipe
# Arguments: tandoor (resource), recipe_id (integer)

tandoor="$1"
recipe_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, recipe_id: $recipe_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_recipe_get_related >./result.json
