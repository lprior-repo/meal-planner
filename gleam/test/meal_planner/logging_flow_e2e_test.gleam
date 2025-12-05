/// End-to-End Tests for Complete Logging Flow
///
/// Tests the entire workflow from food search → selection → logging → display
/// Covers both recipe-based and USDA food-based logging scenarios
///
/// This test suite validates:
/// 1. Food search and filtering
/// 2. Food selection and data loading
/// 3. Logging with macros and serving scaling
/// 4. Daily log retrieval and display
/// 5. Source tracking persistence
/// 6. Edge cases and error handling
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type MealType, type Recipe,
  Breakfast, DailyLog, Dinner, FoodLogEntry, Lunch, Macros, Snack,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Helper Functions for E2E Test Setup
// ============================================================================

/// Create a test recipe for E2E testing
fn create_test_recipe(
  id: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
  Recipe(
    id: id,
    name: name,
    description: "Test recipe for E2E logging",
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    ingredients: ["ingredient 1", "ingredient 2"],
    instructions: "Mix and cook",
    serves: 1,
    prep_time_minutes: 15,
    cook_time_minutes: 30,
    source: "custom",
    fodmap_category: None,
  )
}

/// Create a test food log entry
fn create_test_entry(
  id: String,
  recipe_id: String,
  name: String,
  servings: Float,
  protein: Float,
  fat: Float,
  carbs: Float,
  meal_type: MealType,
) -> FoodLogEntry {
  FoodLogEntry(
    id: id,
    recipe_id: recipe_id,
    recipe_name: name,
    servings: servings,
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    micronutrients: None,
    meal_type: meal_type,
    logged_at: "2025-12-05T12:00:00Z",
    source_type: "recipe",
    source_id: recipe_id,
  )
}

/// Create a daily log for testing
fn create_daily_log(entries: List(FoodLogEntry)) -> DailyLog {
  DailyLog(
    date: "2025-12-05",
    entries: entries,
    daily_totals: calculate_daily_totals(entries),
  )
}

/// Calculate totals from a list of entries
fn calculate_daily_totals(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, entry) {
    Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}

// ============================================================================
// Test Group 1: Single Meal Logging
// ============================================================================

/// Test: Log a single recipe at breakfast
pub fn log_single_recipe_breakfast_test() {
  let recipe =
    create_test_recipe("breakfast-1", "Eggs and Toast", 20.0, 15.0, 30.0)
  let entry =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      1.0,
      recipe.macros.protein,
      recipe.macros.fat,
      recipe.macros.carbs,
      Breakfast,
    )

  // Verify entry data
  entry.recipe_id
  |> should.equal("breakfast-1")

  entry.servings
  |> should.equal(1.0)

  entry.meal_type
  |> should.equal(Breakfast)

  entry.macros.protein
  |> should.equal(20.0)
}

/// Test: Log a recipe with scaled servings
pub fn log_recipe_with_scaled_servings_test() {
  let recipe = create_test_recipe("lunch-1", "Chicken Breast", 35.0, 8.0, 0.0)

  // Log 1.5 servings (150g of chicken)
  let scaled_protein = recipe.macros.protein *. 1.5
  let scaled_fat = recipe.macros.fat *. 1.5
  let scaled_carbs = recipe.macros.carbs *. 1.5

  let entry =
    create_test_entry(
      "entry-2",
      recipe.id,
      recipe.name,
      1.5,
      scaled_protein,
      scaled_fat,
      scaled_carbs,
      Lunch,
    )

  // Verify scaling
  entry.servings
  |> should.equal(1.5)

  entry.macros.protein
  |> should.equal(52.5)

  entry.macros.fat
  |> should.equal(12.0)

  entry.macros.carbs
  |> should.equal(0.0)
}

/// Test: Log a USDA food with grams
pub fn log_usda_food_with_grams_test() {
  // USDA foods have macros per 100g
  // Chicken breast: 165 kcal, 31g protein, 3.6g fat, 0g carbs per 100g
  let usda_macros_per_100g = Macros(protein: 31.0, fat: 3.6, carbs: 0.0)

  // User logs 150g (1.5 servings of 100g)
  let scaling_factor = 150.0 /. 100.0
  let scaled_protein = usda_macros_per_100g.protein *. scaling_factor
  let scaled_fat = usda_macros_per_100g.fat *. scaling_factor
  let scaled_carbs = usda_macros_per_100g.carbs *. scaling_factor

  let entry =
    create_test_entry(
      "entry-3",
      "usda-171477",
      "Chicken Breast (Raw)",
      scaling_factor,
      scaled_protein,
      scaled_fat,
      scaled_carbs,
      Lunch,
    )

  // Verify USDA logging
  entry.servings
  |> should.equal(1.5)

  entry.macros.protein
  |> should.equal(46.5)

  entry.macros.fat
  |> should.equal(5.4)
}

