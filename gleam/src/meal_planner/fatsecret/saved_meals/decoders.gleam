/// FatSecret Saved Meals API - JSON Decoders
///
/// Decoders for parsing FatSecret API responses for saved meals and items.
import gleam/dynamic/decode
import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/saved_meals/types.{
  type MealType, type SavedMeal, type SavedMealItem, type SavedMealItemsResponse,
  type SavedMealsResponse, SavedMeal, SavedMealItem, SavedMealItemsResponse,
  SavedMealsResponse,
}

/// Decode a single meal type string
fn meal_type_decoder() -> decode.Decoder(MealType) {
  use raw <- decode.then(decode.string)
  case types.meal_type_from_string(raw) {
    Ok(meal_type) -> decode.success(meal_type)
    Error(_) -> decode.failure(types.Other, "Invalid meal type: " <> raw)
  }
}

/// Decode a comma-separated list of meal types
/// Example: "breakfast,lunch" -> [Breakfast, Lunch]
fn meal_types_decoder() -> decode.Decoder(List(MealType)) {
  use raw <- decode.then(decode.string)
  let meal_types =
    raw
    |> string.split(",")
    |> list.filter_map(fn(s) {
      let trimmed = string.trim(s)
      types.meal_type_from_string(trimmed)
    })
  decode.success(meal_types)
}

/// Decode float, handling string numbers from API
fn float_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [
    {
      use s <- decode.then(decode.string)
      case float.parse(s) {
        Ok(f) -> decode.success(f)
        Error(_) -> decode.success(0.0)
      }
    },
  ])
}

/// Decode optional string field
fn optional_string_decoder() -> decode.Decoder(Option(String)) {
  decode.optional(decode.string)
}

/// Decode a SavedMeal from JSON
pub fn saved_meal_decoder() -> decode.Decoder(SavedMeal) {
  use saved_meal_id <- decode.field("saved_meal_id", decode.string)
  use saved_meal_name <- decode.field("saved_meal_name", decode.string)
  use saved_meal_description <- decode.field(
    "saved_meal_description",
    optional_string_decoder(),
  )
  use meals <- decode.field("meals", meal_types_decoder())
  use calories <- decode.field("calories", float_decoder())
  use carbohydrate <- decode.field("carbohydrate", float_decoder())
  use protein <- decode.field("protein", float_decoder())
  use fat <- decode.field("fat", float_decoder())

  decode.success(SavedMeal(
    saved_meal_id: types.saved_meal_id_from_string(saved_meal_id),
    saved_meal_name:,
    saved_meal_description:,
    meals:,
    calories:,
    carbohydrate:,
    protein:,
    fat:,
  ))
}

/// Decode a SavedMealItem from JSON
pub fn saved_meal_item_decoder() -> decode.Decoder(SavedMealItem) {
  use saved_meal_item_id <- decode.field("saved_meal_item_id", decode.string)
  use food_id <- decode.field("food_id", decode.string)
  use food_entry_name <- decode.field("food_entry_name", decode.string)
  use serving_id <- decode.field("serving_id", decode.string)
  use number_of_units <- decode.field("number_of_units", float_decoder())
  use calories <- decode.field("calories", float_decoder())
  use carbohydrate <- decode.field("carbohydrate", float_decoder())
  use protein <- decode.field("protein", float_decoder())
  use fat <- decode.field("fat", float_decoder())

  decode.success(SavedMealItem(
    saved_meal_item_id: types.saved_meal_item_id_from_string(saved_meal_item_id),
    food_id:,
    food_entry_name:,
    serving_id:,
    number_of_units:,
    calories:,
    carbohydrate:,
    protein:,
    fat:,
  ))
}

/// Decode saved_meals.get.v2 response
/// Handles both single meal and array of meals
pub fn saved_meals_response_decoder() -> decode.Decoder(SavedMealsResponse) {
  use saved_meals <- decode.field("saved_meals", {
    use saved_meal <- decode.field("saved_meal", {
      decode.one_of(
        // Array of meals
        decode.list(saved_meal_decoder()),
        [
          // Single meal
          {
            use meal <- decode.then(saved_meal_decoder())
            decode.success([meal])
          },
        ],
      )
    })
    decode.success(saved_meal)
  })

  use meal_filter <- decode.optional_field(
    "meal_filter",
    None,
    decode.optional(decode.string),
  )

  decode.success(SavedMealsResponse(saved_meals:, meal_filter:))
}

/// Decode saved_meal_items.get.v2 response
/// Handles both single item and array of items
pub fn saved_meal_items_response_decoder() -> decode.Decoder(
  SavedMealItemsResponse,
) {
  use saved_meal_id <- decode.field("saved_meal_id", decode.string)

  use items <- decode.field("saved_meal_items", {
    use saved_meal_item <- decode.field("saved_meal_item", {
      decode.one_of(
        // Array of items
        decode.list(saved_meal_item_decoder()),
        [
          // Single item
          {
            use item <- decode.then(saved_meal_item_decoder())
            decode.success([item])
          },
          // Empty (no items)
          { decode.success([]) },
        ],
      )
    })
    decode.success(saved_meal_item)
  })

  decode.success(SavedMealItemsResponse(
    saved_meal_id: types.saved_meal_id_from_string(saved_meal_id),
    items:,
  ))
}

/// Decode simple operation success response
/// Example: {"saved_meal_id": "12345"} from saved_meal.create
pub fn saved_meal_id_response_decoder() -> decode.Decoder(types.SavedMealId) {
  use id <- decode.field("saved_meal_id", decode.string)
  decode.success(types.saved_meal_id_from_string(id))
}

/// Decode saved meal item ID from response
/// Example: {"saved_meal_item_id": "67890"} from saved_meal_item.add
pub fn saved_meal_item_id_response_decoder() -> decode.Decoder(
  types.SavedMealItemId,
) {
  use id <- decode.field("saved_meal_item_id", decode.string)
  decode.success(types.saved_meal_item_id_from_string(id))
}
