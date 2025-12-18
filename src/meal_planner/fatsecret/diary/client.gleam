/// FatSecret SDK Food Diary API client
///
/// 3-legged authenticated API calls for food diary management.
/// All operations require user OAuth access token.
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type FoodEntryId, type FoodEntryInput, type FoodEntryUpdate,
  type MonthSummary,
} as diary_types
import meal_planner/logger

pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  let params = case input {
    diary_types.FromFood(
      food_id,
      food_entry_name,
      serving_id,
      number_of_units,
      meal,
      date_int,
    ) -> {
      dict.new()
      |> dict.insert("food_id", food_id)
      |> dict.insert("food_entry_name", food_entry_name)
      |> dict.insert("serving_id", serving_id)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("meal", diary_types.meal_type_to_string(meal))
      |> dict.insert("date_int", int.to_string(date_int))
    }
    diary_types.Custom(
      food_entry_name,
      serving_description,
      number_of_units,
      meal,
      date_int,
      calories,
      carbohydrate,
      protein,
      fat,
    ) -> {
      dict.new()
      |> dict.insert("food_entry_name", food_entry_name)
      |> dict.insert("serving_description", serving_description)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("meal", diary_types.meal_type_to_string(meal))
      |> dict.insert("date_int", int.to_string(date_int))
      |> dict.insert("calories", float.to_string(calories))
      |> dict.insert("carbohydrate", float.to_string(carbohydrate))
      |> dict.insert("protein", float.to_string(protein))
      |> dict.insert("fat", float.to_string(fat))
    }
  }

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.create",
    params,
  ))

  // Parse the response - FatSecret returns {"food_entry_id": {"value": "12345"}}
  json.parse(body, decode.at(["food_entry_id", "value"], decode.string))
  |> result.map(diary_types.food_entry_id)
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry ID from create response")
  })
}

pub fn get_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
) -> Result(FoodEntry, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "food_entry_id",
      diary_types.food_entry_id_to_string(entry_id),
    )

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.get",
    params,
  ))

  json.parse(body, decode.at(["food_entry"], decoders.food_entry_decoder()))
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry response")
  })
}

pub fn edit_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
  update: FoodEntryUpdate,
) -> Result(Nil, FatSecretError) {
  let diary_types.FoodEntryUpdate(number_of_units, meal) = update

  let params =
    dict.new()
    |> dict.insert(
      "food_entry_id",
      diary_types.food_entry_id_to_string(entry_id),
    )

  let params = case number_of_units {
    option.Some(n) -> dict.insert(params, "number_of_units", float.to_string(n))
    option.None -> params
  }

  let params = case meal {
    option.Some(m) ->
      dict.insert(params, "meal", diary_types.meal_type_to_string(m))
    option.None -> params
  }

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.edit",
    params,
  ))

  Ok(Nil)
}

pub fn delete_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "food_entry_id",
      diary_types.food_entry_id_to_string(entry_id),
    )

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.delete",
    params,
  ))

  Ok(Nil)
}

pub fn get_food_entries(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(List(FoodEntry), FatSecretError) {
  // Step 1: Log the request
  let _ =
    logger.info(
      "FatSecret: Requesting food entries for date_int="
      <> int.to_string(date_int),
    )

  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entries.get",
    params,
  ))

  // Step 2: Log the raw response (truncated for large responses)
  let truncated_body = case string.length(body) > 1000 {
    True -> string.slice(body, 0, 1000) <> "...(truncated)"
    False -> body
  }
  let _ = logger.debug("FatSecret API response: " <> truncated_body)

  // Step 3: Try to parse the response
  let parse_result =
    json.parse(
      body,
      decode.one_of(
        // Strategy 1: Standard format with array
        decode.at(
          ["food_entries", "food_entry"],
          decode.list(decoders.food_entry_decoder()),
        ),
        [
          // Strategy 2: Single entry (not in array)
          decode.at(
            ["food_entries", "food_entry"],
            single_entry_to_list_decoder(),
          ),
          // Strategy 3: Missing food_entry key or null value returns empty list
          decode.at(["food_entries"], decode.success([])),
          // Strategy 4: Fallback to empty list if structure completely different
          decode.success([]),
        ],
      ),
    )

  // Step 4: Log the parsing result
  case parse_result {
    Ok(entries) -> {
      let entry_count = list.length(entries)
      let total_calories =
        list.fold(entries, 0.0, fn(acc, entry) { acc +. entry.calories })
      let _ =
        logger.info(
          "FatSecret: Parsed "
          <> int.to_string(entry_count)
          <> " entries, total calories="
          <> float.to_string(total_calories),
        )
      Ok(entries)
    }
    Error(_) -> {
      let _ =
        logger.error(
          "FatSecret: Failed to parse food entries response for date_int="
          <> int.to_string(date_int),
        )
      Error(errors.ParseError("Failed to parse food entries response"))
    }
  }
}

