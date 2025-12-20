/// Tests for FatSecret Recipes JSON decoders
///
/// Verifies correct parsing of FatSecret Recipes API responses including:
/// - Single vs array edge cases for ingredients and directions
/// - Optional nutrition fields
/// - Recipe types list handling
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleeunit/should
import meal_planner/fatsecret/recipes/decoders
import meal_planner/fatsecret/recipes/types

// ============================================================================
// Recipe Decoder Tests (recipe.get.v2)
// ============================================================================

pub fn decode_complete_recipe_test() {
  let json_str = recipe_fixture()

  let result =
    json.parse(json_str, decoders.recipe_decoder())
    |> should.be_ok

  // Verify recipe details
  types.recipe_id_to_string(result.recipe_id) |> should.equal("12345")
  result.recipe_name |> should.equal("Grilled Chicken Salad")
  result.number_of_servings |> should.equal(4.0)

  // Verify timing info
  result.preparation_time_min |> should.equal(Some(15))
  result.cooking_time_min |> should.equal(Some(20))

  // Verify ingredients parsed
  result.ingredients |> list.length |> should.equal(4)
  let assert [first_ing, ..] = result.ingredients
  first_ing.food_name |> should.equal("Chicken Breast")
  first_ing.number_of_units |> should.equal(4.0)

  // Verify directions parsed
  result.directions |> list.length |> should.equal(3)
  let assert [first_dir, ..] = result.directions
  first_dir.direction_number |> should.equal(1)

  // Verify nutrition info
  result.calories |> should.equal(Some(320.0))
  result.protein |> should.equal(Some(45.0))
}

pub fn decode_recipe_with_single_ingredient_test() {
  // When there's only one ingredient, FatSecret returns an object not array
  let json_str = recipe_single_ingredient_fixture()

  let result =
    json.parse(json_str, decoders.recipe_decoder())
    |> should.be_ok

  // Single ingredient should be wrapped in list
  result.ingredients |> list.length |> should.equal(1)
}

// ============================================================================
// Recipe Search Response Tests (recipes.search.v3)
// ============================================================================

pub fn decode_recipe_search_multiple_results_test() {
  let json_str = recipe_search_fixture()

  let result =
    json.parse(json_str, decoders.recipe_search_response_decoder())
    |> should.be_ok

  // Verify pagination metadata
  result.total_results |> should.equal(2)
  result.max_results |> should.equal(20)
  result.page_number |> should.equal(0)

  // Verify recipes list
  result.recipes |> list.length |> should.equal(2)

  let assert [first, ..] = result.recipes
  types.recipe_id_to_string(first.recipe_id) |> should.equal("12345")
  first.recipe_name |> should.equal("Grilled Chicken Salad")
}

pub fn decode_recipe_search_single_result_test() {
  let json_str = recipe_search_single_fixture()

  let result =
    json.parse(json_str, decoders.recipe_search_response_decoder())
    |> should.be_ok

  // Single result should still be wrapped in list
  result.recipes |> list.length |> should.equal(1)
  result.total_results |> should.equal(1)
}

pub fn decode_recipe_search_empty_results_test() {
  let json_str = recipe_search_empty_fixture()

  let result =
    json.parse(json_str, decoders.recipe_search_response_decoder())
    |> should.be_ok

  result.recipes |> list.length |> should.equal(0)
  result.total_results |> should.equal(0)
}

// ============================================================================
// Recipe Types Response Tests (recipe_types.get.v2)
// ============================================================================

