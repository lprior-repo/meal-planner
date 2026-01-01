# shellcheck shell=bash
# Import a recipe from an image or PDF using AI
# Arguments: tandoor (resource), file_path (string), ai_provider_id (integer), recipe_id (optional integer)

tandoor="$1"
file_path="$2"
ai_provider_id="$3"
recipe_id="${4:-null}"

# Build JSON input for binary
if [ "$recipe_id" = "null" ] || [ -z "$recipe_id" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg file_path "$file_path" \
		--argjson ai_provider_id "$ai_provider_id" \
		'{tandoor: $tandoor, file_path: $file_path, ai_provider_id: $ai_provider_id}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg file_path "$file_path" \
		--argjson ai_provider_id "$ai_provider_id" \
		--argjson recipe_id "$recipe_id" \
		'{tandoor: $tandoor, file_path: $file_path, ai_provider_id: $ai_provider_id, recipe_id: $recipe_id}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_ai_import >./result.json
