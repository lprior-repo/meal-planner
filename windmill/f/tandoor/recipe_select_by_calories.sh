# shellcheck shell=bash
# Select recipes by calorie range from a list
# Arguments: recipes (json array), target_calories (integer), min_calories (integer), max_calories (integer), count (integer)

recipes="$1"
target_calories="${2:-2000}"
min_calories="${3:-300}"
max_calories="${4:-800}"
count="${5:-1}"

# Build JSON input for binary
input=$(jq -n \
	--argjson recipes "$recipes" \
	--argjson target_calories "$target_calories" \
	--argjson min_calories "$min_calories" \
	--argjson max_calories "$max_calories" \
	--argjson count "$count" \
	'{recipes: $recipes, target_calories: $target_calories, min_calories: $min_calories, max_calories: $max_calories, count: $count}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_select_by_calories >./result.json
