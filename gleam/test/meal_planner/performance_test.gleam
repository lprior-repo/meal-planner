/// Tests for performance monitoring and metrics collection
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/performance
import meal_planner/query_cache

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Performance Metrics Tests
// ============================================================================

pub fn calculate_hit_rate_test() {
  // 75% hit rate
  performance.calculate_hit_rate(75, 100)
  |> should.equal(0.75)

  // 100% hit rate
  performance.calculate_hit_rate(100, 100)
  |> should.equal(1.0)

  // 0% hit rate
  performance.calculate_hit_rate(0, 100)
  |> should.equal(0.0)

  // Handle division by zero
  performance.calculate_hit_rate(0, 0)
  |> should.equal(0.0)
}

pub fn calculate_time_saved_test() {
  // Cached queries are 10ms, uncached are 100ms, 50 cache hits
  // Time saved = (100 - 10) * 50 = 4500ms
  performance.calculate_time_saved(10.0, 100.0, 50)
  |> should.equal(4500.0)

  // No cache hits
  performance.calculate_time_saved(10.0, 100.0, 0)
  |> should.equal(0.0)

  // Negative time saved (shouldn't happen but test edge case)
  performance.calculate_time_saved(100.0, 50.0, 10)
  |> should.equal(-500.0)
}

pub fn calculate_db_load_reduction_test() {
  // 50% cache hit rate = 50% DB load reduction
  performance.calculate_db_load_reduction(50, 100)
  |> should.equal(50.0)

  // 75% cache hit rate = 75% DB load reduction
  performance.calculate_db_load_reduction(75, 100)
  |> should.equal(75.0)

  // 0% cache hit rate = 0% DB load reduction
  performance.calculate_db_load_reduction(0, 100)
  |> should.equal(0.0)
}

pub fn generate_performance_report_test() {
  let cache_stats =
    query_cache.CacheStats(
      size: 25,
      max_size: 100,
      hits: 75,
      misses: 25,
      hit_rate: 0.75,
      evictions: 0,
    )

  let metrics =
    performance.generate_performance_report(cache_stats, 10.0, 100.0)

  metrics.query_name |> should.equal("search_foods")
  metrics.total_queries |> should.equal(100)
  metrics.cache_hits |> should.equal(75)
  metrics.cache_misses |> should.equal(25)
  metrics.avg_cached_time_ms |> should.equal(10.0)
  metrics.avg_uncached_time_ms |> should.equal(100.0)
  metrics.total_time_saved_ms |> should.equal(6750.0)
  metrics.db_load_reduction_percent |> should.equal(75.0)
}

// ============================================================================
// Benchmark Tests
// ============================================================================

pub fn benchmark_test() {
  // Simple test function that returns Ok
  let test_fn = fn() { Ok(42) }

  let result = performance.benchmark("test_operation", 10, test_fn)

  result.test_name |> should.equal("test_operation")
  result.iterations |> should.equal(10)
  // Response time should be positive
  result.avg_time_ms |> should.not_equal(0.0)
  result.queries_per_second |> should.not_equal(0.0)
}

pub fn compare_performance_test() {
  let before =
    performance.BenchmarkResult(
      test_name: "before",
      iterations: 100,
      avg_time_ms: 100.0,
      min_time_ms: 90.0,
      max_time_ms: 110.0,
      queries_per_second: 10.0,
    )

  let after =
    performance.BenchmarkResult(
      test_name: "after",
      iterations: 100,
      avg_time_ms: 10.0,
      min_time_ms: 9.0,
      max_time_ms: 11.0,
      queries_per_second: 100.0,
    )

  // 10x speedup
  performance.compare_performance(before, after)
  |> should.equal(10.0)
}

pub fn format_improvement_test() {
  // 10x speedup = 900% faster
  performance.format_improvement(10.0)
  |> should.equal("900.0% faster")

  // 2x speedup = 100% faster
  performance.format_improvement(2.0)
  |> should.equal("100.0% faster")

  // No improvement
  performance.format_improvement(1.0)
  |> should.equal("0.0% faster")
}

pub fn format_db_reduction_test() {
  performance.format_db_reduction(50.0)
  |> should.equal("50.0% DB load reduction")

  performance.format_db_reduction(75.5)
  |> should.equal("75.5% DB load reduction")
}

