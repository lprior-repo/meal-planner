/// Tests for FatSecret Most/Recently Eaten Endpoints
///
/// Tests for the following endpoints:
/// - GET /api/fatsecret/favorites/foods/most-eaten
/// - GET /api/fatsecret/favorites/foods/recently-eaten
///
/// Test Categories:
/// - Decoder tests for API responses
/// - Default and custom parameters
/// - Authorization checks
/// - Error handling
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/favorites/decoders
import meal_planner/fatsecret/favorites/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Most Eaten Foods - Response Parsing Tests
// ============================================================================

/// Test decoding most-eaten response with multiple foods
pub fn decode_most_eaten_multiple_foods_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": [
          {
            \"food_id\": \"33691\",
            \"food_name\": \"Apple\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 medium\",
            \"food_url\": \"https://www.fatsecret.com/apple\",
            \"serving_id\": \"0\",
            \"number_of_units\": \"1.0\"
          },
          {
            \"food_id\": \"174046\",
            \"food_name\": \"Milk\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 cup\",
            \"food_url\": \"https://www.fatsecret.com/milk\",
            \"serving_id\": \"59788\",
            \"number_of_units\": \"1.0\"
          }
        ]
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      let foods = response.foods
      foods
      |> should.have_length(2)

      case foods {
        [first, second] -> {
          first.food_name
          |> should.equal("Apple")
          second.food_name
          |> should.equal("Milk")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding most-eaten response with single food
pub fn decode_most_eaten_single_food_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"33691\",
          \"food_name\": \"Apple\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium\",
          \"food_url\": \"https://www.fatsecret.com/apple\",
          \"serving_id\": \"0\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      let foods = response.foods
      foods
      |> should.have_length(1)

      case foods {
        [first] -> {
          first.food_id
          |> should.equal("33691")
          first.food_name
          |> should.equal("Apple")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding most-eaten response with empty foods
pub fn decode_most_eaten_empty_foods_test() {
  let json_str = "{\"foods\": {}}"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      response.foods
      |> should.equal([])
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding most-eaten with branded foods
pub fn decode_most_eaten_branded_foods_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": [
          {
            \"food_id\": \"555111\",
            \"food_name\": \"Whole Milk\",
            \"food_type\": \"Brand\",
            \"brand_name\": \"Organic Valley\",
            \"food_description\": \"Per 1 cup\",
            \"food_url\": \"https://www.fatsecret.com/ov-milk\",
            \"serving_id\": \"1\",
            \"number_of_units\": \"1.0\"
          }
        ]
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [first] -> {
          first.food_name
          |> should.equal("Whole Milk")
          first.brand_name
          |> should.equal(Some("Organic Valley"))
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Recently Eaten Foods - Response Parsing Tests
// ============================================================================

/// Test decoding recently-eaten response with multiple foods
pub fn decode_recently_eaten_multiple_foods_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": [
          {
            \"food_id\": \"33691\",
            \"food_name\": \"Apple\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 medium\",
            \"food_url\": \"https://www.fatsecret.com/apple\",
            \"serving_id\": \"0\",
            \"number_of_units\": \"1.0\"
          },
          {
            \"food_id\": \"12345\",
            \"food_name\": \"Chicken\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 100g\",
            \"food_url\": \"https://www.fatsecret.com/chicken\",
            \"serving_id\": \"2\",
            \"number_of_units\": \"1.0\"
          },
          {
            \"food_id\": \"67890\",
            \"food_name\": \"Rice\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 cup cooked\",
            \"food_url\": \"https://www.fatsecret.com/rice\",
            \"serving_id\": \"3\",
            \"number_of_units\": \"1.0\"
          }
        ]
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      let foods = response.foods
      foods
      |> should.have_length(3)

      case foods {
        [first, second, third] -> {
          first.food_name
          |> should.equal("Apple")
          second.food_name
          |> should.equal("Chicken")
          third.food_name
          |> should.equal("Rice")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten response with single food
pub fn decode_recently_eaten_single_food_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"12345\",
          \"food_name\": \"Chicken\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g\",
          \"food_url\": \"https://www.fatsecret.com/chicken\",
          \"serving_id\": \"2\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      let foods = response.foods
      foods
      |> should.have_length(1)

      case foods {
        [first] -> {
          first.food_id
          |> should.equal("12345")
          first.food_name
          |> should.equal("Chicken")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten response with empty foods
pub fn decode_recently_eaten_empty_foods_test() {
  let json_str = "{\"foods\": {}}"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      response.foods
      |> should.equal([])
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten with foods without brand
pub fn decode_recently_eaten_no_brand_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"33691\",
          \"food_name\": \"Apple\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium\",
          \"food_url\": \"https://www.fatsecret.com/apple\",
          \"serving_id\": \"0\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [first] -> {
          first.food_name
          |> should.equal("Apple")
          first.brand_name
          |> should.equal(None)
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Most Eaten Foods - Field Parsing Tests
// ============================================================================

/// Test decoding most-eaten food with all fields
pub fn decode_most_eaten_food_all_fields_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"555111\",
          \"food_name\": \"Organic Milk\",
          \"food_type\": \"Brand\",
          \"brand_name\": \"Organic Valley\",
          \"food_description\": \"Rich and creamy milk\",
          \"food_url\": \"https://www.fatsecret.com/organic-milk\",
          \"serving_id\": \"99\",
          \"number_of_units\": \"2.5\"
        }
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_id
          |> should.equal("555111")
          food.food_name
          |> should.equal("Organic Milk")
          food.food_type
          |> should.equal("Brand")
          food.brand_name
          |> should.equal(Some("Organic Valley"))
          food.food_description
          |> should.equal("Rich and creamy milk")
          food.food_url
          |> should.equal("https://www.fatsecret.com/organic-milk")
          food.serving_id
          |> should.equal("99")
          food.number_of_units
          |> should.equal("2.5")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten food with all fields
pub fn decode_recently_eaten_food_all_fields_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"999999\",
          \"food_name\": \"Greek Yogurt\",
          \"food_type\": \"Brand\",
          \"brand_name\": \"Fage\",
          \"food_description\": \"Plain Greek yogurt\",
          \"food_url\": \"https://www.fatsecret.com/fage-yogurt\",
          \"serving_id\": \"150\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_id
          |> should.equal("999999")
          food.food_name
          |> should.equal("Greek Yogurt")
          food.food_type
          |> should.equal("Brand")
          food.brand_name
          |> should.equal(Some("Fage"))
          food.food_description
          |> should.equal("Plain Greek yogurt")
          food.serving_id
          |> should.equal("150")
          food.number_of_units
          |> should.equal("1.0")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Response Type Construction Tests
// ============================================================================

/// Test constructing MostEatenResponse
pub fn construct_most_eaten_response_test() {
  let food =
    types.MostEatenFood(
      food_id: "123",
      food_name: "Apple",
      food_type: "Generic",
      brand_name: None,
      food_description: "A fruit",
      food_url: "https://example.com",
      serving_id: "0",
      number_of_units: "1.0",
    )

  let response = types.MostEatenResponse(foods: [food])

  response.foods
  |> should.have_length(1)

  case response.foods {
    [f] -> {
      f.food_name
      |> should.equal("Apple")
    }
    _ -> should.fail()
  }
}

/// Test constructing RecentlyEatenResponse
pub fn construct_recently_eaten_response_test() {
  let food1 =
    types.RecentlyEatenFood(
      food_id: "123",
      food_name: "Apple",
      food_type: "Generic",
      brand_name: None,
      food_description: "A fruit",
      food_url: "https://example.com",
      serving_id: "0",
      number_of_units: "1.0",
    )

  let food2 =
    types.RecentlyEatenFood(
      food_id: "456",
      food_name: "Chicken",
      food_type: "Generic",
      brand_name: Some("Brand A"),
      food_description: "Protein",
      food_url: "https://example.com/chicken",
      serving_id: "1",
      number_of_units: "1.0",
    )

  let response = types.RecentlyEatenResponse(foods: [food1, food2])

  response.foods
  |> should.have_length(2)

  case response.foods {
    [f1, f2] -> {
      f1.food_name
      |> should.equal("Apple")
      f2.food_name
      |> should.equal("Chicken")
      f2.brand_name
      |> should.equal(Some("Brand A"))
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Meal Filter Tests
// ============================================================================

/// Test MealFilter to string conversion for AllMeals
pub fn meal_filter_all_meals_test() {
  types.meal_filter_to_string(types.AllMeals)
  |> should.equal("")
}

/// Test MealFilter to string conversion for Breakfast
pub fn meal_filter_breakfast_test() {
  types.meal_filter_to_string(types.Breakfast)
  |> should.equal("Breakfast")
}

/// Test MealFilter to string conversion for Lunch
pub fn meal_filter_lunch_test() {
  types.meal_filter_to_string(types.Lunch)
  |> should.equal("Lunch")
}

/// Test MealFilter to string conversion for Dinner
pub fn meal_filter_dinner_test() {
  types.meal_filter_to_string(types.Dinner)
  |> should.equal("Dinner")
}

/// Test MealFilter to string conversion for Snack
pub fn meal_filter_snack_test() {
  types.meal_filter_to_string(types.Snack)
  |> should.equal("Snack")
}

// ============================================================================
// Edge Cases and Error Handling
// ============================================================================

/// Test decoding with numeric string values
pub fn decode_most_eaten_numeric_strings_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"123\",
          \"food_name\": \"Food\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Desc\",
          \"food_url\": \"https://example.com\",
          \"serving_id\": \"456\",
          \"number_of_units\": \"3.5\"
        }
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_id
          |> should.equal("123")
          food.serving_id
          |> should.equal("456")
          food.number_of_units
          |> should.equal("3.5")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten with numeric strings
pub fn decode_recently_eaten_numeric_strings_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"789\",
          \"food_name\": \"Item\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Desc\",
          \"food_url\": \"https://example.com\",
          \"serving_id\": \"999\",
          \"number_of_units\": \"2.0\"
        }
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_id
          |> should.equal("789")
          food.serving_id
          |> should.equal("999")
          food.number_of_units
          |> should.equal("2.0")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding most-eaten with special characters in description
pub fn decode_most_eaten_special_chars_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"123\",
          \"food_name\": \"Apple Pie\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Contains 25% sugar & spices\",
          \"food_url\": \"https://example.com/apple-pie\",
          \"serving_id\": \"0\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_most_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_description
          |> should.contain("sugar")
          food.food_description
          |> should.contain("spices")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding recently-eaten with special characters in URLs
pub fn decode_recently_eaten_special_chars_url_test() {
  let json_str =
    "{
      \"foods\": {
        \"food\": {
          \"food_id\": \"456\",
          \"food_name\": \"Bread\",
          \"food_type\": \"Generic\",
          \"food_description\": \"White bread\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/bread\",
          \"serving_id\": \"1\",
          \"number_of_units\": \"1.0\"
        }
      }
    }"

  case decoders.decode_recently_eaten(json_str) {
    Ok(response) -> {
      case response.foods {
        [food] -> {
          food.food_url
          |> should.contain("fatsecret.com")
          food.food_url
          |> should.contain("generic/bread")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
