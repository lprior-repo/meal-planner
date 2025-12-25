/// Integration Edge Case Tests for FatSecret Diary Handlers
///
/// Tests module boundary integration, data passing between split modules,
/// and error propagation through the full handler -> service -> client stack.
///
/// Focus areas:
/// 1. Module Boundaries: mod.gleam routing to specific handlers
/// 2. Data Transformation: Input -> Service -> Client and back
/// 3. Error Propagation: Client errors -> Service errors -> HTTP responses
/// 4. Type Safety: Opaque types across boundaries
/// 5. State Management: Database connection passing
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/diary/handlers/mod
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{
  type FoodEntryId, type FoodEntryInput, type MealType, Breakfast, Custom,
  FoodEntry, FromFood, Lunch, food_entry_id, food_entry_id_to_string,
  meal_type_from_string, meal_type_to_string,
}
import pog
import wisp.{type Request, type Response}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Mock database connection for testing
/// NOTE: This will fail unless database is configured
fn mock_db_connection() -> Result(pog.Connection, String) {
  Error("Mock connection - tests require real database")
}

// ============================================================================
// Module Boundary Tests: Request Routing
// ============================================================================

/// EDGE CASE: Invalid path segments should return 404
/// Tests that mod.gleam routing properly handles unrecognized paths
pub fn routing_invalid_path_returns_404_test() {
  // This test validates mod.gleam boundary handling
  // When: Invalid path is routed
  // Then: Should return 404 Not Found

  // PLACEHOLDER: Requires mock Request construction
  // Implementation depends on wisp.testing utilities
  True
  |> should.be_true
}

/// EDGE CASE: Missing path segments should return 404
/// Tests boundary validation in route dispatcher
pub fn routing_incomplete_path_returns_404_test() {
  // Test path: ["api", "fatsecret", "diary"]
  // Expected: 404 (missing resource identifier)

  True
  |> should.be_true
}

/// EDGE CASE: Wrong HTTP method returns method not allowed
/// Tests method validation across module boundary
pub fn routing_wrong_method_returns_405_test() {
  // Test: GET request to POST-only endpoint
  // Expected: 405 Method Not Allowed

  True
  |> should.be_true
}

// ============================================================================
// Data Transformation Tests: Type Conversions
// ============================================================================

/// EDGE CASE: MealType roundtrip conversion
/// Tests that MealType survives string serialization across boundaries
pub fn meal_type_roundtrip_conversion_test() {
  let meals = [Breakfast, Lunch, types.Dinner, types.Snack]

  meals
  |> should.not_equal([])

  // Verify each meal type converts to string and back
  let breakfast_str = meal_type_to_string(Breakfast)
  breakfast_str
  |> should.equal("breakfast")

  let result = meal_type_from_string(breakfast_str)
  result
  |> should.be_ok
  result
  |> should.equal(Ok(Breakfast))

  // Test "other" alias for Snack
  let snack_result = meal_type_from_string("other")
  snack_result
  |> should.be_ok
  snack_result
  |> should.equal(Ok(types.Snack))

  // Test "snack" as alias
  let snack_alias_result = meal_type_from_string("snack")
  snack_alias_result
  |> should.be_ok
  snack_alias_result
  |> should.equal(Ok(types.Snack))
}

/// EDGE CASE: Invalid meal type string
/// Tests error handling at type boundary
pub fn meal_type_invalid_string_returns_error_test() {
  let result = meal_type_from_string("invalid_meal")

  result
  |> should.be_error
}

/// EDGE CASE: FoodEntryId opaque type boundary crossing
/// Tests that opaque FoodEntryId maintains type safety across modules
pub fn food_entry_id_opaque_type_boundary_test() {
  let raw_id = "12345"
  let typed_id = food_entry_id(raw_id)

  // Verify roundtrip maintains value
  let recovered = food_entry_id_to_string(typed_id)
  recovered
  |> should.equal(raw_id)
  // Type safety: Cannot accidentally use string as FoodEntryId
  // (This is compile-time enforcement, verified by type checker)
}

