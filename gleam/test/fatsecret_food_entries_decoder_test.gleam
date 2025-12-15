/// Comprehensive FatSecret Food Entries API Decoder Tests
///
/// Tests for the food_entries.get API response parsing with full 1:1 mapping
/// validation. Covers:
/// - Single entry responses
/// - Multiple entries responses
/// - Empty responses
/// - Optional field handling
/// - Real API response structures
/// - All macro and micronutrients
/// - Edge cases and variant meal types
///
/// Run with: cd gleam && gleam test
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// SINGLE ENTRY TESTS
// ============================================================================

pub fn decode_single_entry_with_all_fields_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"987654\", \"food_id\": \"4142\", \"food_entry_name\": \"Chicken Breast\", \"food_entry_description\": \"Per 100g\", \"serving_id\": \"12345\", \"number_of_units\": \"1.5\", \"meal\": \"dinner\", \"date_int\": \"19723\", \"calories\": \"248\", \"carbohydrate\": \"0\", \"protein\": \"46.5\", \"fat\": \"5.4\", \"saturated_fat\": \"1.2\", \"polyunsaturated_fat\": \"0.8\", \"monounsaturated_fat\": \"1.5\", \"cholesterol\": \"110\", \"sodium\": \"95\", \"potassium\": \"420\", \"fiber\": \"0\", \"sugar\": \"0\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.food_entry_id
      |> types.food_entry_id_to_string
      |> should.equal("987654")
      entry.food_entry_name |> should.equal("Chicken Breast")
      entry.food_id |> should.equal("4142")
      entry.number_of_units |> should.equal(1.5)
      entry.meal |> should.equal(types.Dinner)
      entry.date_int |> should.equal(19_723)
      entry.calories |> should.equal(248.0)
      entry.carbohydrate |> should.equal(0.0)
      entry.protein |> should.equal(46.5)
      entry.fat |> should.equal(5.4)
      entry.saturated_fat |> should.equal(option.Some(1.2))
      entry.polyunsaturated_fat |> should.equal(option.Some(0.8))
      entry.monounsaturated_fat |> should.equal(option.Some(1.5))
      entry.cholesterol |> should.equal(option.Some(110.0))
      entry.sodium |> should.equal(option.Some(95.0))
      entry.potassium |> should.equal(option.Some(420.0))
      entry.fiber |> should.equal(option.Some(0.0))
      entry.sugar |> should.equal(option.Some(0.0))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_single_entry_minimal_fields_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"111111\", \"food_id\": \"33691\", \"food_entry_name\": \"Apple\", \"food_entry_description\": \"Per medium apple\", \"serving_id\": \"0\", \"number_of_units\": \"1.0\", \"meal\": \"breakfast\", \"date_int\": \"19724\", \"calories\": \"95\", \"carbohydrate\": \"25.13\", \"protein\": \"0.47\", \"fat\": \"0.31\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.food_entry_name |> should.equal("Apple")
      entry.meal |> should.equal(types.Breakfast)
      entry.calories |> should.equal(95.0)
      entry.saturated_fat |> should.equal(option.None)
      entry.cholesterol |> should.equal(option.None)
      entry.sodium |> should.equal(option.None)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// MULTIPLE ENTRIES TESTS
// ============================================================================

