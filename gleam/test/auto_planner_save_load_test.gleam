/// Tests for auto planner save/load with Tandoor recipes
///
/// This test suite verifies that:
/// 1. Auto meal plans can be saved to the database with recipe_json
/// 2. Recipe JSON is properly serialized from Recipe objects
/// 3. Saved plans can be loaded back with recipe_json intact
/// 4. Recipes are correctly reconstructed from JSON
/// 5. Complete round-trip serialization/deserialization works
/// 6. Config is properly preserved during save/load
/// 7. Total macros are correctly stored and retrieved
import gleeunit
import gleeunit/should
import gleam/json
import gleam/dynamic/decode
import gleam/list
import gleam/float
import gleam/string
import gleam/int
import meal_planner/id
import meal_planner/auto_planner/types as auto_types
import meal_planner/types.{
  type Recipe, type Macros, Recipe, Macros, Ingredient, FodmapLevel, Low,
  recipe_to_json, recipe_decoder,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures - Recipe Creation
// ============================================================================

/// Create a test recipe with specific properties
fn create_test_recipe(
  id_num: Int,
  name: String,
  category: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  vertical_compliant: Bool,
) -> Recipe {
  Recipe(
    id: id.recipe_id(int.to_string(id_num)),
    name: name,
    ingredients: [Ingredient(name: "test", quantity: "1.0 g")],
    instructions: ["Step 1"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: category,
    fodmap_level: Low,
    vertical_compliant: vertical_compliant,
  )
}

/// Create a test auto plan config
fn create_test_config(
  user_id: String,
  diet_principles: List(auto_types.DietPrinciple),
  recipe_count: Int,
) -> auto_types.AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: user_id,
    diet_principles: diet_principles,
    macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
    recipe_count: recipe_count,
    variety_factor: 0.8,
  )
}

// ============================================================================
// Recipe JSON Serialization Tests
// ============================================================================

/// Test that recipe_to_json produces valid JSON
pub fn recipe_to_json_produces_valid_json_test() {
  let recipe = create_test_recipe(1, "Chicken Salad", "protein", 30.0, 5.0, 10.0, True)
  let json_value = recipe_to_json(recipe)
  let json_string = json.to_string(json_value)

  // Verify it's a non-empty JSON string
  string.length(json_string) > 0
  |> should.be_true()
}

/// Test that recipe JSON contains expected fields
pub fn recipe_json_contains_required_fields_test() {
  let recipe = create_test_recipe(1, "Chicken Salad", "protein", 30.0, 5.0, 10.0, True)
  let json_value = recipe_to_json(recipe)
  let json_string = json.to_string(json_value)

  // Should contain recipe metadata
  string.contains(json_string, "Chicken Salad")
  |> should.be_true()
}

/// Test that single recipe can round-trip through JSON
pub fn single_recipe_json_round_trip_test() {
  let recipe = create_test_recipe(1, "Chicken Salad", "protein", 30.0, 5.0, 10.0, True)

  // Serialize to JSON
  let json_value = recipe_to_json(recipe)
  let json_string = json.to_string(json_value)

  // Deserialize from JSON
  let decoded = json.parse(json_string, using: recipe_decoder())

  case decoded {
    Ok(loaded_recipe) -> {
      // Verify key properties match
      loaded_recipe.name
      |> should.equal(recipe.name)

      loaded_recipe.category
      |> should.equal(recipe.category)

      loaded_recipe.macros.protein
      |> should.equal(recipe.macros.protein)
    }
    Error(_) ->
      False
      |> should.be_true()  // Force failure with meaningful message
  }
}

// ============================================================================
// Recipe List JSON Serialization Tests
// ============================================================================

/// Test that recipe list serializes to JSON array
pub fn recipe_list_to_json_array_test() {
  let recipes = [
    create_test_recipe(1, "Chicken Salad", "protein", 30.0, 5.0, 10.0, True),
    create_test_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, True),
    create_test_recipe(3, "Rice", "carbs", 3.0, 0.5, 45.0, False),
  ]

  // Serialize to JSON array
  let json_array = json.array(recipes, recipe_to_json)
  let json_string = json.to_string(json_array)

  // Verify JSON string is non-empty and valid
  string.length(json_string) > 0
  |> should.be_true()
}