// ============================================================================
// Real-time Performance Tracking Tests
// ============================================================================

pub fn new_tracker_test() {
  let tracker = performance.new_tracker()

  tracker.dashboard_load_times |> should.equal([])
  tracker.search_latencies |> should.equal([])
  tracker.db_query_counts |> should.equal([])
  tracker.cache_hit_counts |> should.equal(0)
  tracker.cache_miss_counts |> should.equal(0)
  // start_time should be set to current timestamp
  tracker.start_time |> should.not_equal(0)
}

pub fn start_request_test() {
  let ctx = performance.start_request("dashboard")

  ctx.endpoint |> should.equal("dashboard")
  ctx.db_queries |> should.equal(0)
  ctx.start_time |> should.not_equal(0)
  // request_id should be generated
  ctx.request_id
  |> should.not_equal("")
}

pub fn record_cache_hit_test() {
  let tracker = performance.new_tracker()

  let updated = performance.record_cache_hit(tracker)

  updated.cache_hit_counts |> should.equal(1)
  updated.cache_miss_counts |> should.equal(0)

  // Record multiple hits
  let updated2 = performance.record_cache_hit(updated)
  updated2.cache_hit_counts |> should.equal(2)
}

pub fn record_cache_miss_test() {
  let tracker = performance.new_tracker()

  let updated = performance.record_cache_miss(tracker)

  updated.cache_hit_counts |> should.equal(0)
  updated.cache_miss_counts |> should.equal(1)

  // Record multiple misses
  let updated2 = performance.record_cache_miss(updated)
  updated2.cache_miss_counts |> should.equal(2)
}

pub fn record_db_query_test() {
  let ctx = performance.start_request("dashboard")

  let updated = performance.record_db_query(ctx)
  updated.db_queries |> should.equal(1)

  let updated2 = performance.record_db_query(updated)
  updated2.db_queries |> should.equal(2)
}

pub fn get_cache_hit_rate_test() {
  let tracker = performance.new_tracker()

  // No hits or misses = 0% hit rate
  performance.get_cache_hit_rate(tracker)
  |> should.equal(0.0)

  // 75 hits, 25 misses = 75% hit rate
  let tracker_with_data =
    performance.PerformanceTracker(
      ..tracker,
      cache_hit_counts: 75,
      cache_miss_counts: 25,
    )

  performance.get_cache_hit_rate(tracker_with_data)
  |> should.equal(0.75)
}

pub fn end_request_dashboard_test() {
  let tracker = performance.new_tracker()
  let ctx = performance.start_request("dashboard")

  // Simulate some DB queries
  let ctx_with_queries =
    performance.record_db_query(ctx)
    |> performance.record_db_query()

  let updated_tracker = performance.end_request(ctx_with_queries, tracker)

  // Should record dashboard load time
  list.length(updated_tracker.dashboard_load_times) |> should.equal(1)
  // Should record DB query count
  list.length(updated_tracker.db_query_counts) |> should.equal(1)
  // DB query count should be 2
  case updated_tracker.db_query_counts {
    [count, ..] -> count |> should.equal(2)
    [] -> should.fail()
  }
}

pub fn end_request_search_test() {
  let tracker = performance.new_tracker()
  let ctx = performance.start_request("search")

  let updated_tracker = performance.end_request(ctx, tracker)

  // Should record search latency
  list.length(updated_tracker.search_latencies) |> should.equal(1)
  // Should record DB query count
  list.length(updated_tracker.db_query_counts) |> should.equal(1)
}

pub fn get_dashboard_metrics_test() {
  let tracker =
    performance.PerformanceTracker(
      dashboard_load_times: [100.0, 150.0, 200.0],
      search_latencies: [],
      db_query_counts: [2, 3, 2],
      cache_hit_counts: 10,
      cache_miss_counts: 5,
      start_time: 0,
    )

  let metrics = performance.get_dashboard_metrics(tracker)

  metrics.endpoint |> should.equal("dashboard")
  metrics.total_requests |> should.equal(3)
  // Avg = (100 + 150 + 200) / 3 = 150
  metrics.avg_response_time_ms |> should.equal(150.0)
  // Avg DB queries = (2 + 3 + 2) / 3 = 2.33...
  metrics.db_queries_per_request
  |> should.not_equal(0.0)
}

