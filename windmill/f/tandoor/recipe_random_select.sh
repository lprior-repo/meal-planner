# shellcheck shell=bash
# Randomly select recipes by keyword from Tandoor
# Arguments: tandoor (resource), keyword (string), count (integer)

tandoor="$1"
keyword="${2:-meat-church}"
count="${3:-2}"

input=$(jq -n --argjson tandoor "$tandoor" --arg keyword "$keyword" --argjson count "$count" '{tandoor: $tandoor, keyword: $keyword, count: $count}')

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_random_select >./result.json
