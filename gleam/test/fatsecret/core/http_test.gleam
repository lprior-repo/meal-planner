import gleam/dict
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth

pub fn main() {
  gleeunit.main()
}

pub fn test_modules_load() {
  let cfg = config.new("key", "secret")
  let nonce = oauth.generate_nonce()
  let _ = errors.code_from_int(101)

  should.be_true(True)
}
