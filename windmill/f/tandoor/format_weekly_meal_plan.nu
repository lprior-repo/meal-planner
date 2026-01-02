# Format weekly meal plan output using Rust binary
export def main [recipes_json: string, dates_json: string, meal_plan_1_json: string, meal_plan_2_json: string] {
  let data = {recipes: ($recipes_json | from json), dates: ($dates_json | from json), meal_plans: [($meal_plan_1_json | from json), ($meal_plan_2_json | from json)]}
  let result = ($data | to json | /usr/local/bin/meal-planner/tandoor_format_weekly_meal_plan | from json)
  
  # Output as nice tables
  print $"=== Weekly Meal Plan ==="
  print ""
  
  # Recipes table
  print "Recipes:"
  print ($result.recipes | select id name servings working_time waiting_time | table)
  print ""
  
  # Meal plans table
  print "Meal Schedule:"
  print ($result.meal_plans | each { |mp|
    {
      Date: ($mp.from_date | into datetime | format date '%Y-%m-%d'),
      Recipe: $mp.recipe_name,
      Type: (if ($mp.meal_type_name != null) { $mp.meal_type_name } else if ($mp.meal_type != null) { $mp.meal_type.name } else { "Unknown" }),
      Servings: $mp.servings,
      ID: $mp.id
    }
  } | table)
  print ""
  
  # Summary
  print "Summary:"
  [
    {Key: "Recipes Selected", Value: $result.summary.recipes_selected},
    {Key: "Meal Plan IDs", Value: ($result.summary.meal_plan_ids | str join ', ')},
    {Key: "Dates", Value: ($result.summary.cooking_dates | str join ', ')}
  ] | table
}


