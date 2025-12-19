import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/cache
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn create_cache_directory_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let result = cache.ensure_cache_directory(cache_dir)
  result |> should.be_ok()
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn cache_and_retrieve_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let _ = cache.ensure_cache_directory(cache_dir)
  let key = "test_food_search:chicken:10"
  let value = "{\"results\": [\"chicken breast\", \"chicken thigh\"]}"
  let ttl_hours = 24
  let cache_result = cache.cache_response(cache_dir, key, value, ttl_hours)
  cache_result |> should.be_ok()
  let retrieved = cache.get_cached(cache_dir, key)
  retrieved |> should.equal(Some(value))
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn get_nonexistent_key_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let _ = cache.ensure_cache_directory(cache_dir)
  let result = cache.get_cached(cache_dir, "nonexistent_key")
  result |> should.equal(None)
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn expired_entry_not_returned_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let _ = cache.ensure_cache_directory(cache_dir)
  let key = "test_expired:data:1"
  let value = "{\"test\": \"data\"}"
  let ttl_hours = 0
  let _ = cache.cache_response(cache_dir, key, value, ttl_hours)
  let result = cache.get_cached(cache_dir, key)
  result |> should.equal(None)
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn clear_cache_pattern_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let _ = cache.ensure_cache_directory(cache_dir)
  let _ = cache.cache_response(cache_dir, "food:search:chicken", "data1", 24)
  let _ = cache.cache_response(cache_dir, "food:search:beef", "data2", 24)
  let _ = cache.cache_response(cache_dir, "recipe:search:pasta", "data3", 24)
  let clear_result = cache.clear_cache(cache_dir, "food:")
  clear_result |> should.be_ok()
  cache.get_cached(cache_dir, "food:search:chicken") |> should.equal(None)
  cache.get_cached(cache_dir, "food:search:beef") |> should.equal(None)
  cache.get_cached(cache_dir, "recipe:search:pasta")
  |> should.equal(Some("data3"))
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn cleanup_expired_test() {
  let cache_dir = "/tmp/meal-planner-test-cache-" <> random_suffix()
  let _ = cache.ensure_cache_directory(cache_dir)
  let _ = cache.cache_response(cache_dir, "valid:entry", "valid_data", 24)
  let _ = cache.cache_response(cache_dir, "expired:entry", "expired_data", 0)
  let cleanup_result = cache.cleanup_expired(cache_dir)
  cleanup_result |> should.be_ok()
  cache.get_cached(cache_dir, "valid:entry") |> should.equal(Some("valid_data"))
  cache.get_cached(cache_dir, "expired:entry") |> should.equal(None)
  let _ = simplifile.delete(cache_dir)
  Nil
}

pub fn is_offline_test() {
  let result = cache.is_offline()
  result |> should.equal(False)
}

fn random_suffix() -> String {
  let timestamp = erlang_system_time()
  int_to_string(timestamp)
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(int: Int) -> String
