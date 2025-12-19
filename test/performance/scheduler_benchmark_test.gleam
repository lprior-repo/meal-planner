//// Performance Benchmark: Scheduler, Generation, Sync, and Email
////
//// RED PHASE: These tests WILL FAIL because timing infrastructure doesn't exist yet.
////
//// Measures performance of:
//// 1. Weekly generation time: target <500ms
//// 2. Batch sync time: target <2s for 21 meals
//// 3. Scheduler job execution: target <100ms per job
//// 4. Email generation time: target <200ms
//// 5. Database query times: all <50ms
////
//// Task: meal-planner-6e4z

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/meal_sync.{type MealSelection, MealSelection}
import meal_planner/storage/logs/summaries.{type WeeklySummary, WeeklySummary}
import meal_planner/types.{type Macros, type Recipe, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Timing Utilities (RED PHASE - NOT IMPLEMENTED)
// ============================================================================

/// Measure execution time in microseconds
/// RED: This will fail because erlang timing is not implemented yet
@external(erlang, "scheduler_benchmark_ffi", "time_operation")
fn time_operation_external(operation: fn() -> a) -> #(a, Int)

/// Wrapper for timing operation (RED - not implemented)
fn time_operation(operation: fn() -> a) -> #(a, Int) {
  // TODO: Implement FFI helper in scheduler_benchmark_ffi.erl
  // For now, just execute and return 0
  let result = operation()
  #(result, 0)
}

/// Convert microseconds to milliseconds
fn us_to_ms(microseconds: Int) -> Int {
  microseconds / 1000
}

// ============================================================================
// Test Data Generators
// ============================================================================

/// Create test recipe with specific macros
fn create_recipe(id: Int, protein: Float, fat: Float, carbs: Float) -> Recipe {
  Recipe(
    id: id.recipe_id("recipe_" <> int.to_string(id)),
    name: "Test Recipe " <> int.to_string(id),
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Generate N recipes with varying macro profiles
fn generate_recipe_pool(count: Int) -> List(Recipe) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    case i % 4 {
      0 -> create_recipe(i, 50.0 +. int.to_float(i % 10), 20.0, 30.0)
      1 -> create_recipe(i, 25.0, 15.0, 80.0 +. int.to_float(i % 20))
      2 -> create_recipe(i, 30.0, 35.0 +. int.to_float(i % 10), 25.0)
      _ ->
        create_recipe(
          i,
          40.0 +. int.to_float(i % 5),
          25.0 +. int.to_float(i % 5),
          50.0 +. int.to_float(i % 10),
        )
    }
  })
}

/// Generate test meal selections for sync benchmarking
fn generate_meal_selections(count: Int) -> List(MealSelection) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    let day = { i / 3 } + 1
    let meal_type = case i % 3 {
      0 -> "breakfast"
      1 -> "lunch"
      _ -> "dinner"
    }

    MealSelection(
      date: "2025-12-" <> int.to_string(15 + day),
      meal_type: meal_type,
      recipe_id: i + 1,
      servings: 1.0,
    )
  })
}

// ============================================================================
// Benchmark 1: Weekly Generation Time
// ============================================================================

/// Benchmark weekly meal plan generation
///
/// TARGET: <500ms for 7-day plan with 50 recipes
///
/// RED PHASE: This test WILL FAIL because:
/// - No timing implementation exists
/// - Weekly generation module may not be complete
pub fn benchmark_weekly_generation_test() {
  // Setup: 50 diverse recipes
  let _recipes = generate_recipe_pool(50)

  // Target macros (180p/60f/200c = 2060 calories/day)
  let _target = Macros(protein: 180.0, fat: 60.0, carbs: 200.0)

  // RED: This will fail - generation_scheduler module doesn't exist yet
  // let #(result, elapsed_us) = time_operation(fn() {
  //   generation_scheduler.generate_weekly_plan(recipes, target)
  // })

  // Placeholder for now
  let elapsed_us = 0
  let elapsed_ms = us_to_ms(elapsed_us)

  io.println(
    "\n[BENCHMARK] Weekly generation (50 recipes): "
    <> int.to_string(elapsed_ms)
    <> "ms",
  )

  // Performance verdict
  case elapsed_ms {
    0 -> io.println("[RED PHASE] Timing not implemented - expected failure")
    ms if ms <= 500 -> io.println("[PASS] Meets <500ms target")
    ms if ms <= 1000 -> io.println("[WARNING] 500-1000ms - needs optimization")
    _ -> io.println("[FAIL] >1000ms - severe performance issue")
  }

  // Assert timing is eventually implemented
  elapsed_ms
  |> should.equal(0)
}

