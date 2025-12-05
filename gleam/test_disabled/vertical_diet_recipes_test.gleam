/// Comprehensive tests for Vertical Diet recipes
/// Validates recipe data structures, nutritional accuracy, and compliance
import gleam/float
import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/types.{type Macros, type Recipe, Low}
import meal_planner/vertical_diet_recipes

// ============================================================================
// Helper Functions
// ============================================================================

/// Helper to compare floats with tolerance for floating point precision
fn float_close(actual: Float, expected: Float, tolerance: Float) -> Bool {
  float.absolute_value(actual -. expected) <. tolerance
}

/// Validate that a recipe has all required fields populated
fn validate_recipe_structure(recipe: Recipe) -> Bool {
  // ID should be non-empty and follow naming convention
  let valid_id =
    string.length(recipe.id) > 0 && string.starts_with(recipe.id, "vd-")

  // Name should be non-empty
  let valid_name = string.length(recipe.name) > 0

  // Should have at least one ingredient
  let valid_ingredients = recipe.ingredients != []

  // Should have at least one instruction
  let valid_instructions = recipe.instructions != []

  // Servings should be positive
  let valid_servings = recipe.servings > 0

  // Category should be non-empty
  let valid_category = string.length(recipe.category) > 0

  valid_id
  && valid_name
  && valid_ingredients
  && valid_instructions
  && valid_servings
  && valid_category
}

/// Check if macros are reasonable (non-negative, not absurdly high)
fn validate_macros(m: Macros) -> Bool {
  m.protein >=. 0.0
  && m.fat >=. 0.0
  && m.carbs >=. 0.0
  && m.protein <. 200.0
  // Max 200g protein per serving
  && m.fat <. 200.0
  // Max 200g fat per serving
  && m.carbs <. 200.0
  // Max 200g carbs per serving
}

/// Calculate total calories from macros (4-9-4 rule)
fn calculate_calories(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

// ============================================================================
// Recipe Collection Tests
// ============================================================================

pub fn all_recipes_returns_list_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  // Use pattern matching instead of list.length() for O(1) check
  case recipes {
    [] -> should.fail()
    [_, ..] -> should.be_true(True)
  }
}

pub fn all_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  // According to source file: 12 red meat + 6 rice + 7 vegetable = 25 recipes
  list.length(recipes) |> should.equal(25)
}

pub fn all_recipes_have_unique_ids_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let ids = list.map(recipes, fn(r) { r.id })
  let unique_ids = list.unique(ids)
  list.length(ids) |> should.equal(list.length(unique_ids))
}

pub fn all_recipes_have_unique_names_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let names = list.map(recipes, fn(r) { r.name })
  let unique_names = list.unique(names)
  list.length(names) |> should.equal(list.length(unique_names))
}

// ============================================================================
// Recipe Structure Validation Tests
// ============================================================================

pub fn all_recipes_have_valid_structure_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_valid = list.all(recipes, validate_recipe_structure)
  all_valid |> should.be_true()
}

pub fn all_recipes_have_vd_prefix_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_have_prefix =
    list.all(recipes, fn(r) { string.starts_with(r.id, "vd-") })
  all_have_prefix |> should.be_true()
}

pub fn all_recipe_ids_follow_pattern_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  // IDs should be like "vd-ribeye-01", "vd-rice-01", etc.
  let all_valid =
    list.all(recipes, fn(r) {
      let parts = string.split(r.id, "-")
      // Use pattern matching instead of list.length() >= 3
      case parts {
        [_, _, _, ..] -> True
        _ -> False
      }
    })
  all_valid |> should.be_true()
}

pub fn all_recipes_have_positive_servings_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_positive = list.all(recipes, fn(r) { r.servings > 0 })
  all_positive |> should.be_true()
}

pub fn all_recipes_have_ingredients_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_have_ingredients = list.all(recipes, fn(r) { r.ingredients != [] })
  all_have_ingredients |> should.be_true()
}

pub fn all_recipes_have_instructions_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_have_instructions = list.all(recipes, fn(r) { r.instructions != [] })
  all_have_instructions |> should.be_true()
}

// ============================================================================
// Vertical Diet Compliance Tests
// ============================================================================

pub fn all_recipes_marked_vertical_compliant_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_compliant = list.all(recipes, fn(r) { r.vertical_compliant })
  all_compliant |> should.be_true()
}

