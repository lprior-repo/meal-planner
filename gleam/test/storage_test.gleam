import gleam/list
import gleeunit/should
import meal_planner/ncp
import meal_planner/storage
import meal_planner/types.{
  type Recipe, Active, Gain, High, Ingredient, Lose, Low, Macros, Maintain,
  Medium, Moderate, Recipe, Sedentary, UserProfile,
}

// ============================================================================
// User Profile Persistence Tests
// ============================================================================

pub fn save_and_get_user_profile_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    let profile =
      UserProfile(
        bodyweight: 180.0,
        activity_level: Moderate,
        goal: Gain,
        meals_per_day: 4,
      )

    // Save profile
    let assert Ok(Nil) = storage.save_user_profile(conn, profile)

    // Retrieve profile
    let assert Ok(retrieved) = storage.get_user_profile(conn)

    retrieved.bodyweight |> should.equal(180.0)
    retrieved.meals_per_day |> should.equal(4)
  })
}

pub fn save_user_profile_activity_levels_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Test sedentary
    let profile_sed =
      UserProfile(
        bodyweight: 150.0,
        activity_level: Sedentary,
        goal: Lose,
        meals_per_day: 3,
      )
    let assert Ok(Nil) = storage.save_user_profile(conn, profile_sed)
    let assert Ok(retrieved_sed) = storage.get_user_profile(conn)
    // Verify sedentary was stored correctly
    case retrieved_sed.activity_level {
      Sedentary -> should.be_true(True)
      _ -> should.be_true(False)
    }

    // Test active
    let profile_active =
      UserProfile(
        bodyweight: 200.0,
        activity_level: Active,
        goal: Gain,
        meals_per_day: 5,
      )
    let assert Ok(Nil) = storage.save_user_profile(conn, profile_active)
    let assert Ok(retrieved_active) = storage.get_user_profile(conn)
    case retrieved_active.activity_level {
      Active -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

pub fn get_user_profile_not_found_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Try to get profile that doesn't exist
    case storage.get_user_profile(conn) {
      Error(storage.NotFound) -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

pub fn user_profile_upsert_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Save initial profile
    let profile1 =
      UserProfile(
        bodyweight: 175.0,
        activity_level: Moderate,
        goal: Maintain,
        meals_per_day: 3,
      )
    let assert Ok(Nil) = storage.save_user_profile(conn, profile1)

    // Update profile (should replace, not create duplicate)
    let profile2 =
      UserProfile(
        bodyweight: 180.0,
        activity_level: Active,
        goal: Gain,
        meals_per_day: 4,
      )
    let assert Ok(Nil) = storage.save_user_profile(conn, profile2)

    // Should get the updated profile
    let assert Ok(retrieved) = storage.get_user_profile(conn)
    retrieved.bodyweight |> should.equal(180.0)
    retrieved.meals_per_day |> should.equal(4)
  })
}

// ============================================================================
// Nutrition State Persistence Tests
// ============================================================================

pub fn save_and_get_nutrition_state_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    let state =
      ncp.NutritionState(
        date: "2025-01-15",
        consumed: ncp.NutritionData(
          protein: 150.0,
          fat: 60.0,
          carbs: 200.0,
          calories: 1940.0,
        ),
        synced_at: "2025-01-15T18:00:00Z",
      )

    let assert Ok(Nil) = storage.save_nutrition_state(conn, state)
    let assert Ok(retrieved) = storage.get_nutrition_state(conn, "2025-01-15")

    retrieved.date |> should.equal("2025-01-15")
    retrieved.consumed.protein |> should.equal(150.0)
    retrieved.consumed.fat |> should.equal(60.0)
    retrieved.consumed.carbs |> should.equal(200.0)
    retrieved.consumed.calories |> should.equal(1940.0)
    retrieved.synced_at |> should.equal("2025-01-15T18:00:00Z")
  })
}

pub fn get_nutrition_state_not_found_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    case storage.get_nutrition_state(conn, "2025-01-01") {
      Error(storage.NotFound) -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

pub fn get_nutrition_history_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Save multiple days of data
    let state1 =
      ncp.NutritionState(
        date: "2025-01-13",
        consumed: ncp.NutritionData(
          protein: 140.0,
          fat: 55.0,
          carbs: 180.0,
          calories: 1775.0,
        ),
        synced_at: "",
      )

    let state2 =
      ncp.NutritionState(
        date: "2025-01-14",
        consumed: ncp.NutritionData(
          protein: 160.0,
          fat: 65.0,
          carbs: 220.0,
          calories: 2105.0,
        ),
        synced_at: "",
      )

    let state3 =
      ncp.NutritionState(
        date: "2025-01-15",
        consumed: ncp.NutritionData(
          protein: 150.0,
          fat: 60.0,
          carbs: 200.0,
          calories: 1940.0,
        ),
        synced_at: "",
      )

    let assert Ok(Nil) = storage.save_nutrition_state(conn, state1)
    let assert Ok(Nil) = storage.save_nutrition_state(conn, state2)
    let assert Ok(Nil) = storage.save_nutrition_state(conn, state3)

    // Get history with limit of 2 (should get most recent first)
    let assert Ok(history) = storage.get_nutrition_history(conn, 2)

    history |> list.length |> should.equal(2)
  })
}

