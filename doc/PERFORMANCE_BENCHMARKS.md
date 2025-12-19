# Generation Engine Performance Benchmarks

**Task**: meal-planner-aejt Phase 3
**Component**: Weekly Meal Plan Generation Engine
**Analysis Date**: 2025-12-19
**Status**: Pre-implementation (predictions based on algorithm analysis)

---

## Executive Summary

Based on static analysis of the generation algorithm in `src/meal_planner/generator/weekly.gleam`, the engine is **highly optimized** with O(7) constant complexity for core generation. Performance bottlenecks exist only in external API calls (Tandoor, FatSecret) which are **outside** the generation engine scope.

**Predicted Total Latency**: <1 second end-to-end (local processing <50ms, API calls 200-800ms)

---

## 1. Current Performance Measurements

### 1.1 Generation Algorithm (Pure Local Processing)

**Function**: `generate_meal_plan()` (lines 326-395 in `weekly.gleam`)

```gleam
pub fn generate_meal_plan(
  available_breakfasts: List(Recipe),
  available_lunches: List(Recipe),
  available_dinners: List(Recipe),
  target_macros: Macros,
  constraints: Constraints,
  week_of: String,
) -> Result(WeeklyMealPlan, GenerationError)
```

**Algorithm Complexity Analysis**:
- **Input Validation**: O(1) - 3 list length checks
- **Day Loop**: O(7) - Fixed 7 iterations (Monday-Sunday)
- **Recipe Selection per Day**: O(1) - Array index with modulo
  - Breakfast: `get_at(available_breakfasts, idx)` - O(1) list access
  - Lunch: `get_at(available_lunches, idx % 2)` - O(1) modulo + access
  - Dinner: `get_at(available_dinners, idx % 2)` - O(1) modulo + access
- **Locked Meal Override**: O(L × 3) where L = locked meals count (typically 0-3)
  - `find_locked_meal()` iterates locked_meals list 3 times per day
  - Worst case: 21 comparisons (7 days × 3 meals) if all meals locked
- **Total Complexity**: **O(7 + L)** ≈ **O(1)** (constant with small L)

**Predicted Timing** (ERLANG/BEAM VM on modern CPU):
- Recipe pool allocation: <5ms
- Day loop (7 iterations): <20ms
- Locked meal resolution: <10ms
- Struct allocation: <10ms
- **Total Generation**: **<50ms** (local only, no API)

**No Bottlenecks Detected**:
- ✅ No nested loops (no O(n²) operations)
- ✅ No recursive macro balancing (no retry logic)
- ✅ No API calls within generation logic
- ✅ No database queries during generation
- ✅ Fixed iteration count (7 days, not N days)

---

### 1.2 Recipe Fetching (Tandoor API)

**Location**: `src/meal_planner/tandoor/client.gleam`

**Operations**:
1. Fetch breakfast recipes: `GET /api/recipe?category=breakfast&limit=7`
2. Fetch lunch recipes: `GET /api/recipe?category=lunch&limit=2`
3. Fetch dinner recipes: `GET /api/recipe?category=dinner&limit=2`

**Predicted Timing** (sequential calls):
- HTTP request latency: 50-150ms per request (local network)
- JSON parsing: 10-30ms per response
- Total: **3 × (50-150ms) = 150-450ms**

**Optimization Opportunity**: **Parallel API calls** (see Section 4.2)
- With parallelization: **max(150ms) = 150ms** (3x speedup)

---

### 1.3 User Profile Fetching (FatSecret API)

**Location**: `src/meal_planner/fatsecret/meal_logger.gleam`

**Operation**: Fetch user macros target from FatSecret profile

**Predicted Timing**:
- HTTP request to FatSecret: 100-200ms (external API, higher latency)
- OAuth token refresh (if needed): +100ms
- Total: **100-300ms**

**Can Run in Parallel** with Tandoor recipe fetching.

---

### 1.4 Macro Balancing Validation

**Function**: `is_plan_balanced()` (lines 181-188 in `weekly.gleam`)

```gleam
pub fn is_plan_balanced(plan: WeeklyMealPlan) -> Bool {
  let analysis = analyze_plan(plan)
  list.all(analysis, fn(daily) {
    daily.protein_status == OnTarget
    && daily.fat_status == OnTarget
    && daily.carbs_status == OnTarget
  })
}
```