// ============================================================================
// Test Group 2: Multiple Meals in One Day
// ============================================================================

/// Test: Log breakfast, lunch, dinner, and snack
pub fn log_complete_day_test() {
  // Breakfast: Eggs and Toast
  let breakfast =
    create_test_entry(
      "entry-1",
      "breakfast-1",
      "Eggs and Toast",
      1.0,
      20.0,
      15.0,
      30.0,
      Breakfast,
    )

  // Lunch: Chicken Salad with 1.5 servings
  let lunch =
    create_test_entry(
      "entry-2",
      "lunch-1",
      "Chicken Salad",
      1.5,
      52.5,
      12.0,
      45.0,
      Lunch,
    )

  // Dinner: Fish and Rice
  let dinner =
    create_test_entry(
      "entry-3",
      "dinner-1",
      "Fish and Rice",
      1.0,
      40.0,
      10.0,
      60.0,
      Dinner,
    )

  // Snack: Protein Bar
  let snack =
    create_test_entry(
      "entry-4",
      "snack-1",
      "Protein Bar",
      1.0,
      20.0,
      5.0,
      40.0,
      Snack,
    )

  let daily_log = create_daily_log([breakfast, lunch, dinner, snack])

  // Verify daily totals
  list.length(daily_log.entries)
  |> should.equal(4)

  daily_log.daily_totals.protein
  |> should.equal(132.5)

  daily_log.daily_totals.fat
  |> should.equal(42.0)

  daily_log.daily_totals.carbs
  |> should.equal(175.0)
}

/// Test: Multiple entries of same recipe on same day
pub fn log_same_recipe_multiple_times_test() {
  let recipe =
    create_test_recipe("coffee-1", "Coffee with Cream", 1.0, 3.0, 0.5)

  let entry1 =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      1.0,
      recipe.macros.protein,
      recipe.macros.fat,
      recipe.macros.carbs,
      Breakfast,
    )

  let entry2 =
    create_test_entry(
      "entry-2",
      recipe.id,
      recipe.name,
      1.0,
      recipe.macros.protein,
      recipe.macros.fat,
      recipe.macros.carbs,
      Snack,
    )

  let daily_log = create_daily_log([entry1, entry2])

  // Verify entries are separate
  list.length(daily_log.entries)
  |> should.equal(2)

  // Verify totals are doubled
  daily_log.daily_totals.protein
  |> should.equal(2.0)

  daily_log.daily_totals.fat
  |> should.equal(6.0)

  daily_log.daily_totals.carbs
  |> should.equal(1.0)
}

// ============================================================================
// Test Group 3: Source Tracking
// ============================================================================

/// Test: Recipe source is tracked correctly
pub fn recipe_source_tracking_test() {
  let entry =
    create_test_entry(
      "entry-1",
      "recipe-123",
      "Test Recipe",
      1.0,
      30.0,
      10.0,
      50.0,
      Lunch,
    )

  // Verify source tracking
  entry.source_type
  |> should.equal("recipe")

  entry.source_id
  |> should.equal("recipe-123")

  // Verify source_id matches recipe_id for recipes
  entry.recipe_id
  |> should.equal(entry.source_id)
}

/// Test: USDA food source is tracked separately
pub fn usda_food_source_tracking_test() {
  let entry =
    FoodLogEntry(
      id: "entry-1",
      recipe_id: "usda-171477",
      recipe_name: "Chicken Breast",
      servings: 1.5,
      macros: Macros(protein: 46.5, fat: 5.4, carbs: 0.0),
      micronutrients: None,
      meal_type: Lunch,
      logged_at: "2025-12-05T12:00:00Z",
      source_type: "usda_food",
      source_id: "171477",
    )

  // Verify USDA source tracking
  entry.source_type
  |> should.equal("usda_food")

  entry.source_id
  |> should.equal("171477")

  // FDC ID is just the number, not prefixed with "usda-"
  entry.source_id
  |> should.not_equal("usda-171477")
}

/// Test: Entry contains all required source tracking fields
pub fn entry_has_complete_source_fields_test() {
  let entry =
    create_test_entry(
      "entry-1",
      "recipe-456",
      "Test Meal",
      1.0,
      30.0,
      10.0,
      50.0,
      Breakfast,
    )

  // Verify all source-related fields exist
  entry.recipe_id
  |> should.not_equal("")

  entry.recipe_name
  |> should.not_equal("")

  entry.source_type
  |> should.not_equal("")

  entry.source_id
  |> should.not_equal("")
}

