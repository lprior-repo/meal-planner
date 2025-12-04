/// Comprehensive tests for the query_cache module
/// Tests LRU cache with TTL for search queries and dashboard data
import gleam/dict
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/query_cache

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Cache Creation Tests
// ============================================================================

pub fn new_cache_has_default_config_test() {
  let cache = query_cache.new()
  let stats = query_cache.get_stats(cache)

  stats.size |> should.equal(0)
  stats.max_size |> should.equal(100)
  stats.hits |> should.equal(0)
  stats.misses |> should.equal(0)
  stats.hit_rate |> should.equal(0.0)
}

pub fn new_with_config_test() {
  let cache = query_cache.new_with_config(50, 600)
  let stats = query_cache.get_stats(cache)

  stats.max_size |> should.equal(50)
}

pub fn empty_cache_returns_none_test() {
  let cache = query_cache.new()
  let #(updated_cache, result) = query_cache.get(cache, "nonexistent")

  result |> should.equal(None)

  let stats = query_cache.get_stats(updated_cache)
  stats.misses |> should.equal(1)
  stats.hits |> should.equal(0)
}

// ============================================================================
// Get/Put Operations Tests
// ============================================================================

pub fn put_and_get_value_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "test_key", "test_value")

  let #(updated_cache, result) = query_cache.get(cache, "test_key")
  result |> should.equal(Some("test_value"))

  let stats = query_cache.get_stats(updated_cache)
  stats.hits |> should.equal(1)
  stats.misses |> should.equal(0)
  stats.size |> should.equal(1)
}

pub fn put_with_custom_ttl_test() {
  let cache = query_cache.new()
  let cache = query_cache.put_with_ttl(cache, "custom", "value", 3600)

  let #(_updated_cache, result) = query_cache.get(cache, "custom")
  result |> should.equal(Some("value"))
}

pub fn put_overwrites_existing_value_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key", "old_value")
  let cache = query_cache.put(cache, "key", "new_value")

  let #(_updated_cache, result) = query_cache.get(cache, "key")
  result |> should.equal(Some("new_value"))

  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(1)
}

pub fn multiple_keys_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key1", "value1")
  let cache = query_cache.put(cache, "key2", "value2")
  let cache = query_cache.put(cache, "key3", "value3")

  let #(_c1, r1) = query_cache.get(cache, "key1")
  let #(_c2, r2) = query_cache.get(cache, "key2")
  let #(_c3, r3) = query_cache.get(cache, "key3")

  r1 |> should.equal(Some("value1"))
  r2 |> should.equal(Some("value2"))
  r3 |> should.equal(Some("value3"))
}

pub fn get_updates_access_count_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "popular", "data")

  // Access multiple times
  let #(cache, _) = query_cache.get(cache, "popular")
  let #(cache, _) = query_cache.get(cache, "popular")
  let #(cache, _) = query_cache.get(cache, "popular")

  let stats = query_cache.get_stats(cache)
  stats.hits |> should.equal(3)
}

pub fn delete_removes_key_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "to_delete", "value")

  let #(_c, result) = query_cache.get(cache, "to_delete")
  result |> should.equal(Some("value"))

  let cache = query_cache.delete(cache, "to_delete")
  let #(updated_cache, result) = query_cache.get(cache, "to_delete")

  result |> should.equal(None)
  let stats = query_cache.get_stats(updated_cache)
  stats.size |> should.equal(0)
}

pub fn clear_removes_all_entries_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key1", "value1")
  let cache = query_cache.put(cache, "key2", "value2")
  let cache = query_cache.put(cache, "key3", "value3")

  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(3)

  let cache = query_cache.clear(cache)
  let stats = query_cache.get_stats(cache)

  stats.size |> should.equal(0)
  stats.hits |> should.equal(0)
  stats.misses |> should.equal(0)
}

// ============================================================================
// TTL Expiration Tests
// ============================================================================

pub fn expired_entry_returns_none_test() {
  let cache = query_cache.new()
  // Set with 0 second TTL (immediately expired)
  let cache = query_cache.put_with_ttl(cache, "expired", "value", 0)

  // Entry should exist initially
  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(1)

  // Getting expired entry should return None and remove it
  let #(updated_cache, result) = query_cache.get(cache, "expired")
  result |> should.equal(None)

  let stats = query_cache.get_stats(updated_cache)
  stats.size |> should.equal(0)
  stats.misses |> should.equal(1)
}

pub fn valid_entry_not_expired_test() {
  let cache = query_cache.new()
  // Set with long TTL (1 hour)
  let cache = query_cache.put_with_ttl(cache, "valid", "value", 3600)

  let #(_updated_cache, result) = query_cache.get(cache, "valid")
  result |> should.equal(Some("value"))
}

pub fn multiple_ttls_test() {
  let cache = query_cache.new()
  let cache = query_cache.put_with_ttl(cache, "short", "value", 0)
  let cache = query_cache.put_with_ttl(cache, "long", "value", 3600)

  let #(cache, short_result) = query_cache.get(cache, "short")
  let #(_cache, long_result) = query_cache.get(cache, "long")

  short_result |> should.equal(None)
  long_result |> should.equal(Some("value"))
}

