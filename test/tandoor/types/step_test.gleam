import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{Food}
import meal_planner/tandoor/ingredient.{Ingredient}
import meal_planner/tandoor/step.{Step}
import meal_planner/tandoor/unit.{Unit}

/// Test that Step type has all required fields with correct types
/// Validates the fix for meal-planner-2ud4
pub fn step_full_constructor_test() {
  let ingredient =
    Ingredient(
      id: 1,
      food: Some(Food(
        id: ids.food_id_from_int(1),
        name: "Tomato",
        plural_name: None,
        description: "Red tomato",
        recipe: None,
        food_onhand: None,
        supermarket_category: None,
        ignore_shopping: False,
        shopping: "Tomatoes",
        url: None,
        properties: None,
        properties_food_amount: 0.0,
        properties_food_unit: None,
        fdc_id: None,
        parent: None,
        numchild: 0,
        inherit_fields: None,
        full_name: "Produce > Tomato",
      )),
      unit: Some(Unit(
        id: 1,
        name: "gram",
        plural_name: Some("grams"),
        description: Some("Unit of mass"),
        base_unit: None,
        open_data_slug: None,
      )),
      amount: 250.0,
      note: Some("diced"),
      order: 1,
      is_header: False,
      no_amount: False,
      original_text: Some("250g tomatoes, diced"),
    )

  let step =
    Step(
      id: ids.step_id_from_int(1),
      name: "Prepare ingredients",
      instruction: "Chop vegetables finely",
      instruction_markdown: Some("**Chop** vegetables finely"),
      ingredients: [ingredient],
      time: 15,
      order: 0,
      show_as_header: False,
      show_ingredients_table: True,
      file: None,
      step_recipe: Some(5),
      step_recipe_data: None,
      numrecipe: 0,
    )

  // Verify ingredients is List(Ingredient), not List(IngredientId)
  step.name
  |> should.equal("Prepare ingredients")

  step.instruction
  |> should.equal("Chop vegetables finely")

  step.time
  |> should.equal(15)

  step.order
  |> should.equal(0)

  // Verify new fields exist
  step.step_recipe
  |> should.equal(Some(5))

  step.step_recipe_data
  |> should.equal(None)

  step.numrecipe
  |> should.equal(0)

  // Verify ingredients is full Ingredient objects, not just IDs
  case step.ingredients {
    [ing] -> {
      ing.id
      |> should.equal(1)

      ing.amount
      |> should.equal(250.0)
    }
    _ -> {
      should.fail()
    }
  }
}

pub fn step_minimal_constructor_test() {
  let step =
    Step(
      id: ids.step_id_from_int(2),
      name: "Mix",
      instruction: "Mix all together",
      instruction_markdown: None,
      ingredients: [],
      time: 5,
      order: 1,
      show_as_header: False,
      show_ingredients_table: False,
      file: None,
      step_recipe: None,
      step_recipe_data: None,
      numrecipe: 0,
    )

  step.name
  |> should.equal("Mix")

  step.ingredients
  |> should.equal([])

  step.step_recipe
  |> should.equal(None)
}