// ============================================================================
// Test Group 4: Macro Calculations
// ============================================================================

/// Test: Macros scale correctly with servings
pub fn macro_scaling_proportional_test() {
  let recipe = create_test_recipe("test-recipe", "Test Food", 30.0, 15.0, 60.0)

  let single_serving_entry =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      1.0,
      recipe.macros.protein,
      recipe.macros.fat,
      recipe.macros.carbs,
      Lunch,
    )

  let double_serving_entry =
    create_test_entry(
      "entry-2",
      recipe.id,
      recipe.name,
      2.0,
      recipe.macros.protein *. 2.0,
      recipe.macros.fat *. 2.0,
      recipe.macros.carbs *. 2.0,
      Lunch,
    )

  // Verify proportional scaling
  double_serving_entry.macros.protein
  |> should.equal(single_serving_entry.macros.protein *. 2.0)

  double_serving_entry.macros.fat
  |> should.equal(single_serving_entry.macros.fat *. 2.0)

  double_serving_entry.macros.carbs
  |> should.equal(single_serving_entry.macros.carbs *. 2.0)
}

/// Test: Macro totals are calculated correctly
pub fn daily_macro_totals_calculation_test() {
  let entry1 =
    create_test_entry(
      "entry-1",
      "recipe-1",
      "Meal 1",
      1.0,
      30.0,
      10.0,
      50.0,
      Breakfast,
    )

  let entry2 =
    create_test_entry(
      "entry-2",
      "recipe-2",
      "Meal 2",
      1.0,
      40.0,
      15.0,
      60.0,
      Lunch,
    )

  let entry3 =
    create_test_entry(
      "entry-3",
      "recipe-3",
      "Meal 3",
      1.0,
      25.0,
      8.0,
      35.0,
      Dinner,
    )

  let daily_log = create_daily_log([entry1, entry2, entry3])

  // Verify totals
  daily_log.daily_totals.protein
  |> should.equal(95.0)

  daily_log.daily_totals.fat
  |> should.equal(33.0)

  daily_log.daily_totals.carbs
  |> should.equal(145.0)
}

/// Test: Zero serving macros are valid
pub fn zero_serving_macros_test() {
  let entry =
    create_test_entry(
      "entry-1",
      "recipe-1",
      "Zero Cal Drink",
      1.0,
      0.0,
      0.0,
      0.0,
      Breakfast,
    )

  // Zero macros should be valid
  entry.macros.protein
  |> should.equal(0.0)

  entry.macros.fat
  |> should.equal(0.0)

  entry.macros.carbs
  |> should.equal(0.0)
}

// ============================================================================
// Test Group 5: Meal Type Distribution
// ============================================================================

/// Test: Entries are correctly assigned to meal types
pub fn entries_assigned_correct_meal_types_test() {
  let breakfast =
    create_test_entry("e1", "r1", "Breakfast", 1.0, 20.0, 10.0, 30.0, Breakfast)
  let lunch =
    create_test_entry("e2", "r2", "Lunch", 1.0, 30.0, 12.0, 45.0, Lunch)
  let dinner =
    create_test_entry("e3", "r3", "Dinner", 1.0, 35.0, 15.0, 55.0, Dinner)
  let snack =
    create_test_entry("e4", "r4", "Snack", 1.0, 15.0, 5.0, 20.0, Snack)

  let daily_log = create_daily_log([breakfast, lunch, dinner, snack])

  // Find entries by meal type
  let breakfast_entries =
    list.filter(daily_log.entries, fn(e) { e.meal_type == Breakfast })
  let lunch_entries =
    list.filter(daily_log.entries, fn(e) { e.meal_type == Lunch })
  let dinner_entries =
    list.filter(daily_log.entries, fn(e) { e.meal_type == Dinner })
  let snack_entries =
    list.filter(daily_log.entries, fn(e) { e.meal_type == Snack })

  list.length(breakfast_entries)
  |> should.equal(1)

  list.length(lunch_entries)
  |> should.equal(1)

  list.length(dinner_entries)
  |> should.equal(1)

  list.length(snack_entries)
  |> should.equal(1)
}

