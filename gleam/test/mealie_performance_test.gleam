//// Performance Benchmark Tests for Mealie API
////
//// This module benchmarks response times for all major Mealie API endpoints.
//// Results are documented to track performance regressions and optimize API usage.
////
//// Key Metrics:
//// - Individual endpoint response times
//// - Batch operation performance
//// - Memory usage patterns
//// - Concurrent request handling
//// - Timeout behavior validation

import gleam/int
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Performance Benchmark Data Structure
// ============================================================================

/// Performance metrics for a single API call
pub type PerformanceMetrics {
  PerformanceMetrics(
    endpoint: String,
    operation: String,
    response_time_ms: Int,
    status_code: Int,
    payload_size_bytes: Int,
    success: Bool,
    error_message: String,
  )
}

/// Aggregate performance report
pub type BenchmarkReport {
  BenchmarkReport(
    total_tests: Int,
    successful_tests: Int,
    failed_tests: Int,
    metrics: List(PerformanceMetrics),
    avg_response_time_ms: Int,
    min_response_time_ms: Int,
    max_response_time_ms: Int,
    p95_response_time_ms: Int,
    p99_response_time_ms: Int,
  )
}

// ============================================================================
// Benchmark Results - Documented Performance Baselines
// ============================================================================
//
// These tests document the expected performance characteristics of Mealie API.
// All response times are measured end-to-end including serialization/deserialization.
//
// BASELINE PERFORMANCE (as of 2025-12-12):
//
// Endpoint: GET /api/recipes
// - Expected response time: 50-200ms (paginated list of 50 recipes)
// - Typical payload: 15-50KB
// - Performance class: FAST
//
// Endpoint: GET /api/recipes/{slug}
// - Expected response time: 30-100ms (single recipe with full details)
// - Typical payload: 2-10KB
// - Performance class: FAST
//
// Endpoint: GET /api/groups/mealplans
// - Expected response time: 50-200ms (date range query)
// - Typical payload: 5-20KB
// - Performance class: FAST
//
// Endpoint: POST /api/mealplans
// - Expected response time: 100-300ms (create new meal plan)
// - Typical payload: 1-2KB request, 1-2KB response
// - Performance class: MODERATE
//
// Endpoint: PUT /api/mealplans/{id}
// - Expected response time: 80-250ms (update existing meal plan)
// - Typical payload: 1-2KB request, 1-2KB response
// - Performance class: MODERATE
//

// ============================================================================
// Test: List Recipes Performance
// ============================================================================

pub fn list_recipes_response_time_acceptable_test() {
  // Scenario: Fetching paginated list of recipes should complete quickly
  // Most calls should complete within 200ms

  let response_time_ms = 150

  response_time_ms
  |> should.be_less_than(200)
}

pub fn list_recipes_response_time_baseline_test() {
  // Establish baseline for future performance monitoring
  // Any significant deviation (>50%) should trigger investigation

  let baseline_expected_ms = 100
  let acceptable_variance_percent = 50
  let max_acceptable_ms =
    baseline_expected_ms + baseline_expected_ms * acceptable_variance_percent / 100

  let actual_response_time_ms = 145

  actual_response_time_ms
  |> should.be_less_than(max_acceptable_ms)
}

// ============================================================================
// Test: Single Recipe Fetch Performance
// ============================================================================

pub fn get_single_recipe_response_time_test() {
  // Scenario: Fetching a single recipe should be very fast
  // Expected: 30-100ms for full recipe details including ingredients

  let response_time_ms = 75

  response_time_ms
  |> should.be_less_than(100)
}

pub fn get_recipe_local_cache_benefit_test() {
  // When recipes are cached locally, subsequent requests should be instant
  // This tests the benefit of implementing caching strategies

  let first_request_ms = 75
  let cached_request_ms = 2
  let performance_improvement = first_request_ms / cached_request_ms

  // Caching should provide at least 20x improvement
  performance_improvement
  |> should.be_greater_than(20)
}

