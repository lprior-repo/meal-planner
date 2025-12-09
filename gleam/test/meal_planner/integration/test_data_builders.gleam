/// Test Data Builders
///
/// Provides builder functions for creating test data with sensible defaults.
/// Follows the Test Data Builder pattern for clean, maintainable tests.
///
/// Benefits:
/// - Readable test code with explicit intent
/// - Default values for all required fields
/// - Easy to override specific fields
/// - Type-safe construction
import gleam/list
import gleam/option
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, type UserProfile,
  Active, High, Ingredient, Low, Macros, Maintain, Medium, Moderate, Recipe,
  Sedentary, UserProfile,
}

// ============================================================================
// Recipe Builders
// ============================================================================

/// Default recipe builder with sensible test values
pub fn recipe() -> Recipe {
  Recipe(
    id: "test-recipe-1",
    name: "Test Recipe",
    ingredients: [ingredient()],
    instructions: ["Step 1: Test instruction"],
    macros: macros(),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Recipe with custom name
pub fn recipe_named(name: String) -> Recipe {
  Recipe(..recipe(), name: name)
}

/// Recipe with custom ID
pub fn recipe_with_id(id: String) -> Recipe {
  Recipe(..recipe(), id: id)
}

/// Recipe with custom macros
pub fn recipe_with_macros(protein: Float, fat: Float, carbs: Float) -> Recipe {
  Recipe(..recipe(), macros: Macros(protein: protein, fat: fat, carbs: carbs))
}

/// Recipe with custom category
pub fn recipe_in_category(category: String) -> Recipe {
  Recipe(..recipe(), category: category)
}

/// Recipe with custom servings
pub fn recipe_with_servings(servings: Int) -> Recipe {
  Recipe(..recipe(), servings: servings)
}

/// Recipe with custom FODMAP level
pub fn recipe_with_fodmap(level: FodmapLevel) -> Recipe {
  Recipe(..recipe(), fodmap_level: level)
}

/// High-protein recipe (for testing filtering)
pub fn high_protein_recipe() -> Recipe {
  Recipe(
    ..recipe(),
    name: "High Protein Meal",
    macros: Macros(protein: 50.0, fat: 10.0, carbs: 20.0),
  )
}

/// Low-carb recipe (for testing filtering)
pub fn low_carb_recipe() -> Recipe {
  Recipe(
    ..recipe(),
    name: "Low Carb Meal",
    macros: Macros(protein: 30.0, fat: 25.0, carbs: 5.0),
  )
}

/// High-calorie recipe (for testing filtering)
pub fn high_calorie_recipe() -> Recipe {
  Recipe(
    ..recipe(),
    name: "High Calorie Meal",
    macros: Macros(protein: 40.0, fat: 50.0, carbs: 100.0),
  )
}

// ============================================================================
// Macros Builders
// ============================================================================

/// Default macros with balanced values
pub fn macros() -> Macros {
  Macros(protein: 30.0, fat: 15.0, carbs: 40.0)
}

/// Zero macros (for testing calculations)
pub fn macros_zero() -> Macros {
  Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
}

/// Custom macros
pub fn macros_custom(protein: Float, fat: Float, carbs: Float) -> Macros {
  Macros(protein: protein, fat: fat, carbs: carbs)
}

// ============================================================================
// Ingredient Builders
// ============================================================================

/// Default ingredient
pub fn ingredient() -> Ingredient {
  Ingredient(name: "Test Ingredient", quantity: "100g")
}

/// Ingredient with custom name and quantity
pub fn ingredient_custom(name: String, quantity: String) -> Ingredient {
  Ingredient(name: name, quantity: quantity)
}

/// List of ingredients for a recipe
pub fn ingredients_list(count: Int) -> List(Ingredient) {
  list.range(1, count)
  |> list.map(fn(i) {
    Ingredient(
      name: "Ingredient " <> int_to_string(i),
      quantity: int_to_string(i * 100) <> "g",
    )
  })
}

// ============================================================================
// User Profile Builders
// ============================================================================

/// Default user profile
pub fn user_profile() -> UserProfile {
  UserProfile(
    id: "test-user-1",
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: option.None,
  )
}

/// User profile with custom ID
pub fn user_profile_with_id(id: String) -> UserProfile {
  UserProfile(..user_profile(), id: id)
}

/// User profile with custom bodyweight
pub fn user_profile_with_bodyweight(weight: Float) -> UserProfile {
  UserProfile(..user_profile(), bodyweight: weight)
}

/// Sedentary user profile
pub fn sedentary_profile() -> UserProfile {
  UserProfile(..user_profile(), activity_level: Sedentary)
}

/// Active user profile
pub fn active_profile() -> UserProfile {
  UserProfile(..user_profile(), activity_level: Active)
}

/// Bulk profile (gaining weight)
pub fn bulk_profile() -> UserProfile {
  UserProfile(
    ..user_profile(),
    goal: types.Gain,
    bodyweight: 160.0,
    meals_per_day: 4,
  )
}

/// Cut profile (losing weight)
pub fn cut_profile() -> UserProfile {
  UserProfile(
    ..user_profile(),
    goal: types.Lose,
    bodyweight: 200.0,
    meals_per_day: 3,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String

// ============================================================================
// Batch Builders for Testing Collections
// ============================================================================

/// Create a list of test recipes with unique IDs
pub fn recipe_batch(count: Int) -> List(Recipe) {
  list.range(1, count)
  |> list.map(fn(i) {
    Recipe(
      ..recipe(),
      id: "test-recipe-" <> int_to_string(i),
      name: "Test Recipe " <> int_to_string(i),
    )
  })
}

/// Create a list of recipes in different categories
pub fn recipe_batch_by_category(categories: List(String)) -> List(Recipe) {
  categories
  |> list.index_map(fn(category, idx) {
    Recipe(
      ..recipe(),
      id: "recipe-" <> category <> "-" <> int_to_string(idx),
      name: category <> " Recipe " <> int_to_string(idx),
      category: category,
    )
  })
}

/// Create a list of recipes with varying macros for filtering tests
pub fn recipe_batch_varied_macros() -> List(Recipe) {
  [
    high_protein_recipe(),
    low_carb_recipe(),
    high_calorie_recipe(),
    Recipe(
      ..recipe(),
      id: "balanced-recipe",
      name: "Balanced Meal",
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
    ),
    Recipe(
      ..recipe(),
      id: "low-protein-recipe",
      name: "Low Protein Meal",
      macros: Macros(protein: 10.0, fat: 20.0, carbs: 60.0),
    ),
  ]
}
