/// Shopping List Recipe Decoder Tests
///
/// Tests for decoding shopping list recipes from Tandoor API responses.
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/shopping/shopping_list_recipe_decoder
import meal_planner/tandoor/types/shopping/shopping_list_recipe.{
  type ShoppingListRecipe,
}

/// Test decoding a complete shopping list recipe with recipe
pub fn decode_shopping_list_recipe_with_recipe_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"Weekly Meal Prep\",
      \"recipe\": 42,
      \"mealplan\": null,
      \"servings\": 4.0,
      \"created_by\": 1
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_recipe_decoder.decode_shopping_list_recipe(),
    )

  case result {
    Ok(shopping_list) -> {
      // Verify shopping list fields
      shopping_list.id |> ids.shopping_list_id_to_int |> should.equal(1)
      shopping_list.name |> should.equal("Weekly Meal Prep")
      shopping_list.servings |> should.equal(4.0)
      shopping_list.created_by |> ids.user_id_to_int |> should.equal(1)

      // Verify recipe is present
      case shopping_list.recipe {
        Some(recipe_id) ->
          recipe_id |> ids.recipe_id_to_int |> should.equal(42)
        None -> should.fail("Expected recipe to be present")
      }

      // Verify mealplan is None
      shopping_list.mealplan |> should.equal(None)
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode shopping list recipe: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding a shopping list recipe with mealplan
pub fn decode_shopping_list_recipe_with_mealplan_test() {
  let json_str =
    "{
      \"id\": 2,
      \"name\": \"Weekend Groceries\",
      \"recipe\": null,
      \"mealplan\": 7,
      \"servings\": 2.0,
      \"created_by\": 5
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_recipe_decoder.decode_shopping_list_recipe(),
    )

  case result {
    Ok(shopping_list) -> {
      shopping_list.id |> ids.shopping_list_id_to_int |> should.equal(2)
      shopping_list.name |> should.equal("Weekend Groceries")
      shopping_list.servings |> should.equal(2.0)
      shopping_list.created_by |> ids.user_id_to_int |> should.equal(5)

      // Verify recipe is None
      shopping_list.recipe |> should.equal(None)

      // Verify mealplan is present
      case shopping_list.mealplan {
        Some(mealplan_id) ->
          mealplan_id |> ids.meal_plan_id_to_int |> should.equal(7)
        None -> should.fail("Expected mealplan to be present")
      }
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode shopping list with mealplan: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding a minimal shopping list recipe (no recipe or mealplan)
pub fn decode_shopping_list_recipe_minimal_test() {
  let json_str =
    "{
      \"id\": 3,
      \"name\": \"Quick List\",
      \"recipe\": null,
      \"mealplan\": null,
      \"servings\": 1.0,
      \"created_by\": 2
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_recipe_decoder.decode_shopping_list_recipe(),
    )

  case result {
    Ok(shopping_list) -> {
      shopping_list.id |> ids.shopping_list_id_to_int |> should.equal(3)
      shopping_list.name |> should.equal("Quick List")
      shopping_list.servings |> should.equal(1.0)
      shopping_list.created_by |> ids.user_id_to_int |> should.equal(2)
      shopping_list.recipe |> should.equal(None)
      shopping_list.mealplan |> should.equal(None)
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode minimal shopping list: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding a list of shopping list recipes
pub fn decode_shopping_list_recipe_list_test() {
  let json_str =
    "{
      \"results\": [
        {
          \"id\": 1,
          \"name\": \"List 1\",
          \"recipe\": 10,
          \"mealplan\": null,
          \"servings\": 2.0,
          \"created_by\": 1
        },
        {
          \"id\": 2,
          \"name\": \"List 2\",
          \"recipe\": null,
          \"mealplan\": 5,
          \"servings\": 4.0,
          \"created_by\": 1
        }
      ]
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_recipe_decoder.decode_shopping_list_recipe_list(),
    )

  case result {
    Ok(shopping_lists) -> {
      // Verify we got 2 shopping lists
      shopping_lists |> should.have_length(2)

      // Verify first shopping list
      let assert [first, second] = shopping_lists
      first.id |> ids.shopping_list_id_to_int |> should.equal(1)
      first.name |> should.equal("List 1")
      first.servings |> should.equal(2.0)
      case first.recipe {
        Some(recipe_id) -> recipe_id |> ids.recipe_id_to_int |> should.equal(10)
        None -> should.fail("Expected recipe in first list")
      }
      first.mealplan |> should.equal(None)

      // Verify second shopping list
      second.id |> ids.shopping_list_id_to_int |> should.equal(2)
      second.name |> should.equal("List 2")
      second.servings |> should.equal(4.0)
      second.recipe |> should.equal(None)
      case second.mealplan {
        Some(mealplan_id) ->
          mealplan_id |> ids.meal_plan_id_to_int |> should.equal(5)
        None -> should.fail("Expected mealplan in second list")
      }
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode shopping list recipe list: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding empty shopping list recipe list
pub fn decode_shopping_list_recipe_list_empty_test() {
  let json_str = "{\"results\": []}"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_recipe_decoder.decode_shopping_list_recipe_list(),
    )

  case result {
    Ok(shopping_lists) -> {
      shopping_lists |> should.have_length(0)
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode empty shopping list: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}