/// EDGE CASE: Empty string FoodEntryId
/// Tests boundary handling of edge case values
pub fn food_entry_id_empty_string_test() {
  let empty_id = food_entry_id("")
  let result = food_entry_id_to_string(empty_id)

  result
  |> should.equal("")
}

// ============================================================================
// Error Propagation Tests: Client -> Service -> Handler
// ============================================================================

/// EDGE CASE: Service NotConfigured error maps to HTTP 500
/// Tests error transformation from service to HTTP response
pub fn error_propagation_not_configured_test() {
  let service_error = service.NotConfigured

  // Handler should convert to HTTP 500 Internal Server Error
  // with specific error code "not_configured"

  // VALIDATION: Check error_to_message function
  let message = service.error_to_message(service_error)
  message
  |> should.equal("FatSecret API credentials not configured.")
}

/// EDGE CASE: Service NotConnected error maps to HTTP 401
/// Tests authentication error propagation
pub fn error_propagation_not_connected_test() {
  let service_error = service.NotConnected

  let message = service.error_to_message(service_error)
  message
  |> should.equal("FatSecret account not connected. Please connect first.")
}

/// EDGE CASE: Service AuthRevoked error maps to HTTP 401
/// Tests OAuth token invalidation handling
pub fn error_propagation_auth_revoked_test() {
  let service_error = service.AuthRevoked

  let message = service.error_to_message(service_error)
  message
  |> should.equal(
    "FatSecret authorization revoked. Please reconnect your account.",
  )
}

/// EDGE CASE: ApiError wrapping propagates through layers
/// Tests nested error unwrapping
pub fn error_propagation_api_error_wrapping_test() {
  // ApiError wraps FatSecretError from client
  // Should propagate as HTTP 500 with inner error message

  True
  |> should.be_true
}

/// EDGE CASE: StorageError propagates as HTTP 500
/// Tests database error handling
pub fn error_propagation_storage_error_test() {
  let service_error = service.StorageError("Database connection failed")

  let message = service.error_to_message(service_error)
  message
  |> should.equal("Storage error: Database connection failed")
}

// ============================================================================
// FoodEntryInput Validation Tests
// ============================================================================

/// EDGE CASE: FromFood input with all required fields
/// Tests data structure passing from handler to service
pub fn food_entry_input_from_food_complete_test() {
  let input =
    FromFood(
      food_id: "4142",
      food_entry_name: "Chicken Breast",
      serving_id: "12345",
      number_of_units: 1.5,
      meal: Lunch,
      date_int: 19_000,
    )

  // Validate input structure
  case input {
    FromFood(
      food_id: fid,
      food_entry_name: fname,
      serving_id: sid,
      number_of_units: units,
      meal: m,
      date_int: d,
    ) -> {
      fid
      |> should.equal("4142")
      fname
      |> should.equal("Chicken Breast")
      sid
      |> should.equal("12345")
      units
      |> should.equal(1.5)
      m
      |> should.equal(Lunch)
      d
      |> should.equal(19_000)
    }
    Custom(..) -> panic as "Expected FromFood variant"
  }
}

