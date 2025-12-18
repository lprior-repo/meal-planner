import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/food/food.{Food}
import meal_planner/tandoor/types/recipe/ingredient.{Ingredient}
import meal_planner/tandoor/types/unit/unit.{Unit}

pub fn ingredient_creation_test() {
  let tomato =
    Food(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
      description: "A red fruit",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
    )
  let gram =
    Unit(
      id: 1,
      name: "Gram",
      plural_name: Some("Grams"),
      description: Some("A unit of mass"),
      base_unit: None,
      open_data_slug: None,
    )

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
      conversions: [],
      used_in_recipes: [],
      always_use_plural_unit: False,
      always_use_plural_food: False,
    )

  ingredient.id |> should.equal(1)
  ingredient.amount |> should.equal(250.0)
  ingredient.order |> should.equal(0)
  ingredient.is_header |> should.equal(False)
  ingredient.no_amount |> should.equal(False)

  case ingredient.food {
    Some(food) -> food.name |> should.equal("Tomato")
    None -> should.fail()
  }

  case ingredient.unit {
    Some(unit) -> unit.name |> should.equal("Gram")
    None -> should.fail()
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
      conversions: [],
      used_in_recipes: [],
      always_use_plural_unit: False,
      always_use_plural_food: False,
    )

  ingredient.is_header |> should.equal(True)
  ingredient.food |> should.equal(None)
  ingredient.unit |> should.equal(None)
}

pub fn ingredient_no_amount_test() {
  let salt =
    Food(
      id: ids.food_id_from_int(2),
      name: "Salt",
      plural_name: None,
      description: "Sodium chloride",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
    )

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
      conversions: [],
      used_in_recipes: [],
      always_use_plural_unit: False,
      always_use_plural_food: False,
    )

  ingredient.no_amount |> should.equal(True)
  ingredient.amount |> should.equal(0.0)

  case ingredient.note {
    Some(note) -> note |> should.equal("to taste")
    None -> should.fail()
  }
}

pub fn ingredient_with_note_test() {
  let flour =
    Food(
      id: ids.food_id_from_int(3),
      name: "All-purpose flour",
      plural_name: None,
      description: "A type of wheat flour",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
    )
  let cup =
    Unit(
      id: 2,
      name: "Cup",
      plural_name: Some("Cups"),
      description: Some("Volume measurement"),
      base_unit: None,
      open_data_slug: None,
    )

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
      conversions: [],
      used_in_recipes: [],
      always_use_plural_unit: False,
      always_use_plural_food: False,
    )

  ingredient.amount |> should.equal(2.5)

  case ingredient.note {
    Some(note) -> note |> should.equal("sifted")
    None -> should.fail()
  }

  case ingredient.food {
    Some(food) -> food.name |> should.equal("All-purpose flour")
    None -> should.fail()
  }
}
