import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/food/food_simple.{FoodSimple}

pub fn food_simple_full_constructor_test() {
  let food =
    FoodSimple(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
    )

  food.id
  |> should.equal(ids.food_id_from_int(1))

  food.name
  |> should.equal("Tomato")

  food.plural_name
  |> should.equal(Some("Tomatoes"))
}

pub fn food_simple_minimal_test() {
  let food =
    FoodSimple(id: ids.food_id_from_int(2), name: "Garlic", plural_name: None)

  food.id
  |> should.equal(ids.food_id_from_int(2))

  food.name
  |> should.equal("Garlic")

  food.plural_name
  |> should.equal(None)
}

pub fn food_simple_optional_fields_test() {
  let food1 =
    FoodSimple(
      id: ids.food_id_from_int(3),
      name: "Onion",
      plural_name: Some("Onions"),
    )
  let food2 =
    FoodSimple(id: ids.food_id_from_int(4), name: "Salt", plural_name: None)

  should.equal(food1.plural_name, Some("Onions"))
  should.equal(food2.plural_name, None)
}
