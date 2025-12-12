//// Fallback recipe creation for when Mealie API fetch fails
//// Provides a degraded but functional recipe representation based on the recipe slug

import gleam/option.{None, Some}
import meal_planner/mealie/types.{
  type MealieRecipe, MealieRecipe, MealieCategory, MealieTag, MealieNutrition,
}

/// Create a fallback recipe when Mealie API fetch fails
///
/// When the Mealie API is unavailable or returns an error, this function
/// creates a minimal but valid recipe with the display name "Unknown Recipe (slug)".
/// This allows the application to continue functioning gracefully instead of
/// showing error pages.
///
/// The fallback recipe:
/// - Uses the slug as the ID
/// - Shows "Unknown Recipe (slug)" as the name
/// - Has empty ingredients and instructions
/// - Has no nutrition data or image
///
/// Example:
/// ```gleam
/// case mealie_client.get_recipe(config, "chicken-stir-fry") {
///   Ok(recipe) -> handle_recipe(recipe)
///   Error(_) -> {
///     let fallback = create_fallback_recipe("chicken-stir-fry")
///     handle_recipe(fallback)
///   }
/// }
/// ```
pub fn create_fallback_recipe(slug: String) -> MealieRecipe {
  MealieRecipe(
    id: slug,
    slug: slug,
    name: "Unknown Recipe (" <> slug <> ")",
    description: None,
    image: None,
    recipe_yield: None,
    total_time: None,
    prep_time: None,
    cook_time: None,
    rating: None,
    org_url: None,
    recipe_ingredient: [],
    recipe_instructions: [],
    recipe_category: [],
    tags: [],
    nutrition: None,
    date_added: None,
    date_updated: None,
  )
}
