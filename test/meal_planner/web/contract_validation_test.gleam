/// Contract validation test suite
///
/// Tests verify that API responses conform to OpenAPI schema definitions.
/// These are integration tests that ensure backward compatibility.
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/types.{
  Breakfast, DaySummary, FoodEntry, FoodEntryId, Lunch,
}
import meal_planner/fatsecret/foods/types.{
  Food, FoodId, FoodSearchResponse, FoodSearchResult, Nutrition, Serving,
  ServingId,
}
import meal_planner/fatsecret/recipes/types.{
  Recipe, RecipeDirection, RecipeId, RecipeIngredient, RecipeSearchResponse,
  RecipeSearchResult,
}
import meal_planner/web/contract_validator

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Food Entry Contract Tests
// ============================================================================

pub fn food_entry_json_schema_test() {
  // GIVEN: A valid FoodEntry instance
  let entry =
    FoodEntry(
      food_entry_id: types.food_entry_id("123456"),
      food_entry_name: "Chicken Breast",
      food_entry_description: "Per 100g - 165kcal",
      food_id: "4142",
      serving_id: "12345",
      number_of_units: 1.5,
      meal: Lunch,
      date_int: 19_723,
      calories: 247.5,
      carbohydrate: 0.0,
      protein: 46.5,
      fat: 5.1,
      saturated_fat: Some(1.5),
      polyunsaturated_fat: Some(1.0),
      monounsaturated_fat: Some(1.2),
      cholesterol: Some(110.0),
      sodium: Some(95.0),
      potassium: Some(350.0),
      fiber: None,
      sugar: None,
    )

  // WHEN: Encoding to JSON
  let json_obj = contract_validator.food_entry_to_json(entry)

  // THEN: Validate against schema
  contract_validator.validate_food_entry_schema(json_obj)
  |> should.be_ok

  // AND: Required fields are present
  json_obj
  |> json.to_string
  |> should.equal(
    "{\"food_entry_id\":\"123456\",\"food_entry_name\":\"Chicken Breast\",\"food_entry_description\":\"Per 100g - 165kcal\",\"food_id\":\"4142\",\"serving_id\":\"12345\",\"number_of_units\":1.5,\"meal\":\"lunch\",\"date_int\":19723,\"calories\":247.5,\"carbohydrate\":0.0,\"protein\":46.5,\"fat\":5.1,\"saturated_fat\":1.5,\"polyunsaturated_fat\":1.0,\"monounsaturated_fat\":1.2,\"cholesterol\":110.0,\"sodium\":95.0,\"potassium\":350.0}",
  )
}

pub fn food_entry_missing_required_field_test() {
  // GIVEN: A JSON object missing required field (food_id)
  let invalid_json =
    json.object([
      #("food_entry_id", json.string("123")),
      #("food_entry_name", json.string("Test")),
      #("food_entry_description", json.string("Test food")),
      // missing food_id
      #("serving_id", json.string("456")),
      #("number_of_units", json.float(1.0)),
      #("meal", json.string("lunch")),
      #("date_int", json.int(19_723)),
      #("calories", json.float(100.0)),
      #("carbohydrate", json.float(10.0)),
      #("protein", json.float(5.0)),
      #("fat", json.float(3.0)),
    ])

  // WHEN: Validating against schema
  let result = contract_validator.validate_food_entry_schema(invalid_json)

  // THEN: Validation should fail
  result
  |> should.be_error
  |> should.equal("Missing required field: food_id")
}

// ============================================================================
// Food Search Response Contract Tests
// ============================================================================

pub fn food_search_response_schema_test() {
  // GIVEN: A valid FoodSearchResponse
  let response =
    FoodSearchResponse(
      foods: [
        FoodSearchResult(
          food_id: types.food_id("1001"),
          food_name: "Apple",
          food_type: "Generic",
          food_description: "Per 1 medium - 95kcal",
          brand_name: None,
          food_url: "https://fatsecret.com/...",
        ),
      ],
      max_results: 20,
      total_results: 1,
      page_number: 0,
    )

  // WHEN: Encoding to JSON
  let json_obj = contract_validator.food_search_response_to_json(response)

  // THEN: Validate against schema
  contract_validator.validate_food_search_response_schema(json_obj)
  |> should.be_ok
}

// ============================================================================
// Recipe Contract Tests
// ============================================================================

