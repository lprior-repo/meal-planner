/// Shopping List Recipe decoder for Tandoor SDK
///
/// Provides JSON decoders for ShoppingListRecipe types from the Tandoor API.
/// A ShoppingListRecipe represents a collection of ingredients from a recipe or meal plan.
///
/// Example API response:
/// ```json
/// {
///   "id": 1,
///   "name": "Weekly Meal Prep",
///   "recipe": 42,
///   "mealplan": 7,
///   "servings": 4.0,
///   "created_by": 1
/// }
/// ```
import gleam/dynamic/decode
import gleam/option
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/shopping/shopping_list_recipe.{
  type ShoppingListRecipe, ShoppingListRecipe,
}

/// Decode a ShoppingListRecipe from JSON
///
/// Handles both required and optional fields according to the Tandoor API spec.
///
/// Required fields:
/// - id: ShoppingListId
/// - name: String
/// - servings: Float
/// - created_by: UserId
///
/// Optional fields:
/// - recipe: RecipeId (when shopping list is based on a recipe)
/// - mealplan: MealPlanId (when shopping list is based on a meal plan)
pub fn decode_shopping_list_recipe() -> decode.Decoder(ShoppingListRecipe) {
  use id <- decode.field("id", ids.shopping_list_id_decoder())
  use name <- decode.field("name", decode.string)
  use recipe <- decode.field("recipe", decode.optional(ids.recipe_id_decoder()))
  use mealplan <- decode.field(
    "mealplan",
    decode.optional(ids.meal_plan_id_decoder()),
  )
  use servings <- decode.field("servings", decode.float)
  use created_by <- decode.field("created_by", ids.user_id_decoder())

  decode.success(ShoppingListRecipe(
    id: id,
    name: name,
    recipe: recipe,
    mealplan: mealplan,
    servings: servings,
    created_by: created_by,
  ))
}

/// Decode a list of ShoppingListRecipes from a paginated API response
///
/// Used for endpoints that return multiple shopping lists.
///
/// Example JSON:
/// ```json
/// {
///   "results": [
///     { "id": 1, "name": "List 1", ... },
///     { "id": 2, "name": "List 2", ... }
///   ]
/// }
/// ```
pub fn decode_shopping_list_recipe_list() -> decode.Decoder(
  List(ShoppingListRecipe),
) {
  use results <- decode.field("results", decode.list(decode_shopping_list_recipe()))
  decode.success(results)
}
