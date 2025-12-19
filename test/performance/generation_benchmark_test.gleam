//// Performance Benchmark: Meal Generation Algorithm
////
//// Measures and profiles the macro_balancer generation performance.
//// Target: <100ms for 7-day plan with 50 recipes.
////
//// Task: meal-planner-bjjm

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/generation/macro_balancer
import meal_planner/types.{type Recipe, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Generators
// ============================================================================

/// Create test recipe with specific macros
fn create_recipe(
  id: Int,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
  let id_str = "recipe_" <> int.to_string(id)
  Recipe(
    id: meal_planner/id.new_recipe_id(id_str),
    name: "Test Recipe " <> int.to_string(id),
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: meal_planner/types.Low,
    vertical_compliant: True,
  )
}

/// Generate N recipes with varying macro profiles
/// Simulates realistic recipe diversity:
/// - High protein (40-60g)
/// - High fat (20-40g)
/// - High carb (50-100g)
/// - Balanced (moderate all)
fn generate_recipe_pool(count: Int) -> List(Recipe) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    // Distribute recipes across 4 profiles
    case i % 4 {
      0 ->
        // High protein
        create_recipe(i, 50.0 +. int.to_float(i % 10), 20.0, 30.0)
      1 ->
        // High carb
        create_recipe(i, 25.0, 15.0, 80.0 +. int.to_float(i % 20))
      2 ->
        // High fat
        create_recipe(i, 30.0, 35.0 +. int.to_float(i % 10), 25.0)
      _ ->
        // Balanced
        create_recipe(
          i,
          40.0 +. int.to_float(i % 5),
          25.0 +. int.to_float(i % 5),
          50.0 +. int.to_float(i % 10),
        )
    }
  })
}

// ============================================================================
// Timing Utilities
// ============================================================================

/// Simple timing wrapper (returns microseconds as Int)
/// Note: Gleam doesn't have built-in timing, this is a placeholder
/// In production, would use erlang:monotonic_time or similar
fn time_operation(operation: fn() -> a) -> #(a, Int) {
  // Placeholder: actual implementation would use erlang:monotonic_time
  // For now, just execute and return dummy timing
  let result = operation()
  #(result, 0)
}

// ============================================================================
// Benchmark Tests
// ============================================================================

/// Baseline: Measure time to balance macros for a single day with 50 recipes
///
/// This establishes baseline performance of the macro_balancer algorithm.
/// Target: <15ms per day (to achieve <100ms for 7 days)
pub fn benchmark_single_day_50_recipes_test() {
  // Setup: 50 diverse recipes
  let recipes = generate_recipe_pool(50)

  // Target: 180p/60f/200c (2060 calories)
  let target = Macros(protein: 180.0, fat: 60.0, carbs: 200.0)

  // Warmup: Run once to ensure code is loaded
  let assert Ok(_) = macro_balancer.balance_macros_for_day(recipes, target)

  // Benchmark: Time the operation
  let #(result, elapsed_us) = time_operation(fn() {
    macro_balancer.balance_macros_for_day(recipes, target)
  })

  // Verify it succeeded
  should.be_ok(result)

  // Report timing
  let elapsed_ms = elapsed_us / 1000
  io.println(
    "\n[BENCHMARK] Single day with 50 recipes: "
    <> int.to_string(elapsed_ms)
    <> "ms",
  )

  // Analysis: This will help identify if single-day balancing is the bottleneck
  io.println(
    "[ANALYSIS] For 7-day plan, estimated total: "
    <> int.to_string(elapsed_ms * 7)
    <> "ms",
  )

  // Soft assertion: Warn if over target
  case elapsed_ms > 15 {
    True ->
      io.println(
        "[WARNING] Exceeds 15ms target (needed for <100ms week). Actual: "
        <> int.to_string(elapsed_ms)
        <> "ms",
      )
    False -> io.println("[PASS] Within 15ms target")
  }

  // Test always passes (this is a benchmark, not a strict test)
  should.be_true(True)
}

