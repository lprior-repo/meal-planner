# Add recipe to shopping list
{tandoor: ($env.ARG0 | from json), mealplan_id: ($env.ARG1 | into int), recipe_id: ($env.ARG2 | into int)} | to json | /usr/local/bin/meal-planner/tandoor_shopping_list_recipe_add