pub fn all_recipes_have_low_fodmap_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_low_fodmap = list.all(recipes, fn(r) { r.fodmap_level == Low })
  all_low_fodmap |> should.be_true()
}

pub fn all_recipes_pass_vertical_compliance_check_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_compliant =
    list.all(recipes, fn(r) { r.vertical_compliant && r.fodmap_level == Low })
  all_compliant |> should.be_true()
}

// ============================================================================
// Category Classification Tests
// ============================================================================

pub fn recipes_have_valid_categories_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let valid_categories = [
    "beef-main", "bison-main", "lamb-main", "rice-side", "vegetable-side",
  ]

  let all_valid_category =
    list.all(recipes, fn(r) { list.contains(valid_categories, r.category) })
  all_valid_category |> should.be_true()
}

pub fn beef_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let beef_recipes = list.filter(recipes, fn(r) { r.category == "beef-main" })
  // Should have 10 beef main dishes (from inspection of source)
  list.length(beef_recipes) |> should.equal(10)
}

pub fn bison_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let bison_recipes = list.filter(recipes, fn(r) { r.category == "bison-main" })
  // Should have 2 bison recipes
  list.length(bison_recipes) |> should.equal(2)
}

pub fn lamb_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let lamb_recipes = list.filter(recipes, fn(r) { r.category == "lamb-main" })
  // Should have 2 lamb recipes
  list.length(lamb_recipes) |> should.equal(2)
}

pub fn rice_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice_recipes = list.filter(recipes, fn(r) { r.category == "rice-side" })
  // Should have 6 rice preparations
  list.length(rice_recipes) |> should.equal(6)
}

pub fn vegetable_recipes_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let veg_recipes =
    list.filter(recipes, fn(r) { r.category == "vegetable-side" })
  // Should have 7 vegetable sides
  list.length(veg_recipes) |> should.equal(7)
}

// ============================================================================
// Macronutrient Validation Tests
// ============================================================================

pub fn all_recipes_have_valid_macros_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_valid_macros = list.all(recipes, fn(r) { validate_macros(r.macros) })
  all_valid_macros |> should.be_true()
}

pub fn all_recipes_have_non_negative_macros_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_non_negative =
    list.all(recipes, fn(r) {
      r.macros.protein >=. 0.0 && r.macros.fat >=. 0.0 && r.macros.carbs >=. 0.0
    })
  all_non_negative |> should.be_true()
}

pub fn beef_recipes_have_protein_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let beef_recipes = list.filter(recipes, fn(r) { r.category == "beef-main" })
  // All beef recipes should have significant protein (>30g per serving)
  let all_have_protein =
    list.all(beef_recipes, fn(r) { r.macros.protein >. 30.0 })
  all_have_protein |> should.be_true()
}

pub fn rice_recipes_have_carbs_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice_recipes = list.filter(recipes, fn(r) { r.category == "rice-side" })
  // All rice recipes should have significant carbs (>40g per serving)
  let all_have_carbs = list.all(rice_recipes, fn(r) { r.macros.carbs >. 40.0 })
  all_have_carbs |> should.be_true()
}

pub fn rice_recipes_low_fat_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice_recipes = list.filter(recipes, fn(r) { r.category == "rice-side" })
  // Rice should be relatively low fat (<15g per serving)
  let all_low_fat = list.all(rice_recipes, fn(r) { r.macros.fat <. 15.0 })
  all_low_fat |> should.be_true()
}

// ============================================================================
// Specific Recipe Tests (Sample Validation)
// ============================================================================

pub fn classic_grilled_ribeye_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let ribeye =
    list.find(recipes, fn(r) { r.id == "vd-ribeye-01" })
    |> should.be_ok()

  ribeye.name |> should.equal("Classic Grilled Ribeye")
  ribeye.servings |> should.equal(1)
  ribeye.category |> should.equal("beef-main")
  ribeye.vertical_compliant |> should.be_true()
  ribeye.fodmap_level |> should.equal(Low)

  // Check macros
  ribeye.macros.protein |> should.equal(48.0)
  ribeye.macros.fat |> should.equal(32.0)
  ribeye.macros.carbs |> should.equal(0.0)

  // Check ingredients (should have 4)
  list.length(ribeye.ingredients) |> should.equal(4)

  // Check instructions (should have 6)
  list.length(ribeye.instructions) |> should.equal(6)
}