pub fn nutrition_state_upsert_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Save initial state
    let state1 =
      ncp.NutritionState(
        date: "2025-01-15",
        consumed: ncp.NutritionData(
          protein: 100.0,
          fat: 40.0,
          carbs: 150.0,
          calories: 1360.0,
        ),
        synced_at: "",
      )
    let assert Ok(Nil) = storage.save_nutrition_state(conn, state1)

    // Update same date (should replace)
    let state2 =
      ncp.NutritionState(
        date: "2025-01-15",
        consumed: ncp.NutritionData(
          protein: 150.0,
          fat: 60.0,
          carbs: 200.0,
          calories: 1940.0,
        ),
        synced_at: "updated",
      )
    let assert Ok(Nil) = storage.save_nutrition_state(conn, state2)

    // Should get the updated state
    let assert Ok(retrieved) = storage.get_nutrition_state(conn, "2025-01-15")
    retrieved.consumed.protein |> should.equal(150.0)
    retrieved.synced_at |> should.equal("updated")
  })
}

// ============================================================================
// Nutrition Goals Persistence Tests
// ============================================================================

pub fn save_and_get_goals_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    let goals =
      ncp.NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 60.0,
        daily_carbs: 300.0,
        daily_calories: 2500.0,
      )

    let assert Ok(Nil) = storage.save_goals(conn, goals)
    let assert Ok(retrieved) = storage.get_goals(conn)

    retrieved.daily_protein |> should.equal(180.0)
    retrieved.daily_fat |> should.equal(60.0)
    retrieved.daily_carbs |> should.equal(300.0)
    retrieved.daily_calories |> should.equal(2500.0)
  })
}

pub fn get_goals_not_found_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    case storage.get_goals(conn) {
      Error(storage.NotFound) -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

// ============================================================================
// Database Initialization Tests
// ============================================================================

pub fn init_db_creates_tables_test() {
  storage.with_connection(":memory:", fn(conn) {
    // First init should succeed
    let assert Ok(Nil) = storage.init_db(conn)
    // Second init should also succeed (IF NOT EXISTS)
    let assert Ok(Nil) = storage.init_db(conn)
  })
}

// ============================================================================
// Recipe Storage Tests
// ============================================================================

fn make_test_recipe(id: String, name: String) -> Recipe {
  Recipe(
    id: id,
    name: name,
    ingredients: [
      Ingredient(name: "chicken breast", quantity: "200g"),
      Ingredient(name: "olive oil", quantity: "1 tbsp"),
    ],
    instructions: ["Season chicken", "Cook in pan"],
    macros: Macros(protein: 40.0, fat: 8.0, carbs: 2.0),
    servings: 1,
    category: "protein",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

pub fn init_recipe_tables_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)
    // Second call should also succeed (IF NOT EXISTS)
    let assert Ok(Nil) = storage.init_recipe_tables(conn)
  })
}

pub fn save_and_get_recipe_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let recipe = make_test_recipe("recipe-001", "Grilled Chicken")
    let assert Ok(Nil) = storage.save_recipe(conn, recipe)

    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "recipe-001")
    retrieved.name |> should.equal("Grilled Chicken")
    retrieved.id |> should.equal("recipe-001")
    retrieved.macros.protein |> should.equal(40.0)
    retrieved.category |> should.equal("protein")
    retrieved.vertical_compliant |> should.be_true()
  })
}

pub fn get_recipe_by_id_not_found_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    case storage.get_recipe_by_id(conn, "nonexistent") {
      Error(storage.NotFound) -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

pub fn get_all_recipes_empty_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let assert Ok(recipes) = storage.get_all_recipes(conn)
    recipes |> list.length |> should.equal(0)
  })
}

pub fn get_all_recipes_multiple_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let recipe1 = make_test_recipe("recipe-001", "Grilled Chicken")
    let recipe2 = make_test_recipe("recipe-002", "Baked Salmon")
    let recipe3 = make_test_recipe("recipe-003", "Rice Bowl")

    let assert Ok(Nil) = storage.save_recipe(conn, recipe1)
    let assert Ok(Nil) = storage.save_recipe(conn, recipe2)
    let assert Ok(Nil) = storage.save_recipe(conn, recipe3)

    let assert Ok(recipes) = storage.get_all_recipes(conn)
    recipes |> list.length |> should.equal(3)
  })
}

