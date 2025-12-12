/// Example: Log food from Tandoor recipes
///
/// This example demonstrates how to log meals from Tandoor recipes
/// and track nutritional data in the meal planner.
///
/// Prerequisites:
/// - Tandoor running on http://localhost:8000
/// - TANDOOR_API_TOKEN environment variable set
/// - Database configured and running
/// - Tandoor recipes already created
///
/// Usage:
/// ```bash
/// # Run the example
/// gleam run -m examples/tandoor_food_logging_example
/// ```

import gleam/io

// Example 1: Basic food logging workflow
pub fn example_basic_food_logging() {
  io.println("=== Log Food from Tandoor Recipe Example ===\n")

  io.println(
    "Workflow for logging Tandoor recipe meals:\n\n"
    <> "1. Select a Tandoor recipe\n"
    <> "   - Query Tandoor API for available recipes\n"
    <> "   - User selects recipe from UI\n\n"
    <> "2. Specify portion size\n"
    <> "   - Default: 1 serving\n"
    <> "   - User can adjust: 0.5, 1.5, 2.0 servings, etc.\n\n"
    <> "3. Select meal type\n"
    <> "   - Breakfast, Lunch, Dinner, Snack\n\n"
    <> "4. Log to database\n"
    <> "   - Create FoodLogEntry with:  \n"
    <> "     - recipe_id: from Tandoor\n"
    <> "     - recipe_name: from Tandoor\n"
    <> "     - servings: user-selected amount\n"
    <> "     - macros: calculated from recipe nutrition × servings\n"
    <> "     - source_type: \"tandoor_recipe\"\n"
    <> "     - meal_type: user-selected\n\n"
    <> "5. Update nutrition totals for the day\n",
  )
}

// Example 2: Food log entry structure
pub fn example_food_log_entry() {
  io.println("\n=== Food Log Entry Structure ===\n")

  io.println(
    "FoodLogEntry when logging Tandoor recipe:\n\n"
    <> "{\n"
    <> "  id: \"grilled-chicken-breast-456789\",\n"
    <> "  date: \"2025-12-12\",\n"
    <> "  recipe_id: \"grilled-chicken-breast\",\n"
    <> "  recipe_name: \"Grilled Chicken Breast\",\n"
    <> "  servings: 2.0,\n"
    <> "  macros: {\n"
    <> "    protein: 62.0,  // 31 per serving × 2 servings\n"
    <> "    fat: 7.2,       // 3.6 per serving × 2 servings  \n"
    <> "    carbs: 0.0      // 0 per serving × 2 servings\n"
    <> "  },\n"
    <> "  meal_type: \"Lunch\",\n"
    <> "  source_type: \"tandoor_recipe\",\n"
    <> "  source_id: \"grilled-chicken-breast\",\n"
    <> "  logged_at: \"2025-12-12T12:30:00Z\",\n"
    <> "  micronutrients: {... optional details ...}\n"
    <> "}\n",
  )
}

// Example 3: Logging multiple meals in one day
pub fn example_daily_logging() {
  io.println("\n=== Daily Meal Logging Example ===\n")

  io.println(
    "Scenario: User logs meals throughout the day\n\n"
    <> "Breakfast (8:00 AM):\n"
    <> "  - Eggs and Bacon (2 servings)\n"
    <> "  - Protein: 35g, Fat: 30g, Carbs: 5g\n\n"
    <> "Lunch (12:30 PM):\n"
    <> "  - Grilled Chicken (1.5 servings)\n"
    <> "  - Protein: 47g, Fat: 5g, Carbs: 0g\n\n"
    <> "Dinner (6:00 PM):\n"
    <> "  - Salmon with Broccoli (1 serving)\n"
    <> "  - Protein: 40g, Fat: 25g, Carbs: 8g\n\n"
    <> "Daily Totals:\n"
    <> "  - Total Protein: 122g\n"
    <> "  - Total Fat: 60g\n"
    <> "  - Total Carbs: 13g\n"
    <> "  - Total Calories: ~1,220 kcal\n",
  )
}

// Example 4: Portion adjustment calculations
pub fn example_portion_calculations() {
  io.println("\n=== Portion Size Adjustments ===\n")

  io.println(
    "Recipe base nutrition (1 serving):\n"
    <> "  Protein: 31g, Fat: 3.6g, Carbs: 0g\n\n"
    <> "Adjustments:\n"
    <> "  0.5 serving: Protein: 15.5g, Fat: 1.8g, Carbs: 0g\n"
    <> "  1.0 serving: Protein: 31g, Fat: 3.6g, Carbs: 0g\n"
    <> "  1.5 serving: Protein: 46.5g, Fat: 5.4g, Carbs: 0g\n"
    <> "  2.0 serving: Protein: 62g, Fat: 7.2g, Carbs: 0g\n"
    <> "  3.0 serving: Protein: 93g, Fat: 10.8g, Carbs: 0g\n\n"
    <> "Implementation:\n"
    <> "  macro_values = recipe_nutrition × user_servings\n",
  )
}

