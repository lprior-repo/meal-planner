/// FatSecret Saved Meals Tests
///
/// Unit tests for saved meals domain - types, decoders, and business logic.
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/saved_meals/decoders
import meal_planner/fatsecret/saved_meals/types.{
  type SavedMeal, type SavedMealItem, type SavedMealItemsResponse,
  type SavedMealsResponse, Breakfast, ByFoodId, ByNutrition, Dinner, Lunch,
  Other, SavedMeal, SavedMealItem, SavedMealItemsResponse, SavedMealsResponse,
}

// =============================================================================
// Type Tests
// =============================================================================

pub fn meal_type_to_string_test() {
  types.meal_type_to_string(Breakfast)
  |> should.equal("breakfast")

  types.meal_type_to_string(Lunch)
  |> should.equal("lunch")

  types.meal_type_to_string(Dinner)
  |> should.equal("dinner")

  types.meal_type_to_string(Other)
  |> should.equal("other")
}

pub fn meal_type_from_string_test() {
  types.meal_type_from_string("breakfast")
  |> should.equal(Ok(Breakfast))

  types.meal_type_from_string("lunch")
  |> should.equal(Ok(Lunch))

  types.meal_type_from_string("dinner")
  |> should.equal(Ok(Dinner))

  types.meal_type_from_string("other")
  |> should.equal(Ok(Other))

  types.meal_type_from_string("invalid")
  |> should.equal(Error(Nil))
}

pub fn saved_meal_id_roundtrip_test() {
  let id = types.saved_meal_id_from_string("12345")
  types.saved_meal_id_to_string(id)
  |> should.equal("12345")
}

pub fn saved_meal_item_id_roundtrip_test() {
  let id = types.saved_meal_item_id_from_string("67890")
  types.saved_meal_item_id_to_string(id)
  |> should.equal("67890")
}

// =============================================================================
// Decoder Tests
// =============================================================================

pub fn decode_saved_meal_test() {
  let json_str =
    "{
      \"saved_meal_id\": \"123\",
      \"saved_meal_name\": \"Protein Breakfast\",
      \"saved_meal_description\": \"High protein morning meal\",
      \"meals\": \"breakfast,lunch\",
      \"calories\": \"450.5\",
      \"carbohydrate\": \"30.2\",
      \"protein\": \"35.8\",
      \"fat\": \"15.3\"
    }"

  let result =
    json.parse(json_str, decoders.saved_meal_decoder())
    |> should.be_ok

  result.saved_meal_name
  |> should.equal("Protein Breakfast")

  result.saved_meal_description
  |> should.equal(Some("High protein morning meal"))

  result.meals
  |> should.equal([Breakfast, Lunch])

  result.calories
  |> should.equal(450.5)

  result.protein
  |> should.equal(35.8)
}

pub fn decode_saved_meal_no_description_test() {
  let json_str =
    "{
      \"saved_meal_id\": \"456\",
      \"saved_meal_name\": \"Quick Lunch\",
      \"meals\": \"lunch\",
      \"calories\": \"300\",
      \"carbohydrate\": \"40\",
      \"protein\": \"20\",
      \"fat\": \"10\"
    }"

  let result =
    json.parse(json_str, decoders.saved_meal_decoder())
    |> should.be_ok

  result.saved_meal_description
  |> should.equal(None)

  result.meals
  |> should.equal([Lunch])
}

pub fn decode_saved_meal_item_test() {
  let json_str =
    "{
      \"saved_meal_item_id\": \"789\",
      \"food_id\": \"12345\",
      \"food_entry_name\": \"Chicken Breast\",
      \"serving_id\": \"67890\",
      \"number_of_units\": \"2.5\",
      \"calories\": \"275\",
      \"carbohydrate\": \"0\",
      \"protein\": \"60\",
      \"fat\": \"5\"
    }"

  let result =
    json.parse(json_str, decoders.saved_meal_item_decoder())
    |> should.be_ok

  result.food_entry_name
  |> should.equal("Chicken Breast")

  result.number_of_units
  |> should.equal(2.5)

  result.calories
  |> should.equal(275.0)

  result.protein
  |> should.equal(60.0)
}

pub fn decode_saved_meals_response_multiple_test() {
  let json_str =
    "{
      \"saved_meals\": {
        \"saved_meal\": [
          {
            \"saved_meal_id\": \"1\",
            \"saved_meal_name\": \"Meal A\",
            \"meals\": \"breakfast\",
            \"calories\": \"300\",
            \"carbohydrate\": \"40\",
            \"protein\": \"20\",
            \"fat\": \"10\"
          },
          {
            \"saved_meal_id\": \"2\",
            \"saved_meal_name\": \"Meal B\",
            \"meals\": \"lunch,dinner\",
            \"calories\": \"500\",
            \"carbohydrate\": \"60\",
            \"protein\": \"30\",
            \"fat\": \"15\"
          }
        ]
      },
      \"meal_filter\": \"breakfast\"
    }"

  let result =
    json.parse(json_str, decoders.saved_meals_response_decoder())
    |> should.be_ok

  result.saved_meals
  |> should.have_length(2)

  result.meal_filter
  |> should.equal(Some("breakfast"))

  let first = result.saved_meals |> list.first |> should.be_ok
  first.saved_meal_name
  |> should.equal("Meal A")
}