pub fn get_recipes_by_category_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let chicken =
      Recipe(
        ..make_test_recipe("recipe-001", "Grilled Chicken"),
        category: "protein",
      )
    let rice =
      Recipe(
        ..make_test_recipe("recipe-002", "White Rice"),
        category: "carb",
        macros: Macros(protein: 4.0, fat: 0.5, carbs: 45.0),
      )
    let salmon =
      Recipe(
        ..make_test_recipe("recipe-003", "Baked Salmon"),
        category: "protein",
      )

    let assert Ok(Nil) = storage.save_recipe(conn, chicken)
    let assert Ok(Nil) = storage.save_recipe(conn, rice)
    let assert Ok(Nil) = storage.save_recipe(conn, salmon)

    let assert Ok(proteins) = storage.get_recipes_by_category(conn, "protein")
    proteins |> list.length |> should.equal(2)

    let assert Ok(carbs) = storage.get_recipes_by_category(conn, "carb")
    carbs |> list.length |> should.equal(1)
  })
}

pub fn get_recipes_by_category_empty_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let assert Ok(recipes) =
      storage.get_recipes_by_category(conn, "nonexistent")
    recipes |> list.length |> should.equal(0)
  })
}

pub fn save_recipe_upsert_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    // Save initial recipe
    let recipe1 = make_test_recipe("recipe-001", "Grilled Chicken")
    let assert Ok(Nil) = storage.save_recipe(conn, recipe1)

    // Update same recipe (should replace)
    let recipe2 =
      Recipe(
        ..recipe1,
        name: "Spicy Grilled Chicken",
        macros: Macros(protein: 42.0, fat: 10.0, carbs: 3.0),
      )
    let assert Ok(Nil) = storage.save_recipe(conn, recipe2)

    // Should get the updated recipe
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "recipe-001")
    retrieved.name |> should.equal("Spicy Grilled Chicken")
    retrieved.macros.protein |> should.equal(42.0)

    // Should still only have one recipe
    let assert Ok(all) = storage.get_all_recipes(conn)
    all |> list.length |> should.equal(1)
  })
}

pub fn save_recipe_with_fodmap_levels_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    // Low FODMAP
    let low_fodmap =
      Recipe(..make_test_recipe("recipe-low", "Low FODMAP"), fodmap_level: Low)
    let assert Ok(Nil) = storage.save_recipe(conn, low_fodmap)
    let assert Ok(retrieved_low) = storage.get_recipe_by_id(conn, "recipe-low")
    case retrieved_low.fodmap_level {
      Low -> should.be_true(True)
      _ -> should.be_true(False)
    }

    // Medium FODMAP
    let medium_fodmap =
      Recipe(
        ..make_test_recipe("recipe-medium", "Medium FODMAP"),
        fodmap_level: Medium,
      )
    let assert Ok(Nil) = storage.save_recipe(conn, medium_fodmap)
    let assert Ok(retrieved_medium) =
      storage.get_recipe_by_id(conn, "recipe-medium")
    case retrieved_medium.fodmap_level {
      Medium -> should.be_true(True)
      _ -> should.be_true(False)
    }

    // High FODMAP
    let high_fodmap =
      Recipe(
        ..make_test_recipe("recipe-high", "High FODMAP"),
        fodmap_level: High,
      )
    let assert Ok(Nil) = storage.save_recipe(conn, high_fodmap)
    let assert Ok(retrieved_high) =
      storage.get_recipe_by_id(conn, "recipe-high")
    case retrieved_high.fodmap_level {
      High -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

pub fn save_recipe_vertical_compliance_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    // Vertical compliant
    let compliant =
      Recipe(
        ..make_test_recipe("recipe-compliant", "Compliant"),
        vertical_compliant: True,
      )
    let assert Ok(Nil) = storage.save_recipe(conn, compliant)
    let assert Ok(retrieved_compliant) =
      storage.get_recipe_by_id(conn, "recipe-compliant")
    retrieved_compliant.vertical_compliant |> should.be_true()

    // Non-compliant
    let non_compliant =
      Recipe(
        ..make_test_recipe("recipe-noncompliant", "Non-Compliant"),
        vertical_compliant: False,
      )
    let assert Ok(Nil) = storage.save_recipe(conn, non_compliant)
    let assert Ok(retrieved_non) =
      storage.get_recipe_by_id(conn, "recipe-noncompliant")
    retrieved_non.vertical_compliant |> should.be_false()
  })
}

pub fn recipe_ingredients_serialization_test() {
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(Nil) = storage.init_recipe_tables(conn)

    let recipe =
      Recipe(
        id: "recipe-multi-ingredient",
        name: "Complex Recipe",
        ingredients: [
          Ingredient(name: "chicken", quantity: "200g"),
          Ingredient(name: "rice", quantity: "1 cup"),
          Ingredient(name: "vegetables", quantity: "100g"),
        ],
        instructions: ["Step 1", "Step 2", "Step 3"],
        macros: Macros(protein: 35.0, fat: 10.0, carbs: 50.0),
        servings: 2,
        category: "main",
        fodmap_level: Low,
        vertical_compliant: True,
      )

    let assert Ok(Nil) = storage.save_recipe(conn, recipe)
    let assert Ok(retrieved) =
      storage.get_recipe_by_id(conn, "recipe-multi-ingredient")

    // Verify ingredients were serialized and deserialized correctly
    retrieved.ingredients |> list.length |> should.equal(3)
    retrieved.instructions |> list.length |> should.equal(3)
  })
}