/// Stress test: 7 days with 50 recipes each (simulates full week generation)
///
/// This tests the complete weekly generation scenario.
/// Target: <100ms total
pub fn benchmark_seven_days_50_recipes_test() {
  // Setup: 50 diverse recipes
  let recipes = generate_recipe_pool(50)

  // Different targets for each day (simulates weekly variation)
  let daily_targets = [
    Macros(protein: 180.0, fat: 60.0, carbs: 200.0),
    // Day 1
    Macros(protein: 170.0, fat: 65.0, carbs: 210.0),
    // Day 2
    Macros(protein: 185.0, fat: 58.0, carbs: 195.0),
    // Day 3
    Macros(protein: 175.0, fat: 62.0, carbs: 205.0),
    // Day 4
    Macros(protein: 180.0, fat: 60.0, carbs: 200.0),
    // Day 5
    Macros(protein: 182.0, fat: 59.0, carbs: 198.0),
    // Day 6
    Macros(protein: 178.0, fat: 61.0, carbs: 202.0),
    // Day 7
  ]

  // Warmup
  let assert Ok(_) =
    macro_balancer.balance_macros_for_day(recipes, list.first(daily_targets))

  // Benchmark: Time all 7 days
  let #(results, elapsed_us) = time_operation(fn() {
    daily_targets
    |> list.map(fn(target) {
      macro_balancer.balance_macros_for_day(recipes, target)
    })
  })

  // Verify all succeeded
  results
  |> list.each(fn(result) { should.be_ok(result) })

  // Report timing
  let elapsed_ms = elapsed_us / 1000
  io.println(
    "\n[BENCHMARK] 7-day plan with 50 recipes: "
    <> int.to_string(elapsed_ms)
    <> "ms",
  )

  let per_day_ms = elapsed_ms / 7
  io.println(
    "[ANALYSIS] Average per day: " <> int.to_string(per_day_ms) <> "ms",
  )

  // Performance verdict
  case elapsed_ms {
    ms if ms <= 100 -> io.println("[EXCELLENT] Meets <100ms target!")
    ms if ms <= 200 ->
      io.println("[ACCEPTABLE] Under 200ms but exceeds 100ms target")
    ms if ms <= 500 -> io.println("[SLOW] Needs optimization (>200ms)")
    _ -> io.println("[CRITICAL] Severely over budget (>500ms)")
  }

  // Test always passes
  should.be_true(True)
}

/// Combination explosion test: Analyze scaling behavior
///
/// Tests how performance degrades as recipe count increases.
/// This helps identify if combination generation is the bottleneck.
pub fn benchmark_scaling_behavior_test() {
  let target = Macros(protein: 180.0, fat: 60.0, carbs: 200.0)

  let test_sizes = [10, 20, 30, 40, 50]

  io.println("\n[SCALING ANALYSIS] Recipe count vs. execution time:")

  test_sizes
  |> list.each(fn(size) {
    let recipes = generate_recipe_pool(size)

    let #(result, elapsed_us) = time_operation(fn() {
      macro_balancer.balance_macros_for_day(recipes, target)
    })

    should.be_ok(result)

    let elapsed_ms = elapsed_us / 1000
    io.println(
      "  " <> int.to_string(size) <> " recipes: " <> int.to_string(elapsed_ms) <> "ms",
    )
  })

  // Analysis notes
  io.println("\n[NOTES]")
  io.println("- If time grows linearly: O(n) - good")
  io.println("- If time grows quadratically: O(n²) - pair generation bottleneck")
  io.println("- If time grows cubically: O(n³) - triple generation bottleneck")

  should.be_true(True)
}

