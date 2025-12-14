/// Common test utilities for FatSecret SDK tests
///
/// Provides helpers for:
/// - Creating test configurations
/// - Asserting on API responses
/// - Common test data builders
/// - Validation helpers
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleeunit/should
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/foods/types.{
  type Food, type FoodSearchResult, type Nutrition, type Serving,
}

// ============================================================================
// Test Configuration Builders
// ============================================================================

/// Create a test FatSecret configuration
///
/// Uses dummy credentials that won't work in production.
///
/// Example:
/// ```gleam
/// let config = test_config()
/// ```
pub fn test_config() -> FatSecretConfig {
  config.new("test_consumer_key", "test_consumer_secret")
}

/// Create a test access token
///
/// Example:
/// ```gleam
/// let token = test_access_token()
/// ```
pub fn test_access_token() -> AccessToken {
  oauth.AccessToken(
    oauth_token: "test_token",
    oauth_token_secret: "test_token_secret",
  )
}

/// Create a custom test configuration
///
/// Example:
/// ```gleam
/// let config = custom_test_config("my_key", "my_secret")
/// ```
pub fn custom_test_config(
  consumer_key: String,
  consumer_secret: String,
) -> FatSecretConfig {
  config.new(consumer_key, consumer_secret)
}

// ============================================================================
// Test Data Builders
// ============================================================================

/// Create a test nutrition object
///
/// All optional fields are set to None by default.
///
/// Example:
/// ```gleam
/// let nutrition = test_nutrition(
///   calories: 100.0,
///   carbs: 20.0,
///   protein: 5.0,
///   fat: 3.0
/// )
/// ```
pub fn test_nutrition(
  calories calories: Float,
  carbs carbs: Float,
  protein protein: Float,
  fat fat: Float,
) -> Nutrition {
  types.Nutrition(
    calories: calories,
    carbohydrate: carbs,
    protein: protein,
    fat: fat,
    saturated_fat: None,
    polyunsaturated_fat: None,
    monounsaturated_fat: None,
    cholesterol: None,
    sodium: None,
    potassium: None,
    fiber: None,
    sugar: None,
    vitamin_a: None,
    vitamin_c: None,
    calcium: None,
    iron: None,
    vitamin_d: None,
  )
}

/// Create a complete nutrition object with all fields
///
/// Example:
/// ```gleam
/// let nutrition = complete_nutrition()
/// ```
pub fn complete_nutrition() -> Nutrition {
  types.Nutrition(
    calories: 95.0,
    carbohydrate: 25.13,
    protein: 0.47,
    fat: 0.31,
    saturated_fat: Some(0.051),
    polyunsaturated_fat: Some(0.093),
    monounsaturated_fat: Some(0.012),
    cholesterol: Some(0.0),
    sodium: Some(1.0),
    potassium: Some(195.0),
    fiber: Some(4.4),
    sugar: Some(18.91),
    vitamin_a: Some(2.0),
    vitamin_c: Some(14.0),
    calcium: Some(1.0),
    iron: Some(1.0),
    vitamin_d: None,
  )
}

/// Create a test serving
///
/// Example:
/// ```gleam
/// let serving = test_serving(
///   id: "12345",
///   description: "1 cup",
///   calories: 150.0
/// )
/// ```
pub fn test_serving(
  id id: String,
  description description: String,
  calories calories: Float,
) -> Serving {
  types.Serving(
    serving_id: types.ServingId(id),
    serving_description: description,
    serving_url: "https://example.com/serving",
    metric_serving_amount: Some(100.0),
    metric_serving_unit: Some("g"),
    number_of_units: 1.0,
    measurement_description: description,
    nutrition: test_nutrition(
      calories: calories,
      carbs: 20.0,
      protein: 5.0,
      fat: 3.0,
    ),
  )
}

