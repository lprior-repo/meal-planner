import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/food/food.{Food}
import meal_planner/tandoor/types/food/food_simple.{FoodSimple}

pub fn food_full_constructor_test() {
  let recipe = FoodSimple(id: 100, name: "Pasta Recipe", plural_name: None)

  let food =
    Food(
      id: 1,
      name: "Tomato",
      plural_name: Some("Tomatoes"),
      description: "Fresh red tomatoes",
      recipe: Some(recipe),
      food_onhand: Some(True),
      supermarket_category: None,
      ignore_shopping: False,
    )

  food.id
  |> should.equal(1)

  food.name
  |> should.equal("Tomato")

  food.plural_name
  |> should.equal(Some("Tomatoes"))

  food.description
  |> should.equal("Fresh red tomatoes")

  food.food_onhand
  |> should.equal(Some(True))

  food.ignore_shopping
  |> should.equal(False)
}

pub fn food_minimal_test() {
  let food =
    Food(
      id: 2,
      name: "Garlic",
      plural_name: None,
      description: "",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: True,
    )

  food.id
  |> should.equal(2)

  food.name
  |> should.equal("Garlic")

  food.plural_name
  |> should.equal(None)

  food.recipe
  |> should.equal(None)

  food.food_onhand
  |> should.equal(None)

  food.ignore_shopping
  |> should.equal(True)
}

pub fn food_optional_fields_test() {
  let food1 =
    Food(
      id: 3,
      name: "Onion",
      plural_name: Some("Onions"),
      description: "Yellow onions",
      recipe: None,
      food_onhand: Some(False),
      supermarket_category: None,
      ignore_shopping: False,
    )

  let food2 =
    Food(
      id: 4,
      name: "Salt",
      plural_name: None,
      description: "Sea salt",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: True,
    )

  should.equal(food1.plural_name, Some("Onions"))
  should.equal(food1.food_onhand, Some(False))
  should.equal(food2.plural_name, None)
  should.equal(food2.food_onhand, None)
}

pub fn food_with_recipe_test() {
  let recipe =
    FoodSimple(id: 200, name: "Tomato Sauce", plural_name: Some("Sauces"))

  let food =
    Food(
      id: 5,
      name: "Tomato Sauce",
      plural_name: None,
      description: "Homemade sauce",
      recipe: Some(recipe),
      food_onhand: Some(True),
      supermarket_category: None,
      ignore_shopping: False,
    )

  case food.recipe {
    Some(r) -> {
      r.id
      |> should.equal(200)
      r.name
      |> should.equal("Tomato Sauce")
    }
    None -> should.fail()
  }
}
