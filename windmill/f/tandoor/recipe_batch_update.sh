# shellcheck shell=bash
# Batch update recipes

tandoor="$1"
updates="$2"

input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson updates "$updates" \
	'{tandoor: $tandoor, updates: $updates}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_batch_update >./result.json
