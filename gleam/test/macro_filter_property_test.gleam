/// Property-based tests for macro filtering
/// Tests that filtering returns correct subsets of items based on macro constraints
///
/// This demonstrates key property testing concepts for the macro filtering feature:
/// - All returned items match the specified criteria
/// - No matching items are excluded (completeness)
/// - Subset relation holds: filtered_count <= total_count
/// - Empty constraints return all items
/// - Tighter constraints return smaller or equal subsets
/// - Boundary values are included correctly (>= and <=)
/// - Multiple constraints work together (AND logic)
///
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/types.{type Macros, Macros}

// Test data - macro values
fn high_protein() -> Macros {
  Macros(protein: 50.0, fat: 10.0, carbs: 30.0)
}

fn balanced() -> Macros {
  Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
}

fn high_fat() -> Macros {
  Macros(protein: 5.0, fat: 45.0, carbs: 10.0)
}

fn high_carb() -> Macros {
  Macros(protein: 8.0, fat: 5.0, carbs: 75.0)
}

fn low_cal() -> Macros {
  Macros(protein: 12.0, fat: 2.0, carbs: 20.0)
}

fn test_macros() -> List(Macros) {
  [high_protein(), balanced(), high_fat(), high_carb(), low_cal()]
}

// Helper: Check if macro matches constraints
fn matches_protein_range(m: Macros, min: option.Option(Float), max: option.Option(Float)) -> Bool {
  let above_min = case min {
    Some(v) -> m.protein >=. v
    None -> True
  }
  let below_max = case max {
    Some(v) -> m.protein <=. v
    None -> True
  }
  above_min && below_max
}

fn matches_fat_range(m: Macros, min: option.Option(Float), max: option.Option(Float)) -> Bool {
  let above_min = case min {
    Some(v) -> m.fat >=. v
    None -> True
  }
  let below_max = case max {
    Some(v) -> m.fat <=. v
    None -> True
  }
  above_min && below_max
}

fn matches_carbs_range(m: Macros, min: option.Option(Float), max: option.Option(Float)) -> Bool {
  let above_min = case min {
    Some(v) -> m.carbs >=. v
    None -> True
  }
  let below_max = case max {
    Some(v) -> m.carbs <=. v
    None -> True
  }
  above_min && below_max
}

// PROPERTY: All returned macros match protein constraints
pub fn all_returned_match_protein_constraint_test() {
  let all = test_macros()
  let min_protein = Some(20.0)
  let max_protein = Some(40.0)
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, min_protein, max_protein) })

  // Verify all returned macros match the constraint
  filtered |> list.each(fn(m) {
    { matches_protein_range(m, min_protein, max_protein) } |> should.be_true
  })
}

// PROPERTY: Subset correctness - filtered_count <= total_count
pub fn filtered_count_lte_total_test() {
  let all = test_macros()
  let total = list.length(all)
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, Some(30.0), None) })
  { list.length(filtered) <= total } |> should.be_true
}

// PROPERTY: Empty constraints return all macros
pub fn no_constraints_returns_all_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, None, None) && matches_fat_range(m, None, None) && matches_carbs_range(m, None, None) })
  list.length(filtered) |> should.equal(list.length(all))
}

// PROPERTY: Tighter protein constraint reduces results
pub fn tighter_protein_constraint_reduces_results_test() {
  let all = test_macros()
  let loose = all |> list.filter(fn(m) { matches_protein_range(m, Some(10.0), None) })
  let tight = all |> list.filter(fn(m) { matches_protein_range(m, Some(30.0), None) })
  { list.length(tight) <= list.length(loose) } |> should.be_true
}

// PROPERTY: Combining constraints reduces results
pub fn combining_constraints_reduces_results_test() {
  let all = test_macros()
  let single = all |> list.filter(fn(m) { matches_protein_range(m, Some(20.0), None) })
  let double = all |> list.filter(fn(m) { matches_protein_range(m, Some(20.0), None) && matches_fat_range(m, None, Some(20.0)) })
  { list.length(double) <= list.length(single) } |> should.be_true
}

