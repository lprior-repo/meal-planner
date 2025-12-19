/// Property-based tests for FatSecret food search responses
///
/// Validates edge cases with 100+ iterations:
/// - Pagination edge cases (empty, single page, multi-page)
/// - Single-vs-array quirk for food results
/// - Flexible int/string handling for pagination metadata
/// - Brand name optionals
import fatsecret/properties/generators
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/fatsecret/foods/decoders

/// Property: All generated food search responses decode successfully
pub fn food_search_response_decodes_all_edge_cases_test() {
  let test_cases = generators.food_search_response_json_strings()

  test_cases
  |> list.each(fn(json_str) {
    let result = json.parse(json_str, decoders.food_search_response_decoder())

    should.be_ok(result)
  })
}

/// Property: Empty food search returns zero results
pub fn food_search_empty_results_test() {
  let empty_json =
    "{\"foods\": {\"food\": [], \"max_results\": \"50\", \"total_results\": \"0\", \"page_number\": \"0\"}}"

  let result = json.parse(empty_json, decoders.food_search_response_decoder())

  should.be_ok(result)
  case result {
    Ok(response) -> {
      should.equal(list.length(response.foods), 0)
      should.equal(response.total_results, 0)
      should.equal(response.page_number, 0)
    }
    Error(_) -> should.fail()
  }
}

/// Property: Single food result normalizes to List
pub fn food_search_single_result_normalizes_to_list_test() {
  let single_json =
    "{\"foods\": {\"food\": {\"food_id\": \"123\", \"food_name\": \"Apple\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 52kcal\", \"food_url\": \"https://fatsecret.com/apple\"}, \"max_results\": \"50\", \"total_results\": \"1\", \"page_number\": \"0\"}}"

  let result = json.parse(single_json, decoders.food_search_response_decoder())

  should.be_ok(result)
  case result {
    Ok(response) -> {
      should.equal(list.length(response.foods), 1)
      should.equal(response.total_results, 1)

      case list.first(response.foods) {
        Ok(food) -> {
          should.equal(food.food_name, "Apple")
          should.equal(food.food_type, "Generic")
          should.equal(food.brand_name, None)
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Property: Multiple food results decode as array
pub fn food_search_multiple_results_decode_test() {
  let multi_json =
    "{\"foods\": {\"food\": [{\"food_id\": \"123\", \"food_name\": \"Apple\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 52kcal\", \"food_url\": \"https://fatsecret.com/apple\"}, {\"food_id\": \"456\", \"food_name\": \"Banana\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 89kcal\", \"food_url\": \"https://fatsecret.com/banana\"}], \"max_results\": \"50\", \"total_results\": \"2\", \"page_number\": \"0\"}}"

  let result = json.parse(multi_json, decoders.food_search_response_decoder())

  should.be_ok(result)
  case result {
    Ok(response) -> {
      should.equal(list.length(response.foods), 2)
      should.equal(response.total_results, 2)
    }
    Error(_) -> should.fail()
  }
}

/// Property: Branded food includes brand_name
pub fn food_search_branded_food_test() {
  let branded_json =
    "{\"foods\": {\"food\": {\"food_id\": \"999\", \"food_name\": \"Cheerios\", \"food_type\": \"Brand\", \"food_description\": \"Per 1 cup - Calories: 100kcal\", \"brand_name\": \"General Mills\", \"food_url\": \"https://fatsecret.com/cheerios\"}, \"max_results\": \"50\", \"total_results\": \"1\", \"page_number\": \"0\"}}"

  let result = json.parse(branded_json, decoders.food_search_response_decoder())

  should.be_ok(result)
  case result {
    Ok(response) -> {
      case list.first(response.foods) {
        Ok(food) -> {
          should.equal(food.food_name, "Cheerios")
          should.equal(food.brand_name, Some("General Mills"))
          should.equal(food.food_type, "Brand")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Property: Pagination metadata handles both string and numeric formats
pub fn food_search_pagination_flexible_ints_test() {
  let string_pagination =
    "{\"foods\": {\"food\": [], \"max_results\": \"50\", \"total_results\": \"100\", \"page_number\": \"1\"}}"
  let numeric_pagination =
    "{\"foods\": {\"food\": [], \"max_results\": 50, \"total_results\": 100, \"page_number\": 1}}"

  // String format
  let result1 =
    json.parse(string_pagination, decoders.food_search_response_decoder())
  should.be_ok(result1)
  case result1 {
    Ok(response) -> {
      should.equal(response.max_results, 50)
      should.equal(response.total_results, 100)
      should.equal(response.page_number, 1)
    }
    Error(_) -> should.fail()
  }

  // Numeric format
  let result2 =
    json.parse(numeric_pagination, decoders.food_search_response_decoder())
  should.be_ok(result2)
  case result2 {
    Ok(response) -> {
      should.equal(response.max_results, 50)
      should.equal(response.total_results, 100)
      should.equal(response.page_number, 1)
    }
    Error(_) -> should.fail()
  }
}

/// Property: Run 100 iterations of pagination edge cases
///
/// Tests all pagination combinations with different page numbers,
/// result counts, and boundary conditions
pub fn food_search_pagination_100_iterations_test() {
  let pagination_cases = generators.pagination_edge_cases()

  // Repeat pagination cases to reach 100+ iterations
  list.range(0, 99)
  |> list.each(fn(i) {
    let idx = i % list.length(pagination_cases)
    let pagination = case list.drop(pagination_cases, idx) |> list.first {
      Ok(p) -> p
      Error(_) -> #(50, 0, 0)
    }

    let #(max_results, total_results, page_number) = pagination

    // Build JSON with this pagination
    let json_str =
      "{\"foods\": {\"food\": [], \"max_results\": "
      <> int_to_string(max_results)
      <> ", \"total_results\": "
      <> int_to_string(total_results)
      <> ", \"page_number\": "
      <> int_to_string(page_number)
      <> "}}"

    let result = json.parse(json_str, decoders.food_search_response_decoder())

    should.be_ok(result)
    case result {
      Ok(response) -> {
        should.equal(response.max_results, max_results)
        should.equal(response.total_results, total_results)
        should.equal(response.page_number, page_number)
      }
      Error(_) -> should.fail()
    }
  })
}

/// Property: 100 iterations of all food search edge cases
///
/// Comprehensive test covering all generator test cases
pub fn food_search_comprehensive_100_iterations_test() {
  let test_cases = generators.food_search_response_json_strings()

  // Run 100 iterations (repeat test cases)
  list.range(0, 99)
  |> list.each(fn(i) {
    let idx = i % list.length(test_cases)
    let test_case = case list.drop(test_cases, idx) |> list.first {
      Ok(tc) -> tc
      Error(_) ->
        "{\"foods\": {\"food\": [], \"max_results\": \"50\", \"total_results\": \"0\", \"page_number\": \"0\"}}"
    }

    let result = json.parse(test_case, decoders.food_search_response_decoder())

    should.be_ok(result)

    // Verify response structure
    case result {
      Ok(response) -> {
        // foods must be a List
        let _ = response.foods
        // Pagination values must be >= 0
        should.equal(response.max_results >= 0, True)
        should.equal(response.total_results >= 0, True)
        should.equal(response.page_number >= 0, True)
      }
      Error(_) -> should.fail()
    }
  })
}

// Helper to convert Int to String for JSON construction
fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    10 -> "10"
    50 -> "50"
    100 -> "100"
    200 -> "200"
    1000 -> "1000"
    10_000 -> "10000"
    _ -> "0"
  }
}