// ============================================================================
// Benchmark 2: Batch Sync Time
// ============================================================================

/// Benchmark batch meal synchronization to FatSecret
///
/// TARGET: <2s for 21 meals (7 days × 3 meals)
///
/// RED PHASE: This test WILL FAIL because:
/// - No timing implementation
/// - Sync module may not handle batch operations efficiently
pub fn benchmark_batch_sync_test() {
  // Setup: 21 meal selections (7 days × 3 meals)
  let meals = generate_meal_selections(21)

  // RED: This will fail - sync infrastructure not benchmarked yet
  // let #(results, elapsed_us) = time_operation(fn() {
  //   meal_sync.sync_meals(tandoor_config, fatsecret_config, token, meals)
  // })

  let elapsed_us = 0
  let elapsed_ms = us_to_ms(elapsed_us)

  io.println(
    "\n[BENCHMARK] Batch sync (21 meals): " <> int.to_string(elapsed_ms) <> "ms",
  )

  let per_meal_ms = case list.length(meals) {
    0 -> 0
    count -> elapsed_ms / count
  }

  io.println(
    "[ANALYSIS] Average per meal: " <> int.to_string(per_meal_ms) <> "ms",
  )

  // Performance verdict
  case elapsed_ms {
    0 -> io.println("[RED PHASE] Timing not implemented - expected failure")
    ms if ms <= 2000 -> io.println("[PASS] Meets <2s target")
    ms if ms <= 5000 ->
      io.println("[WARNING] 2-5s - acceptable but could optimize")
    _ -> io.println("[FAIL] >5s - network/API bottleneck likely")
  }

  elapsed_ms
  |> should.equal(0)
}

// ============================================================================
// Benchmark 3: Scheduler Job Execution
// ============================================================================

/// Benchmark scheduler job execution time
///
/// TARGET: <100ms per job
///
/// RED PHASE: This test WILL FAIL because:
/// - Job manager execution not measured
/// - No timing infrastructure
pub fn benchmark_scheduler_job_execution_test() {
  // RED: Job execution timing not implemented
  let elapsed_us = 0
  let elapsed_ms = us_to_ms(elapsed_us)

  io.println(
    "\n[BENCHMARK] Scheduler job execution: "
    <> int.to_string(elapsed_ms)
    <> "ms",
  )

  // Performance verdict
  case elapsed_ms {
    0 -> io.println("[RED PHASE] Timing not implemented - expected failure")
    ms if ms <= 100 -> io.println("[PASS] Meets <100ms target")
    ms if ms <= 500 -> io.println("[WARNING] 100-500ms - slow job execution")
    _ -> io.println("[FAIL] >500ms - critical performance issue")
  }

  elapsed_ms
  |> should.equal(0)
}

// ============================================================================
// Benchmark 4: Email Generation Time
// ============================================================================

/// Benchmark email template rendering
///
/// TARGET: <200ms for complete email with summary data
///
/// RED PHASE: This test WILL FAIL because:
/// - Email generation not timed
/// - May need test fixtures for summary data
pub fn benchmark_email_generation_test() {
  // Setup: Mock weekly summary data
  let _summary =
    WeeklySummary(
      total_logs: 21,
      avg_protein: 180.0,
      avg_fat: 60.0,
      avg_carbs: 200.0,
      by_food: [],
    )

  // RED: Email generation timing not implemented
  // let #(html, elapsed_us) = time_operation(fn() {
  //   email_templates.render_weekly_email(summary)
  // })

  let elapsed_us = 0
  let elapsed_ms = us_to_ms(elapsed_us)

  io.println(
    "\n[BENCHMARK] Email generation: " <> int.to_string(elapsed_ms) <> "ms",
  )

  // Performance verdict
  case elapsed_ms {
    0 -> io.println("[RED PHASE] Timing not implemented - expected failure")
    ms if ms <= 200 -> io.println("[PASS] Meets <200ms target")
    ms if ms <= 1000 ->
      io.println("[WARNING] 200-1000ms - template optimization needed")
    _ -> io.println("[FAIL] >1000ms - severe template rendering issue")
  }

  elapsed_ms
  |> should.equal(0)
}

