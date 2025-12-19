# Meal Generation Performance Analysis
**Task**: meal-planner-bjjm
**Agent**: OPTIMIZER Agent 21
**Date**: 2025-12-19

## Executive Summary

Analyzed the macro_balancer meal generation algorithm for performance bottlenecks. The current implementation uses a brute-force combination search strategy that is limited to 3 attempts to prevent exponential explosion. While this prevents worst-case scenarios, there are significant optimization opportunities.

**Target**: <100ms for 7-day plan generation (50 recipes)
**Current Approach**: Combination trial (singles, pairs, triples) with early cutoff
**Status**: Implementation has type system issues that need resolution before benchmarking

## Algorithm Analysis

### Current Implementation (`macro_balancer.gleam`)

```gleam
pub fn balance_macros_for_day(
  recipes: List(Recipe),
  target: Macros,
) -> Result(BalanceResult, String)
```

**Strategy**:
1. Generate all singles (N combinations)
2. Generate all pairs (N*(N-1)/2 combinations)
3. Generate all triples (N*(N-1)*(N-2)/6 combinations)
4. Limit to first 3 attempts
5. Score each by deviation from target
6. Return best match

### Complexity Analysis

For N=50 recipes:
- Singles: 50 combinations
- Pairs: 1,225 combinations
- Triples: 19,600 combinations
- **Total possible**: 20,875 combinations
- **Actually tried**: 3 (due to max_attempts limit)

**Time Complexity**:
- Generate combinations: O(N³) for triples generation
- Evaluate combinations: O(K * M) where K=attempts, M=recipes per combo
- **Overall**: O(N³) dominated by triple generation

### Bottlenecks Identified

#### 1. **Combination Generation** (HIGH IMPACT)
- Current: Generates ALL triples even though only 3 are used
- For 50 recipes: Creates 19,600 combinations, uses 3
- **Wasted computation**: 99.98% of generated combinations discarded
- **Fix**: Lazy generation or skip triple generation entirely

#### 2. **No Early Termination** (HIGH IMPACT)
- Algorithm always tries `max_attempts` (3) combinations
- If first attempt is OnTarget (within ±10%), still tries 2 more
- **Fix**: Return immediately when OnTarget found

#### 3. **No Recipe Pre-filtering** (MEDIUM IMPACT)
- All 50 recipes considered regardless of calorie range
- Example: Target=2000 cal, but includes 500 cal and 2500 cal recipes
- **Fix**: Filter recipes to reasonable calorie range before combining

#### 4. **Redundant Macro Calculations** (LOW IMPACT)
- `macros.calories()` called multiple times per combination
- Protein/fat/carb accessed directly without caching
- **Fix**: Pre-calculate calories for all recipes once

#### 5. **Linear Search for Best** (LOW IMPACT)
- Sorts all K combinations by score
- For K=3, this is negligible
- If K increases, consider priority queue

## Optimization Recommendations

### Priority 1: Early Termination (Easy Win)
**Impact**: 2-3x speedup for good recipe pools
**Complexity**: Trivial

```gleam
fn find_best_combination(
  combinations: List(List(Recipe)),
  target: Macros,
) -> Option(BalanceResult) {
  combinations
  |> list.map(fn(combo) { evaluate_combination(combo, target) })
  |> list.find(fn(result) {
    // Return first OnTarget result immediately
    case result.status {
      OnTarget -> True
      _ -> False
    }
  })
  |> option.from_result
  // If no OnTarget, fall back to sorting by score...
}
```

### Priority 2: Greedy Selection (Biggest Impact)
**Impact**: 10-100x speedup, reduces O(N³) to O(N²)
**Complexity**: Moderate

Instead of brute-force combinations:
1. Find recipe closest to target (O(N))
2. Calculate remaining macro need
3. Find recipe that best fills the gap (O(N))
4. Repeat if needed for third recipe (O(N))

**Total**: O(3N) = O(N) vs. current O(N³)

```gleam
fn greedy_balance(recipes: List(Recipe), target: Macros) -> BalanceResult {
  // Step 1: Find closest single recipe
  let best_single = find_closest_recipe(recipes, target)

  // Step 2: If within tolerance, done
  case is_on_target(best_single, target) {
    True -> BalanceResult(OnTarget, [best_single], ...)
    False -> {
      // Step 3: Find best complement
      let remaining = calculate_remaining(target, best_single.macros)
      let best_pair = find_closest_recipe(recipes, remaining)
      // ... continue logic
    }
  }
}
```

### Priority 3: Recipe Pre-filtering
**Impact**: 2-5x speedup by reducing search space
**Complexity**: Easy

```gleam
fn filter_viable_recipes(
  recipes: List(Recipe),
  target: Macros,
) -> List(Recipe) {
  let target_calories = macros_calories(target)
  let min_cal = target_calories *. 0.5  // Recipes must be at least 50% of target
  let max_cal = target_calories *. 1.5  // And at most 150% of target

  recipes
  |> list.filter(fn(r) {
    let cal = macros_calories(r.macros)
    cal >=. min_cal && cal <=. max_cal
  })
}
```