// ============================================================================
// LRU Eviction Tests
// ============================================================================

pub fn eviction_when_max_size_reached_test() {
  // Create small cache (max 3 entries)
  let cache = query_cache.new_with_config(3, 300)

  // Fill cache
  let cache = query_cache.put(cache, "key1", "value1")
  let cache = query_cache.put(cache, "key2", "value2")
  let cache = query_cache.put(cache, "key3", "value3")

  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(3)

  // Add 4th entry - should evict LRU
  let cache = query_cache.put(cache, "key4", "value4")

  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(3)

  // Verify key4 exists
  let #(_cache, result) = query_cache.get(cache, "key4")
  result |> should.equal(Some("value4"))
}

pub fn lru_evicts_least_recently_used_test() {
  let cache = query_cache.new_with_config(3, 300)

  // Add 3 entries
  let cache = query_cache.put(cache, "old", "value")
  let cache = query_cache.put(cache, "middle", "value")
  let cache = query_cache.put(cache, "recent", "value")

  // Access middle and recent to make them more recent
  let #(cache, _) = query_cache.get(cache, "middle")
  let #(cache, _) = query_cache.get(cache, "recent")

  // Add new entry - should evict "old"
  let cache = query_cache.put(cache, "new", "value")

  let #(_c1, old_result) = query_cache.get(cache, "old")
  let #(_c2, middle_result) = query_cache.get(cache, "middle")
  let #(_c3, recent_result) = query_cache.get(cache, "recent")
  let #(_c4, new_result) = query_cache.get(cache, "new")

  old_result |> should.equal(None)
  middle_result |> should.equal(Some("value"))
  recent_result |> should.equal(Some("value"))
  new_result |> should.equal(Some("value"))
}

pub fn large_cache_no_eviction_test() {
  let cache = query_cache.new_with_config(100, 300)

  // Add many entries but stay under max
  let cache = add_many_entries(cache, 0, 50)

  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(50)

  // All entries should still be accessible
  let #(_cache, result) = query_cache.get(cache, "key_0")
  result |> should.equal(Some("value_0"))

  let #(_cache, result) = query_cache.get(cache, "key_49")
  result |> should.equal(Some("value_49"))
}

// ============================================================================
// Cache Statistics Tests
// ============================================================================

pub fn stats_tracks_hits_and_misses_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key", "value")

  // Hit
  let #(cache, _) = query_cache.get(cache, "key")

  // Miss
  let #(cache, _) = query_cache.get(cache, "nonexistent")

  // Hit
  let #(cache, _) = query_cache.get(cache, "key")

  let stats = query_cache.get_stats(cache)
  stats.hits |> should.equal(2)
  stats.misses |> should.equal(1)
}

pub fn stats_calculates_hit_rate_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key", "value")

  // 3 hits, 1 miss = 75% hit rate
  let #(cache, _) = query_cache.get(cache, "key")
  let #(cache, _) = query_cache.get(cache, "key")
  let #(cache, _) = query_cache.get(cache, "key")
  let #(cache, _) = query_cache.get(cache, "nonexistent")

  let stats = query_cache.get_stats(cache)
  stats.hit_rate |> should.equal(0.75)
}

pub fn stats_zero_hit_rate_when_no_requests_test() {
  let cache = query_cache.new()
  let stats = query_cache.get_stats(cache)

  stats.hit_rate |> should.equal(0.0)
}

pub fn reset_stats_clears_counters_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "key", "value")

  let #(cache, _) = query_cache.get(cache, "key")
  let #(cache, _) = query_cache.get(cache, "nonexistent")

  let stats = query_cache.get_stats(cache)
  stats.hits |> should.equal(1)
  stats.misses |> should.equal(1)

  let cache = query_cache.reset_stats(cache)
  let stats = query_cache.get_stats(cache)

  stats.hits |> should.equal(0)
  stats.misses |> should.equal(0)
  stats.size |> should.equal(1)
  // Entries remain
}

// ============================================================================
// Cache Key Generation Tests
// ============================================================================

pub fn search_key_generation_test() {
  let key = query_cache.search_key("Apple", 10)
  key |> should.equal("search:apple:10")
}

pub fn search_key_normalizes_case_test() {
  let key1 = query_cache.search_key("Apple", 10)
  let key2 = query_cache.search_key("APPLE", 10)
  let key3 = query_cache.search_key("apple", 10)

  key1 |> should.equal(key2)
  key2 |> should.equal(key3)
}

pub fn search_filtered_key_generation_test() {
  let key =
    query_cache.search_filtered_key("chicken", True, False, Some("protein"), 20)

  key |> should.equal("search_filtered:chicken:v:n:protein:20")
}

pub fn search_filtered_key_no_category_test() {
  let key = query_cache.search_filtered_key("bread", False, True, None, 10)

  key |> should.equal("search_filtered:bread:n:b:all:10")
}

pub fn dashboard_key_generation_test() {
  let key = query_cache.dashboard_key("2025-12-04", Some("breakfast"))
  key |> should.equal("dashboard:2025-12-04:breakfast")
}

