import gleeunit
import gleeunit/should
import meal_planner/external/recipe_fetcher

pub fn main() {
  gleeunit.main()
}

pub fn source_name_themealdb_test() {
  recipe_fetcher.source_name(recipe_fetcher.TheMealDB)
  |> should.equal("TheMealDB")
}

pub fn requires_api_key_themealdb_test() {
  recipe_fetcher.requires_api_key(recipe_fetcher.TheMealDB)
  |> should.equal(False)
}

pub fn requires_api_key_spoonacular_test() {
  recipe_fetcher.requires_api_key(recipe_fetcher.Spoonacular)
  |> should.equal(True)
}

pub fn error_message_network_test() {
  recipe_fetcher.error_message(recipe_fetcher.NetworkError("timeout"))
  |> should.equal("Network error: timeout")
}

pub fn error_message_api_key_missing_test() {
  recipe_fetcher.error_message(recipe_fetcher.ApiKeyMissing)
  |> should.equal("API key required but not provided")
}

pub fn spoonacular_requires_key_test() {
  case recipe_fetcher.fetch_recipe(recipe_fetcher.Spoonacular, "test") {
    Error(recipe_fetcher.ApiKeyMissing) -> Nil
    _ -> should.fail()
  }
}
