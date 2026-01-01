# shellcheck shell=bash
# Update an existing meal plan in Tandoor
# Arguments: tandoor (resource), meal_plan_id (number), recipe (optional), meal_type (optional),
#            from_date (optional), to_date (optional), servings (optional), title (optional), note (optional)

tandoor="$1"
meal_plan_id="$2"
recipe="$3"
meal_type="$4"
from_date="$5"
to_date="$6"
servings="$7"
title="$8"
note="$9"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson meal_plan_id "$meal_plan_id" \
	--argjson recipe "${recipe:-null}" \
	--argjson meal_type "${meal_type:-null}" \
	--arg from_date "${from_date:-}" \
	--arg to_date "${to_date:-}" \
	--argjson servings "${servings:-null}" \
	--arg title "${title:-}" \
	--arg note "${note:-}" \
	'{
		tandoor: $tandoor,
		meal_plan_id: $meal_plan_id,
		recipe: $recipe,
		meal_type: $meal_type,
		from_date: (if $from_date == "" then null else $from_date end),
		to_date: (if $to_date == "" then null else $to_date end),
		servings: $servings,
		title: (if $title == "" then null else $title end),
		note: (if $note == "" then null else $note end)
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_meal_plan_update >./result.json
