# shellcheck shell=bash
# Export meal plan as iCal

tandoor="$1"
from_date="${2:-}"
to_date="${3:-}"

# Build input dynamically
input=$(jq -n --argjson tandoor "$tandoor" '{tandoor: $tandoor}')
if [ -n "$from_date" ]; then
	input=$(echo "$input" | jq --arg from_date "$from_date" '. + {from_date: $from_date}')
fi
if [ -n "$to_date" ]; then
	input=$(echo "$input" | jq --arg to_date "$to_date" '. + {to_date: $to_date}')
fi

echo "$input" | /usr/local/bin/meal-planner/tandoor_meal_plan_export_ical >./result.json
