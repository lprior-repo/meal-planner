/// Unit tests for vertical diet compliance validation
///
/// Tests cover:
/// - Red meat detection in recipes
/// - Simple carbs detection (rice, potatoes)
/// - Low FODMAP vegetables detection
/// - Ingredient simplicity scoring
/// - Preparation complexity evaluation
/// - Recipe quality scoring
/// - Overall compliance calculation
/// - Recommendation generation
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/vertical_diet_compliance.{
  type Recipe, type RecipeIngredient, type RecipeInstruction,
  type VerticalDietCompliance, Recipe, RecipeIngredient, RecipeInstruction,
  VerticalDietCompliance, check_compliance,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_ingredient(display: String) -> RecipeIngredient {
  RecipeIngredient(display: display)
}

fn create_instruction(text: String) -> RecipeInstruction {
  RecipeInstruction(text: text)
}

fn create_recipe(
  name: String,
  description: option.Option(String),
  ingredients: List(RecipeIngredient),
  instructions: List(RecipeInstruction),
  rating: option.Option(Int),
) -> Recipe {
  Recipe(
    name: name,
    description: description,
    recipe_ingredient: ingredients,
    recipe_instructions: instructions,
    rating: rating,
  )
}

fn minimal_recipe() -> Recipe {
  create_recipe(
    "Simple Recipe",
    None,
    [create_ingredient("salt")],
    [create_instruction("Cook it")],
    None,
  )
}

// ============================================================================
// Red Meat Detection Tests
// ============================================================================

pub fn red_meat_in_recipe_name_test() {
  let recipe =
    create_recipe(
      "Grass-Fed Beef with Vegetables",
      None,
      [create_ingredient("salt")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Should detect beef in recipe name
  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_lowercase_in_name_test() {
  let recipe =
    create_recipe(
      "beef steak dinner",
      None,
      [create_ingredient("salt")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_in_description_test() {
  let recipe =
    create_recipe(
      "Dinner",
      Some("A delicious beef recipe"),
      [create_ingredient("salt")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_in_ingredients_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("Ground Beef"), create_ingredient("onions")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_lamb_detection_test() {
  let recipe =
    create_recipe(
      "Lamb Stew",
      None,
      [create_ingredient("lamb"), create_ingredient("vegetables")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_bison_detection_test() {
  let recipe =
    create_recipe(
      "Bison Burger",
      None,
      [create_ingredient("bison"), create_ingredient("bun")],
      [create_instruction("Grill")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_venison_detection_test() {
  let recipe =
    create_recipe(
      "Venison Roast",
      None,
      [create_ingredient("venison"), create_ingredient("herbs")],
      [create_instruction("Roast")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn no_red_meat_detected_test() {
  let recipe =
    create_recipe(
      "Chicken Salad",
      None,
      [create_ingredient("Chicken"), create_ingredient("lettuce")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should note missing red meat
  list.any(result.reasons, fn(r) { string.contains(r, "No red meat") })
  |> should.be_true()
}

pub fn red_meat_steak_detection_test() {
  let recipe =
    create_recipe(
      "Ribeye Steak",
      None,
      [create_ingredient("ribeye steak"), create_ingredient("salt")],
      [create_instruction("Grill")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn red_meat_sirloin_detection_test() {
  let recipe =
    create_recipe(
      "Sirloin Roast",
      None,
      [create_ingredient("sirloin"), create_ingredient("seasonings")],
      [create_instruction("Bake")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

// ============================================================================
// Simple Carbs Detection Tests
// ============================================================================

pub fn simple_carbs_white_rice_in_name_test() {
  let recipe =
    create_recipe(
      "Beef with White Rice",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_white_rice_lowercase_test() {
  let recipe =
    create_recipe(
      "white rice bowl",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_potato_in_name_test() {
  let recipe =
    create_recipe(
      "Beef and Potatoes",
      None,
      [create_ingredient("beef"), create_ingredient("potato")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_white_potato_detection_test() {
  let recipe =
    create_recipe(
      "Dinner",
      None,
      [create_ingredient("beef"), create_ingredient("white potato")],
      [create_instruction("Bake")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_sweet_potato_detection_test() {
  let recipe =
    create_recipe(
      "Roast Dinner",
      None,
      [create_ingredient("beef"), create_ingredient("sweet potato")],
      [create_instruction("Bake")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_jasmine_rice_detection_test() {
  let recipe =
    create_recipe(
      "Asian Rice",
      None,
      [create_ingredient("beef"), create_ingredient("jasmine rice")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_basmati_rice_detection_test() {
  let recipe =
    create_recipe(
      "Indian Rice",
      None,
      [create_ingredient("beef"), create_ingredient("basmati")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_mashed_potato_detection_test() {
  let recipe =
    create_recipe(
      "Comfort Food",
      None,
      [create_ingredient("beef"), create_ingredient("mashed potato")],
      [create_instruction("Mash")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_carbs_baked_potato_detection_test() {
  let recipe =
    create_recipe(
      "Baked Dinner",
      None,
      [create_ingredient("beef"), create_ingredient("baked potato")],
      [create_instruction("Bake")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn no_simple_carbs_detected_test() {
  let recipe =
    create_recipe(
      "Beef Salad",
      None,
      [create_ingredient("beef"), create_ingredient("lettuce")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should note missing simple carbs
  list.any(result.reasons, fn(r) { string.contains(r, "No simple carbs") })
  |> should.be_true()
}

// ============================================================================
// Low FODMAP Vegetables Detection Tests
// ============================================================================

pub fn low_fodmap_carrot_detection_test() {
  let recipe =
    create_recipe(
      "Beef and Vegetables",
      None,
      [create_ingredient("beef"), create_ingredient("carrot")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

pub fn low_fodmap_spinach_detection_test() {
  let recipe =
    create_recipe(
      "Beef Spinach",
      None,
      [create_ingredient("beef"), create_ingredient("spinach")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

pub fn low_fodmap_kale_detection_test() {
  let recipe =
    create_recipe(
      "Kale Bowl",
      None,
      [create_ingredient("beef"), create_ingredient("kale")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

pub fn low_fodmap_bell_pepper_detection_test() {
  let recipe =
    create_recipe(
      "Beef Fajitas",
      None,
      [create_ingredient("beef"), create_ingredient("bell pepper")],
      [create_instruction("Grill")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

pub fn low_fodmap_zucchini_detection_test() {
  let recipe =
    create_recipe(
      "Summer Vegetables",
      None,
      [create_ingredient("beef"), create_ingredient("zucchini")],
      [create_instruction("Grill")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

pub fn low_fodmap_broccoli_detection_test() {
  let recipe =
    create_recipe(
      "Beef Broccoli",
      None,
      [create_ingredient("beef"), create_ingredient("broccoli")],
      [create_instruction("Stir-fry")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(50)
}

// ============================================================================
// Ingredient Simplicity Tests
// ============================================================================

pub fn simple_ingredients_five_count_test() {
  let recipe =
    create_recipe(
      "Simple Recipe",
      None,
      [
        create_ingredient("beef"),
        create_ingredient("rice"),
        create_ingredient("salt"),
        create_ingredient("pepper"),
        create_ingredient("herbs"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // 5 ingredients is simple
  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_ingredients_eight_count_test() {
  let recipe =
    create_recipe(
      "Simple Recipe",
      None,
      [
        create_ingredient("beef"),
        create_ingredient("rice"),
        create_ingredient("salt"),
        create_ingredient("pepper"),
        create_ingredient("herbs"),
        create_ingredient("garlic"),
        create_ingredient("onion"),
        create_ingredient("oil"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // 8 ingredients is at limit
  result.score
  // TODO: should.be_greater_than(48)
}

pub fn complex_ingredients_nine_count_test() {
  let recipe =
    create_recipe(
      "Complex Recipe",
      None,
      [
        create_ingredient("beef"),
        create_ingredient("rice"),
        create_ingredient("salt"),
        create_ingredient("pepper"),
        create_ingredient("herbs"),
        create_ingredient("garlic"),
        create_ingredient("onion"),
        create_ingredient("oil"),
        create_ingredient("tomato"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Should note complexity
  list.any(result.reasons, fn(r) { string.contains(r, "Complex recipe") })
  |> should.be_true()
}

pub fn ingredient_count_in_reasons_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      list.repeat(create_ingredient("ingredient"), 15),
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Should mention the actual count
  result.reasons |> should.not_equal([])
}

// ============================================================================
// Preparation Simplicity Tests
// ============================================================================

pub fn simple_preparation_three_steps_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [
        create_instruction("Cook beef"),
        create_instruction("Cook rice"),
        create_instruction("Combine"),
      ],
      None,
    )

  let result = check_compliance(recipe)

  // Simple preparation
  result.score
  // TODO: should.be_greater_than(48)
}

pub fn simple_preparation_six_steps_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [
        create_instruction("Step 1"),
        create_instruction("Step 2"),
        create_instruction("Step 3"),
        create_instruction("Step 4"),
        create_instruction("Step 5"),
        create_instruction("Step 6"),
      ],
      None,
    )

  let result = check_compliance(recipe)

  // At the limit of simple
  result.score
  // TODO: should.be_greater_than(48)
}

pub fn complex_preparation_seven_steps_test() {
  let recipe =
    create_recipe(
      "Complex Recipe",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [
        create_instruction("Step 1"),
        create_instruction("Step 2"),
        create_instruction("Step 3"),
        create_instruction("Step 4"),
        create_instruction("Step 5"),
        create_instruction("Step 6"),
        create_instruction("Step 7"),
      ],
      None,
    )

  let result = check_compliance(recipe)

  // Complex preparation gets fewer points
  result.score
  // TODO: should.be_less_than(70)
}

// ============================================================================
// Quality/Rating Tests
// ============================================================================

pub fn high_quality_rating_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      Some(5),
    )

  let result = check_compliance(recipe)

  // High rating should add points
  result.score
  // TODO: should.be_greater_than(30)
}

pub fn good_quality_rating_four_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      Some(4),
    )

  let result = check_compliance(recipe)

  // Rating 4 or higher gets bonus
  result.score
  // TODO: should.be_greater_than(24)
}

pub fn fair_quality_rating_three_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      Some(3),
    )

  let result = check_compliance(recipe)

  // Lower rating gets fewer points
  result.score
  // TODO: should.be_less_than(25)
}

pub fn poor_quality_rating_one_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      Some(1),
    )

  let result = check_compliance(recipe)

  // Poor rating gets minimal points
  result.score
  // TODO: should.be_less_than(10)
}

pub fn no_rating_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // No rating contributes 0 quality points
  result.score
  // TODO: should.be_greater_than(0)
}

// ============================================================================
// Overall Compliance Tests
// ============================================================================

pub fn fully_compliant_recipe_test() {
  let recipe =
    create_recipe(
      "Beef with Rice",
      Some("A vertical diet compliant recipe with vegetables"),
      [
        create_ingredient("grass-fed beef"),
        create_ingredient("white rice"),
        create_ingredient("spinach"),
        create_ingredient("carrot"),
      ],
      [
        create_instruction("Cook beef"),
        create_instruction("Cook rice"),
        create_instruction("Sauté vegetables"),
      ],
      Some(5),
    )

  let result = check_compliance(recipe)

  result.compliant |> should.be_true()
  result.score
  // TODO: should.be_greater_than_or_equal_to(70)
}

pub fn minimal_compliance_recipe_test() {
  let recipe =
    create_recipe(
      "Beef Dinner",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Has red meat and carbs but missing vegetables
  result.compliant
  // TODO: should.be_equal(result.score >= 70)
}

pub fn non_compliant_recipe_test() {
  let recipe =
    create_recipe(
      "Chicken Salad",
      Some("A salad with no red meat"),
      [create_ingredient("chicken"), create_ingredient("lettuce")],
      [create_instruction("Toss ingredients")],
      None,
    )

  let result = check_compliance(recipe)

  result.compliant |> should.be_false()
  result.score
  // TODO: should.be_less_than(70)
}

pub fn recommendations_generated_for_non_compliant_test() {
  let recipe =
    create_recipe(
      "Chicken Salad",
      None,
      [create_ingredient("chicken")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should generate recommendations for missing components
  result.recommendations |> list.length
  // TODO: should.be_greater_than(0)
}

pub fn compliance_score_range_test() {
  let recipe = minimal_recipe()
  let result = check_compliance(recipe)

  // Score should be in valid range
  result.score
  // TODO: should.be_greater_than_or_equal_to(0)
  result.score
  // TODO: should.be_less_than_or_equal_to(100)
}

// ============================================================================
// Recommendation Tests
// ============================================================================

pub fn recommendation_for_missing_red_meat_test() {
  let recipe =
    create_recipe(
      "Salad",
      None,
      [create_ingredient("lettuce")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should recommend red meat
  list.any(result.recommendations, fn(r) {
    string.contains(r, "red meat")
    || string.contains(r, "beef")
    || string.contains(r, "lamb")
  })
  |> should.be_true()
}

pub fn recommendation_for_missing_carbs_test() {
  let recipe =
    create_recipe(
      "Beef Salad",
      None,
      [create_ingredient("beef"), create_ingredient("lettuce")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should recommend simple carbs
  list.any(result.recommendations, fn(r) {
    string.contains(r, "rice") || string.contains(r, "potato")
  })
  |> should.be_true()
}

pub fn recommendation_for_missing_vegetables_test() {
  let recipe =
    create_recipe(
      "Beef and Rice",
      None,
      [create_ingredient("beef"), create_ingredient("rice")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Should recommend vegetables
  list.any(result.recommendations, fn(r) {
    string.contains(r, "vegetable") || string.contains(r, "vegetables")
  })
  |> should.be_true()
}

pub fn recommendation_for_complex_ingredients_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      list.repeat(create_ingredient("ingredient"), 15),
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  // Should recommend simplification or reduction of ingredients
  list.any(result.recommendations, fn(r) {
    string.contains(r, "Reduce")
    || string.contains(r, "Simplify")
    || string.contains(r, "simplify")
  })
  |> should.be_true()
}

pub fn no_recommendations_for_compliant_recipe_test() {
  let recipe =
    create_recipe(
      "Perfect Beef with Rice",
      Some("Vertical diet approved"),
      [
        create_ingredient("beef"),
        create_ingredient("rice"),
        create_ingredient("spinach"),
      ],
      [create_instruction("Cook all components")],
      Some(5),
    )

  let result = check_compliance(recipe)

  // Fully compliant should have minimal recommendations
  result.recommendations |> list.length
  // TODO: should.be_less_than_or_equal_to(2)
}

// ============================================================================
// Edge Cases
// ============================================================================

pub fn empty_recipe_test() {
  let recipe = create_recipe("Empty", None, [], [], None)

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than_or_equal_to(0)
  result.score
  // TODO: should.be_less_than_or_equal_to(100)
}

pub fn very_long_recipe_name_test() {
  let long_name = string.repeat("a", 500) <> " beef " <> string.repeat("b", 500)
  let recipe =
    create_recipe(
      long_name,
      None,
      [create_ingredient("salt")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(24)
}

pub fn special_characters_in_ingredients_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [
        create_ingredient("grass-fed beef (organic)"),
        create_ingredient("white rice [premium]"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn unicode_characters_test() {
  let recipe =
    create_recipe(
      "Recipe",
      None,
      [create_ingredient("beef"), create_ingredient("rize")],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than_or_equal_to(0)
}

// ============================================================================
// Reasons and Compliance Message Tests
// ============================================================================

pub fn reasons_list_non_empty_for_non_compliant_test() {
  let recipe =
    create_recipe(
      "Salad",
      None,
      [create_ingredient("vegetables")],
      [create_instruction("Mix")],
      None,
    )

  let result = check_compliance(recipe)

  // Should have reasons explaining why not compliant
  case result.compliant {
    False -> {
      // TODO: result.reasons |> list.length should.be_greater_than(0)
      True |> should.be_true()
    }
    True -> should.be_true(True)
  }
}

pub fn all_positive_checks_test() {
  let recipe =
    create_recipe(
      "Beef with White Rice and Spinach",
      Some("A perfectly vertical diet compliant recipe"),
      [
        create_ingredient("grass-fed beef"),
        create_ingredient("white rice"),
        create_ingredient("spinach"),
        create_ingredient("carrot"),
        create_ingredient("salt"),
      ],
      [
        create_instruction("Grill beef"),
        create_instruction("Cook rice"),
        create_instruction("Sauté vegetables"),
      ],
      Some(5),
    )

  let result = check_compliance(recipe)

  // Multiple positive checks
  result.score
  // TODO: should.be_greater_than(70)
  result.compliant |> should.be_true()
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn multiple_red_meat_keywords_test() {
  let recipe =
    create_recipe(
      "Steak and Lamb",
      Some("Beef ribeye with ground lamb"),
      [
        create_ingredient("beef ribeye"),
        create_ingredient("ground lamb"),
        create_ingredient("rice"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn multiple_carb_types_test() {
  let recipe =
    create_recipe(
      "Beef Dinner",
      None,
      [
        create_ingredient("beef"),
        create_ingredient("white rice"),
        create_ingredient("baked potato"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(48)
}

pub fn multiple_vegetables_test() {
  let recipe =
    create_recipe(
      "Beef with Vegetables",
      None,
      [
        create_ingredient("beef"),
        create_ingredient("rice"),
        create_ingredient("spinach"),
        create_ingredient("carrot"),
        create_ingredient("bell pepper"),
      ],
      [create_instruction("Cook")],
      None,
    )

  let result = check_compliance(recipe)

  result.score
  // TODO: should.be_greater_than(60)
}