pub fn simple_white_rice_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice =
    list.find(recipes, fn(r) { r.id == "vd-rice-01" })
    |> should.be_ok()

  rice.name |> should.equal("Simple White Rice")
  rice.servings |> should.equal(4)
  rice.category |> should.equal("rice-side")

  // Check macros - rice should be high carb, low fat
  rice.macros.carbs |> should.equal(90.0)
  rice.macros.fat |> should.equal(1.0)
  rice.macros.protein |> should.equal(8.0)
}

pub fn ground_beef_rice_bowl_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let bowl =
    list.find(recipes, fn(r) { r.id == "vd-beef-rice-03" })
    |> should.be_ok()

  bowl.name |> should.equal("Ground Beef and Rice Bowl")
  bowl.servings |> should.equal(1)

  // Should have balanced macros (protein + carbs)
  bowl.macros.protein |> should.equal(40.0)
  bowl.macros.carbs |> should.equal(45.0)
  bowl.macros.fat |> should.equal(18.0)
}

pub fn bison_burger_patty_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let bison =
    list.find(recipes, fn(r) { r.id == "vd-bison-05" })
    |> should.be_ok()

  bison.name |> should.equal("Bison Burger Patty")
  bison.category |> should.equal("bison-main")
  bison.servings |> should.equal(1)

  // Bison is leaner than beef
  bison.macros.protein |> should.equal(38.0)
  bison.macros.fat |> should.equal(12.0)
  bison.macros.carbs |> should.equal(0.0)
}

pub fn steamed_carrots_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let carrots =
    list.find(recipes, fn(r) { r.id == "vd-veg-carrots-01" })
    |> should.be_ok()

  carrots.name |> should.equal("Simple Steamed Carrots")
  carrots.category |> should.equal("vegetable-side")
  carrots.servings |> should.equal(4)

  // Vegetables should be low calorie
  { carrots.macros.protein <. 10.0 } |> should.be_true()
  { carrots.macros.fat <. 10.0 } |> should.be_true()
}

// ============================================================================
// Ingredient Tests
// ============================================================================

pub fn all_ingredients_have_name_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_ingredients = list.flat_map(recipes, fn(r) { r.ingredients })
  let all_have_name =
    list.all(all_ingredients, fn(i) { string.length(i.name) > 0 })
  all_have_name |> should.be_true()
}

pub fn all_ingredients_have_quantity_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_ingredients = list.flat_map(recipes, fn(r) { r.ingredients })
  let all_have_quantity =
    list.all(all_ingredients, fn(i) { string.length(i.quantity) > 0 })
  all_have_quantity |> should.be_true()
}

pub fn ingredient_quantities_are_reasonable_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_ingredients = list.flat_map(recipes, fn(r) { r.ingredients })
  // All quantities should contain numbers or common measurements
  let all_reasonable =
    list.all(all_ingredients, fn(i) {
      string.contains(i.quantity, "oz")
      || string.contains(i.quantity, "lb")
      || string.contains(i.quantity, "cup")
      || string.contains(i.quantity, "tbsp")
      || string.contains(i.quantity, "tsp")
      || string.contains(i.quantity, "g")
      || string.contains(i.quantity, "0")
      || string.contains(i.quantity, "1")
      || string.contains(i.quantity, "2")
      || string.contains(i.quantity, "3")
      || string.contains(i.quantity, "4")
      || string.contains(i.quantity, "5")
      || string.contains(i.quantity, "6")
      || string.contains(i.quantity, "7")
      || string.contains(i.quantity, "8")
      || string.contains(i.quantity, "9")
    })
  all_reasonable |> should.be_true()
}

// ============================================================================
// Instruction Tests
// ============================================================================

pub fn all_instructions_non_empty_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let all_instructions = list.flat_map(recipes, fn(r) { r.instructions })
  let all_non_empty = list.all(all_instructions, fn(i) { string.length(i) > 0 })
  all_non_empty |> should.be_true()
}

pub fn recipes_have_reasonable_instruction_count_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  // All recipes should have between 3-10 instructions
  let all_reasonable =
    list.all(recipes, fn(r) {
      let count = list.length(r.instructions)
      count >= 3 && count <= 10
    })
  all_reasonable |> should.be_true()
}

// ============================================================================
// Serving Size Tests
// ============================================================================