// PROPERTY: Minimum boundary inclusive (>=)
pub fn minimum_boundary_inclusive_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, Some(50.0), None) })
  // Should include high_protein with exactly 50.0g protein
  let has_50_protein = filtered |> list.any(fn(m) { m.protein >=. 49.9 && m.protein <=. 50.1 })
  has_50_protein |> should.be_true
}

// PROPERTY: Maximum boundary inclusive (<=)
pub fn maximum_boundary_inclusive_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, None, Some(50.0)) })
  // Should include high_protein with exactly 50.0g protein
  let has_50_protein = filtered |> list.any(fn(m) { m.protein >=. 49.9 && m.protein <=. 50.1 })
  has_50_protein |> should.be_true
}

// PROPERTY: Protein filtering independent
pub fn protein_filter_independent_test() {
  let all = test_macros()
  let min_protein = Some(25.0)
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, min_protein, None) })
  // All should have protein >= 25.0
  filtered |> list.each(fn(m) {
    { m.protein >=. 25.0 } |> should.be_true
  })
}

// PROPERTY: Fat filtering independent
pub fn fat_filter_independent_test() {
  let all = test_macros()
  let max_fat = Some(15.0)
  let filtered = all |> list.filter(fn(m) { matches_fat_range(m, None, max_fat) })
  // All should have fat <= 15.0
  filtered |> list.each(fn(m) {
    { m.fat <=. 15.0 } |> should.be_true
  })
}

// PROPERTY: Carbs filtering independent
pub fn carbs_filter_independent_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_carbs_range(m, Some(15.0), Some(55.0)) })
  // All should have 15 <= carbs <= 55
  filtered |> list.each(fn(m) {
    { m.carbs >=. 15.0 && m.carbs <=. 55.0 } |> should.be_true
  })
}

// PROPERTY: Multiple constraints (AND logic)
pub fn multiple_constraints_and_logic_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) {
    matches_protein_range(m, Some(25.0), None)
    && matches_fat_range(m, Some(5.0), Some(25.0))
  })
  // All must satisfy ALL constraints
  filtered |> list.each(fn(m) {
    { m.protein >=. 25.0 } |> should.be_true
    { m.fat >=. 5.0 && m.fat <=. 25.0 } |> should.be_true
  })
}

// PROPERTY: All macros constrained simultaneously
pub fn all_macros_constrained_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) {
    matches_protein_range(m, Some(20.0), Some(60.0))
    && matches_fat_range(m, Some(5.0), Some(30.0))
    && matches_carbs_range(m, Some(20.0), Some(60.0))
  })
  // All must satisfy all three constraints
  filtered |> list.each(fn(m) {
    { m.protein >=. 20.0 && m.protein <=. 60.0 } |> should.be_true
    { m.fat >=. 5.0 && m.fat <=. 30.0 } |> should.be_true
    { m.carbs >=. 20.0 && m.carbs <=. 60.0 } |> should.be_true
  })
}

// PROPERTY: Idempotent filtering
pub fn idempotent_filtering_test() {
  let all = test_macros()
  let once = all |> list.filter(fn(m) { matches_protein_range(m, Some(20.0), None) })
  let twice = once |> list.filter(fn(m) { matches_protein_range(m, Some(20.0), None) })
  once |> should.equal(twice)
}

// PROPERTY: Contradictory constraints return empty
pub fn contradictory_constraints_empty_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, Some(100.0), Some(50.0)) })
  list.length(filtered) |> should.equal(0)
}

// PROPERTY: Exact match with min = max
pub fn exact_match_test() {
  let all = test_macros()
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, Some(30.0), Some(30.0)) })
  // Should only match balanced with exactly 30.0g protein
  let count_30 = filtered |> list.filter(fn(m) { m.protein >=. 29.9 && m.protein <=. 30.1 }) |> list.length
  list.length(filtered) |> should.equal(count_30)
}

// PROPERTY: Verify no matching items excluded
pub fn no_matching_excluded_test() {
  let all = test_macros()
  let should_match = all |> list.filter(fn(m) { m.protein >=. 25.0 && m.protein <=. 50.0 })
  let filtered = all |> list.filter(fn(m) { matches_protein_range(m, Some(25.0), Some(50.0)) })
  list.length(filtered) |> should.equal(list.length(should_match))
}
