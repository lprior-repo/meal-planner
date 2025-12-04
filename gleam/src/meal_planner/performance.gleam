/// Performance monitoring and benchmarking utilities
/// Tracks query execution times and cache performance
/// Target: Monitor 50% DB load reduction in Phase 2

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import meal_planner/query_cache
import meal_planner/storage
import meal_planner/storage_optimized

// ============================================================================
// Performance Tracking Types
// ============================================================================

pub type PerformanceMetrics {
  PerformanceMetrics(
    query_name: String,
    total_queries: Int,
    cache_hits: Int,
    cache_misses: Int,
    avg_cached_time_ms: Float,
    avg_uncached_time_ms: Float,
    total_time_saved_ms: Float,
    db_load_reduction_percent: Float,
  )
}

pub type BenchmarkResult {
  BenchmarkResult(
    test_name: String,
    iterations: Int,
    avg_time_ms: Float,
    min_time_ms: Float,
    max_time_ms: Float,
    queries_per_second: Float,
  )
}

// ============================================================================
// Performance Monitoring
// ============================================================================

/// Calculate cache hit rate
pub fn calculate_hit_rate(hits: Int, total: Int) -> Float {
  case total > 0 {
    True -> int.to_float(hits) /. int.to_float(total)
    False -> 0.0
  }
}

/// Calculate time saved by caching
pub fn calculate_time_saved(
  cached_time_ms: Float,
  uncached_time_ms: Float,
  cache_hits: Int,
) -> Float {
  let time_per_hit = uncached_time_ms -. cached_time_ms
  time_per_hit *. int.to_float(cache_hits)
}

/// Calculate DB load reduction percentage
pub fn calculate_db_load_reduction(
  cache_hits: Int,
  total_queries: Int,
) -> Float {
  let hit_rate = calculate_hit_rate(cache_hits, total_queries)
  // Each cache hit eliminates a DB query, so hit_rate = load reduction
  hit_rate *. 100.0
}

/// Generate performance report
pub fn generate_performance_report(
  cache_stats: query_cache.CacheStats,
  avg_cached_time: Float,
  avg_uncached_time: Float,
) -> PerformanceMetrics {
  let total = cache_stats.hits + cache_stats.misses
  let time_saved =
    calculate_time_saved(avg_cached_time, avg_uncached_time, cache_stats.hits)
  let db_reduction = calculate_db_load_reduction(cache_stats.hits, total)

  PerformanceMetrics(
    query_name: "search_foods",
    total_queries: total,
    cache_hits: cache_stats.hits,
    cache_misses: cache_stats.misses,
    avg_cached_time_ms: avg_cached_time,
    avg_uncached_time_ms: avg_uncached_time,
    total_time_saved_ms: time_saved,
    db_load_reduction_percent: db_reduction,
  )
}

// ============================================================================
// Benchmarking
// ============================================================================

/// Run a benchmark test
pub fn benchmark(
  test_name: String,
  iterations: Int,
  test_fn: fn() -> Result(a, b),
) -> BenchmarkResult {
  let start_time = get_timestamp_ms()
  let results = run_iterations(iterations, test_fn, [])
  let end_time = get_timestamp_ms()

  let total_time = int.to_float(end_time - start_time)
  let avg_time = total_time /. int.to_float(iterations)
  let queries_per_second = 1000.0 /. avg_time

  BenchmarkResult(
    test_name: test_name,
    iterations: iterations,
    avg_time_ms: avg_time,
    min_time_ms: avg_time,
    max_time_ms: avg_time,
    queries_per_second: queries_per_second,
  )
}

/// Run benchmark iterations
fn run_iterations(
  remaining: Int,
  test_fn: fn() -> Result(a, b),
  _results: List(Result(a, b)),
) -> List(Result(a, b)) {
  case remaining {
    0 -> []
    n -> {
      let result = test_fn()
      [result, ..run_iterations(n - 1, test_fn, [])]
    }
  }
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  // Convert to milliseconds
  get_timestamp() / 1_000_000
}

// ============================================================================
// Performance Comparison
// ============================================================================

/// Compare performance before and after optimization
pub fn compare_performance(
  before: BenchmarkResult,
  after: BenchmarkResult,
) -> Float {
  case after.avg_time_ms > 0.0 {
    True -> before.avg_time_ms /. after.avg_time_ms
    False -> 1.0
  }
}

/// Format performance improvement as percentage
pub fn format_improvement(speedup_factor: Float) -> String {
  let percent = { speedup_factor -. 1.0 } *. 100.0
  let percent_str = float.to_string(percent)
  percent_str <> "% faster"
}

/// Format DB load reduction
pub fn format_db_reduction(reduction_percent: Float) -> String {
  let percent_str = float.to_string(reduction_percent)
  percent_str <> "% DB load reduction"
}

// ============================================================================
// Reporting
// ============================================================================

