/// Tests for FatSecret diary decoders
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// MealType Decoder Tests
// ============================================================================

pub fn meal_type_decoder_breakfast_test() {
  let json_str = "\"breakfast\""
  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  decoders.meal_type_decoder()
  |> decode.run(parsed, _)
  |> should.equal(Ok(types.Breakfast))
}

pub fn meal_type_decoder_lunch_test() {
  let json_str = "\"lunch\""
  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  decoders.meal_type_decoder()
  |> decode.run(parsed, _)
  |> should.equal(Ok(types.Lunch))
}

pub fn meal_type_decoder_dinner_test() {
  let json_str = "\"dinner\""
  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  decoders.meal_type_decoder()
  |> decode.run(parsed, _)
  |> should.equal(Ok(types.Dinner))
}

pub fn meal_type_decoder_snack_test() {
  let json_str = "\"other\""
  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  decoders.meal_type_decoder()
  |> decode.run(parsed, _)
  |> should.equal(Ok(types.Snack))
}

// ============================================================================
// DaySummary Decoder Tests
// ============================================================================

pub fn day_summary_decoder_test() {
  let json_str =
    "{
      \"date_int\": \"19723\",
      \"calories\": \"2100.5\",
      \"carbohydrate\": \"200.0\",
      \"protein\": \"150.5\",
      \"fat\": \"70.25\"
    }"

  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  case decoders.day_summary_decoder() |> decode.run(parsed, _) {
    Ok(summary) -> {
      summary.date_int |> should.equal(19_723)
      summary.calories |> should.equal(2100.5)
      summary.carbohydrate |> should.equal(200.0)
      summary.protein |> should.equal(150.5)
      summary.fat |> should.equal(70.25)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// FoodEntry Decoder Tests (Minimal)
// ============================================================================

pub fn food_entry_decoder_minimal_test() {
  // Test with minimal required fields
  let json_str =
    "{
      \"food_entry_id\": \"123456\",
      \"food_entry_name\": \"Chicken Breast\",
      \"food_entry_description\": \"Per 100g\",
      \"food_id\": \"4142\",
      \"serving_id\": \"12345\",
      \"number_of_units\": \"1.5\",
      \"meal\": \"dinner\",
      \"date_int\": \"19723\",
      \"calories\": \"248.0\",
      \"carbohydrate\": \"0.0\",
      \"protein\": \"46.5\",
      \"fat\": \"5.4\"
    }"

  let assert Ok(parsed) = json.parse(json_str, dynamic.dynamic)

  case decoders.food_entry_decoder() |> decode.run(parsed, _) {
    Ok(entry) -> {
      types.food_entry_id_to_string(entry.food_entry_id)
      |> should.equal("123456")
      entry.food_entry_name |> should.equal("Chicken Breast")
      entry.number_of_units |> should.equal(1.5)
      entry.meal |> should.equal(types.Dinner)
      entry.date_int |> should.equal(19_723)
      entry.calories |> should.equal(248.0)
      entry.protein |> should.equal(46.5)
    }
    Error(_) -> should.fail()
  }
}
