/// Comprehensive tests for recipe filtering by macros
/// Tests recipe filtering capabilities with various macro constraints
///
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/types.{
  type Macros, type Recipe, High, Ingredient, Low, Macros, Recipe,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Fixtures
// ============================================================================

fn high_protein_recipe() -> Recipe {
  Recipe(
    id: id.recipe_id("grilled-chicken-breast"),
    name: "Grilled Chicken Breast",
    ingredients: [
      Ingredient(name: "chicken breast", quantity: "200g"),
      Ingredient(name: "olive oil", quantity: "1 tsp"),
    ],
    instructions: ["Grill chicken.", "Serve hot."],
    macros: Macros(protein: 50.0, fat: 10.0, carbs: 30.0),
    servings: 1,
    category: "Protein",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn balanced_recipe() -> Recipe {
  Recipe(
    id: id.recipe_id("vegetable-stir-fry"),
    name: "Vegetable Stir Fry",
    ingredients: [
      Ingredient(name: "vegetables", quantity: "300g"),
      Ingredient(name: "tofu", quantity: "150g"),
    ],
    instructions: ["Heat oil.", "Stir fry vegetables."],
    macros: Macros(protein: 30.0, fat: 20.0, carbs: 50.0),
    servings: 2,
    category: "Vegan",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn high_fat_recipe() -> Recipe {
  Recipe(
    id: id.recipe_id("salmon-with-butter"),
    name: "Salmon with Butter Sauce",
    ingredients: [
      Ingredient(name: "salmon fillet", quantity: "200g"),
      Ingredient(name: "butter", quantity: "50g"),
    ],
    instructions: ["Cook salmon.", "Make butter sauce."],
    macros: Macros(protein: 5.0, fat: 45.0, carbs: 10.0),
    servings: 1,
    category: "Fish",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn high_carb_recipe() -> Recipe {
  Recipe(
    id: id.recipe_id("rice-and-beans"),
    name: "Rice and Beans",
    ingredients: [
      Ingredient(name: "brown rice", quantity: "200g"),
      Ingredient(name: "black beans", quantity: "150g"),
    ],
    instructions: ["Cook rice.", "Cook beans."],
    macros: Macros(protein: 8.0, fat: 5.0, carbs: 75.0),
    servings: 3,
    category: "Vegan",
    fodmap_level: High,
    vertical_compliant: False,
  )
}

fn low_cal_recipe() -> Recipe {
  Recipe(
    id: id.recipe_id("salad-with-chicken"),
    name: "Salad with Grilled Chicken",
    ingredients: [
      Ingredient(name: "mixed greens", quantity: "200g"),
      Ingredient(name: "chicken breast", quantity: "100g"),
    ],
    instructions: ["Chop vegetables.", "Grill chicken."],
    macros: Macros(protein: 12.0, fat: 2.0, carbs: 20.0),
    servings: 1,
    category: "Salad",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn test_recipes() -> List(Recipe) {
  [
    high_protein_recipe(),
    balanced_recipe(),
    high_fat_recipe(),
    high_carb_recipe(),
    low_cal_recipe(),
  ]
}

// ============================================================================
// Helper Functions for Filtering
// ============================================================================

fn filter_by_protein(
  recipes: List(Recipe),
  min: option.Option(Float),
  max: option.Option(Float),
) -> List(Recipe) {
  list.filter(recipes, fn(recipe) {
    let above_min = case min {
      Some(v) -> recipe.macros.protein >=. v
      None -> True
    }
    let below_max = case max {
      Some(v) -> recipe.macros.protein <=. v
      None -> True
    }
    above_min && below_max
  })
}

fn filter_by_fat(
  recipes: List(Recipe),
  min: option.Option(Float),
  max: option.Option(Float),
) -> List(Recipe) {
  list.filter(recipes, fn(recipe) {
    let above_min = case min {
      Some(v) -> recipe.macros.fat >=. v
      None -> True
    }
    let below_max = case max {
      Some(v) -> recipe.macros.fat <=. v
      None -> True
    }
    above_min && below_max
  })
}

fn filter_by_carbs(
  recipes: List(Recipe),
  min: option.Option(Float),
  max: option.Option(Float),
) -> List(Recipe) {
  list.filter(recipes, fn(recipe) {
    let above_min = case min {
      Some(v) -> recipe.macros.carbs >=. v
      None -> True
    }
    let below_max = case max {
      Some(v) -> recipe.macros.carbs <=. v
      None -> True
    }
    above_min && below_max
  })
}

// ============================================================================
// PROTEIN FILTERING TESTS
// ============================================================================

pub fn all_returned_match_protein_constraint_test() {
  let all = test_recipes()
  let min_protein = Some(25.0)
  let max_protein = Some(40.0)
  let filtered = filter_by_protein(all, min_protein, max_protein)

  filtered
  |> list.each(fn(recipe) {
    let matches =
      recipe.macros.protein >=. 25.0 && recipe.macros.protein <=. 40.0
    matches |> should.be_true
  })
}

pub fn protein_filter_excludes_out_of_range_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(45.0), None)

  list.length(filtered) |> should.equal(1)
  let first = list.first(filtered)
  case first {
    Ok(recipe) -> recipe.macros.protein |> should.equal(50.0)
    Error(_) -> should.fail()
  }
}

pub fn protein_minimum_boundary_inclusive_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(50.0), None)

  let has_exact =
    filtered |> list.any(fn(r) { r.macros.protein >=. 49.9 })
  has_exact |> should.be_true
}

pub fn protein_maximum_boundary_inclusive_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, None, Some(50.0))

  let has_exact =
    filtered |> list.any(fn(r) { r.macros.protein <=. 50.1 })
  has_exact |> should.be_true
}

pub fn protein_no_constraint_returns_all_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, None, None)

  list.length(filtered) |> should.equal(list.length(all))
}

// ============================================================================
// FAT FILTERING TESTS
// ============================================================================

pub fn all_returned_match_fat_constraint_test() {
  let all = test_recipes()
  let min_fat = Some(5.0)
  let max_fat = Some(25.0)
  let filtered = filter_by_fat(all, min_fat, max_fat)

  filtered
  |> list.each(fn(recipe) {
    let matches = recipe.macros.fat >=. 5.0 && recipe.macros.fat <=. 25.0
    matches |> should.be_true
  })
}

pub fn fat_filter_excludes_high_fat_test() {
  let all = test_recipes()
  let filtered = filter_by_fat(all, None, Some(15.0))

  let has_high_fat =
    filtered |> list.any(fn(r) { r.macros.fat >=. 40.0 })
  has_high_fat |> should.be_false
}

pub fn fat_minimum_boundary_inclusive_test() {
  let all = test_recipes()
  let filtered = filter_by_fat(all, Some(45.0), None)

  list.length(filtered) |> should.equal(1)
}

// ============================================================================
// CARBS FILTERING TESTS
// ============================================================================

pub fn all_returned_match_carbs_constraint_test() {
  let all = test_recipes()
  let min_carbs = Some(20.0)
  let max_carbs = Some(60.0)
  let filtered = filter_by_carbs(all, min_carbs, max_carbs)

  filtered
  |> list.each(fn(recipe) {
    let matches = recipe.macros.carbs >=. 20.0 && recipe.macros.carbs <=. 60.0
    matches |> should.be_true
  })
}

pub fn carbs_filter_excludes_high_carbs_test() {
  let all = test_recipes()
  let filtered = filter_by_carbs(all, None, Some(40.0))

  let has_high_carbs =
    filtered |> list.any(fn(r) { r.macros.carbs >=. 70.0 })
  has_high_carbs |> should.be_false
}

pub fn carbs_minimum_boundary_inclusive_test() {
  let all = test_recipes()
  let filtered = filter_by_carbs(all, Some(75.0), None)

  list.length(filtered) |> should.equal(1)
}

// ============================================================================
// COMBINED FILTERING TESTS
// ============================================================================

pub fn combining_protein_and_fat_test() {
  let all = test_recipes()
  let filtered =
    all
    |> filter_by_protein(Some(20.0), None)
    |> filter_by_fat(None, Some(25.0))

  filtered
  |> list.each(fn(recipe) {
    { recipe.macros.protein >=. 20.0 } |> should.be_true
    { recipe.macros.fat <=. 25.0 } |> should.be_true
  })
}

pub fn tighter_protein_constraint_reduces_results_test() {
  let all = test_recipes()
  let loose = filter_by_protein(all, Some(10.0), None)
  let tight = filter_by_protein(all, Some(30.0), None)

  { list.length(tight) <= list.length(loose) } |> should.be_true
}

// ============================================================================
// EDGE CASE TESTS
// ============================================================================

pub fn contradictory_constraints_returns_empty_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(100.0), Some(50.0))

  list.length(filtered) |> should.equal(0)
}

