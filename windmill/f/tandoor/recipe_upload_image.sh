# shellcheck shell=bash
# Upload an image for a recipe
# Arguments: tandoor (resource), recipe_id (integer), image_path (string)

tandoor="$1"
recipe_id="$2"
image_path="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_id "$recipe_id" \
	--arg image_path "$image_path" \
	'{tandoor: $tandoor, recipe_id: $recipe_id, image_path: $image_path}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_upload_image >./result.json
