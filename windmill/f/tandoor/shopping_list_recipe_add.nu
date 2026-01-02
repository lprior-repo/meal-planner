# Add recipe to shopping list
# Arguments: tandoor (resource), mealplan_id (int), recipe_id (int)
def main [tandoor: any, mealplan_id: int, recipe_id: int] {
  {tandoor: $tandoor, mealplan_id: $mealplan_id, recipe_id: $recipe_id} | to json | /usr/local/bin/meal-planner/tandoor_shopping_list_recipe_add
}
