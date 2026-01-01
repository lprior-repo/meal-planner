# shellcheck shell=bash
# Update a recipe book in Tandoor

tandoor="$1"
recipe_book_id="$2"
name="${3:-}"
description="${4:-}"

# Build input dynamically
input=$(jq -n --argjson tandoor "$tandoor" --argjson recipe_book_id "$recipe_book_id" '{tandoor: $tandoor, recipe_book_id: $recipe_book_id}')
if [ -n "$name" ]; then
	input=$(echo "$input" | jq --arg name "$name" '. + {name: $name}')
fi
if [ -n "$description" ]; then
	input=$(echo "$input" | jq --arg description "$description" '. + {description: $description}')
fi

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_update >./result.json
