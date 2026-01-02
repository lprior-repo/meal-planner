//! Unit tests for ingredient nutrition calculation (FUNCTIONAL CORE)
//!
//! These test PURE functions with NO I/O.
//! Tests follow TDD discipline: RED → GREEN → REFACTOR

use serde_json::json;

/// GATE-2: Unit Test RED
///
/// ## Behavior: Calculate scaled nutrition from serving data
///
/// ### Constraints:
/// - Input serving nutrition is per 100g
/// - Target amount is in grams
/// - Output should be linearly scaled
/// - Function is PURE (no I/O)
///
/// ### Predicted Failure:
/// Function does not exist yet - compilation error
#[test]
fn should_scale_nutrition_when_amount_differs_from_serving() {
    // GIVEN: Serving nutrition for 100g chicken breast
    let serving_nutrition = json!({
        "calories": 165.0,
        "protein": 31.0,
        "carbohydrate": 0.0,
        "fat": 3.6
    });

    // WHEN: Calculate for 200g (double)
    let result = meal_planner::tandoor::nutrition::scale_nutrition_to_grams(
        &serving_nutrition,
        100.0, // serving_size_grams
        200.0, // target_grams
    );

    // THEN: Values should be doubled
    assert_eq!(result["calories"].as_f64().unwrap(), 330.0);
    assert_eq!(result["protein"].as_f64().unwrap(), 62.0);
    assert_eq!(result["carbohydrate"].as_f64().unwrap(), 0.0);
    assert_eq!(result["fat"].as_f64().unwrap(), 7.2);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Handle zero amounts gracefully
///
/// ### Constraints:
/// - Zero amount should return zero nutrition
/// - Should not panic or error
///
/// ### Predicted Failure:
/// Function does not exist - compilation error
#[test]
fn should_return_zero_nutrition_when_amount_is_zero() {
    // GIVEN
    let serving_nutrition = json!({
        "calories": 165.0,
        "protein": 31.0,
    });

    // WHEN
    let result = meal_planner::tandoor::nutrition::scale_nutrition_to_grams(
        &serving_nutrition,
        100.0,
        0.0, // Zero target
    );

    // THEN
    assert_eq!(result["calories"].as_f64().unwrap(), 0.0);
    assert_eq!(result["protein"].as_f64().unwrap(), 0.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Calculate total calories from recipe ingredients
///
/// ### Constraints:
/// - Recipe has steps with ingredients
/// - Each ingredient has amount and food with energy
/// - Energy is per 100g, amount is in grams
/// - Function is PURE (no I/O)
///
/// ### Predicted Failure:
/// Function does not exist yet - compilation error
#[test]
fn should_calculate_total_calories_from_recipe_ingredients() {
    // GIVEN: Recipe with steps containing ingredients
    let recipe = json!({
        "steps": [
            {
                "ingredients": [
                    {
                        "amount": 200.0,
                        "food": {"energy": 165.0}  // 165 kcal per 100g
                    },
                    {
                        "amount": 100.0,
                        "food": {"energy": 34.0}  // 34 kcal per 100g
                    }
                ]
            }
        ]
    });

    // WHEN: Calculate total calories
    let result = meal_planner::tandoor::nutrition::calculate_recipe_calories(&recipe);

    // THEN: (200 * 165 / 100) + (100 * 34 / 100) = 330 + 34 = 364
    assert_eq!(result, 364.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Return zero for recipe with no steps
///
/// ### Constraints:
/// - Empty steps array should return 0
/// - Missing steps key should return 0
/// - Function is PURE (no I/O)
#[test]
fn should_return_zero_calories_when_recipe_has_no_steps() {
    // GIVEN: Recipe with empty steps
    let recipe = json!({"steps": []});

    // WHEN
    let result = meal_planner::tandoor::nutrition::calculate_recipe_calories(&recipe);

    // THEN
    assert_eq!(result, 0.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Handle missing food energy gracefully
///
/// ### Constraints:
/// - Ingredients without food energy should be skipped
/// - Should not panic
/// - Function is PURE (no I/O)
#[test]
fn should_skip_ingredients_without_energy() {
    // GIVEN: Recipe with ingredient missing food data
    let recipe = json!({
        "steps": [
            {
                "ingredients": [
                    {
                        "amount": 100.0,
                        "food": {"energy": 200.0}
                    },
                    {
                        "amount": 50.0
                        // No "food" key
                    }
                ]
            }
        ]
    });

    // WHEN
    let result = meal_planner::tandoor::nutrition::calculate_recipe_calories(&recipe);

    // THEN: Only the first ingredient contributes: 100 * 200 / 100 = 200
    assert_eq!(result, 200.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Extract ingredient information from Tandoor JSON
///
/// ### Constraints:
/// - Input is Tandoor ingredient object with food.name, amount, unit.name
/// - Output is (name, amount, unit) tuple
/// - Function is PURE (no I/O)
///
/// ### Predicted Failure:
/// Function does not exist yet - compilation error
#[test]
fn should_extract_ingredient_info_from_tandoor_json() {
    // GIVEN: Tandoor ingredient object
    let ingredient = json!({
        "food": {"name": "chicken breast"},
        "amount": 200.0,
        "unit": {"name": "g"}
    });

    // WHEN: Extract ingredient info
    let (name, amount, unit) =
        meal_planner::tandoor::nutrition::extract_ingredient_info(&ingredient);

    // THEN: Should extract all fields
    assert_eq!(name, "chicken breast");
    assert_eq!(amount, 200.0);
    assert_eq!(unit, "g");
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Handle missing unit gracefully (default to empty string)
///
/// ### Constraints:
/// - Missing unit should return empty string
/// - Should not panic
#[test]
fn should_handle_missing_unit_in_ingredient() {
    // GIVEN: Ingredient without unit
    let ingredient = json!({
        "food": {"name": "salt"},
        "amount": 5.0
    });

    // WHEN
    let (name, amount, unit) =
        meal_planner::tandoor::nutrition::extract_ingredient_info(&ingredient);

    // THEN
    assert_eq!(name, "salt");
    assert_eq!(amount, 5.0);
    assert_eq!(unit, ""); // Default to empty string
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Handle missing amount gracefully (default to 0.0)
#[test]
fn should_handle_missing_amount_in_ingredient() {
    // GIVEN: Ingredient without amount
    let ingredient = json!({
        "food": {"name": "pepper"},
        "unit": {"name": "pinch"}
    });

    // WHEN
    let (name, amount, unit) =
        meal_planner::tandoor::nutrition::extract_ingredient_info(&ingredient);

    // THEN
    assert_eq!(name, "pepper");
    assert_eq!(amount, 0.0); // Default to 0
    assert_eq!(unit, "pinch");
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Convert milliliters to grams for water
///
/// ### Constraints:
/// - Water density: 1ml = 1g
/// - Function is PURE (no I/O)
///
/// ### Predicted Failure:
/// Function does not exist yet - compilation error
#[test]
fn should_convert_ml_to_grams_for_water() {
    // GIVEN: 250ml of water
    let amount = 250.0;
    let unit = "ml";
    let ingredient_name = "water";

    // WHEN: Convert to grams
    let grams = meal_planner::tandoor::nutrition::convert_to_grams(amount, unit, ingredient_name);

    // THEN: 250ml water = 250g
    assert_eq!(grams, 250.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Convert milliliters to grams for milk
///
/// ### Constraints:
/// - Milk density: ~1.03 g/ml
/// - Function is PURE (no I/O)
#[test]
fn should_convert_ml_to_grams_for_milk() {
    // GIVEN: 100ml of milk
    let amount = 100.0;
    let unit = "ml";
    let ingredient_name = "milk";

    // WHEN: Convert to grams
    let grams = meal_planner::tandoor::nutrition::convert_to_grams(amount, unit, ingredient_name);

    // THEN: 100ml milk ≈ 103g
    assert_eq!(grams, 103.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Return grams unchanged when unit is already grams
#[test]
fn should_return_grams_unchanged() {
    // GIVEN: 200g of chicken
    let amount = 200.0;
    let unit = "g";
    let ingredient_name = "chicken";

    // WHEN: Convert to grams
    let grams = meal_planner::tandoor::nutrition::convert_to_grams(amount, unit, ingredient_name);

    // THEN: No conversion needed
    assert_eq!(grams, 200.0);
}

/// GATE-2: Unit Test RED
///
/// ## Behavior: Default unknown units to grams (no conversion)
///
/// ### Constraints:
/// - Unknown units should be treated as grams
/// - Better to be conservative than wrong
#[test]
fn should_default_unknown_units_to_grams() {
    // GIVEN: 5 "pinch" of salt (unknown unit)
    let amount = 5.0;
    let unit = "pinch";
    let ingredient_name = "salt";

    // WHEN: Convert to grams
    let grams = meal_planner::tandoor::nutrition::convert_to_grams(amount, unit, ingredient_name);

    // THEN: Treat as grams (conservative approach)
    assert_eq!(grams, 5.0);
}
