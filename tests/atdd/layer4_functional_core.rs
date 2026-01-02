//! Layer 4: Functional Core (Pure Functions)
//!
//! Dave Farley: "The functional core is where your business logic lives, free from I/O."
//!
//! ## GATE-4: All Functions ≤25 Lines
//!
//! This layer contains:
//! - Pure business logic (no I/O)
//! - Deterministic calculations
//! - Composable transformations
//!
//! ## Principles
//!
//! 1. **No I/O**: No HTTP, database, filesystem, or network calls
//! 2. **Deterministic**: Same input always produces same output
//! 3. **Pure**: No side effects, no mutation
//! 4. **Small**: Each function ≤25 lines
//!
//! ## Line Count Enforcement
//!
//! ```bash
//! # Check line counts
//! ./scripts/validate-line-counts.sh
//!
//! # TCR enforcement (GATE-6)
//! ./scripts/tcr.sh
//! ```

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Nutrition calculation result
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NutritionInfo {
    pub calories: f64,
    pub protein: f64,
    pub carbohydrates: f64,
    pub fat: f64,
}

impl NutritionInfo {
    pub fn zero() -> Self {
        Self {
            calories: 0.0,
            protein: 0.0,
            carbohydrates: 0.0,
            fat: 0.0,
        }
    }

    pub fn is_zero(&self) -> bool {
        self.calories == 0.0 && self.protein == 0.0 && self.carbohydrates == 0.0 && self.fat == 0.0
    }
}

/// Ingredient in a recipe
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct IngredientInput {
    pub name: String,
    pub amount: f64,
    pub unit: String,
}

/// Food nutrition data (per 100g)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FoodNutrition {
    pub calories: f64,
    pub protein: f64,
    pub carbohydrates: f64,
    pub fat: f64,
    pub is_valid: bool,
}

/// Recipe nutrition calculation
pub fn calculate_recipe_nutrition(
    ingredients: &[IngredientInput],
    food_data: &[(&str, FoodNutrition)],
) -> NutritionInfo {
    let mut total = NutritionInfo::zero();

    for ingredient in ingredients {
        if let Some(nutrition) = find_food_nutrition(&ingredient.name, food_data) {
            let scaled = scale_nutrition(&nutrition, ingredient.amount);
            total = add_nutrition(&total, &scaled);
        }
    }

    total
}

/// Find nutrition data for a food by name
fn find_food_nutrition(name: &str, food_data: &[(&str, FoodNutrition)]) -> Option<FoodNutrition> {
    food_data
        .iter()
        .find(|(food_name, _)| food_name.to_lowercase() == name.to_lowercase())
        .map(|(_, nutrition)| nutrition.clone())
}

/// Scale nutrition to target amount (assumes nutrition is per 100g)
fn scale_nutrition(nutrition: &FoodNutrition, target_grams: f64) -> NutritionInfo {
    let factor = target_grams / 100.0;
    NutritionInfo {
        calories: nutrition.calories * factor,
        protein: nutrition.protein * factor,
        carbohydrates: nutrition.carbohydrates * factor,
        fat: nutrition.fat * factor,
    }
}

/// Add two nutrition infos together
fn add_nutrition(a: &NutritionInfo, b: &NutritionInfo) -> NutritionInfo {
    NutritionInfo {
        calories: a.calories + b.calories,
        protein: a.protein + b.protein,
        carbohydrates: a.carbohydrates + b.carbohydrates,
        fat: a.fat + b.fat,
    }
}

/// Convert volume to grams for common ingredients
pub fn convert_to_grams(amount: f64, unit: &str, ingredient_name: &str) -> f64 {
    let lower_unit = unit.to_lowercase();
    let lower_ingredient = ingredient_name.to_lowercase();

    match lower_unit.as_str() {
        "g" | "gram" | "grams" => amount,
        "kg" | "kilogram" | "kilograms" => amount * 1000.0,
        "ml" | "milliliter" | "milliliters" => volume_to_grams(amount, &lower_ingredient),
        "l" | "liter" | "liters" => volume_to_grams(amount * 1000.0, &lower_ingredient),
        "cup" | "cups" => volume_to_grams(amount * 240.0, &lower_ingredient),
        "tbsp" | "tablespoon" | "tablespoons" => volume_to_grams(amount * 15.0, &lower_ingredient),
        "tsp" | "teaspoon" | "teaspoons" => volume_to_grams(amount * 5.0, &lower_ingredient),
        "oz" | "ounce" | "ounces" => amount * 28.35,
        "lb" | "lbs" | "pound" | "pounds" => amount * 453.59,
        _ => amount,
    }
}

