import gleeunit/should
import meal_planner/storage
import meal_planner/ncp.{NutritionData, NutritionGoals}

pub fn init_db_test() {
  use conn <- storage.with_connection(":memory:")
  storage.init_db(conn)
  |> should.be_ok()
}

pub fn save_and_get_nutrition_state_test() {
  use conn <- storage.with_connection(":memory:")
  let assert Ok(Nil) = storage.init_db(conn)

  let data =
    NutritionData(protein: 150.0, fat: 60.0, carbs: 200.0, calories: 2000.0)
  let assert Ok(Nil) = storage.save_nutrition_state(conn, "2025-01-15", data)

  let assert Ok(retrieved) = storage.get_nutrition_state(conn, "2025-01-15")
  retrieved.protein |> should.equal(150.0)
  retrieved.fat |> should.equal(60.0)
  retrieved.carbs |> should.equal(200.0)
  retrieved.calories |> should.equal(2000.0)
}

pub fn get_nutrition_state_not_found_test() {
  use conn <- storage.with_connection(":memory:")
  let assert Ok(Nil) = storage.init_db(conn)

  storage.get_nutrition_state(conn, "2025-01-01")
  |> should.be_error()
}

pub fn save_and_get_goals_test() {
  use conn <- storage.with_connection(":memory:")
  let assert Ok(Nil) = storage.init_db(conn)

  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 70.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  let assert Ok(Nil) = storage.save_goals(conn, goals)

  let assert Ok(retrieved) = storage.get_goals(conn)
  retrieved.daily_protein |> should.equal(180.0)
  retrieved.daily_fat |> should.equal(70.0)
  retrieved.daily_carbs |> should.equal(250.0)
  retrieved.daily_calories |> should.equal(2500.0)
}

pub fn update_nutrition_state_test() {
  use conn <- storage.with_connection(":memory:")
  let assert Ok(Nil) = storage.init_db(conn)

  // Save initial state
  let data1 =
    NutritionData(protein: 100.0, fat: 40.0, carbs: 150.0, calories: 1500.0)
  let assert Ok(Nil) = storage.save_nutrition_state(conn, "2025-01-15", data1)

  // Update with new values
  let data2 =
    NutritionData(protein: 120.0, fat: 50.0, carbs: 180.0, calories: 1800.0)
  let assert Ok(Nil) = storage.save_nutrition_state(conn, "2025-01-15", data2)

  // Should get updated values
  let assert Ok(retrieved) = storage.get_nutrition_state(conn, "2025-01-15")
  retrieved.protein |> should.equal(120.0)
  retrieved.calories |> should.equal(1800.0)
}
