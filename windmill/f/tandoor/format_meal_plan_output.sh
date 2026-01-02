# shellcheck shell=bash
# Create meal plan entries and format output
# Arguments: recipes_json (JSON), dates_json (JSON), meal_plan_1_json (JSON), meal_plan_2_json (JSON)

recipes_json="$1"
dates_json="$2"
meal_plan_1_json="$3"
meal_plan_2_json="$4"

# Parse recipes to extract ingredient info
echo "$recipes_json" | jq -r '.[] | "\(.name)|\(.servings)"' >./recipes.txt

# Build output
jq -n --argjson recipes "$recipes_json" --argjson dates "$dates_json" --argjson mp1 "$meal_plan_1_json" --argjson mp2 "$meal_plan_2_json" '
{
  success: true,
  summary: {
    recipes_selected: ($recipes | length),
    cooking_dates: $dates,
    meal_plan_ids: [$mp1.id, $mp2.id]
  },
  meal_plans: [
    {
      recipe_id: $recipes[0].id,
      recipe_name: $recipes[0].name,
      cooking_date: $dates[0],
      meal_type: "dinner"
    },
    {
      recipe_id: $recipes[1].id,
      recipe_name: $recipes[1].name,
      cooking_date: $dates[1],
      meal_type: "dinner"
    }
  ],
  ingredients: ["See Tandoor shopping list"],
  total_calories: "Skipped"
}
'
