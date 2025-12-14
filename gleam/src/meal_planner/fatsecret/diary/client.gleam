/// FatSecret SDK Food Diary API client
///
/// 3-legged authenticated API calls for food diary management.
/// All operations require user OAuth access token.
///
/// The diary API allows creating, reading, updating and deleting food entries,
/// and retrieving aggregated nutrition summaries for dates or months.
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/option
import gleam/result
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types.{
  type FoodEntry,
  type FoodEntryId,
  type FoodEntryInput,
  type FoodEntryUpdate,
  type MonthSummary,
}
import meal_planner/fatsecret/diary/types as types

// ============================================================================
// Food Entry Creation (3-legged)
// ============================================================================

/// Create a new food entry in the diary (food_entry.create method)
///
/// Adds a new food entry to the user's diary. Can be created from an existing
/// FatSecret food or with manually entered nutrition values.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - input: Food entry data to create
///
/// Returns:
/// - Ok(FoodEntryId) with the created entry's ID
/// - Error(FatSecretError) on API failure
///
/// Example:
/// ```gleam
/// let input = FromFood(
///   food_id: "4142",
///   serving_id: "12345",
///   number_of_units: 1.5,
///   meal: Dinner,
///   date_int: 19723,
/// )
/// create_food_entry(config, token, input)
/// ```
pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  let params = case input {
    types.FromFood(food_id, serving_id, number_of_units, meal, date_int) -> {
      dict.new()
      |> dict.insert("food_id", food_id)
      |> dict.insert("serving_id", serving_id)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("meal", types.meal_type_to_string(meal))
      |> dict.insert("date_int", int.to_string(date_int))
    }
    types.Custom(
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
      |> dict.insert("meal", types.meal_type_to_string(meal))
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

  // Parse the response to get the food_entry_id
  json.parse(body, decode.at(["food_entry_id"], decode.string))
  |> result.map(types.food_entry_id)
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry ID from create response")
  })
}

// ============================================================================
// Food Entry Retrieval (3-legged)
// ============================================================================

/// Get a specific food entry by ID (food_entry.get method)
///
/// Retrieves the details of a previously created food entry.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - entry_id: ID of the entry to retrieve
///
/// Returns:
/// - Ok(FoodEntry) with all entry details
/// - Error(FatSecretError) on API failure
pub fn get_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
) -> Result(FoodEntry, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_entry_id", types.food_entry_id_to_string(entry_id))

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

// ============================================================================
// Food Entry Update (3-legged)
// ============================================================================

/// Update an existing food entry (food_entry.edit method)
///
/// Updates the number of units and/or meal type for an existing entry.
/// To change the food or nutrition values, delete and recreate the entry.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - entry_id: ID of the entry to update
/// - update: Update data (only provided fields are updated)
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(FatSecretError) on API failure
pub fn edit_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
  update: FoodEntryUpdate,
) -> Result(Nil, FatSecretError) {
  let types.FoodEntryUpdate(number_of_units, meal) = update

  let params =
    dict.new()
    |> dict.insert("food_entry_id", types.food_entry_id_to_string(entry_id))

  // Add optional parameters
  let params = case number_of_units {
    option.Some(n) -> dict.insert(params, "number_of_units", float.to_string(n))
    option.None -> params
  }

  let params = case meal {
    option.Some(m) -> dict.insert(params, "meal", types.meal_type_to_string(m))
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

// ============================================================================
// Food Entry Deletion (3-legged)
// ============================================================================

/// Delete a food entry from the diary (food_entry.delete method)
///
/// Removes a food entry from the user's diary.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - entry_id: ID of the entry to delete
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(FatSecretError) on API failure
pub fn delete_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_entry_id", types.food_entry_id_to_string(entry_id))

  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.delete",
    params,
  ))

  Ok(Nil)
}

// ============================================================================
// Food Entries for Date (3-legged)
// ============================================================================

/// Get all food entries for a specific date (food_entries.get method)
///
/// Retrieves all food entries logged for the specified date.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - date_int: Date as days since Unix epoch
///
/// Returns:
/// - Ok(List(FoodEntry)) with all entries for the date (empty list if none)
/// - Error(FatSecretError) on API failure
pub fn get_food_entries(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(List(FoodEntry), FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entries.get",
    params,
  ))

  // The response can have either a list or a single entry
  json.parse(
    body,
    decode.one_of(
      decode.at(
        ["food_entries", "food_entry"],
        decode.list(decoders.food_entry_decoder()),
      ),
      [
        decode.at(
          ["food_entries", "food_entry"],
          single_entry_to_list_decoder(),
        ),
      ],
    ),
  )
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entries response")
  })
}

// ============================================================================
// Month Summary (3-legged)
// ============================================================================

/// Get nutrition summary for a month (food_entries.get_month method)
///
/// Retrieves aggregated nutrition data for each day in the specified month.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - date_int: Any date within the desired month
///
/// Returns:
/// - Ok(MonthSummary) with daily summaries for the month
/// - Error(FatSecretError) on API failure
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

  json.parse(
    body,
    decode.at(["month"], decoders.month_summary_decoder()),
  )
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse month summary response")
  })
}

// ============================================================================
// Response Parsing Helpers
// ============================================================================

/// Decode single FoodEntry and wrap in list
fn single_entry_to_list_decoder() -> decode.Decoder(List(FoodEntry)) {
  use entry <- decode.then(decoders.food_entry_decoder())
  decode.success([entry])
}
