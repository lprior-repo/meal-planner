/// Tests for FatSecret Foods client
/// These are integration tests that require valid API credentials
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/foods/client
import meal_planner/fatsecret/foods/types

// Note: These tests require valid FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET
// in your environment. They will be skipped if not configured.

/// Helper to check if FatSecret is configured
fn get_config() -> Result(env.FatSecretConfig, Nil) {
  case env.load_fatsecret_config() {
    Some(config) -> Ok(config)
    None -> Error(Nil)
  }
}

/// Test food search with simple query
pub fn search_foods_simple_test() {
  case get_config() {
    Error(_) -> {
      // Skip test if not configured
      should.be_true(True)
    }
    Ok(config) -> {
      let result = client.search_foods_simple(config, "banana")

      case result {
        Ok(response) -> {
          // Verify response structure
          should.be_true(response.total_results > 0)
          should.be_true(response.max_results == 20)
          should.be_true(response.page_number == 0)
          should.be_true(response.foods != [])
        }
        Error(e) -> {
          // Print error for debugging
          client.error_to_string(e)
          |> should.equal("Expected success")
        }
      }
    }
  }
}

/// Test food search with pagination
pub fn search_foods_with_pagination_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(config) -> {
      let result = client.search_foods(config, "apple", Some(0), Some(10))

      case result {
        Ok(response) -> {
          should.be_true(response.max_results == 10)
          should.be_true(response.page_number == 0)
        }
        Error(_) -> should.fail()
      }
    }
  }
}

/// Test get food by ID
/// Note: Using FatSecret food ID "33691" (Generic - Banana)
pub fn get_food_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(config) -> {
      let food_id = types.food_id("33691")
      let result = client.get_food(config, food_id)

      case result {
        Ok(food) -> {
          // Verify food structure
          should.equal(food.food_name, "Banana")
          should.be_true(food.servings != [])
        }
        Error(e) -> {
          client.error_to_string(e)
          |> should.equal("Expected success")
        }
      }
    }
  }
}

/// Test error handling for invalid food ID
pub fn get_food_invalid_id_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(config) -> {
      let food_id = types.food_id("99999999999")
      let result = client.get_food(config, food_id)

      case result {
        Error(_) -> should.be_true(True)
        Ok(_) -> should.fail()
      }
    }
  }
}

/// Test search with empty query
pub fn search_empty_query_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(config) -> {
      let result = client.search_foods_simple(config, "")

      case result {
        Ok(response) -> {
          // Empty query should return no results or error
          should.be_true(response.foods == [])
        }
        Error(_) -> should.be_true(True)
      }
    }
  }
}
