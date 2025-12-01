//// Test helper functions for integration testing
//// Provides sample data and utilities for database testing

import gleam/int
import gleam/io
import shared/types.{
  type Macros, type Recipe, type UserProfile, Active, Gain, Ingredient, Lose,
  Low, Macros, Maintain, Moderate, Recipe, Sedentary, UserProfile,
}
import simplifile
import sqlight

/// Sample recipe for testing
pub fn sample_recipe() -> Recipe {
  Recipe(
    id: "test-chicken-rice",
    name: "Test Chicken and Rice",
    ingredients: [
      Ingredient(name: "Chicken breast", quantity: "8 oz"),
      Ingredient(name: "White rice", quantity: "1 cup"),
      Ingredient(name: "Olive oil", quantity: "1 tbsp"),
    ],
    instructions: [
      "Cook rice according to package",
      "Season and grill chicken breast",
      "Serve chicken over rice",
    ],
    macros: Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
    servings: 1,
    category: "chicken",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Sample user profile for testing
pub fn sample_profile() -> UserProfile {
  UserProfile(
    id: "test-user-1",
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
  )
}

/// Sample user profile with active lifestyle
pub fn sample_active_profile() -> UserProfile {
  UserProfile(
    id: "test-user-active",
    bodyweight: 200.0,
    activity_level: Active,
    goal: Gain,
    meals_per_day: 4,
  )
}

/// Sample user profile with sedentary lifestyle
pub fn sample_sedentary_profile() -> UserProfile {
  UserProfile(
    id: "test-user-sedentary",
    bodyweight: 160.0,
    activity_level: Sedentary,
    goal: Lose,
    meals_per_day: 3,
  )
}

/// Sample macros for testing
pub fn sample_macros() -> Macros {
  Macros(protein: 40.0, fat: 20.0, carbs: 50.0)
}

/// Sample high-protein recipe for NCP testing
pub fn sample_high_protein_recipe() -> Recipe {
  Recipe(
    id: "test-high-protein",
    name: "High Protein Meal",
    ingredients: [
      Ingredient(name: "Chicken breast", quantity: "12 oz"),
      Ingredient(name: "Egg whites", quantity: "4 eggs"),
    ],
    instructions: ["Cook chicken", "Cook eggs", "Combine"],
    macros: Macros(protein: 80.0, fat: 10.0, carbs: 5.0),
    servings: 1,
    category: "high-protein",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Sample balanced recipe for testing
pub fn sample_balanced_recipe() -> Recipe {
  Recipe(
    id: "test-balanced",
    name: "Balanced Meal",
    ingredients: [
      Ingredient(name: "Salmon", quantity: "6 oz"),
      Ingredient(name: "Sweet potato", quantity: "1 medium"),
      Ingredient(name: "Broccoli", quantity: "1 cup"),
    ],
    instructions: ["Bake salmon", "Roast sweet potato", "Steam broccoli"],
    macros: Macros(protein: 35.0, fat: 15.0, carbs: 30.0),
    servings: 1,
    category: "balanced",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Run a function with a temporary in-memory database
/// Automatically initializes the database and cleans up after
pub fn with_temp_db(f: fn(sqlight.Connection) -> a) -> a {
  sqlight.with_connection(":memory:", f)
}

/// Run a function with a temporary file-based database
/// Creates a temp database file, runs the function, then deletes the file
pub fn with_temp_file_db(f: fn(sqlight.Connection) -> a) -> a {
  let temp_path = "/tmp/test_meal_planner_" <> generate_random_id() <> ".db"

  let result = sqlight.with_connection(temp_path, f)

  // Clean up temp file
  case simplifile.delete(temp_path) {
    Ok(_) -> Nil
    Error(_) -> {
      io.println("Warning: Could not delete temp database: " <> temp_path)
      Nil
    }
  }

  result
}

/// Generate a random ID for temp database files
fn generate_random_id() -> String {
  // Use current timestamp in microseconds as a simple unique ID
  int.to_string(timestamp_microseconds())
}

@external(erlang, "erlang", "system_time")
fn timestamp_microseconds() -> Int
