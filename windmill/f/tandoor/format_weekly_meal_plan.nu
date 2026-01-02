# Format weekly meal plan output using Rust binary
# Arguments: recipes_json (JSON), dates_json (JSON), meal_plan_1_json (JSON), meal_plan_2_json (JSON)
{recipes: ($in.0 | from json), dates: ($in.1 | from json), meal_plans: [($in.2 | from json), ($in.3 | from json)]} | to json | /usr/local/bin/meal-planner/tandoor_format_weekly_meal_plan
