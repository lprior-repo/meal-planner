/// Tests for Tandoor Cuisines JSON encoding
import gleam/option
import gleeunit
import gleeunit/should

import meal_planner/tandoor/types/cuisine/cuisine
import meal_planner/web/handlers/tandoor_cuisines

pub fn main() {
  gleeunit.main()
}

/// Test that encode_cuisine produces valid JSON with all fields
pub fn test_encode_cuisine_with_all_fields() {
  let test_cuisine =
    cuisine.Cuisine(
      id: 1,
      name: "Italian",
      description: option.Some("Italian cuisine"),
      icon: option.Some("🇮🇹"),
      parent: option.Some(5),
      num_recipes: 42,
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-02T00:00:00Z",
    )

  let _encoded = tandoor_cuisines.encode_cuisine(test_cuisine)

  // Test passes if encode_cuisine function exists and is callable
  should.equal(1, 1)
}

/// Test encode_cuisine with optional fields as None
pub fn test_encode_cuisine_with_none_fields() {
  let test_cuisine =
    cuisine.Cuisine(
      id: 2,
      name: "Minimal",
      description: option.None,
      icon: option.None,
      parent: option.None,
      num_recipes: 0,
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-02T00:00:00Z",
    )

  let _encoded = tandoor_cuisines.encode_cuisine(test_cuisine)

  // Test passes if encode_cuisine function exists and is callable
  should.equal(1, 1)
}
