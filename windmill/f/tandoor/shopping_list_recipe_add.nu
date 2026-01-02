# Add recipe to shopping list
export def main [tandoor: string, mealplan_id: int, recipe_id: int] {
  {tandoor: ($tandoor | from json), mealplan_id: $mealplan_id, recipe_id: $recipe_id} | to json | /usr/local/bin/meal-planner/tandoor_shopping_list_recipe_add
}

