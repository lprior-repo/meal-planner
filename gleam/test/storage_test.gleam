import gleam/list
import gleeunit/should
import meal_planner/ncp
import meal_planner/storage
import meal_planner/types.{
  Active, Gain, Lose, Maintain, Moderate, Sedentary, UserProfile,
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
