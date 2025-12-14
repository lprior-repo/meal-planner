/// FatSecret SDK Food Diary API client
///
/// 3-legged authenticated API calls for food diary management.
/// All operations require user OAuth access token.
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
  type FoodEntry, type FoodEntryId, type FoodEntryInput, type FoodEntryUpdate,
  type MonthSummary,
} as diary_types

pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  let params = case input {
    diary_types.FromFood(food_id, serving_id, number_of_units, meal, date_int) -> {
      dict.new()
      |> dict.insert("food_id", food_id)
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

  json.parse(body, decode.at(["food_entry_id"], decode.string))
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
  let params =
    dict.new()
    |> dict.insert("date_int", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entries.get",
    params,
  ))

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