pub fn get_month_summary(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(MonthSummary, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entries.get_month",
    params,
  ))

  json.parse(body, decode.at(["month"], decoders.month_summary_decoder()))
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse month summary response")
  })
}

fn single_entry_to_list_decoder() -> decode.Decoder(List(FoodEntry)) {
  use entry <- decode.then(decoders.food_entry_decoder())
  decode.success([entry])
}

// ============================================================================
// Copy/Template Operations (food_entry.copy, food_entry.copy_meal, etc.)
// ============================================================================

/// Copy all food entries from one date to another
///
/// FatSecret API: food_entry.copy
/// Copies all diary entries from the source date to the target date.
///
/// Parameters:
/// - from_date_int: Source date (days since epoch)
/// - to_date_int: Destination date (days since epoch)
///
/// Returns: Ok(Nil) on success, Error on failure
pub fn copy_entries(
  config: FatSecretConfig,
  token: AccessToken,
  from_date_int: Int,
  to_date_int: Int,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("from_date_int", int.to_string(from_date_int))
    |> dict.insert("to_date_int", int.to_string(to_date_int))

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.copy",
    params,
  ))

  Ok(Nil)
}

/// Copy entries for a specific meal from one date/meal to another
///
/// FatSecret API: food_entry.copy_meal
/// Copies diary entries from a specific meal slot to another meal slot.
///
/// Parameters:
/// - from_date_int: Source date (days since epoch)
/// - from_meal: Source meal type (breakfast, lunch, dinner, other)
/// - to_date_int: Destination date (days since epoch)
/// - to_meal: Destination meal type
///
/// Returns: Ok(Nil) on success, Error on failure
pub fn copy_meal(
  config: FatSecretConfig,
  token: AccessToken,
  from_date_int: Int,
  from_meal: diary_types.MealType,
  to_date_int: Int,
  to_meal: diary_types.MealType,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("from_date_int", int.to_string(from_date_int))
    |> dict.insert("from_meal", diary_types.meal_type_to_string(from_meal))
    |> dict.insert("to_date_int", int.to_string(to_date_int))
    |> dict.insert("to_meal", diary_types.meal_type_to_string(to_meal))

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.copy_meal",
    params,
  ))

  Ok(Nil)
}

/// Commit/finalize a day's diary entries
///
/// FatSecret API: food_entry.commit_day
/// Marks a day as complete/finalized in FatSecret.
///
/// Parameters:
/// - date_int: Date to commit (days since epoch)
///
/// Returns: Ok(Nil) on success, Error on failure
pub fn commit_day(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.commit_day",
    params,
  ))

  Ok(Nil)
}

/// Save a day's entries as a reusable template
///
/// FatSecret API: food_entry.save_template
/// Saves all entries from the specified date as a named template for reuse.
///
/// Parameters:
/// - date_int: Date whose entries to save (days since epoch)
/// - template_name: Name for the template
///
/// Returns: Ok(Nil) on success, Error on failure
pub fn save_template(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
  template_name: String,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))
    |> dict.insert("template_name", template_name)

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.save_template",
    params,
  ))

  Ok(Nil)
}