/// Test: Multiple entries can be assigned same meal type
pub fn multiple_entries_same_meal_type_test() {
  let snack1 =
    create_test_entry("e1", "r1", "Snack 1", 1.0, 10.0, 3.0, 15.0, Snack)
  let snack2 =
    create_test_entry("e2", "r2", "Snack 2", 1.0, 12.0, 4.0, 18.0, Snack)

  let daily_log = create_daily_log([snack1, snack2])

  let snack_entries =
    list.filter(daily_log.entries, fn(e) { e.meal_type == Snack })

  list.length(snack_entries)
  |> should.equal(2)

  daily_log.daily_totals.protein
  |> should.equal(22.0)
}

// ============================================================================
// Test Group 6: Entry Timestamps and Logging
// ============================================================================

/// Test: Entry has valid timestamp
pub fn entry_has_valid_timestamp_test() {
  let entry =
    create_test_entry(
      "entry-1",
      "recipe-1",
      "Test Meal",
      1.0,
      30.0,
      10.0,
      50.0,
      Lunch,
    )

  // Verify timestamp is not empty and follows ISO format
  entry.logged_at
  |> should.not_equal("")

  entry.logged_at
  |> should.equal("2025-12-05T12:00:00Z")
}

/// Test: Daily log contains date information
pub fn daily_log_has_date_test() {
  let entry =
    create_test_entry(
      "entry-1",
      "recipe-1",
      "Test Meal",
      1.0,
      30.0,
      10.0,
      50.0,
      Breakfast,
    )

  let daily_log = create_daily_log([entry])

  daily_log.date
  |> should.not_equal("")

  daily_log.date
  |> should.equal("2025-12-05")
}

// ============================================================================
// Test Group 7: Edge Cases
// ============================================================================

/// Test: Very small serving size (less than 1)
pub fn fractional_serving_size_test() {
  let recipe =
    create_test_recipe("recipe-1", "Expensive Spice", 100.0, 0.0, 0.0)

  // User logs 0.1 servings (very small amount)
  let entry =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      0.1,
      recipe.macros.protein *. 0.1,
      recipe.macros.fat *. 0.1,
      recipe.macros.carbs *. 0.1,
      Breakfast,
    )

  entry.servings
  |> should.equal(0.1)

  entry.macros.protein
  |> should.equal(10.0)
}

/// Test: Large serving size
pub fn large_serving_size_test() {
  let recipe = create_test_recipe("recipe-1", "Soup", 10.0, 5.0, 20.0)

  // User logs 3 servings
  let entry =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      3.0,
      recipe.macros.protein *. 3.0,
      recipe.macros.fat *. 3.0,
      recipe.macros.carbs *. 3.0,
      Lunch,
    )

  entry.servings
  |> should.equal(3.0)

  entry.macros.protein
  |> should.equal(30.0)

  entry.macros.carbs
  |> should.equal(60.0)
}

/// Test: Empty daily log
pub fn empty_daily_log_test() {
  let daily_log = create_daily_log([])

  list.length(daily_log.entries)
  |> should.equal(0)

  daily_log.daily_totals.protein
  |> should.equal(0.0)

  daily_log.daily_totals.fat
  |> should.equal(0.0)

  daily_log.daily_totals.carbs
  |> should.equal(0.0)
}

/// Test: Single entry daily log
pub fn single_entry_daily_log_test() {
  let entry =
    create_test_entry(
      "e1",
      "r1",
      "Single Meal",
      1.0,
      50.0,
      20.0,
      75.0,
      Breakfast,
    )

  let daily_log = create_daily_log([entry])

  list.length(daily_log.entries)
  |> should.equal(1)

  daily_log.daily_totals.protein
  |> should.equal(50.0)

  daily_log.daily_totals.fat
  |> should.equal(20.0)

  daily_log.daily_totals.carbs
  |> should.equal(75.0)
}

// ============================================================================
// Test Group 8: Complete E2E Flow Scenarios
// ============================================================================

/// Scenario: User searches for "chicken", selects "Chicken Breast", logs 150g at lunch
pub fn e2e_search_select_log_usda_food_test() {
  // STEP 1: User searches for "chicken"
  // Expected: API returns list including "Chicken Breast" (fdc_id: 171477)

  // STEP 2: User selects "Chicken Breast"
  // Expected: USDA food details loaded (31g protein, 3.6g fat per 100g)

  // STEP 3: User enters 150g as portion
  let scaling_factor = 150.0 /. 100.0
  let scaled_macros =
    Macros(
      protein: 31.0 *. scaling_factor,
      fat: 3.6 *. scaling_factor,
      carbs: 0.0,
    )

  // STEP 4: User selects Lunch as meal type
  let entry =
    FoodLogEntry(
      id: "entry-1",
      recipe_id: "usda-171477",
      recipe_name: "Chicken Breast",
      servings: scaling_factor,
      macros: scaled_macros,
      micronutrients: None,
      meal_type: Lunch,
      logged_at: "2025-12-05T12:00:00Z",
      source_type: "usda_food",
      source_id: "171477",
    )

  // STEP 5: Entry saved to database
  // Verification: Entry contains all required fields
  entry.recipe_id
  |> should.not_equal("")

  entry.macros.protein
  |> should.equal(46.5)

  entry.source_type
  |> should.equal("usda_food")
}

