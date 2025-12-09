/// Comprehensive tests for the TTL-based cache module
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cache

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Basic Cache Operations Tests
// ============================================================================

pub fn new_cache_is_empty_test() {
  let c = cache.new()
  cache.is_empty(c) |> should.be_true()
  cache.size(c) |> should.equal(0)
}

pub fn set_and_get_value_test() {
  let c = cache.new()
  let c = cache.set(c, "test_key", "test_value", 60)

  let #(_c, result) = cache.get(c, "test_key")
  result |> should.equal(Some("test_value"))
}

pub fn get_nonexistent_key_test() {
  let c = cache.new()
  let #(_c, result) = cache.get(c, "nonexistent")
  result |> should.equal(None)
}

pub fn overwrite_existing_key_test() {
  let c = cache.new()
  let c = cache.set(c, "key", "value1", 60)
  let c = cache.set(c, "key", "value2", 60)

  let #(_c, result) = cache.get(c, "key")
  result |> should.equal(Some("value2"))
}

pub fn cache_size_increases_test() {
  let c = cache.new()
  cache.size(c) |> should.equal(0)

  let c = cache.set(c, "key1", "value1", 60)
  cache.size(c) |> should.equal(1)

  let c = cache.set(c, "key2", "value2", 60)
  cache.size(c) |> should.equal(2)

  // Overwriting doesn't increase size
  let c = cache.set(c, "key1", "new_value", 60)
  cache.size(c) |> should.equal(2)
}

pub fn has_key_test() {
  let c = cache.new()
  let c = cache.set(c, "existing", "value", 60)

  cache.has_key(c, "existing") |> should.be_true()
  cache.has_key(c, "nonexistent") |> should.be_false()
}

// ============================================================================
// TTL and Expiration Tests
// ============================================================================

pub fn expired_entry_returns_none_test() {
  let c = cache.new()
  // Set with 0 second TTL (immediately expired)
  let c = cache.set(c, "expired", "value", 0)

  // Should return None and remove the entry
  let #(c, result) = cache.get(c, "expired")
  result |> should.equal(None)

  // Entry should be gone
  cache.has_key(c, "expired") |> should.be_false()
}

pub fn cleanup_expired_removes_old_entries_test() {
  let c = cache.new()
  let c = cache.set(c, "valid", "value", 3600)
  let c = cache.set(c, "expired1", "value", 0)
  let c = cache.set(c, "expired2", "value", 0)

  cache.size(c) |> should.equal(3)

  let #(c, removed) = cache.cleanup_expired(c)
  removed |> should.equal(2)
  cache.size(c) |> should.equal(1)
  cache.has_key(c, "valid") |> should.be_true()
}

// ============================================================================
// Invalidation Tests
// ============================================================================

pub fn invalidate_removes_key_test() {
  let c = cache.new()
  let c = cache.set(c, "key", "value", 60)
  cache.has_key(c, "key") |> should.be_true()

  let c = cache.invalidate(c, "key")
  cache.has_key(c, "key") |> should.be_false()
}

pub fn invalidate_nonexistent_key_is_safe_test() {
  let c = cache.new()
  let c = cache.set(c, "key1", "value", 60)

  // Should not error
  let c = cache.invalidate(c, "nonexistent")

  // Existing key should still be there
  cache.has_key(c, "key1") |> should.be_true()
}

pub fn invalidate_prefix_test() {
  let c = cache.new()
  let c = cache.set(c, "user:123", "data1", 60)
  let c = cache.set(c, "user:456", "data2", 60)
  let c = cache.set(c, "product:789", "data3", 60)

  cache.size(c) |> should.equal(3)

  // Invalidate all "user:" prefixed keys
  let c = cache.invalidate_prefix(c, "user:")

  cache.size(c) |> should.equal(1)
  cache.has_key(c, "user:123") |> should.be_false()
  cache.has_key(c, "user:456") |> should.be_false()
  cache.has_key(c, "product:789") |> should.be_true()
}

pub fn clear_removes_all_entries_test() {
  let c = cache.new()
  let c = cache.set(c, "key1", "value1", 60)
  let c = cache.set(c, "key2", "value2", 60)
  let c = cache.set(c, "key3", "value3", 60)

  cache.size(c) |> should.equal(3)

  let c = cache.clear(c)
  cache.size(c) |> should.equal(0)
  cache.is_empty(c) |> should.be_true()
}

// ============================================================================
// Key Generation Tests
// ============================================================================

pub fn make_key_generates_consistent_keys_test() {
  let key1 = cache.make_key("prefix", "query", 10)
  let key2 = cache.make_key("prefix", "query", 10)

  key1 |> should.equal(key2)
}

pub fn make_key_different_params_different_keys_test() {
  let key1 = cache.make_key("prefix", "query", 10)
  let key2 = cache.make_key("prefix", "query", 20)
  let key3 = cache.make_key("prefix", "different", 10)

  key1 |> should.not_equal(key2)
  key1 |> should.not_equal(key3)
}

// ============================================================================
// Statistics Tests
// ============================================================================

pub fn stats_reports_correct_counts_test() {
  let c = cache.new()
  let c = cache.set(c, "valid1", "v1", 3600)
  let c = cache.set(c, "valid2", "v2", 3600)
  let c = cache.set(c, "expired", "v3", 0)

  let stats = cache.stats(c)
  stats.total_entries |> should.equal(3)
  stats.expired_entries |> should.equal(1)
}

pub fn stats_on_empty_cache_test() {
  let c = cache.new()
  let stats = cache.stats(c)

  stats.total_entries |> should.equal(0)
  stats.expired_entries |> should.equal(0)
}

// ============================================================================
// Integration and Edge Cases Tests
// ============================================================================

pub fn cache_with_different_value_types_test() {
  // Test with integers
  let c_int = cache.new()
  let c_int = cache.set(c_int, "num", 42, 60)
  let #(_c_int, result) = cache.get(c_int, "num")
  result |> should.equal(Some(42))

  // Test with lists
  let c_list = cache.new()
  let c_list = cache.set(c_list, "list", [1, 2, 3], 60)
  let #(_c_list, result) = cache.get(c_list, "list")
  result |> should.equal(Some([1, 2, 3]))
}

pub fn multiple_get_operations_test() {
  let c = cache.new()
  let c = cache.set(c, "key", "value", 60)

  // First get
  let #(c, result1) = cache.get(c, "key")
  result1 |> should.equal(Some("value"))

  // Second get should still work
  let #(_c, result2) = cache.get(c, "key")
  result2 |> should.equal(Some("value"))
}

pub fn get_expired_cleans_up_entry_test() {
  let c = cache.new()
  let c = cache.set(c, "expired", "value", 0)

  cache.size(c) |> should.equal(1)

  // Getting expired entry should remove it
  let #(c, result) = cache.get(c, "expired")
  result |> should.equal(None)

  cache.size(c) |> should.equal(0)
}

pub fn large_cache_test() {
  // Test with many entries
  let c = cache.new()

  // Add 100 entries
  let c = add_many_entries(c, 0, 100)

  cache.size(c) |> should.equal(100)

  // Verify some entries exist
  let #(_c, result) = cache.get(c, "key_50")
  result |> should.equal(Some("value_50"))
}

// Helper function to add many entries
fn add_many_entries(
  c: cache.Cache(String),
  start: Int,
  end: Int,
) -> cache.Cache(String) {
  case start >= end {
    True -> c
    False -> {
      let key = "key_" <> int.to_string(start)
      let value = "value_" <> int.to_string(start)
      let c = cache.set(c, key, value, 3600)
      add_many_entries(c, start + 1, end)
    }
  }
}