**Complexity**:
- `analyze_plan()`: O(7) - iterates 7 days
- `calculate_daily_macros()` per day: O(3) - sums 3 meals
- Comparison: O(3 × 3) - 3 macros × 3 status checks
- **Total**: O(7 × 9) = **O(63)** ≈ **O(1)** constant

**Predicted Timing**: **<10ms**

**Note**: Current algorithm does **NOT retry** if unbalanced. This is a single-pass check, not a multi-attempt search algorithm.

---

### 1.5 Grocery List Consolidation

**Status**: Not yet implemented (future Phase 4 work)

**Predicted Algorithm** (from codebase patterns):
- Extract ingredients from 21 meals (7 days × 3 meals)
- Group by ingredient name: O(21 × I) where I = avg ingredients per recipe
- Sum quantities: O(G) where G = unique ingredient groups
- **Complexity**: O(21 × I + G) ≈ O(200-500) for typical recipes

**Predicted Timing**: **<100ms**

---

## 2. Target Performance Metrics

### End-to-End Weekly Generation Workflow

| Operation | Target | Confidence |
|-----------|--------|------------|
| **Generation algorithm** (local) | <50ms | ✅ High (O(1) complexity) |
| **Recipe fetching** (Tandoor API, sequential) | <450ms | ⚠️ Medium (network dependent) |
| **Recipe fetching** (Tandoor API, parallel) | <150ms | ✅ High (simple optimization) |
| **Profile fetching** (FatSecret API) | <300ms | ⚠️ Medium (external API) |
| **Macro validation** | <10ms | ✅ High (O(1) complexity) |
| **Grocery consolidation** | <100ms | ✅ High (simple grouping) |
| **Email rendering** | <50ms | ✅ High (string concatenation) |
| **TOTAL (sequential API)** | **<1 second** | ✅ High |
| **TOTAL (parallel API)** | **<500ms** | ✅ High |

### Breakdown by Component

```
┌─────────────────────────────────────────────────────────────┐
│ SEQUENTIAL EXECUTION (current)                              │
├─────────────────────────────────────────────────────────────┤
│ 1. Fetch Tandoor recipes      [====]  150-450ms            │
│ 2. Fetch FatSecret profile    [==]    100-300ms            │
│ 3. Generate weekly plan       [.]     <50ms                │
│ 4. Validate macros             [.]     <10ms                │
│ 5. Consolidate groceries      [.]     <100ms               │
│ 6. Render email                [.]     <50ms                │
├─────────────────────────────────────────────────────────────┤
│ TOTAL:                         960ms (worst case)           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PARALLEL EXECUTION (optimized)                              │
├─────────────────────────────────────────────────────────────┤
│ 1. Fetch Tandoor + FatSecret  [====]  ~300ms (parallel)    │
│ 2. Generate weekly plan       [.]     <50ms                │
│ 3. Validate macros             [.]     <10ms                │
│ 4. Consolidate groceries      [.]     <100ms               │
│ 5. Render email                [.]     <50ms                │
├─────────────────────────────────────────────────────────────┤
│ TOTAL:                         <510ms (optimized)           │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Bottleneck Analysis

### 3.1 Critical Path Analysis

**Bottleneck Ranking** (by impact on total latency):

1. **🔴 HIGH IMPACT: API Calls (Tandoor + FatSecret)**
   - **Current**: 250-750ms (62-78% of total time)
   - **Risk**: Network latency, API rate limits, timeouts
   - **Mitigation**: Parallel execution (Section 4.2)

2. **🟡 MEDIUM IMPACT: Grocery Consolidation**
   - **Current**: <100ms (10% of total time)
   - **Risk**: O(n) ingredient grouping could degrade with large recipe pools
   - **Mitigation**: Pre-index ingredients by name (Section 4.3)

3. **🟢 LOW IMPACT: Generation Algorithm**
   - **Current**: <50ms (5% of total time)
   - **Risk**: None - O(1) complexity is optimal
   - **Mitigation**: None needed

4. **🟢 LOW IMPACT: Macro Validation**
   - **Current**: <10ms (1% of total time)
   - **Risk**: None - single pass, no retry loop
   - **Mitigation**: None needed

### 3.2 Amdahl's Law Analysis

**Sequential Fraction**: 0.70 (API calls)
**Parallel Fraction**: 0.30 (local processing)

**Speedup with Parallel API**:
```
Speedup = 1 / (0.30 + 0.70/3) ≈ 2.3x
960ms → 420ms
```

**Conclusion**: Parallelizing API calls yields **2-3x speedup** with minimal code changes.

---

### 3.3 Memory Profile

**Peak Memory Usage** (estimated):

- Recipe pool (11 recipes × 2KB): ~22KB
- Weekly plan (21 meals × 2KB): ~42KB
- Locked meals (max 3): ~6KB
- Grocery list (50 ingredients): ~10KB
- **Total Peak**: **<100KB** (negligible for BEAM VM)

**No Memory Bottlenecks**: All data structures fit comfortably in L1/L2 cache.

---

## 4. Optimization Roadmap

### 4.1 Phase 1: Baseline Measurement (Week 1)

**Goal**: Replace predictions with real measurements

**Tasks**:
1. Implement timing wrapper in `test/performance/scheduler_benchmark_test.gleam`
   - Use `erlang:monotonic_time/0` for microsecond precision
   - Wrapper: `time_operation(fn() -> a) -> #(a, Int)`