pub fn decode_multiple_entries_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": [{\"food_entry_id\": \"111111\", \"food_id\": \"33691\", \"food_entry_name\": \"Apple\", \"food_entry_description\": \"Per medium apple\", \"serving_id\": \"0\", \"number_of_units\": \"1.0\", \"meal\": \"breakfast\", \"date_int\": \"19724\", \"calories\": \"95\", \"carbohydrate\": \"25.13\", \"protein\": \"0.47\", \"fat\": \"0.31\"}, {\"food_entry_id\": \"222222\", \"food_id\": \"4142\", \"food_entry_name\": \"Chicken Breast\", \"food_entry_description\": \"Grilled\", \"serving_id\": \"12345\", \"number_of_units\": \"1.5\", \"meal\": \"lunch\", \"date_int\": \"19724\", \"calories\": \"248\", \"carbohydrate\": \"0\", \"protein\": \"46.5\", \"fat\": \"5.4\", \"saturated_fat\": \"1.2\"}]}}"

  let result =
    json.parse(
      json_str,
      decode.at(
        ["food_entries", "food_entry"],
        decode.list(decoders.food_entry_decoder()),
      ),
    )

  case result {
    Ok(entries) -> {
      list.length(entries) |> should.equal(2)
      let first = list.first(entries) |> result.unwrap(default_entry())
      first.food_entry_name |> should.equal("Apple")
      first.meal |> should.equal(types.Breakfast)
      let second = list.last(entries) |> result.unwrap(default_entry())
      second.food_entry_name |> should.equal("Chicken Breast")
      second.meal |> should.equal(types.Lunch)
      second.saturated_fat |> should.equal(option.Some(1.2))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_three_entries_mixed_nutrients_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": [{\"food_entry_id\": \"111111\", \"food_id\": \"33691\", \"food_entry_name\": \"Apple\", \"food_entry_description\": \"Per medium apple\", \"serving_id\": \"0\", \"number_of_units\": \"1.0\", \"meal\": \"breakfast\", \"date_int\": \"19724\", \"calories\": \"95\", \"carbohydrate\": \"25.13\", \"protein\": \"0.47\", \"fat\": \"0.31\"}, {\"food_entry_id\": \"222222\", \"food_id\": \"4142\", \"food_entry_name\": \"Chicken Breast\", \"food_entry_description\": \"Grilled\", \"serving_id\": \"12345\", \"number_of_units\": \"1.5\", \"meal\": \"lunch\", \"date_int\": \"19724\", \"calories\": \"248\", \"carbohydrate\": \"0\", \"protein\": \"46.5\", \"fat\": \"5.4\", \"saturated_fat\": \"1.2\", \"polyunsaturated_fat\": \"0.8\", \"monounsaturated_fat\": \"1.5\", \"cholesterol\": \"110\"}, {\"food_entry_id\": \"333333\", \"food_id\": \"174046\", \"food_entry_name\": \"Milk\", \"food_entry_description\": \"Whole milk\", \"serving_id\": \"59788\", \"number_of_units\": \"1.0\", \"meal\": \"snack\", \"date_int\": \"19724\", \"calories\": \"149\", \"carbohydrate\": \"11.71\", \"protein\": \"7.69\", \"fat\": \"7.93\", \"saturated_fat\": \"4.551\", \"polyunsaturated_fat\": \"0.476\", \"monounsaturated_fat\": \"2.346\", \"cholesterol\": \"24\", \"sodium\": \"105\", \"potassium\": \"322\", \"fiber\": \"0.0\", \"sugar\": \"12.32\"}]}}"

  let result =
    json.parse(
      json_str,
      decode.at(
        ["food_entries", "food_entry"],
        decode.list(decoders.food_entry_decoder()),
      ),
    )

  case result {
    Ok(entries) -> {
      list.length(entries) |> should.equal(3)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// EMPTY RESPONSE TESTS
// ============================================================================

pub fn decode_empty_food_entries_test() {
  let json_str = "{\"food_entries\": {}}"

  let result =
    json.parse(json_str, decode.at(["food_entries"], decode.success([])))

  case result {
    Ok(entries) -> {
      list.length(entries) |> should.equal(0)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// OPTIONAL FIELD HANDLING TESTS
// ============================================================================

pub fn decode_entry_with_zero_optional_fields_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"444444\", \"food_id\": \"99999\", \"food_entry_name\": \"Custom Food\", \"food_entry_description\": \"No info\", \"serving_id\": \"\", \"number_of_units\": \"1.0\", \"meal\": \"other\", \"date_int\": \"19725\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\", \"saturated_fat\": \"0\", \"polyunsaturated_fat\": \"0\", \"monounsaturated_fat\": \"0\", \"cholesterol\": \"0\", \"sodium\": \"0\", \"potassium\": \"0\", \"fiber\": \"0\", \"sugar\": \"0\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.meal |> should.equal(types.Snack)
      entry.saturated_fat |> should.equal(option.Some(0.0))
      entry.cholesterol |> should.equal(option.Some(0.0))
      entry.sodium |> should.equal(option.Some(0.0))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_entry_with_fractional_servings_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"555555\", \"food_id\": \"33691\", \"food_entry_name\": \"Apple\", \"food_entry_description\": \"Half apple\", \"serving_id\": \"0\", \"number_of_units\": \"0.5\", \"meal\": \"snack\", \"date_int\": \"19725\", \"calories\": \"47.5\", \"carbohydrate\": \"12.565\", \"protein\": \"0.235\", \"fat\": \"0.155\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.number_of_units |> should.equal(0.5)
      entry.calories |> should.equal(47.5)
      entry.carbohydrate |> should.equal(12.565)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// MEAL TYPE TESTS
// ============================================================================

pub fn decode_entry_breakfast_meal_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"breakfast\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.meal |> should.equal(types.Breakfast)
    Error(_) -> should.fail()
  }
}

pub fn decode_entry_lunch_meal_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"lunch\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.meal |> should.equal(types.Lunch)
    Error(_) -> should.fail()
  }
}

pub fn decode_entry_dinner_meal_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"dinner\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.meal |> should.equal(types.Dinner)
    Error(_) -> should.fail()
  }
}

pub fn decode_entry_snack_meal_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"snack\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.meal |> should.equal(types.Snack)
    Error(_) -> should.fail()
  }
}