pub fn exact_match_protein_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(30.0), Some(30.0))

  filtered
  |> list.each(fn(recipe) {
    { recipe.macros.protein >=. 29.9 && recipe.macros.protein <=. 30.1 }
    |> should.be_true
  })
}

pub fn filter_empty_list_test() {
  let empty: List(Recipe) = []
  let filtered = filter_by_protein(empty, Some(20.0), None)

  list.length(filtered) |> should.equal(0)
}

pub fn filter_single_recipe_match_test() {
  let single = [high_protein_recipe()]
  let filtered = filter_by_protein(single, Some(40.0), None)

  list.length(filtered) |> should.equal(1)
}

pub fn filter_single_recipe_no_match_test() {
  let single = [low_cal_recipe()]
  let filtered = filter_by_protein(single, Some(20.0), None)

  list.length(filtered) |> should.equal(0)
}

// ============================================================================
// COMPLETENESS TESTS
// ============================================================================

pub fn no_matching_recipes_excluded_test() {
  let all = test_recipes()
  let expected =
    all |> list.filter(fn(r) { r.macros.protein >=. 25.0 && r.macros.protein <=. 50.0 })
  let filtered = filter_by_protein(all, Some(25.0), Some(50.0))

  list.length(filtered) |> should.equal(list.length(expected))
}

pub fn exact_result_count_for_constraint_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(40.0), None)

  list.length(filtered) |> should.equal(2)
}

pub fn idempotent_filtering_test() {
  let all = test_recipes()
  let once = filter_by_protein(all, Some(20.0), None)
  let twice =
    once |> filter_by_protein(Some(20.0), None)

  once |> should.equal(twice)
}

// ============================================================================
// SUBSET PROPERTY TESTS
// ============================================================================

pub fn filtered_is_subset_of_original_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(30.0), None)

  { list.length(filtered) <= list.length(all) } |> should.be_true
}

pub fn all_filtered_exist_in_original_test() {
  let all = test_recipes()
  let filtered = filter_by_protein(all, Some(30.0), None)

  filtered
  |> list.each(fn(recipe) {
    let exists =
      all |> list.any(fn(r) { r.id == recipe.id })
    exists |> should.be_true
  })
}
