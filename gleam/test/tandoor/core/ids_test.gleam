import gleam/dynamic
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/ids

pub fn main() {
  gleeunit.main()
}

// RecipeId tests
pub fn recipe_id_from_int_test() {
  let id = ids.recipe_id_from_int(42)
  ids.recipe_id_to_int(id)
  |> should.equal(42)
}

pub fn recipe_id_decoder_test() {
  let json_value = dynamic.from(42)
  let assert Ok(parsed) = ids.recipe_id_decoder()(json_value)
  ids.recipe_id_to_int(parsed)
  |> should.equal(42)
}

// FoodId tests
pub fn food_id_from_int_test() {
  let id = ids.food_id_from_int(123)
  ids.food_id_to_int(id)
  |> should.equal(123)
}

pub fn food_id_decoder_test() {
  let json_value = dynamic.from(123)
  let assert Ok(parsed) = ids.food_id_decoder()(json_value)
  ids.food_id_to_int(parsed)
  |> should.equal(123)
}

// UnitId tests
pub fn unit_id_from_int_test() {
  let id = ids.unit_id_from_int(5)
  ids.unit_id_to_int(id)
  |> should.equal(5)
}

pub fn unit_id_decoder_test() {
  let json_value = dynamic.from(5)
  let assert Ok(parsed) = ids.unit_id_decoder()(json_value)
  ids.unit_id_to_int(parsed)
  |> should.equal(5)
}

// KeywordId tests
pub fn keyword_id_from_int_test() {
  let id = ids.keyword_id_from_int(789)
  ids.keyword_id_to_int(id)
  |> should.equal(789)
}

pub fn keyword_id_decoder_test() {
  let json_value = dynamic.from(789)
  let assert Ok(parsed) = ids.keyword_id_decoder()(json_value)
  ids.keyword_id_to_int(parsed)
  |> should.equal(789)
}

// MealPlanId tests
pub fn meal_plan_id_from_int_test() {
  let id = ids.meal_plan_id_from_int(10)
  ids.meal_plan_id_to_int(id)
  |> should.equal(10)
}

pub fn meal_plan_id_decoder_test() {
  let json_value = dynamic.from(10)
  let assert Ok(parsed) = ids.meal_plan_id_decoder()(json_value)
  ids.meal_plan_id_to_int(parsed)
  |> should.equal(10)
}

// StepId tests
pub fn step_id_from_int_test() {
  let id = ids.step_id_from_int(55)
  ids.step_id_to_int(id)
  |> should.equal(55)
}

pub fn step_id_decoder_test() {
  let json_value = dynamic.from(55)
  let assert Ok(parsed) = ids.step_id_decoder()(json_value)
  ids.step_id_to_int(parsed)
  |> should.equal(55)
}

// IngredientId tests
pub fn ingredient_id_from_int_test() {
  let id = ids.ingredient_id_from_int(999)
  ids.ingredient_id_to_int(id)
  |> should.equal(999)
}

pub fn ingredient_id_decoder_test() {
  let json_value = dynamic.from(999)
  let assert Ok(parsed) = ids.ingredient_id_decoder()(json_value)
  ids.ingredient_id_to_int(parsed)
  |> should.equal(999)
}

// UserId tests
pub fn user_id_from_int_test() {
  let id = ids.user_id_from_int(1)
  ids.user_id_to_int(id)
  |> should.equal(1)
}

pub fn user_id_decoder_test() {
  let json_value = dynamic.from(1)
  let assert Ok(parsed) = ids.user_id_decoder()(json_value)
  ids.user_id_to_int(parsed)
  |> should.equal(1)
}

// SupermarketId tests
pub fn supermarket_id_from_int_test() {
  let id = ids.supermarket_id_from_int(77)
  ids.supermarket_id_to_int(id)
  |> should.equal(77)
}

pub fn supermarket_id_decoder_test() {
  let json_value = dynamic.from(77)
  let assert Ok(parsed) = ids.supermarket_id_decoder()(json_value)
  ids.supermarket_id_to_int(parsed)
  |> should.equal(77)
}

// StorageId tests
pub fn storage_id_from_int_test() {
  let id = ids.storage_id_from_int(333)
  ids.storage_id_to_int(id)
  |> should.equal(333)
}

pub fn storage_id_decoder_test() {
  let json_value = dynamic.from(333)
  let assert Ok(parsed) = ids.storage_id_decoder()(json_value)
  ids.storage_id_to_int(parsed)
  |> should.equal(333)
}
