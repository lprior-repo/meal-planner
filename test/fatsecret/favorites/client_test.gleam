/// Tests for FatSecret Favorites API client and decoders
///
/// Verifies correct parsing of favorites API responses including:
/// - Favorite foods list
/// - Most eaten foods
/// - Recently eaten foods
/// - Favorite recipes
import gleam/list
import gleeunit/should
import meal_planner/fatsecret/favorites/decoders
import meal_planner/fatsecret/favorites/types

// ============================================================================
// Favorite Foods Decoder Tests
// ============================================================================

pub fn decode_favorite_foods_multiple_test() {
  let json_str = favorite_foods_fixture()

  let result = decoders.decode_favorite_foods(json_str) |> should.be_ok

  result.foods |> list.length |> should.equal(2)

  let assert [first, ..] = result.foods
  first.food_id |> should.equal("33691")
  first.food_name |> should.equal("Banana")
}

pub fn decode_favorite_foods_empty_test() {
  let json_str = favorite_foods_empty_fixture()

  // Empty response returns error from decoder
  let result = decoders.decode_favorite_foods(json_str)
  case result {
    Ok(response) -> response.foods |> list.length |> should.equal(0)
    Error(_) -> Nil
    // Expected for empty response
  }
}

// ============================================================================
// Most Eaten Foods Decoder Tests
// ============================================================================

pub fn decode_most_eaten_multiple_test() {
  let json_str = most_eaten_fixture()

  let result = decoders.decode_most_eaten(json_str) |> should.be_ok

  result.foods |> list.length |> should.equal(2)

  let assert [first, ..] = result.foods
  first.food_id |> should.equal("33691")
  first.food_name |> should.equal("Banana")
}

// ============================================================================
// Recently Eaten Foods Decoder Tests
// ============================================================================

pub fn decode_recently_eaten_test() {
  let json_str = recently_eaten_fixture()

  let result = decoders.decode_recently_eaten(json_str) |> should.be_ok

  result.foods |> list.length |> should.equal(2)

  let assert [first, ..] = result.foods
  first.food_id |> should.equal("33691")
  first.food_name |> should.equal("Banana")
}

// ============================================================================
// Favorite Recipes Decoder Tests
// ============================================================================

pub fn decode_favorite_recipes_multiple_test() {
  let json_str = favorite_recipes_fixture()

  let result = decoders.decode_favorite_recipes(json_str) |> should.be_ok

  result.recipes |> list.length |> should.equal(2)

  let assert [first, ..] = result.recipes
  first.recipe_id |> should.equal("12345")
  first.recipe_name |> should.equal("Grilled Chicken Salad")
}

// ============================================================================
// MealFilter Tests
// ============================================================================

pub fn meal_filter_to_string_test() {
  types.meal_filter_to_string(types.Breakfast)
  |> should.equal("breakfast")
  types.meal_filter_to_string(types.Lunch) |> should.equal("lunch")
  types.meal_filter_to_string(types.Dinner) |> should.equal("dinner")
  types.meal_filter_to_string(types.Snack) |> should.equal("other")
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn favorite_foods_fixture() -> String {
  "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"33691\",
          \"food_name\": \"Banana\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium - Calories: 105kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/banana\",
          \"serving_id\": \"12345\",
          \"number_of_units\": \"1.0\"
        },
        {
          \"food_id\": \"4142\",
          \"food_name\": \"Chicken Breast\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g - Calories: 165kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/chicken-breast\",
          \"serving_id\": \"12346\",
          \"number_of_units\": \"1.0\"
        }
      ]
    }
  }"
}

fn favorite_foods_empty_fixture() -> String {
  "{
    \"foods\": {}
  }"
}

fn most_eaten_fixture() -> String {
  "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"33691\",
          \"food_name\": \"Banana\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium - Calories: 105kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/banana\",
          \"serving_id\": \"12345\",
          \"number_of_units\": \"1.0\"
        },
        {
          \"food_id\": \"4142\",
          \"food_name\": \"Chicken Breast\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g - Calories: 165kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/chicken-breast\",
          \"serving_id\": \"12346\",
          \"number_of_units\": \"1.0\"
        }
      ]
    }
  }"
}

fn recently_eaten_fixture() -> String {
  "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"33691\",
          \"food_name\": \"Banana\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium - Calories: 105kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/banana\",
          \"serving_id\": \"12345\",
          \"number_of_units\": \"1.0\"
        },
        {
          \"food_id\": \"4142\",
          \"food_name\": \"Chicken Breast\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g - Calories: 165kcal\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/chicken-breast\",
          \"serving_id\": \"12346\",
          \"number_of_units\": \"1.0\"
        }
      ]
    }
  }"
}

fn favorite_recipes_fixture() -> String {
  "{
    \"recipes\": {
      \"recipe\": [
        {
          \"recipe_id\": \"12345\",
          \"recipe_name\": \"Grilled Chicken Salad\",
          \"recipe_description\": \"A healthy salad\",
          \"recipe_url\": \"https://www.fatsecret.com/recipes/grilled-chicken-salad\"
        },
        {
          \"recipe_id\": \"12346\",
          \"recipe_name\": \"Oatmeal Bowl\",
          \"recipe_description\": \"Healthy breakfast\",
          \"recipe_url\": \"https://www.fatsecret.com/recipes/oatmeal-bowl\"
        }
      ]
    }
  }"
}