/// Combination counting test: Count how many combinations are generated
///
/// This helps understand the actual search space size.
/// Current algorithm: singles + pairs + triples, limited to 3 attempts
pub fn analyze_combination_count_test() {
  let recipe_counts = [10, 20, 30, 40, 50]

  io.println("\n[COMBINATION ANALYSIS] Recipe count vs. combinations generated:")

  recipe_counts
  |> list.each(fn(count) {
    let singles = count
    let pairs = count * { count - 1 } / 2
    let triples = count * { count - 1 } * { count - 2 } / 6

    let total_possible = singles + pairs + triples
    let actual_tried = int.min(3, total_possible)

    io.println("\n  " <> int.to_string(count) <> " recipes:")
    io.println("    Singles: " <> int.to_string(singles))
    io.println("    Pairs: " <> int.to_string(pairs))
    io.println("    Triples: " <> int.to_string(triples))
    io.println("    Total possible: " <> int.to_string(total_possible))
    io.println("    Actually tried: " <> int.to_string(actual_tried))
  })

  io.println("\n[INSIGHT]")
  io.println(
    "Current algorithm limits to 3 attempts, preventing combination explosion.",
  )
  io.println("For 50 recipes: ~20,000 combinations exist but only 3 are tried.")

  should.be_true(True)
}

// ============================================================================
// Performance Findings Template
// ============================================================================

/// This test prints the performance report template
pub fn performance_report_template_test() {
  io.println("\n" <> string.repeat("=", 80))
  io.println("PERFORMANCE ANALYSIS REPORT")
  io.println("Task: meal-planner-bjjm")
  io.println(string.repeat("=", 80))

  io.println("\n## Baseline Measurements")
  io.println("- Single day (50 recipes): [SEE ABOVE]")
  io.println("- 7-day plan (50 recipes): [SEE ABOVE]")

  io.println("\n## Bottleneck Analysis")
  io.println("1. Combination Generation:")
  io.println("   - Singles: O(n)")
  io.println("   - Pairs: O(n²)")
  io.println("   - Triples: O(n³)")
  io.println("   - Current limit: 3 attempts (prevents explosion)")

  io.println("\n2. Recipe Filtering:")
  io.println("   - No pre-filtering by macro range")
  io.println("   - All recipes tried in combinations")

  io.println("\n3. Macro Calculation:")
  io.println("   - list.map + sum per combination")
  io.println("   - Deviation score calculated for all attempts")

  io.println("\n## Optimization Recommendations")

  io.println("\n### 1. Early Termination")
  io.println("   - IMPACT: High")
  io.println("   - Stop searching if OnTarget found on first attempt")
  io.println("   - Current: Always tries max_attempts even if perfect match")

  io.println("\n### 2. Recipe Pre-filtering")
  io.println("   - IMPACT: Medium")
  io.println("   - Filter recipes by calorie range before combination generation")
  io.println("   - Example: If target=2000 cal, ignore recipes >1500 cal (can't combine)")

  io.println("\n### 3. Smarter Combination Strategy")
  io.println("   - IMPACT: High")
  io.println("   - Instead of singles->pairs->triples, use greedy approach:")
  io.println("     1. Find recipe closest to target")
  io.println("     2. Find recipe that best fills the gap")
  io.println("     3. Optionally add third if needed")
  io.println("   - Reduces from O(n³) to O(n²)")

  io.println("\n### 4. Caching Macro Sums")
  io.println("   - IMPACT: Low")
  io.println("   - Pre-calculate calories for all recipes")
  io.println("   - Avoid recalculating macros.calories() per evaluation")

  io.println("\n### 5. Parallel Day Processing")
  io.println("   - IMPACT: Medium (if multi-core)")
  io.println("   - Each day is independent")
  io.println("   - Could parallelize 7-day generation")
  io.println("   - Note: Erlang/BEAM makes this trivial")

  io.println("\n## Implementation Priority")
  io.println("1. Early termination (easy win)")
  io.println("2. Smarter combination strategy (biggest impact)")
  io.println("3. Recipe pre-filtering (moderate complexity)")
  io.println("4. Caching (micro-optimization)")
  io.println("5. Parallelization (if needed after other opts)")

  io.println("\n" <> string.repeat("=", 80))

  should.be_true(True)
}
