# shellcheck shell=bash
# Search FatSecret recipes
# Arguments: fatsecret (resource), search_expression (string), max_results (int, optional), page_number (int, optional), recipe_type (string, optional)

fatsecret="$1"
search_expression="$2"
max_results="$3"
page_number="$4"
recipe_type="$5"

# Build input JSON, conditionally including optional fields
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg search_expression "$search_expression" \
	--argjson max_results "${max_results:-null}" \
	--argjson page_number "${page_number:-null}" \
	--arg recipe_type "$recipe_type" \
	'{fatsecret: $fatsecret, search_expression: $search_expression} + (if $max_results != null then {max_results: $max_results} else {} end) + (if $page_number != null then {page_number: $page_number} else {} end) + (if $recipe_type != "" then {recipe_type: $recipe_type} else {} end)')

echo "$input" | /usr/local/bin/meal-planner/fatsecret_recipes_search >./result.json
