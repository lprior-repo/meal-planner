/// FatSecret Saved Meals API Client (3-legged OAuth)
///
/// All methods require authenticated user access via AccessToken.
/// API methods:
/// - saved_meal.create - Create new saved meal template
/// - saved_meal.edit - Update saved meal details
/// - saved_meal.delete - Remove saved meal
/// - saved_meals.get.v2 - Get user's saved meals (optionally filtered)
/// - saved_meal_item.add - Add food item to saved meal
/// - saved_meal_item.edit - Update saved meal item
/// - saved_meal_item.delete - Remove item from saved meal
/// - saved_meal_items.get.v2 - Get items in a saved meal
import gleam/dict.{type Dict}
import gleam/float
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client.{
  type AccessToken, type FatSecretError, ApiError, ParseError, RequestFailed,
}
import meal_planner/fatsecret/saved_meals/decoders
import meal_planner/fatsecret/saved_meals/types.{
  type MealType, type SavedMeal, type SavedMealId, type SavedMealItem,
  type SavedMealItemId, type SavedMealItemInput, type SavedMealItemsResponse,
  type SavedMealsResponse,
}

// =============================================================================
// Saved Meal Management
// =============================================================================

/// Create a new saved meal template
/// Returns the newly created saved_meal_id
pub fn create_saved_meal(
  config: FatSecretConfig,
  token: AccessToken,
  name: String,
  description: Option(String),
  meals: List(MealType),
) -> Result(SavedMealId, FatSecretError) {
  let meals_str =
    meals
    |> list.map(types.meal_type_to_string)
    |> list.fold("", fn(acc, m) {
      case acc {
        "" -> m
        _ -> acc <> "," <> m
      }
    })

  let params =
    dict.new()
    |> dict.insert("saved_meal_name", name)
    |> dict.insert("meals", meals_str)
    |> {
      fn(d) {
        case description {
          option.Some(desc) -> dict.insert(d, "saved_meal_description", desc)
          option.None -> d
        }
      }
    }

  use body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal.create",
    params,
  ))

  case json.parse(body, decoders.saved_meal_id_response_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) ->
      Error(ParseError("Failed to parse saved_meal_id from: " <> body))
  }
}

/// Edit an existing saved meal's details
pub fn edit_saved_meal(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_id: SavedMealId,
  name: Option(String),
  description: Option(String),
  meals: Option(List(MealType)),
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_id",
      types.saved_meal_id_to_string(saved_meal_id),
    )
    |> {
      fn(d) {
        case name {
          option.Some(n) -> dict.insert(d, "saved_meal_name", n)
          option.None -> d
        }
      }
    }
    |> {
      fn(d) {
        case description {
          option.Some(desc) -> dict.insert(d, "saved_meal_description", desc)
          option.None -> d
        }
      }
    }
    |> {
      fn(d) {
        case meals {
          option.Some(m_list) -> {
            let meals_str =
              m_list
              |> list.map(types.meal_type_to_string)
              |> list.fold("", fn(acc, m) {
                case acc {
                  "" -> m
                  _ -> acc <> "," <> m
                }
              })
            dict.insert(d, "meals", meals_str)
          }
          option.None -> d
        }
      }
    }

  use _body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal.edit",
    params,
  ))

  Ok(Nil)
}

/// Delete a saved meal
pub fn delete_saved_meal(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_id: SavedMealId,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_id",
      types.saved_meal_id_to_string(saved_meal_id),
    )

  use _body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal.delete",
    params,
  ))

  Ok(Nil)
}

/// Get user's saved meals, optionally filtered by meal type
pub fn get_saved_meals(
  config: FatSecretConfig,
  token: AccessToken,
  meal_filter: Option(MealType),
) -> Result(SavedMealsResponse, FatSecretError) {
  let params = case meal_filter {
    option.Some(meal) ->
      dict.new()
      |> dict.insert("meal", types.meal_type_to_string(meal))
    option.None -> dict.new()
  }

  use body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meals.get.v2",
    params,
  ))

  case json.parse(body, decoders.saved_meals_response_decoder()) {
    Ok(response) -> Ok(response)
    Error(_) -> Error(ParseError("Failed to parse saved meals: " <> body))
  }
}

// =============================================================================
// Saved Meal Items Management
// =============================================================================

/// Add a food item to a saved meal
/// Returns the newly created saved_meal_item_id
pub fn add_saved_meal_item(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_id: SavedMealId,
  item: SavedMealItemInput,
) -> Result(SavedMealItemId, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_id",
      types.saved_meal_id_to_string(saved_meal_id),
    )
    |> add_item_params(item)

  use body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal_item.add",
    params,
  ))

  case json.parse(body, decoders.saved_meal_item_id_response_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) ->
      Error(ParseError("Failed to parse saved_meal_item_id from: " <> body))
  }
}

/// Edit a saved meal item
pub fn edit_saved_meal_item(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_item_id: SavedMealItemId,
  item: SavedMealItemInput,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_item_id",
      types.saved_meal_item_id_to_string(saved_meal_item_id),
    )
    |> add_item_params(item)

  use _body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal_item.edit",
    params,
  ))

  Ok(Nil)
}

/// Delete a saved meal item
pub fn delete_saved_meal_item(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_item_id: SavedMealItemId,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_item_id",
      types.saved_meal_item_id_to_string(saved_meal_item_id),
    )

  use _body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal_item.delete",
    params,
  ))

  Ok(Nil)
}

/// Get items in a saved meal
pub fn get_saved_meal_items(
  config: FatSecretConfig,
  token: AccessToken,
  saved_meal_id: SavedMealId,
) -> Result(SavedMealItemsResponse, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "saved_meal_id",
      types.saved_meal_id_to_string(saved_meal_id),
    )

  use body <- result.try(client.make_authenticated_request(
    config,
    token,
    "saved_meal_items.get.v2",
    params,
  ))

  case json.parse(body, decoders.saved_meal_items_response_decoder()) {
    Ok(response) -> Ok(response)
    Error(_) -> Error(ParseError("Failed to parse saved meal items: " <> body))
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Add item parameters to dict based on input type
fn add_item_params(
  params: Dict(String, String),
  item: SavedMealItemInput,
) -> Dict(String, String) {
  case item {
    types.ByFoodId(food_id, serving_id, number_of_units) ->
      params
      |> dict.insert("food_id", food_id)
      |> dict.insert("serving_id", serving_id)
      |> dict.insert("number_of_units", float.to_string(number_of_units))

    types.ByNutrition(
      food_entry_name,
      serving_description,
      number_of_units,
      calories,
      carbohydrate,
      protein,
      fat,
    ) ->
      params
      |> dict.insert("food_entry_name", food_entry_name)
      |> dict.insert("serving_description", serving_description)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("calories", float.to_string(calories))
      |> dict.insert("carbohydrate", float.to_string(carbohydrate))
      |> dict.insert("protein", float.to_string(protein))
      |> dict.insert("fat", float.to_string(fat))
  }
}
