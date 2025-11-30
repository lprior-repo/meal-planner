-record(food_log_entry, {
    id :: binary(),
    recipe_id :: binary(),
    recipe_name :: binary(),
    servings :: float(),
    macros :: shared@types:macros(),
    meal_type :: shared@types:meal_type(),
    logged_at :: binary()
}).