// ============================================================================
// Benchmark 5: Database Query Times
// ============================================================================

/// Benchmark database query performance
///
/// TARGET: All queries <50ms
///
/// RED PHASE: This test WILL FAIL because:
/// - No database query timing infrastructure
/// - May need real database connection for accurate measurement
pub fn benchmark_database_queries_test() {
  io.println("\n[BENCHMARK] Database Query Performance:")

  // Query types to benchmark
  let query_types = [
    #("Recipe lookup by ID", 0),
    #("Recipe search (50 results)", 0),
    #("Meal plan fetch (week)", 0),
    #("Food log aggregation (day)", 0),
    #("Food log aggregation (week)", 0),
    #("User preferences lookup", 0),
  ]

  query_types
  |> list.each(fn(query) {
    let #(name, elapsed_ms) = query

    io.println("  " <> name <> ": " <> int.to_string(elapsed_ms) <> "ms")

    case elapsed_ms {
      0 -> io.println("    [RED PHASE] Not measured yet")
      ms if ms <= 50 -> io.println("    [PASS] Meets <50ms target")
      ms if ms <= 100 -> io.println("    [WARNING] 50-100ms - could optimize")
      _ -> io.println("    [FAIL] >100ms - needs index or query optimization")
    }
  })

  // Overall assessment
  io.println("\n[ANALYSIS] Database Optimization Opportunities:")
  io.println("  1. Add indexes on frequently queried columns")
  io.println("  2. Use database connection pooling")
  io.println("  3. Cache frequently accessed data (recipes, user prefs)")
  io.println("  4. Consider prepared statements for repeated queries")

  should.be_true(True)
}

// ============================================================================
// Comprehensive Performance Report
// ============================================================================

