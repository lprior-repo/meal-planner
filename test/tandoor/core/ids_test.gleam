/// Tests for Tandoor ID Type Wrappers
///
/// Tests type-safe ID wrappers for all Tandoor resource types.
/// Verifies to_int, from_int, and decoder functions work correctly.
import gleam/dynamic/decode
import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/ids

// ============================================================================
// RecipeId Tests
// ============================================================================

pub fn test_recipe_id_to_int() {
  let id = ids.recipe_id_from_int(42)
  ids.recipe_id_to_int(id)
  |> should.equal(42)
}

pub fn test_recipe_id_roundtrip() {
  let original = 123
  original
  |> ids.recipe_id_from_int
  |> ids.recipe_id_to_int
  |> should.equal(original)
}

pub fn test_recipe_id_decoder() {
  let json_data = json.int(456)
  let dynamic_data = json.to_string(json_data) |> decode.string_to_dynamic

  decode.run(dynamic_data, ids.recipe_id_decoder())
  |> should.be_ok
  |> ids.recipe_id_to_int
  |> should.equal(456)
}

// ============================================================================
// FoodId Tests
// ============================================================================

pub fn test_food_id_to_int() {
  let id = ids.food_id_from_int(99)
  ids.food_id_to_int(id)
  |> should.equal(99)
}

pub fn test_food_id_roundtrip() {
  let original = 555
  original
  |> ids.food_id_from_int
  |> ids.food_id_to_int
  |> should.equal(original)
}

pub fn test_food_id_decoder() {
  let json_data = json.int(777)
  let dynamic_data = json.to_string(json_data) |> decode.string_to_dynamic

  decode.run(dynamic_data, ids.food_id_decoder())
  |> should.be_ok
  |> ids.food_id_to_int
  |> should.equal(777)
}

// ============================================================================
// UnitId Tests
// ============================================================================

pub fn test_unit_id_to_int() {
  let id = ids.unit_id_from_int(10)
  ids.unit_id_to_int(id)
  |> should.equal(10)
}

pub fn test_unit_id_roundtrip() {
  let original = 25
  original
  |> ids.unit_id_from_int
  |> ids.unit_id_to_int
  |> should.equal(original)
}

// ============================================================================
// KeywordId Tests
// ============================================================================

pub fn test_keyword_id_to_int() {
  let id = ids.keyword_id_from_int(7)
  ids.keyword_id_to_int(id)
  |> should.equal(7)
}

pub fn test_keyword_id_decoder() {
  let json_data = json.int(88)
  let dynamic_data = json.to_string(json_data) |> decode.string_to_dynamic

  decode.run(dynamic_data, ids.keyword_id_decoder())
  |> should.be_ok
  |> ids.keyword_id_to_int
  |> should.equal(88)
}

// ============================================================================
// MealPlanId Tests
// ============================================================================

pub fn test_meal_plan_id_to_int() {
  let id = ids.meal_plan_id_from_int(15)
  ids.meal_plan_id_to_int(id)
  |> should.equal(15)
}

pub fn test_meal_plan_id_roundtrip() {
  let original = 333
  original
  |> ids.meal_plan_id_from_int
  |> ids.meal_plan_id_to_int
  |> should.equal(original)
}

// ============================================================================
// StepId Tests
// ============================================================================

pub fn test_step_id_to_int() {
  let id = ids.step_id_from_int(50)
  ids.step_id_to_int(id)
  |> should.equal(50)
}

pub fn test_step_id_roundtrip() {
  let original = 101
  original
  |> ids.step_id_from_int
  |> ids.step_id_to_int
  |> should.equal(original)
}

// ============================================================================
// IngredientId Tests
// ============================================================================

pub fn test_ingredient_id_to_int() {
  let id = ids.ingredient_id_from_int(200)
  ids.ingredient_id_to_int(id)
  |> should.equal(200)
}

pub fn test_ingredient_id_decoder() {
  let json_data = json.int(444)
  let dynamic_data = json.to_string(json_data) |> decode.string_to_dynamic

  decode.run(dynamic_data, ids.ingredient_id_decoder())
  |> should.be_ok
  |> ids.ingredient_id_to_int
  |> should.equal(444)
}

// ============================================================================
// UserId Tests
// ============================================================================

pub fn test_user_id_to_int() {
  let id = ids.user_id_from_int(1)
  ids.user_id_to_int(id)
  |> should.equal(1)
}

pub fn test_user_id_roundtrip() {
  let original = 42
  original
  |> ids.user_id_from_int
  |> ids.user_id_to_int
  |> should.equal(original)
}

// ============================================================================
// SupermarketId Tests
// ============================================================================

pub fn test_supermarket_id_to_int() {
  let id = ids.supermarket_id_from_int(8)
  ids.supermarket_id_to_int(id)
  |> should.equal(8)
}

pub fn test_supermarket_id_roundtrip() {
  let original = 77
  original
  |> ids.supermarket_id_from_int
  |> ids.supermarket_id_to_int
  |> should.equal(original)
}

// ============================================================================
// ShoppingListId Tests
// ============================================================================

pub fn test_shopping_list_id_to_int() {
  let id = ids.shopping_list_id_from_int(12)
  ids.shopping_list_id_to_int(id)
  |> should.equal(12)
}

pub fn test_shopping_list_id_roundtrip() {
  let original = 999
  original
  |> ids.shopping_list_id_from_int
  |> ids.shopping_list_id_to_int
  |> should.equal(original)
}

// ============================================================================
// PropertyId Tests
// ============================================================================

pub fn test_property_id_to_int() {
  let id = ids.property_id_from_int(3)
  ids.property_id_to_int(id)
  |> should.equal(3)
}

pub fn test_property_id_roundtrip() {
  let original = 66
  original
  |> ids.property_id_from_int
  |> ids.property_id_to_int
  |> should.equal(original)
}

pub fn test_property_id_decoder() {
  let json_data = json.int(22)
  let dynamic_data = json.to_string(json_data) |> decode.string_to_dynamic

  decode.run(dynamic_data, ids.property_id_decoder())
  |> should.be_ok
  |> ids.property_id_to_int
  |> should.equal(22)
}

// ============================================================================
// CuisineId Tests
// ============================================================================

pub fn test_cuisine_id_to_int() {
  let id = ids.cuisine_id_from_int(5)
  ids.cuisine_id_to_int(id)
  |> should.equal(5)
}

pub fn test_cuisine_id_roundtrip() {
  let original = 111
  original
  |> ids.cuisine_id_from_int
  |> ids.cuisine_id_to_int
  |> should.equal(original)
}