pub fn dashboard_key_no_meal_type_test() {
  let key = query_cache.dashboard_key("2025-12-04", None)
  key |> should.equal("dashboard:2025-12-04:all")
}

pub fn recent_meals_key_generation_test() {
  let key = query_cache.recent_meals_key(5)
  key |> should.equal("recent_meals:5")
}

pub fn food_nutrients_key_generation_test() {
  let key = query_cache.food_nutrients_key(123_456)
  key |> should.equal("nutrients:123456")
}

pub fn different_keys_for_different_params_test() {
  let key1 = query_cache.search_key("apple", 10)
  let key2 = query_cache.search_key("apple", 20)
  let key3 = query_cache.search_key("orange", 10)

  key1 |> should.not_equal(key2)
  key1 |> should.not_equal(key3)
  key2 |> should.not_equal(key3)
}

// ============================================================================
// Performance Metrics Tests
// ============================================================================

pub fn calculate_improvement_test() {
  // 10x improvement: uncached 100ms, cached 10ms
  let improvement = query_cache.calculate_improvement(10.0, 100.0)
  improvement |> should.equal(10.0)

  // 2x improvement
  let improvement = query_cache.calculate_improvement(50.0, 100.0)
  improvement |> should.equal(2.0)
}

pub fn calculate_improvement_zero_uncached_test() {
  let improvement = query_cache.calculate_improvement(10.0, 0.0)
  improvement |> should.equal(1.0)
}

pub fn record_metric_does_not_crash_test() {
  // This is a stub function, just verify it doesn't crash
  query_cache.record_metric(True, "test_query", 15.5)
  query_cache.record_metric(False, "test_query", 150.0)
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn full_cache_workflow_test() {
  let cache = query_cache.new()

  // Put multiple items
  let cache = query_cache.put(cache, "item1", "data1")
  let cache = query_cache.put(cache, "item2", "data2")
  let cache = query_cache.put(cache, "item3", "data3")

  // Access some items
  let #(cache, _) = query_cache.get(cache, "item1")
  let #(cache, _) = query_cache.get(cache, "item2")

  // Delete one
  let cache = query_cache.delete(cache, "item2")

  // Check stats
  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(2)
  stats.hits |> should.equal(2)

  // Clear everything
  let cache = query_cache.clear(cache)
  let stats = query_cache.get_stats(cache)
  stats.size |> should.equal(0)
}

pub fn cache_with_different_value_types_test() {
  // Test with integers
  let cache_int = query_cache.new()
  let cache_int = query_cache.put(cache_int, "number", 42)
  let #(_c, result) = query_cache.get(cache_int, "number")
  result |> should.equal(Some(42))

  // Test with lists
  let cache_list = query_cache.new()
  let cache_list = query_cache.put(cache_list, "list", [1, 2, 3])
  let #(_c, result) = query_cache.get(cache_list, "list")
  result |> should.equal(Some([1, 2, 3]))
}

pub fn concurrent_operations_simulation_test() {
  let cache = query_cache.new()

  // Simulate multiple operations
  let cache = query_cache.put(cache, "key1", "value1")
  let #(cache, _) = query_cache.get(cache, "key1")
  let cache = query_cache.put(cache, "key2", "value2")
  let #(cache, _) = query_cache.get(cache, "key1")
  let #(cache, _) = query_cache.get(cache, "key2")
  let cache = query_cache.put(cache, "key3", "value3")
  let #(cache, _) = query_cache.get(cache, "nonexistent")

  let stats = query_cache.get_stats(cache)
  stats.hits |> should.equal(3)
  stats.misses |> should.equal(1)
  stats.size |> should.equal(3)
}

// ============================================================================
// Edge Cases and Error Handling
// ============================================================================

pub fn empty_key_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "", "value")

  let #(_cache, result) = query_cache.get(cache, "")
  result |> should.equal(Some("value"))
}

pub fn very_long_key_test() {
  let cache = query_cache.new()
  let long_key =
    "search_filtered:very_long_query_string_that_goes_on_and_on:v:n:category:100"
  let cache = query_cache.put(cache, long_key, "value")

  let #(_cache, result) = query_cache.get(cache, long_key)
  result |> should.equal(Some("value"))
}

pub fn unicode_keys_test() {
  let cache = query_cache.new()
  let cache = query_cache.put(cache, "食べ物", "food")
  let cache = query_cache.put(cache, "🍎", "apple")

  let #(cache, result1) = query_cache.get(cache, "食べ物")
  let #(_cache, result2) = query_cache.get(cache, "🍎")

  result1 |> should.equal(Some("food"))
  result2 |> should.equal(Some("apple"))
}

// ============================================================================
// Helper Functions
// ============================================================================

fn add_many_entries(
  cache: query_cache.QueryCache(String),
  start: Int,
  end: Int,
) -> query_cache.QueryCache(String) {
  case start >= end {
    True -> cache
    False -> {
      let key = "key_" <> int.to_string(start)
      let value = "value_" <> int.to_string(start)
      let cache = query_cache.put(cache, key, value)
      add_many_entries(cache, start + 1, end)
    }
  }
}