/// Create a test food
///
/// Example:
/// ```gleam
/// let food = test_food(
///   id: "33691",
///   name: "Apple",
///   food_type: "Generic"
/// )
/// ```
pub fn test_food(
  id id: String,
  name name: String,
  food_type food_type: String,
) -> Food {
  types.Food(
    food_id: types.FoodId(id),
    food_name: name,
    brand_name: None,
    food_type: food_type,
    food_url: "https://example.com/food/" <> id,
    servings: [
      test_serving(id: "0", description: "1 serving", calories: 100.0),
    ],
  )
}

/// Create a test food search result
///
/// Example:
/// ```gleam
/// let result = test_search_result(
///   id: "33691",
///   name: "Apple",
///   description: "Per 1 medium - Calories: 95kcal"
/// )
/// ```
pub fn test_search_result(
  id id: String,
  name name: String,
  description description: String,
) -> FoodSearchResult {
  types.FoodSearchResult(
    food_id: types.FoodId(id),
    food_name: name,
    brand_name: None,
    food_type: "Generic",
    food_description: description,
    food_url: "https://example.com/food/" <> id,
  )
}

// ============================================================================
// Assertion Helpers
// ============================================================================

/// Assert that a nutrition object has expected macros
///
/// Example:
/// ```gleam
/// nutrition
/// |> assert_macros(
///   calories: 95.0,
///   carbs: 25.13,
///   protein: 0.47,
///   fat: 0.31
/// )
/// ```
pub fn assert_macros(
  nutrition: Nutrition,
  calories calories: Float,
  carbs carbs: Float,
  protein protein: Float,
  fat fat: Float,
) -> Nil {
  nutrition.calories
  |> should.equal(calories)

  nutrition.carbohydrate
  |> should.equal(carbs)

  nutrition.protein
  |> should.equal(protein)

  nutrition.fat
  |> should.equal(fat)
}

/// Assert that a serving has expected values
///
/// Example:
/// ```gleam
/// serving
/// |> assert_serving(
///   id: "12345",
///   description: "1 cup",
///   calories: 150.0
/// )
/// ```
pub fn assert_serving(
  serving: Serving,
  id id: String,
  description description: String,
  calories calories: Float,
) -> Nil {
  types.serving_id_to_string(serving.serving_id)
  |> should.equal(id)

  serving.serving_description
  |> should.equal(description)

  serving.nutrition.calories
  |> should.equal(calories)
}

/// Assert that a food has expected properties
///
/// Example:
/// ```gleam
/// food
/// |> assert_food(
///   id: "33691",
///   name: "Apple",
///   food_type: "Generic",
///   serving_count: 1
/// )
/// ```
pub fn assert_food(
  food: Food,
  id id: String,
  name name: String,
  food_type food_type: String,
  serving_count serving_count: Int,
) -> Nil {
  types.food_id_to_string(food.food_id)
  |> should.equal(id)

  food.food_name
  |> should.equal(name)

  food.food_type
  |> should.equal(food_type)

  food.servings
  |> list.length
  |> should.equal(serving_count)
}

/// Assert that an optional value is Some
///
/// Example:
/// ```gleam
/// nutrition.fiber
/// |> assert_some
/// |> should.equal(4.4)
/// ```
pub fn assert_some(opt: Option(a)) -> a {
  case opt {
    Some(value) -> value
    None -> {
      should.fail()
      // This is unreachable but needed for type checking
      panic as "assert_some: got None"
    }
  }
}

/// Assert that an optional value is None
///
/// Example:
/// ```gleam
/// nutrition.vitamin_d
/// |> assert_none
/// ```
pub fn assert_none(opt: Option(a)) -> Nil {
  case opt {
    None -> Nil
    Some(_) -> should.fail()
  }
}

/// Assert that a list has expected length
///
/// Example:
/// ```gleam
/// food.servings
/// |> assert_length(3)
/// ```
pub fn assert_length(list: List(a), expected: Int) -> List(a) {
  list
  |> list.length
  |> should.equal(expected)

  list
}

/// Assert that a list is not empty
///
/// Example:
/// ```gleam
/// search_results.foods
/// |> assert_not_empty
/// ```
pub fn assert_not_empty(list: List(a)) -> List(a) {
  case list {
    [] -> {
      should.fail()
      []
    }
    _ -> list
  }
}

