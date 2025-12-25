/// PostgreSQL storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import meal_planner/id
import meal_planner/ncp
import meal_planner/postgres
import meal_planner/storage/utils
import meal_planner/types.{
  type UserProfile, daily_calorie_target, daily_carb_target, daily_fat_target,
  daily_macro_targets, daily_protein_target, micronutrients_decoder,
  micronutrients_to_json, new_user_profile, user_profile_activity_level,
  user_profile_bodyweight, user_profile_goal, user_profile_meals_per_day,
  user_profile_micronutrient_goals,
}
import meal_planner/types/user_profile.{
  type ActivityLevel, type Goal, Active, Gain, Lose, Maintain, Moderate,
  Sedentary,
}
import pog

/// Error type for storage operations
pub type StorageError {
  NotFound
  DatabaseError(String)
  InvalidInput(String)
  Unauthorized(String)
}

/// Convert a Result with pog.QueryError to a Result with StorageError
///
/// This helper eliminates the duplicate pattern:
/// ```gleam
/// case result {
///   Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
///   Ok(x) -> Ok(x)
/// }
/// ```
pub fn result_to_storage_error(
  result: Result(a, pog.QueryError),
) -> Result(a, StorageError) {
  case result {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(value) -> Ok(value)
  }
}

/// Database configuration (re-export from postgres module)
pub type DbConfig =
  postgres.Config

/// Default configuration for development (re-export from postgres module)
pub fn default_config() -> DbConfig {
  postgres.default_config()
}

/// Start the database connection pool (re-export from postgres module)
pub fn start_pool(config: DbConfig) -> Result(pog.Connection, String) {
  postgres.connect(config)
  |> result.map_error(postgres.format_error)
}

// Nutrition State

/// Save nutrition state for a specific date
pub fn save_nutrition_state(
  conn: pog.Connection,
  state: ncp.NutritionState,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO nutrition_state (date, protein, fat, carbs, calories, synced_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (date) DO UPDATE SET
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs,
       calories = EXCLUDED.calories,
       synced_at = NOW()"

  pog.query(sql)
  |> pog.parameter(pog.text(state.date))
  |> pog.parameter(pog.float(state.consumed.protein))
  |> pog.parameter(pog.float(state.consumed.fat))
  |> pog.parameter(pog.float(state.consumed.carbs))
  |> pog.parameter(pog.float(state.consumed.calories))
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(_) { Nil })
}