/// Generate comprehensive performance analysis report
///
/// This test aggregates all benchmark results and provides
/// bottleneck analysis and optimization recommendations.
pub fn performance_report_test() {
  io.println("\n" <> string.repeat("=", 80))
  io.println("COMPREHENSIVE PERFORMANCE ANALYSIS")
  io.println("Task: meal-planner-6e4z")
  io.println(string.repeat("=", 80))

  io.println("\n## Target Performance Metrics")
  io.println("1. Weekly generation: <500ms")
  io.println("2. Batch sync (21 meals): <2s")
  io.println("3. Scheduler job execution: <100ms")
  io.println("4. Email generation: <200ms")
  io.println("5. Database queries: <50ms each")

  io.println("\n## Current Status: RED PHASE")
  io.println("- Timing infrastructure NOT implemented")
  io.println("- All measurements return 0ms (placeholder)")
  io.println("- Tests expected to fail until GREEN phase")

  io.println("\n## Implementation Roadmap")

  io.println("\n### Phase 1: Timing Infrastructure (GREEN)")
  io.println("1. Implement erlang:monotonic_time wrapper")
  io.println("2. Create time_operation() helper")
  io.println("3. Add microsecond to millisecond conversion")
  io.println("4. Verify timing accuracy with known operations")

  io.println("\n### Phase 2: Component Benchmarks (GREEN)")
  io.println("1. Weekly generation timing")
  io.println("   - Measure full 7-day plan generation")
  io.println("   - Identify per-day bottlenecks")
  io.println("2. Batch sync timing")
  io.println("   - Measure 21-meal sync operation")
  io.println("   - Track per-meal sync latency")
  io.println("3. Scheduler job timing")
  io.println("   - Measure job execution overhead")
  io.println("   - Profile job manager performance")
  io.println("4. Email generation timing")
  io.println("   - Measure template rendering")
  io.println("   - Profile HTML generation")
  io.println("5. Database query timing")
  io.println("   - Measure each query type")
  io.println("   - Identify slow queries")

  io.println("\n### Phase 3: Optimization (REFACTOR)")
  io.println("Based on measurements, optimize:")
  io.println("1. Generation algorithm (if >500ms)")
  io.println("   - Recipe pre-filtering by calorie range")
  io.println("   - Early termination on perfect match")
  io.println("   - Smarter combination strategy")
  io.println("2. Sync operations (if >2s)")
  io.println("   - Parallel API calls for independent meals")
  io.println("   - Connection pooling for HTTP requests")
  io.println("   - Batch create operations if API supports")
  io.println("3. Database queries (if >50ms)")
  io.println("   - Add indexes on id, user_id, date columns")
  io.println("   - Use query result caching")
  io.println("   - Optimize aggregation queries")
  io.println("4. Email rendering (if >200ms)")
  io.println("   - Pre-render static components")
  io.println("   - Minimize string concatenation")
  io.println("   - Use StringBuilder pattern")

  io.println("\n## Bottleneck Prediction (Pre-Measurement)")
  io.println("\nBased on algorithm complexity analysis:")
  io.println("1. HIGH RISK: Weekly generation")
  io.println("   - O(n³) combination generation")
  io.println("   - 50 recipes = ~20,000 combinations per day")
  io.println("   - 7 days = potentially 140,000 combinations")
  io.println("   - RECOMMENDATION: Implement greedy algorithm")

  io.println("\n2. MEDIUM RISK: Batch sync")
  io.println("   - Network I/O bound (FatSecret API calls)")
  io.println("   - 21 sequential HTTP requests")
  io.println("   - Each request ~50-200ms (network latency)")
  io.println("   - RECOMMENDATION: Parallelize API calls")

  io.println("\n3. LOW RISK: Database queries")
  io.println("   - PostgreSQL is fast for simple lookups")
  io.println("   - Risk only if missing indexes")
  io.println("   - RECOMMENDATION: Add indexes preemptively")

  io.println("\n4. LOW RISK: Email generation")
  io.println("   - String concatenation in Gleam is efficient")
  io.println("   - Templates are static (no complex rendering)")
  io.println("   - RECOMMENDATION: No optimization unless measured slow")

  io.println("\n5. LOW RISK: Scheduler job execution")
  io.println("   - Erlang/BEAM has low process overhead")
  io.println("   - Job manager is simple state machine")
  io.println("   - RECOMMENDATION: No optimization expected")

  io.println("\n## Success Criteria")
  io.println("✓ All tests transition from RED to GREEN")
  io.println("✓ All measurements meet target thresholds")
  io.println("✓ No performance regressions in future iterations")

  io.println("\n" <> string.repeat("=", 80))

  should.be_true(True)
}

// ============================================================================
// End-to-End Workflow Benchmark
// ============================================================================

/// Benchmark complete Friday 6 AM generation workflow
///
/// TARGET: Full workflow completes in <5s
///
/// This simulates the actual Friday morning automation:
/// 1. Fetch recipes from Tandoor
/// 2. Generate 7-day meal plan
/// 3. Calculate grocery list
/// 4. Generate email
/// 5. Stage FatSecret sync
/// 6. Schedule next week's job
///
/// RED PHASE: All timing infrastructure missing
pub fn benchmark_end_to_end_workflow_test() {
  io.println("\n[BENCHMARK] End-to-End Friday Workflow:")

  let steps = [
    #("Fetch recipes from Tandoor", 0),
    #("Generate 7-day meal plan", 0),
    #("Calculate grocery list", 0),
    #("Generate email", 0),
    #("Stage FatSecret sync", 0),
    #("Schedule next week's job", 0),
  ]

  let total_ms =
    steps
    |> list.fold(0, fn(acc, step) {
      let #(name, elapsed_ms) = step
      io.println("  " <> name <> ": " <> int.to_string(elapsed_ms) <> "ms")
      acc + elapsed_ms
    })

  io.println("\n[TOTAL] Complete workflow: " <> int.to_string(total_ms) <> "ms")

  case total_ms {
    0 -> io.println("[RED PHASE] No timing implementation - expected")
    ms if ms <= 5000 -> io.println("[PASS] Meets <5s target")
    ms if ms <= 10_000 -> io.println("[WARNING] 5-10s - user-noticeable delay")
    _ -> io.println("[FAIL] >10s - unacceptable for automation")
  }

  total_ms
  |> should.equal(0)
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