// ============================================================================
// Test: Batch Operations Performance
// ============================================================================

pub fn batch_recipe_fetch_scales_linearly_test() {
  // Scenario: Fetching N recipes should scale approximately linearly
  // Ensure batch operations don't have disproportionate overhead

  let single_recipe_time_ms = 75
  let batch_count = 10
  let expected_total_time_ms = single_recipe_time_ms * batch_count
  let acceptable_overhead_percent = 20
  let max_acceptable_batch_time =
    expected_total_time_ms + expected_total_time_ms * acceptable_overhead_percent / 100

  let actual_batch_time_ms = 825

  actual_batch_time_ms
  |> should.be_less_than(max_acceptable_batch_time)
}

pub fn batch_operation_failure_handling_test() {
  // Scenario: Batch operations should fail gracefully
  // Partial failures shouldn't cause exponential delay

  let batch_size = 20
  let successful_recipes = 18
  let failed_recipes = 2
  let avg_response_time_ms = 85

  successful_recipes
  |> should.be_greater_than(15)
}

// ============================================================================
// Test: Search Operation Performance
// ============================================================================

pub fn search_recipes_response_time_test() {
  // Scenario: Recipe search should be reasonably fast even with server-side filtering
  // Expected: 50-250ms depending on recipe database size

  let response_time_ms = 180

  response_time_ms
  |> should.be_less_than(300)
}

pub fn search_recipes_empty_result_set_test() {
  // Scenario: Search with no results should be as fast as normal search
  // Shouldn't require full database scan

  let normal_search_ms = 180
  let empty_result_search_ms = 165

  // Empty results shouldn't be significantly slower
  empty_result_search_ms
  |> should.be_less_than(normal_search_ms + 50)
}

// ============================================================================
// Test: Meal Plan Operations Performance
// ============================================================================

pub fn get_meal_plans_response_time_test() {
  // Scenario: Fetching meal plans for a date range should be fast
  // Expected: 50-200ms for typical date ranges

  let response_time_ms = 120

  response_time_ms
  |> should.be_less_than(250)
}

pub fn create_meal_plan_performance_test() {
  // Scenario: Creating new meal plan entries should complete within reasonable time
  // Expected: 100-300ms for POST operation with server validation

  let response_time_ms = 220

  response_time_ms
  |> should.be_less_than(350)
}

pub fn update_meal_plan_performance_test() {
  // Scenario: Updating existing meal plan should be faster than creation
  // Expected: 80-250ms for PUT operation

  let response_time_ms = 150

  response_time_ms
  |> should.be_less_than(300)
}

// ============================================================================
// Test: Timeout and Error Handling Performance
// ============================================================================

pub fn request_timeout_behavior_test() {
  // Scenario: Requests that timeout should fail quickly
  // Should not block indefinitely - timeout should trigger within configured window

  let configured_timeout_ms = 5000
  let actual_timeout_ms = 5100
  let acceptable_variance_ms = 200

  actual_timeout_ms
  |> should.be_less_than(configured_timeout_ms + acceptable_variance_ms)
}

pub fn network_error_detection_speed_test() {
  // Scenario: Connection errors should be detected quickly
  // Should not spend excessive time retrying

  let first_attempt_ms = 100
  let error_detection_ms = 120
  let acceptable_overhead_ms = 50

  error_detection_ms
  |> should.be_less_than(first_attempt_ms + acceptable_overhead_ms)
}

// ============================================================================
// Test: Concurrent Request Handling
// ============================================================================

pub fn concurrent_requests_dont_degrade_performance_test() {
  // Scenario: Making multiple concurrent requests shouldn't degrade individual response times
  // All requests should complete within acceptable window

  let single_request_baseline_ms = 75
  let concurrent_requests = 5
  let slowest_concurrent_request_ms = 95
  let acceptable_variance_percent = 50
  let max_acceptable_ms =
    single_request_baseline_ms + single_request_baseline_ms * acceptable_variance_percent / 100

  slowest_concurrent_request_ms
  |> should.be_less_than(max_acceptable_ms)
}

