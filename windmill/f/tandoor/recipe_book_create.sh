# shellcheck shell=bash
# Create a new recipe book in Tandoor

tandoor="$1"
name="$2"
description="${3:-}"

if [ -n "$description" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		--arg description "$description" \
		'{tandoor: $tandoor, name: $name, description: $description}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		'{tandoor: $tandoor, name: $name}')
fi

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_create >./result.json