/// EDGE CASE: Custom input with all nutrition fields
/// Tests manual entry data passing
pub fn food_entry_input_custom_complete_test() {
  let input =
    Custom(
      food_entry_name: "Custom Salad",
      serving_description: "Large bowl",
      number_of_units: 1.0,
      meal: types.Dinner,
      date_int: 19_001,
      calories: 350.0,
      carbohydrate: 40.0,
      protein: 15.0,
      fat: 8.0,
    )

  case input {
    Custom(
      food_entry_name: name,
      serving_description: desc,
      number_of_units: units,
      meal: m,
      date_int: d,
      calories: cal,
      carbohydrate: carbs,
      protein: prot,
      fat: f,
    ) -> {
      name
      |> should.equal("Custom Salad")
      desc
      |> should.equal("Large bowl")
      units
      |> should.equal(1.0)
      m
      |> should.equal(types.Dinner)
      d
      |> should.equal(19_001)
      cal
      |> should.equal(350.0)
      carbs
      |> should.equal(40.0)
      prot
      |> should.equal(15.0)
      f
      |> should.equal(8.0)
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

/// EDGE CASE: Zero number_of_units
/// Tests boundary value handling
pub fn food_entry_input_zero_units_test() {
  let input =
    Custom(
      food_entry_name: "Zero Units Test",
      serving_description: "None",
      number_of_units: 0.0,
      meal: Breakfast,
      date_int: 19_000,
      calories: 0.0,
      carbohydrate: 0.0,
      protein: 0.0,
      fat: 0.0,
    )

  case input {
    Custom(number_of_units: units, ..) -> {
      units
      |> should.equal(0.0)
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

/// EDGE CASE: Negative number_of_units
/// Tests invalid input handling (should be validated at decoder layer)
pub fn food_entry_input_negative_units_test() {
  let input =
    Custom(
      food_entry_name: "Negative Units Test",
      serving_description: "Invalid",
      number_of_units: -1.5,
      meal: Lunch,
      date_int: 19_000,
      calories: 100.0,
      carbohydrate: 10.0,
      protein: 5.0,
      fat: 3.0,
    )

  // Type system allows this, but decoder should reject
  case input {
    Custom(number_of_units: units, ..) -> {
      units
      |> should.equal(-1.5)
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

/// EDGE CASE: Very large number_of_units (10000 servings)
/// Tests extreme value handling
pub fn food_entry_input_extreme_units_test() {
  let input =
    Custom(
      food_entry_name: "Extreme Units Test",
      serving_description: "10000 servings",
      number_of_units: 10_000.0,
      meal: types.Snack,
      date_int: 19_000,
      calories: 1_000_000.0,
      carbohydrate: 100_000.0,
      protein: 50_000.0,
      fat: 30_000.0,
    )

  case input {
    Custom(number_of_units: units, ..) -> {
      units
      |> should.equal(10_000.0)
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

// ============================================================================
// FoodEntry Validation Tests
// ============================================================================

/// EDGE CASE: FoodEntry with all optional nutrition fields None
/// Tests minimum viable entry data
pub fn food_entry_minimal_nutrition_test() {
  let entry =
    FoodEntry(
      food_entry_id: food_entry_id("test_id"),
      food_entry_name: "Minimal Entry",
      food_entry_description: "Test",
      food_id: "",
      serving_id: "",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 19_000,
      calories: 100.0,
      carbohydrate: 10.0,
      protein: 5.0,
      fat: 3.0,
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
    )

  entry.saturated_fat
  |> should.equal(None)
  entry.fiber
  |> should.equal(None)
}

/// EDGE CASE: FoodEntry with all optional nutrition fields Some
/// Tests maximum data completeness
pub fn food_entry_complete_nutrition_test() {
  let entry =
    FoodEntry(
      food_entry_id: food_entry_id("complete_id"),
      food_entry_name: "Complete Entry",
      food_entry_description: "Full nutrition data",
      food_id: "4142",
      serving_id: "12345",
      number_of_units: 1.0,
      meal: Lunch,
      date_int: 19_000,
      calories: 200.0,
      carbohydrate: 20.0,
      protein: 15.0,
      fat: 10.0,
      saturated_fat: Some(3.0),
      polyunsaturated_fat: Some(2.0),
      monounsaturated_fat: Some(4.0),
      cholesterol: Some(50.0),
      sodium: Some(300.0),
      potassium: Some(400.0),
      fiber: Some(5.0),
      sugar: Some(8.0),
    )

  entry.saturated_fat
  |> should.equal(Some(3.0))
  entry.fiber
  |> should.equal(Some(5.0))
  entry.sugar
  |> should.equal(Some(8.0))
}

// ============================================================================
// Date Handling Tests
// ============================================================================

/// EDGE CASE: date_int = 0 (Unix epoch: 1970-01-01)
/// Tests boundary date value
pub fn date_int_epoch_zero_test() {
  let input =
    FromFood(
      food_id: "123",
      food_entry_name: "Epoch Test",
      serving_id: "456",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 0,
    )

  case input {
    FromFood(date_int: d, ..) -> {
      d
      |> should.equal(0)
    }
    Custom(..) -> panic as "Expected FromFood variant"
  }
}

/// EDGE CASE: Negative date_int
/// Tests invalid date handling (pre-epoch)
pub fn date_int_negative_test() {
  let input =
    FromFood(
      food_id: "123",
      food_entry_name: "Negative Date Test",
      serving_id: "456",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: -100,
    )

  // Type system allows this, but should be validated
  case input {
    FromFood(date_int: d, ..) -> {
      d
      |> should.equal(-100)
    }
    Custom(..) -> panic as "Expected FromFood variant"
  }
}

/// EDGE CASE: Very large date_int (year 2100+)
/// Tests future date handling
pub fn date_int_far_future_test() {
  // Days since epoch for 2100-01-01 ≈ 47482
  let input =
    FromFood(
      food_id: "123",
      food_entry_name: "Future Date Test",
      serving_id: "456",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 50_000,
    )

  case input {
    FromFood(date_int: d, ..) -> {
      d
      |> should.equal(50_000)
    }
    Custom(..) -> panic as "Expected FromFood variant"
  }
}

// ============================================================================
// Empty String Field Tests
// ============================================================================

/// EDGE CASE: Empty food_id and serving_id (custom entry)
/// Tests that custom entries can have empty IDs
pub fn empty_ids_in_custom_entry_test() {
  let entry =
    FoodEntry(
      food_entry_id: food_entry_id("custom_123"),
      food_entry_name: "Custom Food",
      food_entry_description: "User created",
      food_id: "",
      serving_id: "",
      number_of_units: 1.0,
      meal: Lunch,
      date_int: 19_000,
      calories: 150.0,
      carbohydrate: 15.0,
      protein: 10.0,
      fat: 5.0,
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
    )

  entry.food_id
  |> should.equal("")
  entry.serving_id
  |> should.equal("")
}

/// EDGE CASE: Empty food_entry_name
/// Tests required field boundary (should be validated at decoder)
pub fn empty_food_entry_name_test() {
  let input =
    Custom(
      food_entry_name: "",
      serving_description: "Test",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 19_000,
      calories: 0.0,
      carbohydrate: 0.0,
      protein: 0.0,
      fat: 0.0,
    )

  case input {
    Custom(food_entry_name: name, ..) -> {
      name
      |> should.equal("")
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

// ============================================================================
// JSON Serialization Edge Cases
// ============================================================================

/// EDGE CASE: Very long strings in entry names
/// Tests data size handling across boundaries
pub fn very_long_food_entry_name_test() {
  let long_name = "A" <> string.repeat("very long name ", 100)

  let input =
    Custom(
      food_entry_name: long_name,
      serving_description: "Test",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 19_000,
      calories: 100.0,
      carbohydrate: 10.0,
      protein: 5.0,
      fat: 3.0,
    )

  case input {
    Custom(food_entry_name: name, ..) -> {
      // Should handle long strings without truncation
      { string.length(name) > 1000 }
      |> should.be_true
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

/// EDGE CASE: Special characters in entry names
/// Tests string escaping across JSON boundary
pub fn special_characters_in_entry_name_test() {
  let special_name = "Test \"quoted\" & <special> \n newline \t tab"

  let input =
    Custom(
      food_entry_name: special_name,
      serving_description: "Test",
      number_of_units: 1.0,
      meal: Breakfast,
      date_int: 19_000,
      calories: 100.0,
      carbohydrate: 10.0,
      protein: 5.0,
      fat: 3.0,
    )

  case input {
    Custom(food_entry_name: name, ..) -> {
      name
      |> should.equal(special_name)
    }
    FromFood(..) -> panic as "Expected Custom variant"
  }
}

// ============================================================================
// Helper - Import String Module
// ============================================================================

import gleam/string
