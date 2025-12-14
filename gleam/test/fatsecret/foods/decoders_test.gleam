/// Tests for FatSecret Foods decoders
///
/// These tests verify proper handling of:
/// 1. Single vs array results (FatSecret quirk)
/// 2. Numeric strings vs actual numbers
/// 3. Missing optional fields
/// 4. Real API response structures
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/foods/decoders
import meal_planner/fatsecret/foods/types

// ============================================================================
// Nutrition Decoder Tests
// ============================================================================

pub fn decode_nutrition_all_fields_test() {
  let json_str =
    "{
      \"calories\": \"95\",
      \"carbohydrate\": \"25.13\",
      \"protein\": \"0.47\",
      \"fat\": \"0.31\",
      \"saturated_fat\": \"0.051\",
      \"polyunsaturated_fat\": \"0.093\",
      \"monounsaturated_fat\": \"0.012\",
      \"cholesterol\": \"0\",
      \"sodium\": \"1\",
      \"potassium\": \"195\",
      \"fiber\": \"4.4\",
      \"sugar\": \"18.91\",
      \"vitamin_a\": \"2\",
      \"vitamin_c\": \"14\",
      \"calcium\": \"1\",
      \"iron\": \"1\"
    }"

  case json.parse(json_str, using: decoders.decode_nutrition) {
    Ok(nutrition) -> {
      nutrition.calories
      |> should.equal(95.0)

      nutrition.carbohydrate
      |> should.equal(25.13)

      nutrition.protein
      |> should.equal(0.47)

      nutrition.fat
      |> should.equal(0.31)

      nutrition.saturated_fat
      |> should.equal(Some(0.051))

      nutrition.fiber
      |> should.equal(Some(4.4))

      nutrition.sugar
      |> should.equal(Some(18.91))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_numeric_types_test() {
  // Test both string and number formats
  let json_str =
    "{
      \"calories\": 150.5,
      \"carbohydrate\": \"20\",
      \"protein\": 5.5,
      \"fat\": \"8.0\"
    }"

  case json.parse(json_str, using: decoders.decode_nutrition) {
    Ok(nutrition) -> {
      nutrition.calories
      |> should.equal(150.5)

      nutrition.carbohydrate
      |> should.equal(20.0)

      nutrition.protein
      |> should.equal(5.5)

      nutrition.fat
      |> should.equal(8.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_missing_optionals_test() {
  let json_str =
    "{
      \"calories\": \"100\",
      \"carbohydrate\": \"15\",
      \"protein\": \"3\",
      \"fat\": \"2\"
    }"

  case json.parse(json_str, using: decoders.decode_nutrition) {
    Ok(nutrition) -> {
      nutrition.calories
      |> should.equal(100.0)

      nutrition.saturated_fat
      |> should.equal(None)

      nutrition.fiber
      |> should.equal(None)

      nutrition.vitamin_a
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Serving Decoder Tests
// ============================================================================

pub fn decode_serving_complete_test() {
  let json_str =
    "{
      \"serving_id\": \"12345\",
      \"serving_description\": \"1 medium (3\\\" dia)\",
      \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\",
      \"metric_serving_amount\": \"182.000\",
      \"metric_serving_unit\": \"g\",
      \"number_of_units\": \"1.000\",
      \"measurement_description\": \"medium (3\\\" dia)\",
      \"calories\": \"95\",
      \"carbohydrate\": \"25.13\",
      \"protein\": \"0.47\",
      \"fat\": \"0.31\",
      \"saturated_fat\": \"0.051\",
      \"polyunsaturated_fat\": \"0.093\",
      \"monounsaturated_fat\": \"0.012\",
      \"cholesterol\": \"0\",
      \"sodium\": \"1\",
      \"potassium\": \"195\",
      \"fiber\": \"4.4\",
      \"sugar\": \"18.91\",
      \"vitamin_a\": \"2\",
      \"vitamin_c\": \"14\",
      \"calcium\": \"1\",
      \"iron\": \"1\"
    }"

  case json.parse(json_str, using: decoders.decode_serving) {
    Ok(serving) -> {
      types.serving_id_to_string(serving.serving_id)
      |> should.equal("12345")

      serving.serving_description
      |> should.equal("1 medium (3\" dia)")

      serving.metric_serving_amount
      |> should.equal(Some(182.0))

      serving.metric_serving_unit
      |> should.equal(Some("g"))

      serving.number_of_units
      |> should.equal(1.0)

      serving.nutrition.calories
      |> should.equal(95.0)

      serving.nutrition.carbohydrate
      |> should.equal(25.13)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_serving_no_metric_test() {
  // Some servings don't have metric info
  let json_str =
    "{
      \"serving_id\": \"67890\",
      \"serving_description\": \"1 cup sliced\",
      \"serving_url\": \"https://example.com\",
      \"number_of_units\": \"1.000\",
      \"measurement_description\": \"cup sliced\",
      \"calories\": \"57\",
      \"carbohydrate\": \"15\",
      \"protein\": \"0.29\",
      \"fat\": \"0.19\"
    }"

  case json.parse(json_str, using: decoders.decode_serving) {
    Ok(serving) -> {
      serving.metric_serving_amount
      |> should.equal(None)

      serving.metric_serving_unit
      |> should.equal(None)

      serving.measurement_description
      |> should.equal("cup sliced")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Food Decoder Tests - Single vs Array
// ============================================================================

pub fn decode_food_single_serving_test() {
  // FatSecret returns object when there's only 1 serving
  let json_str =
    "{
      \"food\": {
        \"food_id\": \"33691\",
        \"food_name\": \"Apple\",
        \"food_type\": \"Generic\",
        \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\",
        \"servings\": {
          \"serving\": {
            \"serving_id\": \"0\",
            \"serving_description\": \"1 medium (3\\\" dia)\",
            \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\",
            \"metric_serving_amount\": \"182.000\",
            \"metric_serving_unit\": \"g\",
            \"number_of_units\": \"1.000\",
            \"measurement_description\": \"medium (3\\\" dia)\",
            \"calories\": \"95\",
            \"carbohydrate\": \"25.13\",
            \"protein\": \"0.47\",
            \"fat\": \"0.31\"
          }
        }
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_response) {
    Ok(food) -> {
      types.food_id_to_string(food.food_id)
      |> should.equal("33691")

      food.food_name
      |> should.equal("Apple")

      food.food_type
      |> should.equal("Generic")

      food.brand_name
      |> should.equal(None)

      // Single serving should be converted to list
      food.servings
      |> should.have_length(1)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_food_multiple_servings_test() {
  // FatSecret returns array when there are multiple servings
  let json_str =
    "{
      \"food\": {
        \"food_id\": \"12345\",
        \"food_name\": \"Milk\",
        \"food_type\": \"Generic\",
        \"food_url\": \"https://example.com/milk\",
        \"servings\": {
          \"serving\": [
            {
              \"serving_id\": \"1\",
              \"serving_description\": \"1 cup\",
              \"serving_url\": \"https://example.com/s1\",
              \"metric_serving_amount\": \"244.000\",
              \"metric_serving_unit\": \"ml\",
              \"number_of_units\": \"1.000\",
              \"measurement_description\": \"cup\",
              \"calories\": \"149\",
              \"carbohydrate\": \"12\",
              \"protein\": \"8\",
              \"fat\": \"8\"
            },
            {
              \"serving_id\": \"2\",
              \"serving_description\": \"100 ml\",
              \"serving_url\": \"https://example.com/s2\",
              \"metric_serving_amount\": \"100.000\",
              \"metric_serving_unit\": \"ml\",
              \"number_of_units\": \"100.000\",
              \"measurement_description\": \"ml\",
              \"calories\": \"61\",
              \"carbohydrate\": \"5\",
              \"protein\": \"3\",
              \"fat\": \"3\"
            }
          ]
        }
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_response) {
    Ok(food) -> {
      food.servings
      |> should.have_length(2)

      // Check first serving
      let assert [first, _second] = food.servings

      types.serving_id_to_string(first.serving_id)
      |> should.equal("1")

      first.serving_description
      |> should.equal("1 cup")
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_food_branded_test() {
  let json_str =
    "{
      \"food\": {
        \"food_id\": \"999\",
        \"food_name\": \"Whole Milk\",
        \"food_type\": \"Brand\",
        \"food_url\": \"https://example.com\",
        \"brand_name\": \"Generic Brand\",
        \"servings\": {
          \"serving\": {
            \"serving_id\": \"1\",
            \"serving_description\": \"1 cup\",
            \"serving_url\": \"https://example.com\",
            \"number_of_units\": \"1\",
            \"measurement_description\": \"cup\",
            \"calories\": \"150\",
            \"carbohydrate\": \"12\",
            \"protein\": \"8\",
            \"fat\": \"8\"
          }
        }
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_response) {
    Ok(food) -> {
      food.brand_name
      |> should.equal(Some("Generic Brand"))

      food.food_type
      |> should.equal("Brand")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Search Results Decoder Tests
// ============================================================================

pub fn decode_search_single_result_test() {
  // FatSecret returns object for single result
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"33691\",
          \"food_name\": \"Apple\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium - Calories: 95kcal | Fat: 0.31g | Carbs: 25.13g | Protein: 0.47g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
        },
        \"max_results\": \"20\",
        \"total_results\": \"1\",
        \"page_number\": \"0\"
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_search_response) {
    Ok(response) -> {
      response.foods
      |> should.have_length(1)

      response.max_results
      |> should.equal(20)

      response.total_results
      |> should.equal(1)

      response.page_number
      |> should.equal(0)

      let assert [food] = response.foods

      types.food_id_to_string(food.food_id)
      |> should.equal("33691")

      food.food_name
      |> should.equal("Apple")

      food.brand_name
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_search_multiple_results_test() {
  // FatSecret returns array for multiple results
  let json_str =
    "{
      \"foods\": {
        \"food\": [
          {
            \"food_id\": \"33691\",
            \"food_name\": \"Apple\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 medium - Calories: 95kcal | Fat: 0.31g | Carbs: 25.13g | Protein: 0.47g\",
            \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
          },
          {
            \"food_id\": \"12345\",
            \"food_name\": \"Apple Juice\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 cup - Calories: 114kcal | Fat: 0.28g | Carbs: 28.11g | Protein: 0.15g\",
            \"food_url\": \"https://example.com/juice\"
          }
        ],
        \"max_results\": \"20\",
        \"total_results\": \"2\",
        \"page_number\": \"0\"
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_search_response) {
    Ok(response) -> {
      response.foods
      |> should.have_length(2)

      let assert [apple, juice] = response.foods

      apple.food_name
      |> should.equal("Apple")

      juice.food_name
      |> should.equal("Apple Juice")
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_search_branded_result_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"555\",
          \"food_name\": \"Whole Milk\",
          \"brand_name\": \"Organic Valley\",
          \"food_type\": \"Brand\",
          \"food_description\": \"Per 1 cup - Calories: 150kcal | Fat: 8g | Carbs: 12g | Protein: 8g\",
          \"food_url\": \"https://example.com\"
        },
        \"max_results\": \"20\",
        \"total_results\": \"1\",
        \"page_number\": \"0\"
      }
    }"

  case json.parse(json_str, using: decoders.decode_food_search_response) {
    Ok(response) -> {
      let assert [result] = response.foods

      result.brand_name
      |> should.equal(Some("Organic Valley"))

      result.food_type
      |> should.equal("Brand")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Edge Cases
// ============================================================================

pub fn decode_numeric_string_edge_cases_test() {
  // Test various numeric string formats
  let json_str =
    "{
      \"calories\": \"0\",
      \"carbohydrate\": \"0.0\",
      \"protein\": \"0.00\",
      \"fat\": \"1.234567\"
    }"

  case json.parse(json_str, using: decoders.decode_nutrition) {
    Ok(nutrition) -> {
      nutrition.calories
      |> should.equal(0.0)

      nutrition.carbohydrate
      |> should.equal(0.0)

      nutrition.fat
      |> should.equal(1.234567)
    }
    Error(_) -> should.fail()
  }
}