/// Get nutrition state for a specific date
pub fn get_nutrition_state(
  conn: pog.Connection,
  date: String,
) -> Result(ncp.NutritionState, StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at::text
     FROM nutrition_state WHERE date = $1"

  let decoder = {
    use date <- decode.field(0, decode.string)
    use protein <- decode.field(1, decode.float)
    use fat <- decode.field(2, decode.float)
    use carbs <- decode.field(3, decode.float)
    use calories <- decode.field(4, decode.float)
    use synced_at <- decode.field(5, decode.string)
    decode.success(ncp.NutritionState(
      date: date,
      consumed: ncp.NutritionData(
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
      ),
      synced_at: synced_at,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Get nutrition history for the last N days
pub fn get_nutrition_history(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(ncp.NutritionState), StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at::text
     FROM nutrition_state ORDER BY date DESC LIMIT $1"

  let decoder = {
    use date <- decode.field(0, decode.string)
    use protein <- decode.field(1, decode.float)
    use fat <- decode.field(2, decode.float)
    use carbs <- decode.field(3, decode.float)
    use calories <- decode.field(4, decode.float)
    use synced_at <- decode.field(5, decode.string)
    decode.success(ncp.NutritionState(
      date: date,
      consumed: ncp.NutritionData(
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
      ),
      synced_at: synced_at,
    ))
  }

  pog.query(sql)
  |> pog.parameter(pog.int(limit))
  |> pog.returning(decoder)
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

// Nutrition Goals

/// Save nutrition goals
pub fn save_goals(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO nutrition_goals (id, daily_protein, daily_fat, daily_carbs, daily_calories)
     VALUES (1, $1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       daily_protein = EXCLUDED.daily_protein,
       daily_fat = EXCLUDED.daily_fat,
       daily_carbs = EXCLUDED.daily_carbs,
       daily_calories = EXCLUDED.daily_calories"

  pog.query(sql)
  |> pog.parameter(pog.float(goals.daily_protein))
  |> pog.parameter(pog.float(goals.daily_fat))
  |> pog.parameter(pog.float(goals.daily_carbs))
  |> pog.parameter(pog.float(goals.daily_calories))
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(_) { Nil })
}

/// Get nutrition goals
pub fn get_goals(
  conn: pog.Connection,
) -> Result(ncp.NutritionGoals, StorageError) {
  let sql =
    "SELECT daily_protein, daily_fat, daily_carbs, daily_calories
     FROM nutrition_goals WHERE id = 1"

  let decoder = {
    use daily_protein <- decode.field(0, decode.float)
    use daily_fat <- decode.field(1, decode.float)
    use daily_carbs <- decode.field(2, decode.float)
    use daily_calories <- decode.field(3, decode.float)
    decode.success(ncp.NutritionGoals(
      daily_protein: daily_protein,
      daily_fat: daily_fat,
      daily_carbs: daily_carbs,
      daily_calories: daily_calories,
    ))
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

// User Profile

/// Save user profile
pub fn save_user_profile(
  conn: pog.Connection,
  profile: UserProfile,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO user_profile (id, bodyweight, activity_level, goal, meals_per_day, micronutrient_goals)
     VALUES (1, $1, $2, $3, $4, $5)
     ON CONFLICT (id) DO UPDATE SET
       bodyweight = EXCLUDED.bodyweight,
       activity_level = EXCLUDED.activity_level,
       goal = EXCLUDED.goal,
       meals_per_day = EXCLUDED.meals_per_day,
       micronutrient_goals = EXCLUDED.micronutrient_goals"

  let activity_str = case user_profile_activity_level(profile) {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }

  let goal_str = case user_profile_goal(profile) {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }

  // Encode micronutrient_goals to JSON string
  let micronutrient_goals_json = case user_profile_micronutrient_goals(profile) {
    Some(goals) ->
      pog.nullable(
        pog.text,
        Some(micronutrients_to_json(goals) |> json.to_string),
      )
    None -> pog.null()
  }

  pog.query(sql)
  |> pog.parameter(pog.float(user_profile_bodyweight(profile)))
  |> pog.parameter(pog.text(activity_str))
  |> pog.parameter(pog.text(goal_str))
  |> pog.parameter(pog.int(user_profile_meals_per_day(profile)))
  |> pog.parameter(micronutrient_goals_json)
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(_) { Nil })
}

/// Get user profile
pub fn get_user_profile(
  conn: pog.Connection,
) -> Result(UserProfile, StorageError) {
  let sql =
    "SELECT id, bodyweight, activity_level, goal, meals_per_day, micronutrient_goals
     FROM user_profile WHERE id = 1"

  let decoder = {
    use user_id <- decode.field(0, decode.int)
    use bodyweight <- decode.field(1, decode.float)
    use activity_str <- decode.field(2, decode.string)
    use goal_str <- decode.field(3, decode.string)
    use meals_per_day <- decode.field(4, decode.int)
    use micronutrient_goals_str <- decode.field(
      5,
      decode.optional(decode.string),
    )

    let activity_level = case activity_str {
      "sedentary" -> Sedentary
      "moderate" -> Moderate
      "active" -> Active
      _ -> Moderate
    }

    let goal = case goal_str {
      "gain" -> Gain
      "maintain" -> Maintain
      "lose" -> Lose
      _ -> Maintain
    }

    // Decode micronutrient_goals from JSON string
    let micronutrient_goals = case micronutrient_goals_str {
      Some(json_str) ->
        case json.parse(json_str, using: micronutrients_decoder()) {
          Ok(goals) -> Some(goals)
          Error(_) -> None
        }
      None -> None
    }

    case
      new_user_profile(
        id: id.user_id(int.to_string(user_id)),
        bodyweight: bodyweight,
        activity_level: activity_level,
        goal: goal,
        meals_per_day: meals_per_day,
        micronutrient_goals: micronutrient_goals,
      )
    {
      Ok(profile) -> decode.success(profile)
      Error(err) -> decode.failure(_, err)
    }
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}