pub fn decode_saved_meals_response_single_test() {
  let json_str =
    "{
      \"saved_meals\": {
        \"saved_meal\": {
          \"saved_meal_id\": \"1\",
          \"saved_meal_name\": \"Solo Meal\",
          \"meals\": \"dinner\",
          \"calories\": \"600\",
          \"carbohydrate\": \"50\",
          \"protein\": \"40\",
          \"fat\": \"20\"
        }
      }
    }"

  let result =
    json.parse(json_str, decoders.saved_meals_response_decoder())
    |> should.be_ok

  result.saved_meals
  |> should.have_length(1)

  result.meal_filter
  |> should.equal(None)
}

pub fn decode_saved_meal_items_response_test() {
  let json_str =
    "{
      \"saved_meal_id\": \"123\",
      \"saved_meal_items\": {
        \"saved_meal_item\": [
          {
            \"saved_meal_item_id\": \"1\",
            \"food_id\": \"100\",
            \"food_entry_name\": \"Oatmeal\",
            \"serving_id\": \"200\",
            \"number_of_units\": \"1\",
            \"calories\": \"150\",
            \"carbohydrate\": \"27\",
            \"protein\": \"5\",
            \"fat\": \"3\"
          },
          {
            \"saved_meal_item_id\": \"2\",
            \"food_id\": \"101\",
            \"food_entry_name\": \"Banana\",
            \"serving_id\": \"201\",
            \"number_of_units\": \"1.5\",
            \"calories\": \"135\",
            \"carbohydrate\": \"35\",
            \"protein\": \"2\",
            \"fat\": \"0.5\"
          }
        ]
      }
    }"

  let result =
    json.parse(json_str, decoders.saved_meal_items_response_decoder())
    |> should.be_ok

  result.items
  |> should.have_length(2)

  let first = result.items |> list.first |> should.be_ok
  first.food_entry_name
  |> should.equal("Oatmeal")
}

pub fn decode_saved_meal_items_response_empty_test() {
  let json_str =
    "{
      \"saved_meal_id\": \"123\",
      \"saved_meal_items\": {
        \"saved_meal_item\": []
      }
    }"

  let result =
    json.parse(json_str, decoders.saved_meal_items_response_decoder())
    |> should.be_ok

  result.items
  |> should.have_length(0)
}

pub fn decode_saved_meal_id_response_test() {
  let json_str = "{\"saved_meal_id\": \"99999\"}"

  let result =
    json.parse(json_str, decoders.saved_meal_id_response_decoder())
    |> should.be_ok

  types.saved_meal_id_to_string(result)
  |> should.equal("99999")
}

pub fn decode_saved_meal_item_id_response_test() {
  let json_str = "{\"saved_meal_item_id\": \"88888\"}"

  let result =
    json.parse(json_str, decoders.saved_meal_item_id_response_decoder())
    |> should.be_ok

  types.saved_meal_item_id_to_string(result)
  |> should.equal("88888")
}

// =============================================================================
// SavedMealItemInput Tests
// =============================================================================

pub fn saved_meal_item_input_by_food_id_test() {
  let input = ByFoodId(food_id: "123", serving_id: "456", number_of_units: 2.0)

  case input {
    ByFoodId(food_id: id, serving_id: sid, number_of_units: units) -> {
      id
      |> should.equal("123")
      sid
      |> should.equal("456")
      units
      |> should.equal(2.0)
    }
    _ -> panic as "Expected ByFoodId"
  }
}

pub fn saved_meal_item_input_by_nutrition_test() {
  let input =
    ByNutrition(
      food_entry_name: "Custom Food",
      serving_description: "1 cup",
      number_of_units: 1.0,
      calories: 200.0,
      carbohydrate: 30.0,
      protein: 10.0,
      fat: 5.0,
    )

  case input {
    ByNutrition(
      food_entry_name: name,
      serving_description: serving,
      number_of_units: units,
      calories: cal,
      carbohydrate: carbs,
      protein: prot,
      fat: fat_val,
    ) -> {
      name
      |> should.equal("Custom Food")
      serving
      |> should.equal("1 cup")
      units
      |> should.equal(1.0)
      cal
      |> should.equal(200.0)
      carbs
      |> should.equal(30.0)
      prot
      |> should.equal(10.0)
      fat_val
      |> should.equal(5.0)
    }
    _ -> panic as "Expected ByNutrition"
  }
}