pub fn decode_recipe_types_test() {
  let json_str = recipe_types_fixture()

  let result =
    json.parse(json_str, decoders.recipe_types_response_decoder())
    |> should.be_ok

  result.recipe_types |> list.length |> should.equal(3)
  let assert [first, ..] = result.recipe_types
  first |> should.equal("Main Dish")
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn recipe_fixture() -> String {
  "{
    \"recipe_id\": \"12345\",
    \"recipe_name\": \"Grilled Chicken Salad\",
    \"recipe_url\": \"https://www.fatsecret.com/recipes/grilled-chicken-salad\",
    \"recipe_description\": \"A healthy and delicious grilled chicken salad\",
    \"recipe_image\": \"https://m.ftscrt.com/static/recipe/12345.jpg\",
    \"number_of_servings\": 4.0,
    \"preparation_time_min\": 15,
    \"cooking_time_min\": 20,
    \"rating\": 4.5,
    \"recipe_types\": {
      \"recipe_type\": [\"Main Dish\", \"Salad\"]
    },
    \"ingredients\": {
      \"ingredient\": [
        {
          \"food_id\": \"33691\",
          \"food_name\": \"Chicken Breast\",
          \"serving_id\": \"12345\",
          \"number_of_units\": 4.0,
          \"measurement_description\": \"piece\",
          \"ingredient_description\": \"4 chicken breasts\",
          \"ingredient_url\": \"https://www.fatsecret.com/calories-nutrition/generic/chicken-breast\"
        },
        {
          \"food_id\": \"33692\",
          \"food_name\": \"Mixed Greens\",
          \"number_of_units\": 8.0,
          \"measurement_description\": \"cup\",
          \"ingredient_description\": \"8 cups mixed greens\"
        },
        {
          \"food_id\": \"33693\",
          \"food_name\": \"Tomato\",
          \"number_of_units\": 2.0,
          \"measurement_description\": \"medium\",
          \"ingredient_description\": \"2 tomatoes\"
        },
        {
          \"food_id\": \"33694\",
          \"food_name\": \"Balsamic Vinegar\",
          \"number_of_units\": 0.5,
          \"measurement_description\": \"cup\",
          \"ingredient_description\": \"1/2 cup balsamic vinegar\"
        }
      ]
    },
    \"directions\": {
      \"direction\": [
        {\"direction_number\": 1, \"direction_description\": \"Grill chicken until cooked through\"},
        {\"direction_number\": 2, \"direction_description\": \"Slice chicken and place on greens\"},
        {\"direction_number\": 3, \"direction_description\": \"Add tomatoes and drizzle with vinegar\"}
      ]
    },
    \"calories\": 320.0,
    \"carbohydrate\": 12.0,
    \"protein\": 45.0,
    \"fat\": 9.0,
    \"saturated_fat\": 2.0,
    \"cholesterol\": 95.0,
    \"sodium\": 250.0,
    \"fiber\": 3.0,
    \"sugar\": 6.0
  }"
}

fn recipe_single_ingredient_fixture() -> String {
  "{
    \"recipe_id\": \"12345\",
    \"recipe_name\": \"Simple Recipe\",
    \"recipe_url\": \"https://www.fatsecret.com/recipes/simple-recipe\",
    \"recipe_description\": \"A simple recipe\",
    \"number_of_servings\": 1.0,
    \"recipe_types\": {
      \"recipe_type\": \"Main Dish\"
    },
    \"ingredients\": {
      \"ingredient\": {
        \"food_id\": \"33691\",
        \"food_name\": \"Chicken Breast\",
        \"number_of_units\": 1.0,
        \"measurement_description\": \"piece\",
        \"ingredient_description\": \"1 chicken breast\"
      }
    },
    \"directions\": {
      \"direction\": {\"direction_number\": 1, \"direction_description\": \"Cook it\"}
    }
  }"
}

fn recipe_search_fixture() -> String {
  "{
    \"recipes\": {
      \"recipe\": [
        {
          \"recipe_id\": \"12345\",
          \"recipe_name\": \"Grilled Chicken Salad\",
          \"recipe_description\": \"A healthy grilled chicken salad\",
          \"recipe_url\": \"https://www.fatsecret.com/recipes/grilled-chicken-salad\",
          \"recipe_image\": \"https://m.ftscrt.com/static/recipe/12345.jpg\"
        },
        {
          \"recipe_id\": \"12346\",
          \"recipe_name\": \"Chicken Caesar Salad\",
          \"recipe_description\": \"Classic caesar salad with grilled chicken\",
          \"recipe_url\": \"https://www.fatsecret.com/recipes/chicken-caesar-salad\",
          \"recipe_image\": \"https://m.ftscrt.com/static/recipe/12346.jpg\"
        }
      ],
      \"max_results\": 20,
      \"total_results\": 2,
      \"page_number\": 0
    }
  }"
}

fn recipe_search_single_fixture() -> String {
  "{
    \"recipes\": {
      \"recipe\": {
        \"recipe_id\": \"12345\",
        \"recipe_name\": \"Grilled Chicken Salad\",
        \"recipe_description\": \"A healthy grilled chicken salad\",
        \"recipe_url\": \"https://www.fatsecret.com/recipes/grilled-chicken-salad\"
      },
      \"max_results\": 20,
      \"total_results\": 1,
      \"page_number\": 0
    }
  }"
}

fn recipe_search_empty_fixture() -> String {
  "{
    \"recipes\": {
      \"max_results\": 20,
      \"total_results\": 0,
      \"page_number\": 0
    }
  }"
}

fn recipe_types_fixture() -> String {
  "{
    \"recipe_types\": {
      \"recipe_type\": [\"Main Dish\", \"Appetizers\", \"Desserts\"]
    }
  }"
}