pub fn serving_sizes_are_reasonable_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  // Servings should be between 1 and 10
  let all_reasonable =
    list.all(recipes, fn(r) { r.servings >= 1 && r.servings <= 10 })
  all_reasonable |> should.be_true()
}

pub fn main_dishes_typically_fewer_servings_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let main_dishes =
    list.filter(recipes, fn(r) {
      r.category == "beef-main"
      || r.category == "bison-main"
      || r.category == "lamb-main"
    })
  // Main protein dishes typically 1-2 servings
  let most_single_serving =
    list.count(main_dishes, fn(r) { r.servings <= 2 })
    >= list.length(main_dishes) / 2
  most_single_serving |> should.be_true()
}

// ============================================================================
// Calorie Calculation Tests
// ============================================================================

pub fn ribeye_calorie_calculation_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let ribeye =
    list.find(recipes, fn(r) { r.id == "vd-ribeye-01" })
    |> should.be_ok()

  // Protein: 48g * 4 = 192 cal
  // Fat: 32g * 9 = 288 cal
  // Carbs: 0g * 4 = 0 cal
  // Total: 480 cal
  let calories = calculate_calories(ribeye.macros)
  float_close(calories, 480.0, 0.01) |> should.be_true()
}

pub fn rice_calorie_calculation_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice =
    list.find(recipes, fn(r) { r.id == "vd-rice-01" })
    |> should.be_ok()

  // Protein: 8g * 4 = 32 cal
  // Fat: 1g * 9 = 9 cal
  // Carbs: 90g * 4 = 360 cal
  // Total: 401 cal per serving (4 servings total)
  let calories = calculate_calories(rice.macros)
  float_close(calories, 401.0, 0.01) |> should.be_true()
}

// ============================================================================
// Recipe Pairing Tests (Nutritional Balance)
// ============================================================================

pub fn beef_and_rice_makes_balanced_meal_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let beef =
    list.find(recipes, fn(r) { r.id == "vd-ribeye-01" })
    |> should.be_ok()
  let rice =
    list.find(recipes, fn(r) { r.id == "vd-rice-01" })
    |> should.be_ok()

  // Combined should have good protein and carbs
  let combined_protein = beef.macros.protein +. rice.macros.protein
  let combined_carbs = beef.macros.carbs +. rice.macros.carbs

  // Should have >50g protein and >80g carbs
  { combined_protein >. 50.0 } |> should.be_true()
  { combined_carbs >. 80.0 } |> should.be_true()
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn chuck_roast_multiple_servings_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let roast =
    list.find(recipes, fn(r) { r.id == "vd-chuck-roast-12" })
    |> should.be_ok()

  // Chuck roast should have 8 servings (bulk cooking)
  roast.servings |> should.equal(8)

  // Should still have reasonable per-serving macros
  validate_macros(roast.macros) |> should.be_true()
}

pub fn zero_carb_recipes_exist_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let zero_carb_recipes = list.filter(recipes, fn(r) { r.macros.carbs == 0.0 })
  // Should have several zero-carb protein recipes - use pattern matching for O(1)
  case zero_carb_recipes {
    [] -> should.fail()
    [_, ..] -> should.be_true(True)
  }
}

pub fn all_beef_ingredients_present_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let beef_recipes = list.filter(recipes, fn(r) { r.category == "beef-main" })

  // Every beef recipe should mention beef in ingredients
  let all_have_beef =
    list.all(beef_recipes, fn(r) {
      list.any(r.ingredients, fn(i) {
        string.contains(string.lowercase(i.name), "beef")
        || string.contains(string.lowercase(i.name), "ribeye")
        || string.contains(string.lowercase(i.name), "strip")
        || string.contains(string.lowercase(i.name), "sirloin")
        || string.contains(string.lowercase(i.name), "chuck")
      })
    })
  all_have_beef |> should.be_true()
}

pub fn rice_recipes_use_white_rice_test() {
  let recipes = vertical_diet_recipes.all_recipes()
  let rice_recipes = list.filter(recipes, fn(r) { r.category == "rice-side" })

  // All rice recipes should mention rice in ingredients
  let all_use_rice =
    list.all(rice_recipes, fn(r) {
      list.any(r.ingredients, fn(i) {
        string.contains(string.lowercase(i.name), "rice")
      })
    })
  all_use_rice |> should.be_true()
}