fn volume_to_grams(volume_ml: f64, ingredient: &str) -> f64 {
    match ingredient {
        "water" | "milk" | "cream" => volume_ml,
        "flour" => volume_ml * 0.59,
        "sugar" => volume_ml * 0.85,
        "butter" => volume_ml * 0.96,
        "oil" => volume_ml * 0.92,
        "honey" => volume_ml * 1.42,
        _ => volume_ml,
    }
}

/// Parse recipe JSON from Tandoor API
pub fn parse_tandoor_recipe(json: &Value) -> Option<Vec<IngredientInput>> {
    let steps = json.get("steps")?.as_array()?;
    let mut ingredients = Vec::new();

    for step in steps {
        let step_ingredients = step.get("ingredients")?.as_array()?;
        for ing in step_ingredients {
            if let (Some(name), Some(amount)) = (
                ing.get("food")?.get("name")?.as_str(),
                ing.get("amount")?.as_f64(),
            ) {
                let unit = ing
                    .get("unit")?
                    .get("name")?
                    .as_str()
                    .unwrap_or("")
                    .to_string();

                ingredients.push(IngredientInput {
                    name: name.to_string(),
                    amount,
                    unit,
                });
            }
        }
    }

    Some(ingredients)
}

/// Extract FatSecret food nutrition from API response
pub fn parse_fatsecret_food(json: &Value) -> Option<FoodNutrition> {
    let food = json.get("food")?;
    let servings = food.get("servings")?.as_array()?;
    let default_serving = servings.iter().find(|s| {
        s.get("serving_description")?
            .as_str()?
            .to_lowercase()
            .contains("100")
    })?;

    let calories = default_serving.get("calories")?.as_str()?.parse().ok()?;
    let protein = default_serving.get("protein")?.as_str()?.parse().ok()?;
    let carbs = default_serving
        .get("carbohydrate")?
        .as_str()?
        .parse()
        .ok()?;
    let fat = default_serving.get("fat")?.as_str()?.parse().ok()?;

    Some(FoodNutrition {
        calories,
        protein,
        carbohydrates: carbs,
        fat,
        is_valid: true,
    })
}

/// Meal plan generation (pure algorithm)
pub struct MealPlanGenerator {
    pub target_calories: i32,
    pub meal_count: usize,
    pub recipes: Vec<RecipeSummary>,
}

pub struct RecipeSummary {
    pub id: i64,
    pub name: String,
    pub calories: f64,
    pub meal_type: String,
}

impl MealPlanGenerator {
    pub fn new(target_calories: i32, meal_count: usize) -> Self {
        Self {
            target_calories,
            meal_count,
            recipes: Vec::new(),
        }
    }

    pub fn add_recipe(&mut self, recipe: RecipeSummary) {
        self.recipes.push(recipe);
    }

    pub fn generate(&self) -> Vec<MealSlot> {
        let calories_per_meal = self.target_calories as f64 / self.meal_count as f64;
        let mut slots = Vec::new();

        let mut available: Vec<_> = self.recipes.iter().collect();
        let mut remaining = self.target_calories as f64;

        for i in 0..self.meal_count {
            let target = if i == self.meal_count - 1 {
                remaining
            } else {
                calories_per_meal
            };

            let recipe = self.select_recipe(&available, target);
            match recipe {
                Some(r) => {
                    slots.push(MealSlot {
                        meal_number: i + 1,
                        recipe_id: r.id,
                        recipe_name: r.name.clone(),
                        calories: r.calories,
                    });
                    remaining -= r.calories;
                    available.retain(|x| x.id != r.id);
                }
                None => {
                    slots.push(MealSlot {
                        meal_number: i + 1,
                        recipe_id: 0,
                        recipe_name: "Unknown".to_string(),
                        calories: 0.0,
                    });
                }
            }
        }

        slots
    }