### Priority 4: Calorie Caching
**Impact**: 10-20% speedup
**Complexity**: Trivial

```gleam
pub opaque type RecipeWithCalories {
  RecipeWithCalories(recipe: Recipe, calories: Float)
}

fn preprocess_recipes(recipes: List(Recipe)) -> List(RecipeWithCalories) {
  list.map(recipes, fn(r) {
    RecipeWithCalories(recipe: r, calories: macros_calories(r.macros))
  })
}
```

### Priority 5: Parallel Day Processing (If Needed)
**Impact**: 7x speedup (one per day)
**Complexity**: Easy on BEAM/Erlang

```gleam
pub fn balance_week(
  recipes: List(Recipe),
  daily_targets: List(Macros),
) -> List(BalanceResult) {
  // Erlang/BEAM makes this trivial with process.map_parallel
  daily_targets
  |> process.map_parallel(fn(target) {
    balance_macros_for_day(recipes, target)
  })
}
```

## Performance Projections

### Current Implementation (Estimated)
- Single day (50 recipes): ~15-20ms (dominated by triple generation)
- 7-day plan: ~105-140ms
- **Verdict**: Likely FAILS <100ms target

### With Early Termination Only
- Single day: ~5-10ms (30% hit rate on first attempt)
- 7-day plan: ~35-70ms
- **Verdict**: PASSES <100ms target

### With Greedy Selection
- Single day: ~0.5-2ms (O(N) vs O(N³))
- 7-day plan: ~3.5-14ms
- **Verdict**: EASILY PASSES, 10x headroom

### With All Optimizations
- Single day: ~0.3-1ms
- 7-day plan: ~2-7ms
- **Verdict**: 15-50x faster than target

## Implementation Plan

1. **Fix Type System Issues** (Prerequisite)
   - Resolve `types.Macros` vs `types/macros.Macros` conflict
   - Ensure imports are consistent
   - Tests must compile and run

2. **Baseline Measurement** (Before optimization)
   - Run performance benchmark tests
   - Measure actual timings for 50 recipes, 7 days
   - Confirm bottleneck is combination generation

3. **Implement Early Termination** (Quick win)
   - Modify `find_best_combination` to return on first OnTarget
   - Re-measure performance
   - Expected: 2-3x improvement

4. **Implement Greedy Selection** (Big impact)
   - Replace brute-force with greedy algorithm
   - Maintain existing API (`balance_macros_for_day`)
   - Re-measure performance
   - Expected: 10-100x improvement

5. **Add Pre-filtering** (Polish)
   - Filter recipes before combining
   - Re-measure performance
   - Expected: Additional 2x improvement

## Risks and Trade-offs

### Greedy vs. Exhaustive Search
- **Greedy**: Fast (O(N)) but may not find global optimum
- **Current**: Slow (O(N³)) and still doesn't guarantee optimum (only tries 3)
- **Verdict**: Greedy is strictly better (faster AND explores more space)

### Precision vs. Speed
- Current ±10% tolerance is reasonable
- Greedy algorithm should hit same tolerance >90% of the time
- For edge cases where greedy fails, can fall back to exhaustive

### BEAM/Erlang Considerations
- Erlang excels at parallelism (easy 7x speedup for weekly generation)
- List operations are well-optimized
- Pattern matching is near-zero cost
- **Recommendation**: Use parallel processing for weekly generation

## Testing Strategy

1. **Performance Tests** (`test/performance/generation_benchmark_test.gleam`)
   - `benchmark_single_day_50_recipes_test`: Baseline measurement
   - `benchmark_seven_days_50_recipes_test`: Weekly target (<100ms)
   - `benchmark_scaling_behavior_test`: Verify O(N) vs O(N³)
   - `analyze_combination_count_test`: Understand search space

2. **Correctness Tests** (`test/generation/macro_balancer_test.gleam`)
   - Verify greedy produces results within ±10% tolerance
   - Edge cases: very few recipes, conflicting macro ratios
   - Compare greedy vs exhaustive for small N (should match)

3. **Regression Tests**
   - Ensure optimizations don't break existing behavior
   - BalanceStatus values remain correct (OnTarget, NeedsAdjustment, Conflict)

## Conclusion

The meal generation algorithm has significant performance optimization opportunities:

1. **Immediate**: Early termination gives 2-3x improvement with 5-line change
2. **High Impact**: Greedy selection gives 10-100x improvement, reduces complexity from O(N³) to O(N)
3. **Polish**: Pre-filtering and caching give additional 2-3x improvement
4. **If Needed**: Parallelization gives 7x improvement for weekly generation

**Recommended approach**:
1. Fix type system issues (prerequisite)
2. Implement early termination (quick win)
3. Implement greedy selection (biggest impact)
4. Measure and iterate

**Expected outcome**: <10ms for 7-day generation (10x better than 100ms target)

---

*Note: Actual performance measurements require compiling and running the benchmark tests. Current implementation has type system conflicts between `types.Macros` and `types/macros.Macros` that must be resolved first.*