pub fn recipe_json_schema_test() {
  // GIVEN: A valid Recipe instance
  let recipe =
    Recipe(
      recipe_id: types.recipe_id("789"),
      recipe_name: "Grilled Chicken",
      recipe_url: "https://fatsecret.com/...",
      recipe_description: "Simple grilled chicken breast",
      recipe_image: Some("https://images.fatsecret.com/..."),
      number_of_servings: 4.0,
      preparation_time_min: Some(10),
      cooking_time_min: Some(20),
      rating: Some(4.5),
      recipe_types: ["Main Dish"],
      ingredients: [
        RecipeIngredient(
          food_id: "4142",
          food_name: "Chicken Breast",
          serving_id: Some("12345"),
          number_of_units: 4.0,
          measurement_description: "breast",
          ingredient_description: "4 chicken breasts",
          ingredient_url: Some("https://fatsecret.com/..."),
        ),
      ],
      directions: [
        RecipeDirection(
          direction_number: 1,
          direction_description: "Preheat grill to medium-high heat",
        ),
        RecipeDirection(
          direction_number: 2,
          direction_description: "Grill chicken for 6-7 minutes per side",
        ),
      ],
      calories: Some(165.0),
      carbohydrate: Some(0.0),
      protein: Some(31.0),
      fat: Some(3.6),
      saturated_fat: Some(1.0),
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: Some(85.0),
      sodium: Some(74.0),
      potassium: Some(256.0),
      fiber: None,
      sugar: None,
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  // WHEN: Encoding to JSON
  let json_obj = contract_validator.recipe_to_json(recipe)

  // THEN: Validate against schema
  contract_validator.validate_recipe_schema(json_obj)
  |> should.be_ok
}

// ============================================================================
// Error Response Contract Tests
// ============================================================================

pub fn error_response_schema_test() {
  // GIVEN: A FatSecret error response
  let error_json =
    json.object([
      #(
        "error",
        json.object([
          #("code", json.int(101)),
          #("message", json.string("Missing required parameter")),
        ]),
      ),
    ])

  // WHEN: Validating against schema
  let result = contract_validator.validate_error_response_schema(error_json)

  // THEN: Validation should pass
  result
  |> should.be_ok
}

pub fn error_response_invalid_code_test() {
  // GIVEN: An error response with invalid code (not in enum)
  let invalid_error =
    json.object([
      #(
        "error",
        json.object([
          #("code", json.int(999)),
          // Not a valid FatSecret error code
          #("message", json.string("Unknown error")),
        ]),
      ),
    ])

  // WHEN: Validating against schema
  let result = contract_validator.validate_error_response_schema(invalid_error)

  // THEN: Validation should fail
  result
  |> should.be_error
  |> should.equal("Invalid error code: 999 (not in FatSecret API spec)")
}

// ============================================================================
// Day Summary Contract Tests
// ============================================================================

pub fn day_summary_schema_test() {
  // GIVEN: A valid DaySummary
  let summary =
    DaySummary(
      date_int: 19_723,
      calories: 2150.0,
      carbohydrate: 250.0,
      protein: 150.0,
      fat: 65.0,
    )

  // WHEN: Encoding to JSON
  let json_obj = contract_validator.day_summary_to_json(summary)

  // THEN: Validate against schema
  contract_validator.validate_day_summary_schema(json_obj)
  |> should.be_ok
}

// ============================================================================
// Backward Compatibility Tests
// ============================================================================

pub fn food_entry_backward_compatible_with_v1_test() {
  // GIVEN: A FoodEntry JSON (current version)
  let current_json =
    json.object([
      #("food_entry_id", json.string("123")),
      #("food_entry_name", json.string("Apple")),
      #("food_entry_description", json.string("1 medium")),
      #("food_id", json.string("1001")),
      #("serving_id", json.string("2001")),
      #("number_of_units", json.float(1.0)),
      #("meal", json.string("breakfast")),
      #("date_int", json.int(19_723)),
      #("calories", json.float(95.0)),
      #("carbohydrate", json.float(25.0)),
      #("protein", json.float(0.5)),
      #("fat", json.float(0.3)),
    ])

  // WHEN: Checking backward compatibility
  let result =
    contract_validator.check_backward_compatibility(
      schema_name: "FoodEntry",
      old_version: "1.0",
      new_version: "1.1",
      old_json: current_json,
      new_json: current_json,
    )

  // THEN: Should be compatible (all v1 fields present)
  result
  |> should.be_ok
}

pub fn breaking_change_detection_test() {
  // GIVEN: Old and new versions with breaking change (removed field)
  let old_json =
    json.object([
      #("food_entry_id", json.string("123")),
      #("food_entry_name", json.string("Apple")),
      #("deprecated_field", json.string("value")),
      // This will be removed
      #("calories", json.float(95.0)),
    ])

  let new_json =
    json.object([
      #("food_entry_id", json.string("123")),
      #("food_entry_name", json.string("Apple")),
      // deprecated_field removed - BREAKING CHANGE
      #("calories", json.float(95.0)),
    ])

  // WHEN: Checking compatibility
  let result =
    contract_validator.check_backward_compatibility(
      schema_name: "FoodEntry",
      old_version: "1.0",
      new_version: "2.0",
      old_json: old_json,
      new_json: new_json,
    )

  // THEN: Should detect breaking change
  result
  |> should.be_error
  |> should.equal("Breaking change: field 'deprecated_field' removed")
}