    fn select_recipe<'a>(
        &self,
        available: &[&'a RecipeSummary],
        target: f64,
    ) -> Option<&'a RecipeSummary> {
        available
            .iter()
            .min_by_key(|r| ((r.calories - target).abs()) as i32)
            .copied()
    }
}

pub struct MealSlot {
    pub meal_number: usize,
    pub recipe_id: i64,
    pub recipe_name: String,
    pub calories: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nutrition_info_zero() {
        let zero = NutritionInfo::zero();
        assert_eq!(zero.calories, 0.0);
        assert_eq!(zero.protein, 0.0);
    }

    #[test]
    fn nutrition_info_is_zero() {
        assert!(NutritionInfo::zero().is_zero());
        assert!(!NutritionInfo {
            calories: 1.0,
            protein: 0.0,
            carbohydrates: 0.0,
            fat: 0.0,
        }
        .is_zero());
    }

    #[test]
    fn calculate_recipe_nutrition_simple() {
        let ingredients = vec![IngredientInput {
            name: "chicken breast".to_string(),
            amount: 200.0,
            unit: "g".to_string(),
        }];

        let food_data = vec![(
            "chicken breast",
            FoodNutrition {
                calories: 165.0,
                protein: 31.0,
                carbohydrates: 0.0,
                fat: 3.6,
                is_valid: true,
            },
        )];

        let result = calculate_recipe_nutrition(&ingredients, &food_data);
        assert_eq!(result.calories, 330.0);
        assert_eq!(result.protein, 62.0);
    }

    #[test]
    fn convert_grams_unchanged() {
        assert_eq!(convert_to_grams(200.0, "g", "chicken"), 200.0);
        assert_eq!(convert_to_grams(1.0, "kg", "flour"), 1000.0);
    }

    #[test]
    fn convert_ounces_to_grams() {
        let result = convert_to_grams(1.0, "oz", "cheese");
        assert!((result - 28.35).abs() < 0.01);
    }

    #[test]
    fn convert_water_ml_to_grams() {
        assert_eq!(convert_to_grams(250.0, "ml", "water"), 250.0);
    }

    #[test]
    fn convert_flour_cup_to_grams() {
        let result = convert_to_grams(1.0, "cup", "flour");
        assert!((result - 141.6).abs() < 0.1); // 240ml * 0.59
    }

    #[test]
    fn meal_plan_generator() {
        let mut generator = MealPlanGenerator::new(2000, 3);
        generator.add_recipe(RecipeSummary {
            id: 1,
            name: "Breakfast".to_string(),
            calories: 500.0,
            meal_type: "breakfast".to_string(),
        });
        generator.add_recipe(RecipeSummary {
            id: 2,
            name: "Lunch".to_string(),
            calories: 700.0,
            meal_type: "lunch".to_string(),
        });
        generator.add_recipe(RecipeSummary {
            id: 3,
            name: "Dinner".to_string(),
            calories: 800.0,
            meal_type: "dinner".to_string(),
        });

        let plan = generator.generate();
        assert_eq!(plan.len(), 3);
        assert!(plan.iter().all(|m| m.recipe_id > 0));
    }

    #[test]
    fn parse_tandoor_recipe() {
        let json = serde_json::json!({
            "steps": [
                {
                    "ingredients": [
                        {
                            "food": {"name": "chicken"},
                            "amount": 200.0,
                            "unit": {"name": "g"}
                        }
                    ]
                }
            ]
        });

        let ingredients = parse_tandoor_recipe(&json);
        assert!(ingredients.is_some());
        let ingredients = ingredients.unwrap();
        assert_eq!(ingredients.len(), 1);
        assert_eq!(ingredients[0].name, "chicken");
        assert_eq!(ingredients[0].amount, 200.0);
    }
}