2. Benchmark each component in isolation:
   - Generation algorithm (without API calls)
   - Tandoor API fetch (sequential)
   - FatSecret API fetch
   - Grocery consolidation
   - Email rendering
3. Record baseline metrics in test output
4. Commit: `GREEN: Performance baseline measurements (meal-planner-aejt)`

**Success Criteria**:
- All tests transition from RED (placeholders) to GREEN (actual timings)
- Measurements confirm predictions within ±30%

---

### 4.2 Phase 2: Parallel API Optimization (Week 2)

**Goal**: Reduce API latency from 450ms → 150ms

**Current Sequential Flow**:
```gleam
// Sequential (slow)
let breakfast_recipes = fetch_recipes("breakfast")  // 150ms
let lunch_recipes = fetch_recipes("lunch")          // 150ms
let dinner_recipes = fetch_recipes("dinner")        // 150ms
let user_profile = fetch_profile()                  // 200ms
// Total: 650ms
```

**Optimized Parallel Flow**:
```gleam
// Parallel (fast)
use #(breakfast_recipes, lunch_recipes, dinner_recipes, user_profile) <- result.try(
  gleam_erlang.process.parallel4(
    fn() { fetch_recipes("breakfast") },  // \
    fn() { fetch_recipes("lunch") },      //  > All execute concurrently
    fn() { fetch_recipes("dinner") },     //  > Max latency: ~200ms
    fn() { fetch_profile() },             // /
  )
)
// Total: ~200ms (3x speedup)
```

**Implementation**:
1. Add `gleam_erlang` dependency for `process.parallel4()`
2. Refactor `scheduler/generation_scheduler.gleam` to spawn concurrent tasks
3. Add timeout handling (500ms per task)
4. Benchmark: target <200ms for all API calls
5. Commit: `REFACTOR: Parallel API fetching (meal-planner-aejt)`

**Risk**: API rate limiting (mitigation: add exponential backoff)

---

### 4.3 Phase 3: Grocery List Optimization (Week 3)

**Goal**: Pre-index ingredients to avoid O(n²) grouping

**Current Naive Grouping** (hypothetical future implementation):
```gleam
// O(n²) - nested loop
fn consolidate_groceries(meals: List(Meal)) -> List(GroceryItem) {
  meals
  |> list.flat_map(fn(meal) { meal.ingredients })  // O(21 × I)
  |> list.group(fn(ing) { ing.name })              // O(G²) worst case
  |> list.map(sum_quantities)                      // O(G)
}
```

**Optimized HashMap Grouping**:
```gleam
import gleam/map

// O(n) - single pass
fn consolidate_groceries_fast(meals: List(Meal)) -> List(GroceryItem) {
  meals
  |> list.flat_map(fn(meal) { meal.ingredients })
  |> list.fold(map.new(), fn(acc, ing) {
       map.update(acc, ing.name, fn(qty) {
         case qty {
           Some(q) -> q +. ing.quantity
           None -> ing.quantity
         }
       })
     })
  |> map.to_list
  |> list.map(to_grocery_item)
}
```

**Expected Speedup**: 50-100ms → 10-20ms (5x faster)

**Benchmark**: Target <20ms for grocery consolidation

---

