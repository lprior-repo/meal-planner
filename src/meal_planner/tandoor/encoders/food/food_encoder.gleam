/// Food encoder for Tandoor SDK
///
/// This module provides JSON encoders for Food and FoodCreate types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (always encoded)
/// - Clean, minimal JSON output matching Tandoor API expectations
///
/// TDD Implementation: GREEN phase - making tests pass
import gleam/json.{type Json}
import meal_planner/tandoor/types.{type TandoorFoodCreateRequest}

// ============================================================================
// Food Create Encoder
// ============================================================================

/// Encode a TandoorFoodCreateRequest to JSON
///
/// This encoder creates minimal JSON for food creation requests.
/// It only includes the required 'name' field.
///
/// # Example
/// ```gleam
/// let food = TandoorFoodCreateRequest(name: "Tomato")
/// let encoded = encode_food_create(food)
/// json.to_string(encoded) // "{\"name\":\"Tomato\"}"
/// ```
///
/// # Arguments
/// * `food` - The food create request to encode
///
/// # Returns
/// JSON representation of the food create request
pub fn encode_food_create(food: TandoorFoodCreateRequest) -> Json {
  json.object([#("name", json.string(food.name))])
}