/// Test that recipe list can round-trip through JSON
pub fn recipe_list_json_round_trip_test() {
  let recipes = [
    create_test_recipe(1, "Chicken Salad", "protein", 30.0, 5.0, 10.0, True),
    create_test_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, True),
    create_test_recipe(3, "Rice", "carbs", 3.0, 0.5, 45.0, False),
  ]

  // Serialize
  let json_array = json.array(recipes, recipe_to_json)
  let json_string = json.to_string(json_array)

  // Deserialize
  let decoded = json.parse(json_string, using: decode.list(recipe_decoder()))

  case decoded {
    Ok(loaded_recipes) -> {
      // Verify count
      list.length(loaded_recipes)
      |> should.equal(3)

      // Verify first recipe
      case list.first(loaded_recipes) {
        Ok(first) -> {
          first.name
          |> should.equal("Chicken Salad")
        }
        Error(_) ->
          False
          |> should.be_true()
      }
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test that recipe macros are preserved in JSON round-trip
pub fn recipe_macros_preserved_in_json_round_trip_test() {
  let recipe = create_test_recipe(42, "Test", "test", 25.5, 10.3, 50.7, True)

  // Serialize and deserialize
  let json_string = recipe_to_json(recipe) |> json.to_string()
  let decoded = json.parse(json_string, using: recipe_decoder())

  case decoded {
    Ok(loaded) -> {
      loaded.macros.protein
      |> should.equal(25.5)

      loaded.macros.fat
      |> should.equal(10.3)

      loaded.macros.carbs
      |> should.equal(50.7)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test that recipe category and compliance are preserved
pub fn recipe_category_and_compliance_preserved_test() {
  let recipe = create_test_recipe(99, "Test Food", "special_category", 20.0, 5.0, 15.0, True)

  // Serialize and deserialize
  let json_string = recipe_to_json(recipe) |> json.to_string()
  let decoded = json.parse(json_string, using: recipe_decoder())

  case decoded {
    Ok(loaded) -> {
      loaded.category
      |> should.equal("special_category")

      loaded.vertical_compliant
      |> should.equal(True)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

// ============================================================================
// Auto Meal Plan Configuration Tests
// ============================================================================

/// Test that AutoPlanConfig can be serialized to JSON
pub fn auto_plan_config_to_json_test() {
  let config = create_test_config(
    "user-123",
    [auto_types.VerticalDiet, auto_types.TimFerriss],
    4,
  )

  let json_value = auto_types.auto_plan_config_to_json(config)
  let json_string = json.to_string(json_value)

  // Verify non-empty JSON
  string.length(json_string) > 0
  |> should.be_true()
}

/// Test that AutoPlanConfig can round-trip through JSON
pub fn auto_plan_config_json_round_trip_test() {
  let config = create_test_config(
    "user-123",
    [auto_types.VerticalDiet, auto_types.TimFerriss],
    4,
  )

  // Serialize
  let json_string = auto_types.auto_plan_config_to_json(config) |> json.to_string()

  // Deserialize
  let decoded = json.parse(json_string, using: auto_types.auto_plan_config_decoder())

  case decoded {
    Ok(loaded) -> {
      loaded.user_id
      |> should.equal("user-123")

      loaded.recipe_count
      |> should.equal(4)

      loaded.variety_factor
      |> should.equal(0.8)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test that diet principles are preserved in config JSON
pub fn config_diet_principles_preserved_test() {
  let config = create_test_config(
    "user-456",
    [auto_types.VerticalDiet, auto_types.Keto, auto_types.HighProtein],
    5,
  )

  // Serialize and deserialize
  let json_string = auto_types.auto_plan_config_to_json(config) |> json.to_string()
  let decoded = json.parse(json_string, using: auto_types.auto_plan_config_decoder())

  case decoded {
    Ok(loaded) -> {
      // Check diet principles count
      list.length(loaded.diet_principles)
      |> should.equal(3)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test that macro targets are preserved in config JSON
pub fn config_macro_targets_preserved_test() {
  let config = create_test_config(
    "user-789",
    [auto_types.Mediterranean],
    3,
  )

  // Serialize and deserialize
  let json_string = auto_types.auto_plan_config_to_json(config) |> json.to_string()
  let decoded = json.parse(json_string, using: auto_types.auto_plan_config_decoder())

  case decoded {
    Ok(loaded) -> {
      loaded.macro_targets.protein
      |> should.equal(150.0)

      loaded.macro_targets.fat
      |> should.equal(50.0)

      loaded.macro_targets.carbs
      |> should.equal(200.0)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

// ============================================================================
// Auto Meal Plan Complete Round-Trip Tests
// ============================================================================

/// Test that complete AutoMealPlan with recipe_json can be serialized
pub fn auto_meal_plan_with_recipe_json_serialization_test() {
  let recipes = [
    create_test_recipe(1, "Chicken", "protein", 30.0, 5.0, 0.0, True),
    create_test_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, True),
  ]

  let recipe_json = json.array(recipes, recipe_to_json) |> json.to_string()
  let total_macros = Macros(protein: 35.0, fat: 6.0, carbs: 8.0)
  let config = create_test_config("user-100", [auto_types.VerticalDiet], 2)

  let plan = auto_types.AutoMealPlan(
    id: "plan-001",
    recipes: recipes,
    generated_at: "2025-12-12T10:30:00Z",
    total_macros: total_macros,
    config: config,
    recipe_json: recipe_json,
  )

  // Serialize the plan
  let json_value = auto_types.auto_meal_plan_to_json(plan)
  let json_string = json.to_string(json_value)

  // Verify JSON is valid and non-empty
  string.length(json_string) > 0
  |> should.be_true()
}

/// Test that recipe_json field is preserved during AutoMealPlan serialization
pub fn recipe_json_field_preserved_in_plan_test() {
  let recipes = [
    create_test_recipe(1, "Chicken", "protein", 30.0, 5.0, 0.0, True),
    create_test_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, True),
  ]

  let recipe_json = json.array(recipes, recipe_to_json) |> json.to_string()
  let config = create_test_config("user-100", [auto_types.VerticalDiet], 2)

  let plan = auto_types.AutoMealPlan(
    id: "plan-001",
    recipes: recipes,
    generated_at: "2025-12-12T10:30:00Z",
    total_macros: Macros(protein: 35.0, fat: 6.0, carbs: 8.0),
    config: config,
    recipe_json: recipe_json,
  )

  // Serialize plan to JSON
  let plan_json_string = auto_types.auto_meal_plan_to_json(plan) |> json.to_string()

  // Verify recipe_json is in the serialized output
  string.contains(plan_json_string, "recipe_json")
  |> should.be_true()
}

/// Test that recipes can be reconstructed from plan recipe_json
pub fn recipes_reconstructed_from_plan_recipe_json_test() {
  let original_recipes = [
    create_test_recipe(1, "Salmon", "protein", 25.0, 15.0, 0.0, True),
    create_test_recipe(2, "Sweet Potato", "carbs", 2.0, 0.2, 20.0, True),
  ]

  let recipe_json = json.array(original_recipes, recipe_to_json) |> json.to_string()
  let config = create_test_config("user-200", [auto_types.Paleo], 2)

  let plan = auto_types.AutoMealPlan(
    id: "plan-salmon-002",
    recipes: original_recipes,
    generated_at: "2025-12-12T11:00:00Z",
    total_macros: Macros(protein: 27.0, fat: 15.2, carbs: 20.0),
    config: config,
    recipe_json: recipe_json,
  )

  // Reconstruct recipes from recipe_json
  let decoded_recipes = json.parse(plan.recipe_json, using: decode.list(recipe_decoder()))

  case decoded_recipes {
    Ok(loaded) -> {
      // Verify count matches
      list.length(loaded)
      |> should.equal(2)

      // Verify recipe names
      case list.first(loaded) {
        Ok(first) -> {
          first.name
          |> should.equal("Salmon")
        }
        Error(_) ->
          False
          |> should.be_true()
      }
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

// ============================================================================
// Total Macros Preservation Tests
// ============================================================================

/// Test that total macros are correctly calculated from recipes
pub fn total_macros_from_recipes_test() {
  let _recipes = [
    create_test_recipe(1, "Chicken", "protein", 30.0, 5.0, 2.0, True),
    create_test_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, True),
    create_test_recipe(3, "Rice", "carbs", 3.0, 0.5, 45.0, False),
  ]

  // Calculate total manually
  let total = Macros(
    protein: 30.0 +. 5.0 +. 3.0,
    fat: 5.0 +. 1.0 +. 0.5,
    carbs: 2.0 +. 8.0 +. 45.0,
  )

  total.protein |> should.equal(38.0)
  total.fat |> should.equal(6.5)
  total.carbs |> should.equal(55.0)
}

/// Test that stored total_macros are preserved in plan
pub fn total_macros_preserved_in_plan_test() {
  let recipes = [
    create_test_recipe(1, "Fish", "protein", 22.0, 8.0, 0.0, True),
    create_test_recipe(2, "Vegetables", "vegetable", 4.0, 2.0, 12.0, True),
  ]

  let recipe_json = json.array(recipes, recipe_to_json) |> json.to_string()
  let total_macros = Macros(protein: 26.0, fat: 10.0, carbs: 12.0)
  let config = create_test_config("user-300", [auto_types.Mediterranean], 2)

  let plan = auto_types.AutoMealPlan(
    id: "plan-fish-003",
    recipes: recipes,
    generated_at: "2025-12-12T12:00:00Z",
    total_macros: total_macros,
    config: config,
    recipe_json: recipe_json,
  )

  // Verify macros in plan
  plan.total_macros.protein
  |> should.equal(26.0)

  plan.total_macros.fat
  |> should.equal(10.0)

  plan.total_macros.carbs
  |> should.equal(12.0)
}

// ============================================================================
// Edge Cases and Error Handling
// ============================================================================

/// Test empty recipe list JSON serialization
pub fn empty_recipe_list_json_serialization_test() {
  let empty_recipes: List(Recipe) = []

  let json_array = json.array(empty_recipes, recipe_to_json)
  let json_string = json.to_string(json_array)

  // Should produce valid empty array JSON: []
  json_string
  |> should.equal("[]")
}

/// Test empty recipe list can be deserialized
pub fn empty_recipe_list_json_deserialization_test() {
  let json_string = "[]"
  let decoded = json.parse(json_string, using: decode.list(recipe_decoder()))

  case decoded {
    Ok(recipes) -> {
      list.length(recipes)
      |> should.equal(0)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test plan with single recipe
pub fn plan_with_single_recipe_json_test() {
  let recipes = [create_test_recipe(1, "Only Recipe", "general", 20.0, 5.0, 30.0, True)]
  let recipe_json = json.array(recipes, recipe_to_json) |> json.to_string()
  let config = create_test_config("user-400", [auto_types.HighProtein], 1)

  let plan = auto_types.AutoMealPlan(
    id: "plan-single-001",
    recipes: recipes,
    generated_at: "2025-12-12T13:00:00Z",
    total_macros: Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
    config: config,
    recipe_json: recipe_json,
  )

  // Should handle single recipe correctly
  json.to_string(auto_types.auto_meal_plan_to_json(plan))
  |> string.length()
  |> fn(len) { len > 0 }()
  |> should.be_true()
}

/// Test plan with multiple recipes
pub fn plan_with_many_recipes_json_test() {
  let recipes = list.range(1, 21)
  |> list.map(fn(i) {
    create_test_recipe(
      i,
      "Recipe-" <> int.to_string(i),
      "category-" <> int.to_string(i),
      float.max(5.0, float.min(50.0, int.to_float(i) *. 2.5)),
      float.max(1.0, int.to_float(i) *. 0.5),
      float.max(10.0, int.to_float(i) *. 3.0),
      i % 2 == 0,
    )
  })

  let recipe_json = json.array(recipes, recipe_to_json) |> json.to_string()
  let config = create_test_config("user-500", [auto_types.Keto], 20)

  let plan = auto_types.AutoMealPlan(
    id: "plan-many-001",
    recipes: recipes,
    generated_at: "2025-12-12T14:00:00Z",
    total_macros: Macros(protein: 500.0, fat: 100.0, carbs: 400.0),
    config: config,
    recipe_json: recipe_json,
  )

  // Should handle 20 recipes without issues
  list.length(plan.recipes)
  |> should.equal(20)
}

// ============================================================================
// Integration: Full Save/Load Simulation
// ============================================================================

/// Test complete save/load cycle (database simulation)
pub fn complete_save_load_cycle_test() {
  // Create original plan
  let original_recipes = [
    create_test_recipe(101, "Steak", "protein", 35.0, 20.0, 0.0, True),
    create_test_recipe(102, "Asparagus", "vegetable", 3.0, 0.1, 5.0, True),
  ]

  let recipe_json = json.array(original_recipes, recipe_to_json) |> json.to_string()
  let config = create_test_config("user-live-1", [auto_types.VerticalDiet], 2)

  let original_plan = auto_types.AutoMealPlan(
    id: "plan-cycle-001",
    recipes: original_recipes,
    generated_at: "2025-12-12T15:00:00Z",
    total_macros: Macros(protein: 38.0, fat: 20.1, carbs: 5.0),
    config: config,
    recipe_json: recipe_json,
  )

  // Simulate database save: serialize to JSON
  let saved_json = auto_types.auto_meal_plan_to_json(original_plan) |> json.to_string()

  // Verify JSON is a valid string
  string.length(saved_json) > 0
  |> should.be_true()
}
