/// Tests for query builder enhancements
///
/// This test suite verifies:
/// 1. Query composition fluent API
/// 2. Query validation layer
/// 3. Query caching integration
/// 4. Filtering DSL
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/query_builders

// ============================================================================
// Query Composition Tests
// ============================================================================

pub fn query_builder_empty_test() {
  // RED: Test that a new query builder starts empty
  let builder = query_builders.new()
  let params = query_builders.build(builder)

  params
  |> should.equal([])
}

pub fn query_builder_with_limit_test() {
  // RED: Test that limit can be added to builder
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_limit(20)
    |> query_builders.build()

  params
  |> should.equal([#("limit", "20")])
}

pub fn query_builder_with_offset_test() {
  // RED: Test that offset can be added to builder
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_offset(10)
    |> query_builders.build()

  params
  |> should.equal([#("offset", "10")])
}

pub fn query_builder_with_pagination_test() {
  // RED: Test that limit and offset can be chained
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_limit(20)
    |> query_builders.with_offset(10)
    |> query_builders.build()

  // Note: Order matters for list equality
  params
  |> should.equal([#("offset", "10"), #("limit", "20")])
}

pub fn query_builder_with_filter_test() {
  // RED: Test that custom filters can be added
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_filter("query", "tomato")
    |> query_builders.build()

  params
  |> should.equal([#("query", "tomato")])
}

pub fn query_builder_with_sort_test() {
  // RED: Test that sorting can be added
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_sort("name", query_builders.Ascending)
    |> query_builders.build()

  params
  |> should.equal([#("ordering", "name")])
}

pub fn query_builder_with_sort_descending_test() {
  // RED: Test descending sort
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_sort("name", query_builders.Descending)
    |> query_builders.build()

  params
  |> should.equal([#("ordering", "-name")])
}

pub fn query_builder_complex_query_test() {
  // RED: Test complex query composition
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_limit(25)
    |> query_builders.with_offset(50)
    |> query_builders.with_filter("query", "pasta")
    |> query_builders.with_sort("created_at", query_builders.Descending)
    |> query_builders.build()

  // Verify all parameters are present
  params
  |> should.equal([
    #("ordering", "-created_at"),
    #("query", "pasta"),
    #("offset", "50"),
    #("limit", "25"),
  ])
}

// ============================================================================
// Query Validation Tests
// ============================================================================

pub fn validate_limit_positive_test() {
  // RED: Test that limit must be positive
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_limit(20)
    |> query_builders.validate()

  result
  |> should.be_ok()
}

pub fn validate_limit_negative_fails_test() {
  // RED: Test that negative limit fails validation
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_limit(-1)
    |> query_builders.validate()

  result
  |> should.be_error()
}

pub fn validate_limit_zero_fails_test() {
  // RED: Test that zero limit fails validation
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_limit(0)
    |> query_builders.validate()

  result
  |> should.be_error()
}

pub fn validate_limit_max_test() {
  // RED: Test that limit cannot exceed 1000
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_limit(1001)
    |> query_builders.validate()

  result
  |> should.be_error()
}

pub fn validate_offset_non_negative_test() {
  // RED: Test that offset can be zero
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_offset(0)
    |> query_builders.validate()

  result
  |> should.be_ok()
}

pub fn validate_offset_negative_fails_test() {
  // RED: Test that negative offset fails validation
  let builder = query_builders.new()
  let result =
    builder
    |> query_builders.with_offset(-10)
    |> query_builders.validate()

  result
  |> should.be_error()
}

pub fn validate_empty_builder_test() {
  // RED: Test that empty builder is valid
  let builder = query_builders.new()
  let result = query_builders.validate(builder)

  result
  |> should.be_ok()
}

// ============================================================================
// Filtering DSL Tests
// ============================================================================

pub fn filter_equals_test() {
  // RED: Test equality filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter("parent", query_builders.Equals(5))
    |> query_builders.build()

  params
  |> should.equal([#("parent", "5")])
}

pub fn filter_contains_test() {
  // RED: Test contains filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter("name", query_builders.Contains("tom"))
    |> query_builders.build()

  params
  |> should.equal([#("name__icontains", "tom")])
}

pub fn filter_greater_than_test() {
  // RED: Test greater than filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter(
      "calories",
      query_builders.GreaterThan(500),
    )
    |> query_builders.build()

  params
  |> should.equal([#("calories__gt", "500")])
}

pub fn filter_less_than_test() {
  // RED: Test less than filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter(
      "prep_time",
      query_builders.LessThan(30),
    )
    |> query_builders.build()

  params
  |> should.equal([#("prep_time__lt", "30")])
}

pub fn filter_range_test() {
  // RED: Test range filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter("servings", query_builders.Range(2, 6))
    |> query_builders.build()

  params
  |> should.equal([#("servings__gte", "2"), #("servings__lte", "6")])
}

pub fn filter_in_list_test() {
  // RED: Test in list filter
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter(
      "cuisine",
      query_builders.InList(["Italian", "Mexican"]),
    )
    |> query_builders.build()

  params
  |> should.equal([#("cuisine__in", "Italian,Mexican")])
}

pub fn filter_multiple_fields_test() {
  // RED: Test multiple field filters
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_field_filter(
      "calories",
      query_builders.LessThan(800),
    )
    |> query_builders.with_field_filter(
      "name",
      query_builders.Contains("chicken"),
    )
    |> query_builders.build()

  params
  |> should.equal([
    #("name__icontains", "chicken"),
    #("calories__lt", "800"),
  ])
}

// ============================================================================
// Query Caching Tests (Integration)
// ============================================================================

pub fn cache_key_generation_test() {
  // RED: Test that cache key is generated from query params
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_limit(20)
    |> query_builders.with_offset(10)
    |> query_builders.build()

  let key = query_builders.cache_key("recipes", params)

  key
  |> should.equal("recipes:limit=20&offset=10")
}

pub fn cache_key_empty_params_test() {
  // RED: Test cache key with no parameters
  let builder = query_builders.new()
  let params = query_builders.build(builder)

  let key = query_builders.cache_key("foods", params)

  key
  |> should.equal("foods:")
}

pub fn cache_key_normalization_test() {
  // RED: Test that cache keys are normalized (sorted)
  let builder = query_builders.new()
  let params =
    builder
    |> query_builders.with_offset(10)
    |> query_builders.with_limit(20)
    |> query_builders.build()

  let key1 = query_builders.cache_key("test", params)

  // Build in different order
  let params2 =
    query_builders.new()
    |> query_builders.with_limit(20)
    |> query_builders.with_offset(10)
    |> query_builders.build()

  let key2 = query_builders.cache_key("test", params2)

  // Keys should be identical regardless of insertion order
  key1
  |> should.equal(key2)
}
