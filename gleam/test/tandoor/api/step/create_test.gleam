/// Tests for Step Create API with StepId opaque type
import gleam/option
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/recipe/step_encoder.{StepCreateRequest}
import meal_planner/tandoor/types/recipe/step.{Step}

/// Test that Step type uses StepId opaque type for id field
pub fn step_uses_step_id_test() {
  let step_id = ids.step_id_from_int(123)
  let ingredient_id_1 = ids.ingredient_id_from_int(1)
  let ingredient_id_2 = ids.ingredient_id_from_int(2)

  let step =
    Step(
      id: step_id,
      name: "Test Step",
      instruction: "Do something",
      instruction_markdown: option.None,
      ingredients: [ingredient_id_1, ingredient_id_2],
      time: 15,
      order: 0,
      show_as_header: False,
      show_ingredients_table: True,
      file: option.None,
    )

  // Verify we can extract the int value
  ids.step_id_to_int(step.id)
  |> should.equal(123)

  // Verify ingredients are IngredientId
  step.ingredients
  |> should.have_length(2)
}

/// Test that StepCreateRequest uses IngredientId for ingredients
pub fn step_create_request_uses_ingredient_id_test() {
  let ingredient_id_1 = ids.ingredient_id_from_int(1)
  let ingredient_id_2 = ids.ingredient_id_from_int(2)

  let request =
    StepCreateRequest(
      name: "Prepare ingredients",
      instruction: "Chop all vegetables",
      ingredients: [ingredient_id_1, ingredient_id_2],
      time: 15,
      order: 0,
      show_as_header: False,
      show_ingredients_table: True,
      file: option.None,
    )

  // Verify ingredients are IngredientId
  request.ingredients
  |> should.have_length(2)
}
