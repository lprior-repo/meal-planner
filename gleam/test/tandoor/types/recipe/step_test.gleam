import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/recipe/step.{Step}

pub fn step_creation_test() {
  let step =
    Step(
      id: 1,
      name: "Prepare Ingredients",
      instruction: "Chop vegetables into small pieces",
      instruction_markdown: Some("**Chop** vegetables into small pieces"),
      ingredients: [],
      time: 10,
      order: 0,
      show_as_header: False,
      show_ingredients_table: True,
      file: None,
    )

  step.id |> should.equal(1)
  step.name |> should.equal("Prepare Ingredients")
  step.instruction |> should.equal("Chop vegetables into small pieces")
  step.time |> should.equal(10)
  step.order |> should.equal(0)
  step.show_as_header |> should.equal(False)
  step.show_ingredients_table |> should.equal(True)
}

pub fn step_with_header_test() {
  let step =
    Step(
      id: 2,
      name: "Section: Cooking",
      instruction: "",
      instruction_markdown: None,
      ingredients: [],
      time: 0,
      order: 1,
      show_as_header: True,
      show_ingredients_table: False,
      file: None,
    )

  step.show_as_header |> should.equal(True)
  step.name |> should.equal("Section: Cooking")
}

pub fn step_with_markdown_test() {
  let markdown_text = "# Important\n\n- Point 1\n- Point 2"
  let step =
    Step(
      id: 3,
      name: "Read Notes",
      instruction: "Important Point 1 Point 2",
      instruction_markdown: Some(markdown_text),
      ingredients: [],
      time: 0,
      order: 2,
      show_as_header: False,
      show_ingredients_table: False,
      file: None,
    )

  case step.instruction_markdown {
    Some(md) -> md |> should.equal(markdown_text)
    None -> should.fail()
  }
}

pub fn step_with_ingredients_test() {
  let step =
    Step(
      id: 4,
      name: "Mix ingredients",
      instruction: "Combine flour, eggs, and milk in a bowl",
      instruction_markdown: None,
      ingredients: [1, 2, 3],
      time: 5,
      order: 3,
      show_as_header: False,
      show_ingredients_table: True,
      file: None,
    )

  step.ingredients |> should.equal([1, 2, 3])
  step.show_ingredients_table |> should.equal(True)
}