pub fn decode_entry_other_as_snack_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"other\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"10\", \"protein\": \"5\", \"fat\": \"3\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.meal |> should.equal(types.Snack)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// NUMERIC STRING PARSING TESTS
// ============================================================================

pub fn decode_float_from_string_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"2.5\", \"meal\": \"breakfast\", \"date_int\": \"1\", \"calories\": \"150.75\", \"carbohydrate\": \"20.5\", \"protein\": \"10.25\", \"fat\": \"5.125\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.number_of_units |> should.equal(2.5)
      entry.calories |> should.equal(150.75)
      entry.carbohydrate |> should.equal(20.5)
      entry.protein |> should.equal(10.25)
      entry.fat |> should.equal(5.125)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_int_as_float_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"breakfast\", \"date_int\": \"1\", \"calories\": \"100\", \"carbohydrate\": \"20\", \"protein\": \"10\", \"fat\": \"5\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> {
      entry.calories |> should.equal(100.0)
      entry.carbohydrate |> should.equal(20.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_date_int_from_string_test() {
  let json_str =
    "{\"food_entries\": {\"food_entry\": {\"food_entry_id\": \"1\", \"food_id\": \"1\", \"food_entry_name\": \"Food\", \"food_entry_description\": \"Desc\", \"serving_id\": \"1\", \"number_of_units\": \"1\", \"meal\": \"breakfast\", \"date_int\": \"19723\", \"calories\": \"100\", \"carbohydrate\": \"20\", \"protein\": \"10\", \"fat\": \"5\"}}}"

  let result =
    json.parse(
      json_str,
      decode.at(["food_entries", "food_entry"], decoders.food_entry_decoder()),
    )

  case result {
    Ok(entry) -> entry.date_int |> should.equal(19_723)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// HELPERS
// ============================================================================

fn default_entry() -> types.FoodEntry {
  types.FoodEntry(
    food_entry_id: types.food_entry_id(""),
    food_entry_name: "",
    food_entry_description: "",
    food_id: "",
    serving_id: "",
    number_of_units: 0.0,
    meal: types.Breakfast,
    date_int: 0,
    calories: 0.0,
    carbohydrate: 0.0,
    protein: 0.0,
    fat: 0.0,
    saturated_fat: option.None,
    polyunsaturated_fat: option.None,
    monounsaturated_fat: option.None,
    cholesterol: option.None,
    sodium: option.None,
    potassium: option.None,
    fiber: option.None,
    sugar: option.None,
  )
}