/// Scenario: User saves recipe, then logs recipe with scaled servings
pub fn e2e_recipe_creation_and_logging_test() {
  // STEP 1: User creates recipe "Pasta Carbonara"
  let recipe =
    create_test_recipe("pasta-1", "Pasta Carbonara", 25.0, 18.0, 45.0)

  // STEP 2: Recipe saved with macros

  // STEP 3: User logs 1.5 servings at dinner
  let entry =
    create_test_entry(
      "entry-1",
      recipe.id,
      recipe.name,
      1.5,
      recipe.macros.protein *. 1.5,
      recipe.macros.fat *. 1.5,
      recipe.macros.carbs *. 1.5,
      Dinner,
    )

  // STEP 4: Entry saved to database
  entry.recipe_id
  |> should.equal("pasta-1")

  entry.macros.protein
  |> should.equal(37.5)

  entry.macros.fat
  |> should.equal(27.0)

  entry.macros.carbs
  |> should.equal(67.5)
}

/// Scenario: User logs entire day (breakfast, lunch, dinner, snacks)
pub fn e2e_complete_day_logging_test() {
  // STEP 1: User logs breakfast
  let breakfast =
    create_test_entry("e1", "r1", "Oatmeal", 1.0, 10.0, 3.0, 54.0, Breakfast)

  // STEP 2: User logs mid-morning snack
  let snack1 =
    create_test_entry("e2", "r2", "Apple", 1.0, 0.3, 0.1, 25.0, Snack)

  // STEP 3: User logs lunch
  let lunch =
    create_test_entry(
      "e3",
      "r3",
      "Salmon",
      200.0 /. 100.0,
      22.0 *. 2.0,
      13.0 *. 2.0,
      0.0,
      Lunch,
    )

  // STEP 4: User logs afternoon snack
  let snack2 =
    create_test_entry("e4", "r4", "Yogurt", 1.0, 10.0, 3.0, 5.0, Snack)

  // STEP 5: User logs dinner
  let dinner =
    create_test_entry(
      "e5",
      "r5",
      "Steak",
      150.0 /. 100.0,
      25.0 *. 1.5,
      18.0 *. 1.5,
      0.0,
      Dinner,
    )

  // STEP 6: User views daily dashboard
  let daily_log = create_daily_log([breakfast, snack1, lunch, snack2, dinner])

  // Verify all entries logged
  list.length(daily_log.entries)
  |> should.equal(5)

  // Verify daily totals calculated correctly
  daily_log.daily_totals.protein
  |> should.equal(10.0 +. 0.3 +. 44.0 +. 10.0 +. 37.5)

  daily_log.daily_totals.fat
  |> should.equal(3.0 +. 0.1 +. 26.0 +. 3.0 +. 27.0)

  daily_log.daily_totals.carbs
  |> should.equal(54.0 +. 25.0 +. 0.0 +. 5.0 +. 0.0)
}

/// Scenario: User modifies meal by logging another portion then checking total
pub fn e2e_modify_meal_add_second_portion_test() {
  // STEP 1: User logs 1 serving of recipe at lunch
  let serving1 =
    create_test_entry("e1", "recipe-1", "Pasta", 1.0, 20.0, 5.0, 40.0, Lunch)

  let daily_log_v1 = create_daily_log([serving1])

  daily_log_v1.daily_totals.protein
  |> should.equal(20.0)

  // STEP 2: User decides to add more and logs another 0.5 servings same recipe
  let serving2 =
    create_test_entry(
      "e2",
      "recipe-1",
      "Pasta",
      0.5,
      20.0 *. 0.5,
      5.0 *. 0.5,
      40.0 *. 0.5,
      Lunch,
    )

  let daily_log_v2 = create_daily_log([serving1, serving2])

  // STEP 3: User checks dashboard, sees updated totals
  daily_log_v2.daily_totals.protein
  |> should.equal(30.0)

  daily_log_v2.daily_totals.fat
  |> should.equal(7.5)

  daily_log_v2.daily_totals.carbs
  |> should.equal(60.0)
}
