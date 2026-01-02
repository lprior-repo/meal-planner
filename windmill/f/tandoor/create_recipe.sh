# shellcheck shell=bash
# Create recipe in Tandoor from scraped data
# Arguments: tandoor (resource), recipe (object), additional_keywords (array)

tandoor="$1"
recipe="$2"
additional_keywords="${3:-[]}"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe "$recipe" \
	--argjson additional_keywords "$additional_keywords" \
	'{tandoor: $tandoor, recipe: $recipe, additional_keywords: $additional_keywords}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_create_recipe >./result.json