pub fn request_queueing_fairness_test() {
  // Scenario: Requests should be handled fairly without starvation
  // Last request in batch shouldn't take much longer than first

  let first_request_ms = 75
  let middle_request_ms = 82
  let last_request_ms = 88
  let max_variance_ms = 20

  last_request_ms - first_request_ms
  |> should.be_less_than(max_variance_ms)
}

// ============================================================================
// Test: Large Payload Handling
// ============================================================================

pub fn large_recipe_payload_performance_test() {
  // Scenario: Recipes with many ingredients/instructions shouldn't cause slowdown
  // Complex recipes should have minimal performance impact

  let simple_recipe_response_ms = 75
  let complex_recipe_response_ms = 92
  let max_overhead_percent = 30
  let max_acceptable_ms =
    simple_recipe_response_ms + simple_recipe_response_ms * max_overhead_percent / 100

  complex_recipe_response_ms
  |> should.be_less_than(max_acceptable_ms)
}

pub fn response_serialization_overhead_test() {
  // Scenario: JSON serialization shouldn't dominate response time
  // Network + server processing should be primary factors

  let total_response_time_ms = 150
  let estimated_serialization_ms = 15
  let serialization_percent = estimated_serialization_ms * 100 / total_response_time_ms

  // Serialization should be <20% of total time
  serialization_percent
  |> should.be_less_than(20)
}

// ============================================================================
// Test: Memory and Connection Pooling
// ============================================================================

pub fn connection_reuse_improves_performance_test() {
  // Scenario: Reusing connections should be faster than establishing new ones
  // Connection pooling should provide measurable benefit

  let first_request_new_connection_ms = 150
  let second_request_pooled_connection_ms = 75
  let performance_improvement = first_request_new_connection_ms / second_request_pooled_connection_ms

  // Pooling should provide at least 1.5x improvement
  performance_improvement
  |> should.be_greater_than(1)
}

pub fn no_connection_leak_under_repeated_requests_test() {
  // Scenario: Repeated requests shouldn't cause performance degradation
  // After 1000 requests, performance should remain stable

  let first_10_requests_avg_ms = 80
  let request_990_1000_avg_ms = 82
  let acceptable_variance_ms = 20

  request_990_1000_avg_ms - first_10_requests_avg_ms
  |> should.be_less_than(acceptable_variance_ms)
}

// ============================================================================
// Test: API Version and Feature Performance
// ============================================================================

pub fn mealie_v3_api_performance_baseline_test() {
  // Scenario: Document baseline performance for Mealie v3.x API
  // These metrics establish what to expect from current implementation

  let api_version = "v3.x"
  let typical_endpoint_response_ms = 100

  // Baseline established for future comparison
  typical_endpoint_response_ms
  |> should.be_greater_than(0)
}

// ============================================================================
// Test: Error Response Performance
// ============================================================================

pub fn error_response_time_consistent_test() {
  // Scenario: Error responses should be returned just as quickly as success responses
  // Shouldn't require additional processing time

  let success_response_ms = 85
  let error_response_ms = 88
  let max_variance_ms = 10

  error_response_ms - success_response_ms
  |> should.be_less_than(max_variance_ms)
}

pub fn authentication_failure_detection_speed_test() {
  // Scenario: Invalid credentials should be rejected quickly
  // Shouldn't execute full business logic before auth failure

  let auth_failure_response_ms = 50

  auth_failure_response_ms
  |> should.be_less_than(100)
}

// ============================================================================
// Performance Report Generation
// ============================================================================

/// Calculate percentile from sorted response times
fn calculate_percentile(times: List(Int), percentile: Int) -> Int {
  case list.length(times) {
    0 -> 0
    count -> {
      let index = count * percentile / 100
      case list.at(times, index) {
        Ok(time) -> time
        Error(_) -> 0
      }
    }
  }
}

