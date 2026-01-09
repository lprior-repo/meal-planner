//  FatSecret API Client Tests
//  Tests for FatSecret OAuth and API operations

import gleeunit
import gleeunit/should
import fatsecret

pub fn main() {
  gleeunit.main()
}

pub fn create_oauth_config_test() {
  let config = fatsecret.new_oauth("test_key", "test_secret")

  config.consumer_key
  |> should.equal("test_key")

  config.consumer_secret
  |> should.equal("test_secret")
}

pub fn add_user_credentials_test() {
  let config = fatsecret.new_oauth("key", "secret")
  let with_user = fatsecret.with_user_credentials(config, "user_token", "user_secret")

  with_user.consumer_key
  |> should.equal("key")
}

pub fn search_foods_returns_result_test() {
  let config = fatsecret.new_oauth("key", "secret")
  let result = fatsecret.search_foods(config, "apple")

  case result {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true()
}

pub fn get_food_returns_error_test() {
  let config = fatsecret.new_oauth("key", "secret")
  let result = fatsecret.get_food(config, "12345")

  case result {
    Ok(_) -> False
    Error(_) -> True
  }
  |> should.be_true()
}

pub fn log_food_returns_error_test() {
  let config = fatsecret.new_oauth("key", "secret")
  let result = fatsecret.log_food(config, "food_id", "serving_id", 20088, "breakfast")

  case result {
    Ok(_) -> False
    Error(_) -> True
  }
  |> should.be_true()
}
