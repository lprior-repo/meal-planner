import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/recipe/ingredient.{Food, Ingredient, Unit}

pub fn ingredient_creation_test() {
  let tomato = Food(id: 1, name: "Tomato")
  let gram = Unit(id: 1, name: "Gram", abbreviation: "g")

  let ingredient =
    Ingredient(
      id: 1,
      food: Some(tomato),
      unit: Some(gram),
      amount: 250.0,
      note: Some("Fresh, ripe tomatoes"),
      order: 0,
      is_header: False,
      no_amount: False,
      original_text: Some("250g fresh, ripe tomatoes"),
    )

  ingredient.id |> should.equal(1)
  ingredient.amount |> should.equal(250.0)
  ingredient.order |> should.equal(0)
  ingredient.is_header |> should.equal(False)
  ingredient.no_amount |> should.equal(False)

  case ingredient.food {
    Some(food) -> food.name |> should.equal("Tomato")
    None -> should.fail("Expected food to be present")
  }

  case ingredient.unit {
    Some(unit) -> unit.abbreviation |> should.equal("g")
    None -> should.fail("Expected unit to be present")
  }
}

pub fn ingredient_header_test() {
  let ingredient =
    Ingredient(
      id: 2,
      food: None,
      unit: None,
      amount: 0.0,
      note: None,
      order: 0,
      is_header: True,
      no_amount: True,
      original_text: Some("For the sauce:"),
    )

  ingredient.is_header |> should.equal(True)
  ingredient.food |> should.equal(None)
  ingredient.unit |> should.equal(None)
}

pub fn ingredient_no_amount_test() {
  let salt = Food(id: 2, name: "Salt")

  let ingredient =
    Ingredient(
      id: 3,
      food: Some(salt),
      unit: None,
      amount: 0.0,
      note: Some("to taste"),
      order: 5,
      is_header: False,
      no_amount: True,
      original_text: Some("Salt to taste"),
    )

  ingredient.no_amount |> should.equal(True)
  ingredient.amount |> should.equal(0.0)

  case ingredient.note {
    Some(note) -> note |> should.equal("to taste")
    None -> should.fail("Expected note to be present")
  }
}

pub fn ingredient_with_note_test() {
  let flour = Food(id: 3, name: "All-purpose flour")
  let cup = Unit(id: 2, name: "Cup", abbreviation: "cup")

  let ingredient =
    Ingredient(
      id: 4,
      food: Some(flour),
      unit: Some(cup),
      amount: 2.5,
      note: Some("sifted"),
      order: 1,
      is_header: False,
      no_amount: False,
      original_text: Some("2 1/2 cups all-purpose flour, sifted"),
    )

  ingredient.amount |> should.equal(2.5)

  case ingredient.note {
    Some(note) -> note |> should.equal("sifted")
    None -> should.fail("Expected note to be present")
  }

  case ingredient.food {
    Some(food) -> food.name |> should.equal("All-purpose flour")
    None -> should.fail("Expected food to be present")
  }
}
