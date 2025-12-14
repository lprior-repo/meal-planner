/// Tests for shopping list recipe encoder
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/shopping/shopping_list_recipe_encoder
import meal_planner/tandoor/types/shopping/shopping_list_recipe.{
  ShoppingListRecipeCreate, ShoppingListRecipeUpdate,
}

pub fn encode_shopping_list_recipe_create_minimal_test() {
  let list =
    ShoppingListRecipeCreate(
      name: "My Shopping List",
      recipe: None,
      mealplan: None,
      servings: 1.0,
    )

  let encoded =
    shopping_list_recipe_encoder.encode_shopping_list_recipe_create(list)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"name\":\"My Shopping List\",\"recipe\":null,\"mealplan\":null,\"servings\":1.0}",
  )
}

pub fn encode_shopping_list_recipe_create_with_recipe_test() {
  let list =
    ShoppingListRecipeCreate(
      name: "Weekly Meal Prep",
      recipe: Some(ids.recipe_id_from_int(100)),
      mealplan: None,
      servings: 4.0,
    )

  let encoded =
    shopping_list_recipe_encoder.encode_shopping_list_recipe_create(list)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"name\":\"Weekly Meal Prep\",\"recipe\":100,\"mealplan\":null,\"servings\":4.0}",
  )
}

pub fn encode_shopping_list_recipe_create_with_mealplan_test() {
  let list =
    ShoppingListRecipeCreate(
      name: "Meal Plan Shopping",
      recipe: None,
      mealplan: Some(ids.meal_plan_id_from_int(5)),
      servings: 2.0,
    )

  let encoded =
    shopping_list_recipe_encoder.encode_shopping_list_recipe_create(list)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"name\":\"Meal Plan Shopping\",\"recipe\":null,\"mealplan\":5,\"servings\":2.0}",
  )
}

pub fn encode_shopping_list_recipe_update_minimal_test() {
  let update =
    ShoppingListRecipeUpdate(
      name: "Updated List",
      recipe: None,
      mealplan: None,
      servings: 1.0,
    )

  let encoded =
    shopping_list_recipe_encoder.encode_shopping_list_recipe_update(update)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"name\":\"Updated List\",\"recipe\":null,\"mealplan\":null,\"servings\":1.0}",
  )
}

pub fn encode_shopping_list_recipe_update_with_values_test() {
  let update =
    ShoppingListRecipeUpdate(
      name: "Complete Meal Prep",
      recipe: Some(ids.recipe_id_from_int(200)),
      mealplan: Some(ids.meal_plan_id_from_int(10)),
      servings: 6.0,
    )

  let encoded =
    shopping_list_recipe_encoder.encode_shopping_list_recipe_update(update)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"name\":\"Complete Meal Prep\",\"recipe\":200,\"mealplan\":10,\"servings\":6.0}",
  )
}
