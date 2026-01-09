//  Tandoor API Client Tests
//  Tests for Tandoor recipe management operations

import gleeunit
import gleeunit/should
import tandoor

pub fn main() {
  gleeunit.main()
}

pub fn create_tandoor_config_test() {
  let config = tandoor.new_config("http://localhost:8090", "test_token")

  config.base_url
  |> should.equal("http://localhost:8090")

  config.api_token
  |> should.equal("test_token")
}

pub fn test_connection_returns_ok_test() {
  let config = tandoor.new_config("http://localhost:8090", "token")
  let result = tandoor.test_connection(config)

  case result {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true()
}

pub fn list_recipes_returns_ok_test() {
  let config = tandoor.new_config("http://localhost:8090", "token")
  let result = tandoor.list_recipes(config, 10, 0)

  case result {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true()
}

pub fn get_recipe_returns_error_test() {
  let config = tandoor.new_config("http://localhost:8090", "token")
  let result = tandoor.get_recipe(config, 123)

  case result {
    Ok(_) -> False
    Error(_) -> True
  }
  |> should.be_true()
}

pub fn create_recipe_returns_error_test() {
  let config = tandoor.new_config("http://localhost:8090", "token")
  let result = tandoor.create_recipe(config, "Test Recipe", "A test recipe", 4)

  case result {
    Ok(_) -> False
    Error(_) -> True
  }
  |> should.be_true()
}

pub fn list_ingredients_returns_ok_test() {
  let config = tandoor.new_config("http://localhost:8090", "token")
  let result = tandoor.list_ingredients(config, 10, 0)

  case result {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true()
}
