/// Tests for FatSecret Favorites domain
///
/// NOTE: These tests require:
/// 1. FatSecret API credentials (FATSECRET_CONSUMER_KEY/SECRET)
/// 2. OAuth encryption key (OAUTH_ENCRYPTION_KEY)
/// 3. A connected FatSecret account (run OAuth flow first)
///
/// Run with: gleam test --target erlang
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/favorites/decoders
import meal_planner/fatsecret/favorites/types

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// Type Tests
// =============================================================================

pub fn meal_filter_to_string_test() {
  types.meal_filter_to_string(types.AllMeals)
  |> should.equal("all")

  types.meal_filter_to_string(types.Breakfast)
  |> should.equal("breakfast")

  types.meal_filter_to_string(types.Lunch)
  |> should.equal("lunch")

  types.meal_filter_to_string(types.Dinner)
  |> should.equal("dinner")

  types.meal_filter_to_string(types.Snack)
  |> should.equal("other")
}

// =============================================================================
// Decoder Tests
// =============================================================================

pub fn decode_favorite_foods_single_test() {
  let json =
    "{
      \"favorite_foods\": {
        \"max_results\": \"50\",
        \"page_number\": \"0\",
        \"total_results\": \"1\",
        \"favorite_food\": {
          \"food_id\": \"12345\",
          \"food_name\": \"Apple\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium (182g)\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
        }
      }
    }"

  let result = decoders.decode_favorite_foods(json)

  result
  |> should.be_ok
  |> fn(response) {
    response.foods
    |> should.have_length(1)

    let food = response.foods |> list.first |> should.be_ok

    food.food_id |> should.equal("12345")
    food.food_name |> should.equal("Apple")
    food.food_type |> should.equal("Generic")
    food.brand_name |> should.equal(None)
    food.food_description |> should.equal("Per 1 medium (182g)")
    food.food_url
    |> should.equal(
      "https://www.fatsecret.com/calories-nutrition/generic/apple",
    )

    response.max_results |> should.equal(50)
    response.total_results |> should.equal(1)
    response.page_number |> should.equal(0)
  }
}

pub fn decode_favorite_foods_multiple_test() {
  let json =
    "{
      \"favorite_foods\": {
        \"max_results\": \"50\",
        \"page_number\": \"0\",
        \"total_results\": \"2\",
        \"favorite_food\": [
          {
            \"food_id\": \"12345\",
            \"food_name\": \"Apple\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 medium (182g)\",
            \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
          },
          {
            \"food_id\": \"67890\",
            \"food_name\": \"Banana\",
            \"food_type\": \"Generic\",
            \"brand_name\": \"Dole\",
            \"food_description\": \"Per 1 medium (118g)\",
            \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/banana\"
          }
        ]
      }
    }"

  let result = decoders.decode_favorite_foods(json)

  result
  |> should.be_ok
  |> fn(response) {
    response.foods |> should.have_length(2)
    response.max_results |> should.equal(50)
    response.total_results |> should.equal(2)

    let food2 = response.foods |> list.last |> should.be_ok
    food2.food_id |> should.equal("67890")
    food2.brand_name |> should.equal(Some("Dole"))
  }
}

pub fn decode_most_eaten_test() {
  let json =
    "{
      \"most_eaten\": {
        \"meal\": \"breakfast\",
        \"food\": [
          {
            \"food_id\": \"111\",
            \"food_name\": \"Oatmeal\",
            \"food_type\": \"Generic\",
            \"food_description\": \"Per 1 cup\",
            \"food_url\": \"https://example.com/oatmeal\",
            \"eat_count\": 42
          }
        ]
      }
    }"

  let result = decoders.decode_most_eaten(json)

  result
  |> should.be_ok
  |> fn(response) {
    response.meal |> should.equal(Some("breakfast"))
    response.foods |> should.have_length(1)

    let food = response.foods |> list.first |> should.be_ok
    food.eat_count |> should.equal(42)
  }
}

pub fn decode_recently_eaten_test() {
  let json =
    "{
      \"recently_eaten\": {
        \"food\": {
          \"food_id\": \"222\",
          \"food_name\": \"Chicken Breast\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g\",
          \"food_url\": \"https://example.com/chicken\"
        }
      }
    }"

  let result = decoders.decode_recently_eaten(json)

  result
  |> should.be_ok
  |> fn(response) {
    response.meal |> should.equal(None)
    response.foods |> should.have_length(1)

    let food = response.foods |> list.first |> should.be_ok
    food.food_id |> should.equal("222")
    food.food_name |> should.equal("Chicken Breast")
  }
}

pub fn decode_favorite_recipes_test() {
  let json =
    "{
      \"favorite_recipes\": {
        \"max_results\": \"20\",
        \"page_number\": \"0\",
        \"total_results\": \"1\",
        \"favorite_recipe\": {
          \"recipe_id\": \"999\",
          \"recipe_name\": \"Chocolate Chip Cookies\",
          \"recipe_description\": \"Classic homemade cookies\",
          \"recipe_url\": \"https://example.com/cookies\",
          \"recipe_image\": \"https://example.com/cookies.jpg\"
        }
      }
    }"

  let result = decoders.decode_favorite_recipes(json)

  result
  |> should.be_ok
  |> fn(response) {
    response.recipes |> should.have_length(1)
    response.max_results |> should.equal(20)
    response.total_results |> should.equal(1)
    response.page_number |> should.equal(0)

    let recipe = response.recipes |> list.first |> should.be_ok
    recipe.recipe_id |> should.equal("999")
    recipe.recipe_name |> should.equal("Chocolate Chip Cookies")
    recipe.recipe_image |> should.equal(Some("https://example.com/cookies.jpg"))
  }
}
// =============================================================================
// Integration Tests (require real API credentials and OAuth token)
// =============================================================================

// NOTE: These tests are commented out as they require:
// 1. Real FatSecret API credentials
// 2. A connected OAuth token in the database
// 3. Network access to FatSecret API
//
// To run integration tests:
// 1. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET
// 2. Set OAUTH_ENCRYPTION_KEY
// 3. Complete the OAuth flow to get an access token
// 4. Uncomment the tests below

// pub fn get_favorite_foods_integration_test() {
//   let conn = test_db_connection()
//   let result = service.get_favorite_foods(conn, None, None)
//   result |> should.be_ok
// }

// pub fn add_and_delete_favorite_food_integration_test() {
//   let conn = test_db_connection()
//   let food_id = "12345"
//
//   // Add
//   service.add_favorite_food(conn, food_id)
//   |> should.be_ok
//
//   // Verify it's in favorites
//   let favorites = service.get_favorite_foods(conn, None, None)
//   favorites
//   |> should.be_ok
//   |> fn(response) {
//     response.foods
//     |> list.any(fn(f) { f.food_id == food_id })
//     |> should.be_true
//   }
//
//   // Delete
//   service.delete_favorite_food(conn, food_id)
//   |> should.be_ok
// }

// pub fn get_most_eaten_integration_test() {
//   let conn = test_db_connection()
//   let result = service.get_most_eaten(conn, Some(types.Breakfast))
//   result |> should.be_ok
// }

// pub fn get_recently_eaten_integration_test() {
//   let conn = test_db_connection()
//   let result = service.get_recently_eaten(conn, None)
//   result |> should.be_ok
// }
