import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cache/invalidation

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Basic Operations Tests
// ============================================================================

pub fn new_cache_is_empty_test() {
  let cache = invalidation.new()
  invalidation.is_empty(cache)
  |> should.be_true()
}

pub fn set_and_get_value_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let #(_cache, result) = invalidation.get(cache, "key1")

  result
  |> should.equal(Some("value1"))
}

pub fn get_nonexistent_key_returns_none_test() {
  let cache = invalidation.new()
  let #(_cache, result) = invalidation.get(cache, "missing")

  result
  |> should.equal(None)
}

pub fn set_overwrites_existing_value_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let cache = invalidation.set(cache, "key1", "value2")
  let #(_cache, result) = invalidation.get(cache, "key1")

  result
  |> should.equal(Some("value2"))
}

// ============================================================================
// Invalidation Tests
// ============================================================================

pub fn invalidate_removes_entry_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let cache = invalidation.invalidate(cache, "key1")
  let #(_cache, result) = invalidation.get(cache, "key1")

  result
  |> should.equal(None)
}

pub fn invalidate_nonexistent_key_is_noop_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let cache = invalidation.invalidate(cache, "missing")

  invalidation.size(cache)
  |> should.equal(1)
}

pub fn clear_removes_all_entries_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let cache = invalidation.set(cache, "key2", "value2")
  let cache = invalidation.clear(cache)

  invalidation.is_empty(cache)
  |> should.be_true()
}

// ============================================================================
// Tag-Based Invalidation Tests
// ============================================================================

pub fn set_with_tags_test() {
  let cache = invalidation.new()
  let cache =
    invalidation.set_with_tags(cache, "recipe:1", "Recipe 1", [
      "recipe",
      "user:123",
    ])

  invalidation.has_valid_key(cache, "recipe:1")
  |> should.be_true()
}

pub fn invalidate_by_tag_removes_all_matching_test() {
  let cache = invalidation.new()
  let cache =
    invalidation.set_with_tags(cache, "recipe:1", "Recipe 1", ["recipe"])
  let cache =
    invalidation.set_with_tags(cache, "recipe:2", "Recipe 2", ["recipe"])
  let cache = invalidation.set_with_tags(cache, "user:1", "User 1", ["user"])

  let cache = invalidation.invalidate_by_tag(cache, "recipe")

  // Recipe entries should be gone
  invalidation.has_valid_key(cache, "recipe:1")
  |> should.be_false()

  invalidation.has_valid_key(cache, "recipe:2")
  |> should.be_false()

  // User entry should remain
  invalidation.has_valid_key(cache, "user:1")
  |> should.be_true()
}

pub fn keys_by_tag_returns_matching_keys_test() {
  let cache = invalidation.new()
  let cache =
    invalidation.set_with_tags(cache, "recipe:1", "Recipe 1", ["recipe"])
  let cache =
    invalidation.set_with_tags(cache, "recipe:2", "Recipe 2", ["recipe"])

  let keys = invalidation.keys_by_tag(cache, "recipe")

  should.equal(2, list.length(keys))
}

// ============================================================================
// Prefix-Based Invalidation Tests
// ============================================================================

pub fn invalidate_by_prefix_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "recipe:1", "Recipe 1")
  let cache = invalidation.set(cache, "recipe:2", "Recipe 2")
  let cache = invalidation.set(cache, "user:1", "User 1")

  let cache = invalidation.invalidate_by_prefix(cache, "recipe:")

  // Recipe entries should be gone
  invalidation.has_valid_key(cache, "recipe:1")
  |> should.be_false()

  invalidation.has_valid_key(cache, "recipe:2")
  |> should.be_false()

  // User entry should remain
  invalidation.has_valid_key(cache, "user:1")
  |> should.be_true()
}

// ============================================================================
// Dependency Tracking Tests
// ============================================================================

pub fn set_with_dependencies_test() {
  let cache = invalidation.new()
  // First create the dependency
  let cache = invalidation.set(cache, "recipe:1", "Recipe 1")
  // Then create entry that depends on it
  let cache =
    invalidation.set_with_dependencies(cache, "meal_plan:1", "Meal Plan 1", [
      "recipe:1",
    ])

  let deps = invalidation.get_dependencies(cache, "meal_plan:1")

  should.equal(["recipe:1"], deps)
}

pub fn cascade_invalidation_test() {
  let cache = invalidation.new()
  // Create base entry
  let cache = invalidation.set(cache, "recipe:1", "Recipe 1")
  // Create dependent entry
  let cache =
    invalidation.set_with_dependencies(cache, "meal_plan:1", "Meal Plan 1", [
      "recipe:1",
    ])

  // Cascade invalidate the recipe
  let cache = invalidation.invalidate_cascade(cache, "recipe:1")

  // Both should be gone
  invalidation.has_valid_key(cache, "recipe:1")
  |> should.be_false()

  invalidation.has_valid_key(cache, "meal_plan:1")
  |> should.be_false()
}

// ============================================================================
// Utility Function Tests
// ============================================================================

pub fn make_key_joins_parts_test() {
  let key = invalidation.make_key(["recipe", "123", "nutrition"])
  should.equal("recipe:123:nutrition", key)
}

pub fn recipe_tag_formats_correctly_test() {
  invalidation.recipe_tag("123")
  |> should.equal("recipe:123")
}

pub fn user_tag_formats_correctly_test() {
  invalidation.user_tag("456")
  |> should.equal("user:456")
}

pub fn meal_plan_tag_formats_correctly_test() {
  invalidation.meal_plan_tag("789")
  |> should.equal("meal_plan:789")
}

pub fn date_tag_formats_correctly_test() {
  invalidation.date_tag("2025-01-15")
  |> should.equal("date:2025-01-15")
}

// ============================================================================
// Statistics Tests
// ============================================================================

pub fn size_reflects_entry_count_test() {
  let cache = invalidation.new()
  let cache = invalidation.set(cache, "key1", "value1")
  let cache = invalidation.set(cache, "key2", "value2")
  let cache = invalidation.set(cache, "key3", "value3")

  invalidation.size(cache)
  |> should.equal(3)
}

pub fn stats_returns_correct_counts_test() {
  let cache = invalidation.new()
  let cache = invalidation.set_with_tags(cache, "key1", "value1", ["tag1"])
  let cache = invalidation.set_with_tags(cache, "key2", "value2", ["tag2"])

  let stats = invalidation.stats(cache)

  stats.total_entries
  |> should.equal(2)
}