### 4.4 Phase 4: Database Query Optimization (Future)

**Status**: Not yet implemented (scheduler persistence)

**Predicted Optimizations**:
1. Add index on `scheduled_jobs.next_run_at` (for job scheduler)
2. Add index on `meal_plans.week_of` (for plan lookups)
3. Add index on `food_logs.date, user_id` (for trend analysis)
4. Use prepared statements for repeated queries

**Target**: All queries <50ms (currently N/A)

---

### 4.5 Phase 5: Caching Layer (Future)

**Goal**: Reduce redundant API calls

**Cache Candidates**:
1. **Recipe Pool** (TTL: 1 hour)
   - Key: `user_id:category:limit`
   - Invalidate: On recipe CRUD operations
   - Speedup: 150-450ms → <5ms (100x faster)
2. **User Profile** (TTL: 24 hours)
   - Key: `user_id:profile`
   - Invalidate: On profile update
   - Speedup: 100-300ms → <5ms (50x faster)
3. **Weekly Plans** (TTL: Until next generation)
   - Key: `user_id:week_of`
   - Invalidate: On regeneration
   - Speedup: 50ms → <5ms (10x faster)

**Implementation**: Use `gleam/erlang/ets` or Redis

**Total Cached Speedup**: 960ms → <50ms (20x faster for repeated requests)

---

## 5. Edge Cases and Failure Modes

### 5.1 Timeout Scenarios

| Scenario | Timeout | Fallback Behavior |
|----------|---------|-------------------|
| Tandoor API timeout | 500ms | Return cached recipes or default pool |
| FatSecret API timeout | 500ms | Use stored target macros from DB |
| Database timeout | 200ms | Return error, retry once |
| Email send timeout | 2000ms | Queue for async retry |

**Monitoring**: Log all timeouts to metrics (future work)

---

### 5.2 Large Recipe Pools

**Scenario**: User has 500+ recipes in Tandoor

**Current Behavior**:
- Generation still O(7) - only uses first 11 recipes
- Recipe fetch: 150ms → 300ms (larger JSON response)
- No impact on algorithm complexity

**Optimization**: Add pagination and filter by recent usage

---

### 5.3 Network Failures

**Scenario**: Tandoor API unreachable

**Current Behavior**: Generation fails with `NetworkError`

**Proposed Resilience**:
1. Retry with exponential backoff (3 attempts)
2. Fall back to cached recipes (if available)
3. Alert user via email if generation fails
4. Auto-reschedule job for 1 hour later

**Implementation**: Add retry logic in `scheduler/executor.gleam`

---

## 6. Performance Regression Prevention

### 6.1 Continuous Benchmarking

**Setup**:
1. Run `test/performance/scheduler_benchmark_test.gleam` in CI
2. Track metrics over time in CSV:
   ```csv
   commit,generation_ms,api_ms,total_ms
   abc123,45,420,510
   def456,48,410,505
   ```
3. Alert on >10% regression

**Tools**: GitHub Actions + CSV metrics + threshold checks

---

### 6.2 Baseline Assertions

**Add to Tests**:
```gleam
pub fn performance_regression_test() {
  let #(_result, elapsed_us) = time_operation(fn() {
    generate_weekly_plan(recipes, target)
  })

  let elapsed_ms = elapsed_us / 1000

  // Assert: Generation completes in <100ms (with margin)
  elapsed_ms
  |> should.be_true(fn(ms) { ms < 100 })
}
```

**Commit**: Run on every PR

---

## 7. Summary and Next Steps

### 7.1 Key Findings

✅ **Generation algorithm is highly optimized** (O(1) complexity, <50ms)
✅ **No nested loops or exponential operations**
✅ **No redundant macro calculations**
⚠️ **API calls are the bottleneck** (62-78% of latency)
⚠️ **Sequential execution is suboptimal** (3x slower than parallel)

### 7.2 Recommended Actions

**Immediate (Week 1)**:
1. ✅ Implement timing infrastructure
2. ✅ Baseline measurements
3. ✅ Confirm <1s total latency

**Short-term (Week 2-3)**:
1. ⚡ Parallel API fetching (3x speedup)
2. ⚡ Grocery list optimization (5x speedup)
3. ⚡ Add timeout handling

**Long-term (Month 2+)**:
1. 🔄 Caching layer (20x speedup for cache hits)
2. 🔄 Database indexing
3. 🔄 Network resilience