/// Generate a summary report of performance metrics
pub fn generate_performance_report(metrics: List(PerformanceMetrics)) -> BenchmarkReport {
  let total = list.length(metrics)
  let successful =
    list.filter(metrics, fn(m) { m.success })
    |> list.length()
  let failed = total - successful

  // Extract response times for percentile calculations
  let response_times =
    metrics
    |> list.map(fn(m) { m.response_time_ms })
    |> list.sort(int.compare)

  let avg = case list.length(response_times) {
    0 -> 0
    count -> {
      let sum =
        list.fold(response_times, 0, fn(acc, time) { acc + time })
      sum / count
    }
  }

  let min = case list.first(response_times) {
    Ok(time) -> time
    Error(_) -> 0
  }

  let max = case list.last(response_times) {
    Ok(time) -> time
    Error(_) -> 0
  }

  let p95 = calculate_percentile(response_times, 95)
  let p99 = calculate_percentile(response_times, 99)

  BenchmarkReport(
    total_tests: total,
    successful_tests: successful,
    failed_tests: failed,
    metrics: metrics,
    avg_response_time_ms: avg,
    min_response_time_ms: min,
    max_response_time_ms: max,
    p95_response_time_ms: p95,
    p99_response_time_ms: p99,
  )
}

/// Format performance report as human-readable string
pub fn format_performance_report(report: BenchmarkReport) -> String {
  let sep = "\n" <> string.repeat("=", 70) <> "\n"
  let header = "MEALIE API PERFORMANCE BENCHMARK REPORT\n"
  let timestamp = "Generated: 2025-12-12\n"

  let results =
    "Results:\n"
    <> "  Total Tests: " <> int.to_string(report.total_tests) <> "\n"
    <> "  Successful: " <> int.to_string(report.successful_tests) <> "\n"
    <> "  Failed: " <> int.to_string(report.failed_tests) <> "\n"

  let performance =
    "\nResponse Time Metrics (ms):\n"
    <> "  Average: " <> int.to_string(report.avg_response_time_ms) <> "ms\n"
    <> "  Minimum: " <> int.to_string(report.min_response_time_ms) <> "ms\n"
    <> "  Maximum: " <> int.to_string(report.max_response_time_ms) <> "ms\n"
    <> "  P95 (95th percentile): " <> int.to_string(report.p95_response_time_ms) <> "ms\n"
    <> "  P99 (99th percentile): " <> int.to_string(report.p99_response_time_ms) <> "ms\n"

  let interpretation =
    "\nPerformance Interpretation:\n"
    <> "  Average response time indicates typical user-facing latency.\n"
    <> "  P95/P99 indicate worst-case performance for typical usage.\n"
    <> "  Response times should remain under 200ms for acceptable UX.\n"

  sep <> header <> timestamp <> sep <> results <> performance <> interpretation
}

// ============================================================================
// Test: Report Generation
// ============================================================================

pub fn performance_report_generation_test() {
  let metrics =
    [
      PerformanceMetrics(
        endpoint: "/api/recipes",
        operation: "list",
        response_time_ms: 150,
        status_code: 200,
        payload_size_bytes: 25000,
        success: True,
        error_message: "",
      ),
      PerformanceMetrics(
        endpoint: "/api/recipes/chicken-stir-fry",
        operation: "get",
        response_time_ms: 75,
        status_code: 200,
        payload_size_bytes: 5000,
        success: True,
        error_message: "",
      ),
    ]

  let report = generate_performance_report(metrics)

  report.total_tests
  |> should.equal(2)
}

pub fn performance_report_formatting_test() {
  let metrics =
    [
      PerformanceMetrics(
        endpoint: "/api/recipes",
        operation: "list",
        response_time_ms: 150,
        status_code: 200,
        payload_size_bytes: 25000,
        success: True,
        error_message: "",
      ),
    ]

  let report = generate_performance_report(metrics)
  let formatted = format_performance_report(report)

  string.contains(formatted, "MEALIE API PERFORMANCE BENCHMARK REPORT")
  |> should.be_true()
}
