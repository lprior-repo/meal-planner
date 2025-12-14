import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/types/food/food.{type Food}

pub fn decode_food_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"Tomato\",
      \"plural_name\": \"Tomatoes\",
      \"description\": \"Fresh red tomatoes\",
      \"recipe\": null,
      \"food_onhand\": true,
      \"supermarket_category\": null,
      \"ignore_shopping\": false
    }"

  let result: Result(Food, _) = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(food) -> {
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
    Error(_) -> should.fail()
  }
}

pub fn decode_food_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"name\": \"Garlic\",
      \"plural_name\": null,
      \"description\": \"\",
      \"recipe\": null,
      \"food_onhand\": null,
      \"supermarket_category\": null,
      \"ignore_shopping\": true
    }"

  let result: Result(Food, _) = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(food) -> {
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
    Error(_) -> should.fail()
  }
}

pub fn decode_food_with_recipe_test() {
  let json_str =
    "{
      \"id\": 3,
      \"name\": \"Tomato Sauce\",
      \"plural_name\": null,
      \"description\": \"Homemade sauce\",
      \"recipe\": {
        \"id\": 100,
        \"name\": \"Sauce Recipe\",
        \"plural_name\": \"Sauces\"
      },
      \"food_onhand\": true,
      \"supermarket_category\": null,
      \"ignore_shopping\": false
    }"

  let result: Result(Food, _) = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(food) -> {
      food.id
      |> should.equal(3)

      case food.recipe {
        Some(recipe) -> {
          recipe.id
          |> should.equal(100)
          recipe.name
          |> should.equal("Sauce Recipe")
          recipe.plural_name
          |> should.equal(Some("Sauces"))
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_food_with_supermarket_category_test() {
  let json_str =
    "{
      \"id\": 4,
      \"name\": \"Milk\",
      \"plural_name\": null,
      \"description\": \"Whole milk\",
      \"recipe\": null,
      \"food_onhand\": false,
      \"supermarket_category\": 5,
      \"ignore_shopping\": false
    }"

  let result: Result(Food, _) = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(food) -> {
      food.id
      |> should.equal(4)
      food.supermarket_category
      |> should.equal(Some(5))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_food_invalid_json_test() {
  let json_str = "{\"id\": \"not_a_number\"}"

  let result = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_food_missing_required_fields_test() {
  let json_str = "{\"id\": 1}"

  let result = json.parse(json_str, using: food_decoder.food_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}