pub fn get_search_metrics_test() {
  let tracker =
    performance.PerformanceTracker(
      dashboard_load_times: [],
      search_latencies: [50.0, 75.0, 100.0, 125.0],
      db_query_counts: [1, 1, 2, 1],
      cache_hit_counts: 8,
      cache_miss_counts: 2,
      start_time: 0,
    )

  let metrics = performance.get_search_metrics(tracker)

  metrics.endpoint |> should.equal("search")
  metrics.total_requests |> should.equal(4)
  // Avg = (50 + 75 + 100 + 125) / 4 = 87.5
  metrics.avg_response_time_ms |> should.equal(87.5)
}

// ============================================================================
// Phase 2 Verification Tests
// ============================================================================

pub fn verify_phase2_target_success_test() {
  // Create cache stats with >50% hit rate
  let cache_stats =
    query_cache.CacheStats(
      size: 50,
      max_size: 100,
      hits: 60,
      misses: 40,
      hit_rate: 0.6,
      evictions: 0,
    )

  // Should succeed with 60% > 50% target
  performance.verify_phase2_target(cache_stats)
  |> should.be_ok()
}

pub fn verify_phase2_target_failure_test() {
  // Create cache stats with <50% hit rate
  let cache_stats =
    query_cache.CacheStats(
      size: 30,
      max_size: 100,
      hits: 30,
      misses: 70,
      hit_rate: 0.3,
      evictions: 0,
    )

  // Should fail with 30% < 50% target
  performance.verify_phase2_target(cache_stats)
  |> should.be_error()
}

pub fn generate_phase2_report_test() {
  let cache_stats =
    query_cache.CacheStats(
      size: 50,
      max_size: 100,
      hits: 75,
      misses: 25,
      hit_rate: 0.75,
      evictions: 0,
    )

  let before =
    performance.BenchmarkResult(
      test_name: "before_optimization",
      iterations: 100,
      avg_time_ms: 100.0,
      min_time_ms: 90.0,
      max_time_ms: 110.0,
      queries_per_second: 10.0,
    )

  let after =
    performance.BenchmarkResult(
      test_name: "after_optimization",
      iterations: 100,
      avg_time_ms: 10.0,
      min_time_ms: 9.0,
      max_time_ms: 11.0,
      queries_per_second: 100.0,
    )

  let report = performance.generate_phase2_report(cache_stats, before, after)

  // Report should contain key metrics
  report
  |> should.not_equal("")

  // Should mention Phase 2
  should_match(report, "Phase 2")

  // Should show achieved target (75% > 50%)
  should_match(report, "ACHIEVED")
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn empty_tracker_metrics_test() {
  let tracker = performance.new_tracker()

  let dash_metrics = performance.get_dashboard_metrics(tracker)
  dash_metrics.total_requests |> should.equal(0)
  dash_metrics.avg_response_time_ms |> should.equal(0.0)

  let search_metrics = performance.get_search_metrics(tracker)
  search_metrics.total_requests |> should.equal(0)
  search_metrics.avg_response_time_ms |> should.equal(0.0)
}

pub fn multiple_requests_test() {
  let tracker = performance.new_tracker()

  // Simulate 5 dashboard requests
  let ctx1 = performance.start_request("dashboard")
  let tracker = performance.end_request(ctx1, tracker)

  let ctx2 = performance.start_request("dashboard")
  let tracker = performance.end_request(ctx2, tracker)

  let ctx3 = performance.start_request("dashboard")
  let tracker = performance.end_request(ctx3, tracker)

  // Simulate 3 search requests
  let ctx4 = performance.start_request("search")
  let tracker = performance.end_request(ctx4, tracker)

  let ctx5 = performance.start_request("search")
  let tracker = performance.end_request(ctx5, tracker)

  // Verify counts
  list.length(tracker.dashboard_load_times) |> should.equal(3)
  list.length(tracker.search_latencies) |> should.equal(2)
  list.length(tracker.db_query_counts) |> should.equal(5)
}

// Helper function to check if a string contains a substring
fn should_match(haystack: String, needle: String) {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> should.fail()
  }
}