/// Print performance metrics to console
pub fn print_metrics(metrics: PerformanceMetrics) -> Nil {
  io.println("\n=== Performance Metrics ===")
  io.println("Query: " <> metrics.query_name)
  io.println("Total Queries: " <> int.to_string(metrics.total_queries))
  io.println("Cache Hits: " <> int.to_string(metrics.cache_hits))
  io.println("Cache Misses: " <> int.to_string(metrics.cache_misses))
  io.println(
    "Hit Rate: "
    <> float.to_string(
      calculate_hit_rate(metrics.cache_hits, metrics.total_queries) *. 100.0,
    )
    <> "%",
  )
  io.println(
    "Avg Cached Time: " <> float.to_string(metrics.avg_cached_time_ms) <> "ms",
  )
  io.println(
    "Avg Uncached Time: "
    <> float.to_string(metrics.avg_uncached_time_ms)
    <> "ms",
  )
  io.println(
    "Total Time Saved: "
    <> float.to_string(metrics.total_time_saved_ms)
    <> "ms",
  )
  io.println(
    "DB Load Reduction: "
    <> float.to_string(metrics.db_load_reduction_percent)
    <> "%",
  )
  io.println("========================\n")
}

/// Print benchmark results
pub fn print_benchmark(result: BenchmarkResult) -> Nil {
  io.println("\n=== Benchmark Results ===")
  io.println("Test: " <> result.test_name)
  io.println("Iterations: " <> int.to_string(result.iterations))
  io.println("Avg Time: " <> float.to_string(result.avg_time_ms) <> "ms")
  io.println(
    "Queries/sec: " <> float.to_string(result.queries_per_second),
  )
  io.println("========================\n")
}

/// Print performance comparison
pub fn print_comparison(
  before: BenchmarkResult,
  after: BenchmarkResult,
) -> Nil {
  let speedup = compare_performance(before, after)
  let improvement = format_improvement(speedup)

  io.println("\n=== Performance Comparison ===")
  io.println("Before: " <> float.to_string(before.avg_time_ms) <> "ms")
  io.println("After: " <> float.to_string(after.avg_time_ms) <> "ms")
  io.println("Speedup: " <> float.to_string(speedup) <> "x")
  io.println("Improvement: " <> improvement)
  io.println("=============================\n")
}

// ============================================================================
// Phase 2 Verification
// ============================================================================

/// Verify Phase 2 performance targets
/// Target: 50% DB load reduction
pub fn verify_phase2_target(
  cache_stats: query_cache.CacheStats,
) -> Result(Nil, String) {
  let db_reduction =
    calculate_db_load_reduction(
      cache_stats.hits,
      cache_stats.hits + cache_stats.misses,
    )

  case db_reduction >= 50.0 {
    True -> {
      io.println(
        "✓ Phase 2 target achieved: "
        <> format_db_reduction(db_reduction),
      )
      Ok(Nil)
    }
    False -> {
      io.println(
        "✗ Phase 2 target not met: "
        <> format_db_reduction(db_reduction)
        <> " (need 50%)",
      )
      Error("DB load reduction below 50% target")
    }
  }
}

/// Generate comprehensive Phase 2 report
pub fn generate_phase2_report(
  cache_stats: query_cache.CacheStats,
  before_benchmark: BenchmarkResult,
  after_benchmark: BenchmarkResult,
) -> String {
  let speedup = compare_performance(before_benchmark, after_benchmark)
  let db_reduction =
    calculate_db_load_reduction(
      cache_stats.hits,
      cache_stats.hits + cache_stats.misses,
    )

  let report =
    string.concat([
      "\n",
      "╔════════════════════════════════════════════════════════════╗\n",
      "║         Phase 2: Database Query Optimization              ║\n",
      "╠════════════════════════════════════════════════════════════╣\n",
      "║ PERFORMANCE IMPROVEMENTS:                                  ║\n",
      "║                                                            ║\n",
      "║ Query Speedup:        ",
      string.pad_left(float.to_string(speedup), 10, " "),
      "x                   ║\n",
      "║ DB Load Reduction:    ",
      string.pad_left(float.to_string(db_reduction), 10, " "),
      "%                  ║\n",
      "║ Cache Hit Rate:       ",
      string.pad_left(
        float.to_string(cache_stats.hit_rate *. 100.0),
        10,
        " ",
      ),
      "%                  ║\n",
      "║                                                            ║\n",
      "║ OPTIMIZATIONS APPLIED:                                     ║\n",
      "║ ✓ Covering indexes for food_logs queries                  ║\n",
      "║ ✓ Partial indexes for search filtering                    ║\n",
      "║ ✓ LRU cache for popular search queries                    ║\n",
      "║ ✓ Query plan optimization with index hints                ║\n",
      "║ ✓ Performance monitoring and metrics                       ║\n",
      "║                                                            ║\n",
      "║ TARGET STATUS:                                             ║\n",
      "║ ",
      case db_reduction >= 50.0 {
        True -> "✓ ACHIEVED: 50% DB load reduction target          "
        False -> "✗ NOT MET: Below 50% target                       "
      },
      "║\n",
      "╚════════════════════════════════════════════════════════════╝\n",
      "\n",
    ])

  report
}