### 7.3 Success Metrics

| Metric | Baseline | Target | Stretch Goal |
|--------|----------|--------|--------------|
| Generation (local) | <50ms | <50ms | <20ms |
| API calls (sequential) | 650ms | 500ms | 200ms (parallel) |
| API calls (parallel) | N/A | 200ms | 100ms |
| Total end-to-end | 960ms | 500ms | 200ms (cached) |

**Definition of Done**: All targets met, benchmarks green in CI, no regressions.

---

## Appendix A: Algorithm Walkthrough

### Example Execution Trace

**Input**:
- Breakfasts: `[B1, B2, B3, B4, B5, B6, B7]`
- Lunches: `[L1, L2]`
- Dinners: `[D1, D2]`
- Target: `Macros(180.0, 60.0, 200.0)`
- Constraints: `Constraints([], [])`

**Execution**:
```
Day 0 (Monday):    breakfast=B1(idx=0), lunch=L1(0%2=0), dinner=D1(0%2=0)
Day 1 (Tuesday):   breakfast=B2(idx=1), lunch=L2(1%2=1), dinner=D2(1%2=1)
Day 2 (Wednesday): breakfast=B3(idx=2), lunch=L1(2%2=0), dinner=D1(2%2=0)
Day 3 (Thursday):  breakfast=B4(idx=3), lunch=L2(3%2=1), dinner=D2(3%2=1)
Day 4 (Friday):    breakfast=B5(idx=4), lunch=L1(4%2=0), dinner=D1(4%2=0)
Day 5 (Saturday):  breakfast=B6(idx=5), lunch=L2(5%2=1), dinner=D2(5%2=1)
Day 6 (Sunday):    breakfast=B7(idx=6), lunch=L1(6%2=0), dinner=D1(6%2=0)
```

**Result**: 7 unique breakfasts, ABABABA lunch pattern, ABABABA dinner pattern

**Complexity**: 7 iterations × 3 assignments = **21 operations** = **O(1)**

---

## Appendix B: Measurement Methodology

### Timing Infrastructure

**Implementation** (to be added in Phase 1):

```gleam
// scheduler_benchmark_ffi.erl
-module(scheduler_benchmark_ffi).
-export([time_operation/1]).

time_operation(Fun) ->
    Start = erlang:monotonic_time(microsecond),
    Result = Fun(),
    End = erlang:monotonic_time(microsecond),
    Elapsed = End - Start,
    {Result, Elapsed}.
```

```gleam
// scheduler_benchmark_test.gleam
@external(erlang, "scheduler_benchmark_ffi", "time_operation")
fn time_operation(operation: fn() -> a) -> #(a, Int)

pub fn benchmark_generation_test() {
  let #(result, elapsed_us) = time_operation(fn() {
    generate_weekly_plan(recipes, target)
  })

  let elapsed_ms = elapsed_us / 1000
  io.println("Generation: " <> int.to_string(elapsed_ms) <> "ms")

  // Assert reasonable performance
  elapsed_ms |> should.be_true(fn(ms) { ms < 100 })
}
```

**Validation**: Run 100 iterations, compute p50/p95/p99 percentiles

---

## Appendix C: References

### Codebase Files

- **Generation Engine**: `src/meal_planner/generator/weekly.gleam`
- **Scheduler Executor**: `src/meal_planner/scheduler/executor.gleam`
- **Tandoor Client**: `src/meal_planner/tandoor/client.gleam`
- **FatSecret Logger**: `src/meal_planner/fatsecret/meal_logger.gleam`
- **Benchmark Tests**: `test/performance/scheduler_benchmark_test.gleam`

### Related Tasks

- **meal-planner-aejt**: Performance analysis (this document)
- **meal-planner-918**: Autonomous nutritional control plane
- **meal-planner-6e4z**: Scheduler benchmarks (test infrastructure)

### External Resources

- BEAM VM Performance: https://www.erlang.org/doc/efficiency_guide/
- Gleam HTTP Client: https://hexdocs.pm/gleam_httpc/
- Amdahl's Law: https://en.wikipedia.org/wiki/Amdahl%27s_law

---

**Document Version**: 1.0
**Last Updated**: 2025-12-19
**Maintainer**: Lewis (via Claude Code)
**Review Status**: Ready for implementation