/// Assert that a string contains a substring
///
/// Example:
/// ```gleam
/// food.food_description
/// |> assert_contains("Calories:")
/// ```
pub fn assert_contains(haystack: String, needle: String) -> String {
  case string.contains(haystack, needle) {
    True -> haystack
    False -> {
      should.fail()
      haystack
    }
  }
}

/// Assert that two floats are approximately equal
///
/// Uses epsilon of 0.0001 for comparison.
///
/// Example:
/// ```gleam
/// actual
/// |> assert_float_equal(expected)
/// ```
pub fn assert_float_equal(actual: Float, expected: Float) -> Nil {
  let diff = case actual >. expected {
    True -> actual -. expected
    False -> expected -. actual
  }

  case diff <. 0.0001 {
    True -> Nil
    False -> should.fail()
  }
}

// ============================================================================
// Parameter Builders
// ============================================================================

/// Build search parameters
///
/// Example:
/// ```gleam
/// let params = search_params("apple")
/// |> with_max_results(10)
/// |> with_page_number(0)
/// ```
pub fn search_params(search_expression: String) -> Dict(String, String) {
  dict.from_list([
    #("search_expression", search_expression),
  ])
}

/// Add max_results parameter
pub fn with_max_results(
  params: Dict(String, String),
  max_results: Int,
) -> Dict(String, String) {
  dict.insert(params, "max_results", int.to_string(max_results))
}

/// Add page_number parameter
pub fn with_page_number(
  params: Dict(String, String),
  page_number: Int,
) -> Dict(String, String) {
  dict.insert(params, "page_number", int.to_string(page_number))
}

/// Build food.get parameters
///
/// Example:
/// ```gleam
/// let params = food_get_params("33691")
/// ```
pub fn food_get_params(food_id: String) -> Dict(String, String) {
  dict.from_list([
    #("food_id", food_id),
  ])
}

/// Build food_entries.get parameters
///
/// Example:
/// ```gleam
/// let params = food_entries_params("2025-12-14")
/// ```
pub fn food_entries_params(date: String) -> Dict(String, String) {
  dict.from_list([
    #("date", date),
  ])
}

// ============================================================================
// Validation Helpers
// ============================================================================

/// Validate that a food ID is in the correct format
///
/// FatSecret food IDs are numeric strings.
///
/// Example:
/// ```gleam
/// "33691" |> is_valid_food_id |> should.be_true
/// ```
pub fn is_valid_food_id(food_id: String) -> Bool {
  case int.parse(food_id) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Validate that a serving ID is in the correct format
///
/// Example:
/// ```gleam
/// "12345" |> is_valid_serving_id |> should.be_true
/// ```
pub fn is_valid_serving_id(serving_id: String) -> Bool {
  case int.parse(serving_id) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Validate that calories are reasonable (0-10000)
///
/// Example:
/// ```gleam
/// 95.0 |> are_reasonable_calories |> should.be_true
/// ```
pub fn are_reasonable_calories(calories: Float) -> Bool {
  calories >=. 0.0 && calories <=. 10_000.0
}

/// Validate that macros sum to reasonable calories
///
/// Using Atwater coefficients: 4 cal/g for carbs and protein, 9 cal/g for fat.
/// Allows 10% tolerance for rounding.
///
/// Example:
/// ```gleam
/// nutrition |> macros_match_calories |> should.be_true
/// ```
pub fn macros_match_calories(nutrition: Nutrition) -> Bool {
  let calculated =
    nutrition.carbohydrate
    *. 4.0
    +. nutrition.protein
    *. 4.0
    +. nutrition.fat
    *. 9.0

  let diff = case calculated >. nutrition.calories {
    True -> calculated -. nutrition.calories
    False -> nutrition.calories -. calculated
  }

  let tolerance = nutrition.calories *. 0.1

  diff <=. tolerance
}
