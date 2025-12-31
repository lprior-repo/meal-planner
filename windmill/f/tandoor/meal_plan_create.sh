# shellcheck shell=bash
# Create a new meal plan in Tandoor
# Arguments: tandoor (resource), recipe, meal_type, from_date, servings, to_date (optional), title (optional), note (optional)

tandoor="$1"
recipe="$2"
meal_type="$3"
from_date="$4"
servings="$5"
to_date="$6"
title="$7"
note="$8"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe "$recipe" \
	--argjson meal_type "$meal_type" \
	--arg from_date "$from_date" \
	--argjson servings "$servings" \
	--argjson to_date "${to_date:-null}" \
	--argjson title "${title:-null}" \
	--argjson note "${note:-null}" \
	'{tandoor: $tandoor, recipe: $recipe, meal_type: $meal_type, from_date: $from_date, servings: $servings, to_date: $to_date, title: $title, note: $note}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_meal_plan_create >./result.json