// Example 5: Database storage
pub fn example_database_storage() {
  io.println("\n=== Database Storage ===\n")

  io.println(
    "SQL insert for food log entry:\n\n"
    <> "INSERT INTO food_logs (\n"
    <> "  id, date, recipe_id, recipe_name, servings,\n"
    <> "  protein, fat, carbs, meal_type, source_type, source_id,\n"
    <> "  fiber, sugar, sodium, logged_at\n"
    <> ") VALUES (\n"
    <> "  'grilled-chicken-breast-456789',\n"
    <> "  '2025-12-12',\n"
    <> "  'grilled-chicken-breast',\n"
    <> "  'Grilled Chicken Breast',\n"
    <> "  2.0,\n"
    <> "  62.0, 7.2, 0.0,\n"
    <> "  'Lunch',\n"
    <> "  'tandoor_recipe',\n"
    <> "  'grilled-chicken-breast',\n"
    <> "  NULL, NULL, NULL,\n"
    <> "  NOW()\n"
    <> ");\n",
  )
}

// Example 6: Retrieving logged meals
pub fn example_retrieve_logged_meals() {
  io.println("\n=== Retrieve Logged Meals ===\n")

  io.println(
    "Query to get daily logs:\n\n"
    <> "SELECT id, recipe_id, recipe_name, servings, protein, fat, carbs,\n"
    <> "       meal_type, logged_at\n"
    <> "FROM food_logs\n"
    <> "WHERE date = '2025-12-12'\n"
    <> "ORDER BY logged_at ASC;\n\n"
    <> "Response:\n"
    <> "id                          | recipe_id          | servings | protein | fat | carbs\n"
    <> "--------------------------- | ------------------ | -------- | ------- | --- | -----\n"
    <> "eggs-bacon-123             | eggs-bacon         | 2.0      | 35      | 30  | 5\n"
    <> "grilled-chicken-breast-456 | grilled-chicken    | 1.5      | 47      | 5   | 0\n"
    <> "salmon-broccoli-789        | salmon-broccoli    | 1.0      | 40      | 25  | 8\n",
  )
}

// Example 7: Error handling when logging
pub fn example_error_handling() {
  io.println("\n=== Error Handling ===\n")

  io.println(
    "Validation before logging:\n\n"
    <> "1. Recipe exists in Tandoor\n"
    <> "   Error: Recipe not found (404)\n"
    <> "   Solution: Refresh recipe list\n\n"
    <> "2. Portion size is valid (> 0)\n"
    <> "   Error: Invalid portion size\n"
    <> "   Solution: Request valid decimal number\n\n"
    <> "3. Meal type is valid\n"
    <> "   Error: Invalid meal type\n"
    <> "   Solution: Use: Breakfast, Lunch, Dinner, Snack\n\n"
    <> "4. Date is valid\n"
    <> "   Error: Date in future or very old\n"
    <> "   Solution: Use recent dates only\n\n"
    <> "5. User is authenticated\n"
    <> "   Error: Unauthorized (401)\n"
    <> "   Solution: Ensure user is logged in\n",
  )
}

// Example 8: Best practices
pub fn example_best_practices() {
  io.println("\n=== Best Practices for Food Logging ===\n")

  io.println(
    "1. Caching\n"
    <> "   - Cache Tandoor recipes locally\n"
    <> "   - Refresh cache periodically (daily/weekly)\n"
    <> "   - Serve from cache for better performance\n\n"
    <> "2. Portion Tracking\n"
    <> "   - Allow decimal servings (0.5, 1.5, 2.0)\n"
    <> "   - Validate portion > 0\n"
    <> "   - Round to sensible decimals (0.1 precision)\n\n"
    <> "3. Macro Calculations\n"
    <> "   - Always multiply recipe macros by servings\n"
    <> "   - Round final values to 1 decimal place\n"
    <> "   - Verify totals match expected ranges\n\n"
    <> "4. Data Consistency\n"
    <> "   - Store source_type and source_id for traceability\n"
    <> "   - Include logged_at timestamp for sorting\n"
    <> "   - Keep recipe_name denormalized for readability\n\n"
    <> "5. User Experience\n"
    <> "   - Show macro preview before confirming log\n"
    <> "   - Allow quick access to recent meals\n"
    <> "   - Provide meal templates for common meals\n"
    <> "   - Support batch logging\n",
  )
}

pub fn main() {
  example_basic_food_logging()
  example_food_log_entry()
  example_daily_logging()
  example_portion_calculations()
  example_database_storage()
  example_retrieve_logged_meals()
  example_error_handling()
  example_best_practices()

  io.println(
    "\n=== Next Steps ===\n"
    <> "1. Review tandoor_api_query_example.gleam for fetching recipes\n"
    <> "2. Review tandoor_recipe_creation_example.gleam for creating recipes\n"
    <> "3. Integrate with web handlers for UI\n"
    <> "4. Test with real Tandoor instance\n"
    <> "5. Monitor performance with large datasets\n",
  )
}
