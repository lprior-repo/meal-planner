//! Layer 2: Domain Specific Language (DSL)
//!
//! Dave Farley: "The DSL is the vocabulary of your domain, hiding all technical complexity."
//!
//! ## GATE-2: DSL Implementation Tests
//!
//! This layer provides:
//! - Domain operations (create_recipe, calculate_nutrition)
//! - Test data builders (valid_ingredients, test_recipes)
//! - Meaningful error messages in domain terms
//!
//! ## Implementation Change Rule
//!
//! ONE implementation change affects ONE place in the DSL.
//! All Layer 1 tests stay GREEN.
//!
//! ## What This Layer Does
//!
//! - Translates domain intent to protocol calls
//!
//! ## What This Layer Does NOT
//!
//! - Know about HTTP endpoints
//! - Know about database tables
//! - Know about API authentication

use crate::atdd::atdd_framework::{DSLResult, Layer};
use serde_json::Value;
use std::error::Error;

/// Domain object: Test Recipe
#[derive(Debug, Clone)]
pub struct TestRecipe {
    pub id: i64,
    pub name: String,
    pub ingredients: Vec<TestIngredient>,
}

/// Domain object: Recipe Ingredient
#[derive(Debug, Clone)]
pub struct TestIngredient {
    pub name: String,
    pub amount: f64,
    pub unit: String,
}

/// Domain object: Nutrition Result
#[derive(Debug, Clone)]
pub struct NutritionResult {
    pub success: bool,
    pub calories: Option<f64>,
    pub protein: Option<f64>,
    pub carbohydrates: Option<f64>,
    pub fat: Option<f64>,
    pub failed_ingredients: Vec<String>,
}

/// Domain object: Weekly Meal Plan
#[derive(Debug, Clone)]
pub struct WeeklyMealPlan {
    pub days: Vec<DayPlan>,
}

/// Domain object: Day in Meal Plan
#[derive(Debug, Clone)]
pub struct DayPlan {
    pub name: String,
    pub meals: Vec<Meal>,
}

/// Domain object: Meal
#[derive(Debug, Clone)]
pub struct Meal {
    pub name: String,
    pub recipe_id: i64,
    pub calories: f64,
}

/// DSL error type
#[derive(Debug)]
pub struct DSLError {
    message: String,
    layer: Layer,
}

impl DSLError {
    pub fn new(message: &str, layer: Layer) -> Self {
        Self {
            message: message.to_string(),
            layer,
        }
    }
}

impl std::fmt::Display for DSLError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{}] {}", self.layer, self.message)
    }
}

impl Error for DSLError {}

/// Result type for DSL operations
pub type DSLResult<T> = Result<T, DSLError>;

/// DSL for Recipe Nutrition Tests
///
/// This struct provides domain operations that hide all technical details.
/// Layer 1 (acceptance tests) use ONLY these methods.
#[derive(Debug, Clone)]
pub struct RecipeNutritionDSL {
    driver: Box<dyn NutritionProtocolDriver>,
}

impl RecipeNutritionDSL {
    /// Create new DSL instance with default driver
    pub async fn new() -> Self {
        Self::with_driver(Box::new(BinaryProtocolDriver::new()))
    }

    /// Create DSL with custom driver (for testing)
    pub fn with_driver(driver: Box<dyn NutritionProtocolDriver>) -> Self {
        Self { driver }
    }

    /// Create a recipe with ingredients
    ///
    /// Domain operation: Setup test data
    pub async fn create_recipe_with_ingredients(
        &mut self,
        name: &str,
        ingredients: Vec<(&str, f64, &str)>,
    ) -> TestRecipe {
        let domain_ingredients: Vec<TestIngredient> = ingredients
            .into_iter()
            .map(|(name, amount, unit)| TestIngredient {
                name: name.to_string(),
                amount,
                unit: unit.to_string(),
            })
            .collect();

        let recipe = TestRecipe {
            id: 0,
            name: name.to_string(),
            ingredients: domain_ingredients.clone(),
        };

        let created = self
            .driver
            .create_recipe(&recipe.name, &domain_ingredients)
            .await
            .expect("Failed to create recipe");

        TestRecipe {
            id: created.id,
            name: recipe.name,
            ingredients: domain_ingredients,
        }
    }

    /// Calculate and update recipe nutrition
    ///
    /// Domain operation: Get nutrition data from FatSecret
    pub async fn calculate_and_update_recipe_nutrition(
        &mut self,
        recipe_id: i64,
    ) -> NutritionResult {
        self.driver
            .calculate_nutrition(recipe_id)
            .await
            .expect("Failed to calculate nutrition")
    }

    /// Verify recipe has calories matching condition
    ///
    /// Domain verification: Check business rule
    pub async fn verify_recipe_has_calories<F>(
        &self,
        recipe_id: i64,
        condition: F,
    ) -> Result<(), DSLError>
    where
        F: Fn(f64) -> bool,
    {
        let nutrition = self.driver.get_nutrition(recipe_id).await?;
        let calories = nutrition
            .calories
            .ok_or_else(|| DSLError::new("Recipe has no calorie data", Layer::DSL))?;

        if !condition(calories) {
            return Err(DSLError::new(
                &format!("Calories {} did not satisfy condition", calories),
                Layer::DSL,
            ));
        }

        Ok(())
    }

    /// Verify recipe has protein matching condition
    pub async fn verify_recipe_has_protein<F>(
        &self,
        recipe_id: i64,
        condition: F,
    ) -> Result<(), DSLError>
    where
        F: Fn(f64) -> bool,
    {
        let nutrition = self.driver.get_nutrition(recipe_id).await?;
        let protein = nutrition
            .protein
            .ok_or_else(|| DSLError::new("Recipe has no protein data", Layer::DSL))?;

        if !condition(protein) {
            return Err(DSLError::new(
                &format!("Protein {} did not satisfy condition", protein),
                Layer::DSL,
            ));
        }

        Ok(())
    }

    /// Verify nutrition source field
    pub async fn verify_nutrition_source(
        &self,
        recipe_id: i64,
        expected: &str,
    ) -> Result<(), DSLError> {
        let source = self.driver.get_nutrition_source(recipe_id).await?;
        if source != expected {
            return Err(DSLError::new(
                &format!("Expected source '{}', got '{}'", expected, source),
                Layer::DSL,
            ));
        }
        Ok(())
    }

    /// Verify failed ingredients list
    pub async fn verify_failed_ingredients(
        &self,
        recipe_id: i64,
        expected: Vec<&str>,
    ) -> Result<(), DSLError> {
        let nutrition = self.driver.get_nutrition(recipe_id).await?;
        let expected: Vec<String> = expected.iter().map(|s| s.to_string()).collect();

        if nutrition.failed_ingredients != expected {
            return Err(DSLError::new(
                &format!(
                    "Expected failed ingredients {:?}, got {:?}",
                    expected, nutrition.failed_ingredients
                ),
                Layer::DSL,
            ));
        }

        Ok(())
    }

    /// Set recipe calories to specific value
    pub async fn set_recipe_calories(&mut self, recipe_id: i64, calories: f64) {
        self.driver
            .set_calories(recipe_id, calories)
            .await
            .expect("Failed to set calories");
    }

    /// Generate weekly meal plan
    pub async fn generate_weekly_meal_plan(
        &mut self,
        diet_type: &str,
        calorie_target: i32,
        meal_types: Vec<&str>,
    ) -> WeeklyMealPlan {
        self.driver
            .generate_plan(diet_type, calorie_target, &meal_types)
            .await
            .expect("Failed to generate meal plan")
    }
}

/// Protocol Driver Trait (Layer 3)
///
/// Defines the interface between DSL and external systems.
/// Implementations handle specific protocols (HTTP, DB, etc.)
#[async_trait::async_trait]
pub trait NutritionProtocolDriver: Send + Sync {
    async fn create_recipe(
        &self,
        name: &str,
        ingredients: &[TestIngredient],
    ) -> Result<TestRecipe, Box<dyn Error>>;
    async fn calculate_nutrition(&self, recipe_id: i64) -> Result<NutritionResult, Box<dyn Error>>;
    async fn get_nutrition(&self, recipe_id: i64) -> Result<NutritionResult, Box<dyn Error>>;
    async fn get_nutrition_source(&self, recipe_id: i64) -> Result<String, Box<dyn Error>>;
    async fn set_calories(&self, recipe_id: i64, calories: f64) -> Result<(), Box<dyn Error>>;
    async fn generate_plan(
        &self,
        diet_type: &str,
        calorie_target: i32,
        meal_types: &[&str],
    ) -> Result<WeeklyMealPlan, Box<dyn Error>>;
}

/// Binary Protocol Driver
///
/// Implementation that calls external binaries via stdin/stdout.
/// This is Layer 3 - the adapter between DSL and external systems.
#[derive(Debug, Clone)]
pub struct BinaryProtocolDriver {
    binary_path: String,
}

impl BinaryProtocolDriver {
    pub fn new() -> Self {
        Self {
            binary_path: "target/release/tandoor_recipe_calculate_nutrition".to_string(),
        }
    }
}

#[async_trait::async_trait]
impl NutritionProtocolDriver for BinaryProtocolDriver {
    async fn create_recipe(
        &self,
        name: &str,
        ingredients: &[TestIngredient],
    ) -> Result<TestRecipe, Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "create",
            "name": name,
            "ingredients": ingredients,
        });

        let output =
            run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        let id = output["id"].as_i64().ok_or("Missing id")?;
        Ok(TestRecipe {
            id,
            name: name.to_string(),
            ingredients: ingredients.to_vec(),
        })
    }

    async fn calculate_nutrition(&self, recipe_id: i64) -> Result<NutritionResult, Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "calculate",
            "recipe_id": recipe_id,
        });

        let output =
            run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        Ok(NutritionResult {
            success: output["success"].as_bool().unwrap_or(false),
            calories: output["calories"].as_f64(),
            protein: output["protein"].as_f64(),
            carbohydrates: output["carbohydrates"].as_f64(),
            fat: output["fat"].as_f64(),
            failed_ingredients: output["failed_ingredients"]
                .as_array()
                .map(|arr| {
                    arr.iter()
                        .filter_map(|v| v.as_str().map(|s| s.to_string()))
                        .collect()
                })
                .unwrap_or_default(),
        })
    }

    async fn get_nutrition(&self, recipe_id: i64) -> Result<NutritionResult, Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "get",
            "recipe_id": recipe_id,
        });

        let output =
            run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        Ok(NutritionResult {
            success: output["success"].as_bool().unwrap_or(false),
            calories: output["calories"].as_f64(),
            protein: output["protein"].as_f64(),
            carbohydrates: output["carbohydrates"].as_f64(),
            fat: output["fat"].as_f64(),
            failed_ingredients: vec![],
        })
    }

    async fn get_nutrition_source(&self, recipe_id: i64) -> Result<String, Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "get_source",
            "recipe_id": recipe_id,
        });

        let output =
            run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        output["source"]
            .as_str()
            .map(|s| s.to_string())
            .ok_or_else(|| {
                Box::new(DSLError::new("Missing source", Layer::ProtocolDriver)) as Box<dyn Error>
            })
    }

    async fn set_calories(&self, recipe_id: i64, calories: f64) -> Result<(), Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "set_calories",
            "recipe_id": recipe_id,
            "calories": calories,
        });

        run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        Ok(())
    }

    async fn generate_plan(
        &self,
        diet_type: &str,
        calorie_target: i32,
        meal_types: &[&str],
    ) -> Result<WeeklyMealPlan, Box<dyn Error>> {
        let input = serde_json::json!({
            "action": "generate_plan",
            "diet_type": diet_type,
            "calorie_target": calorie_target,
            "meal_types": meal_types,
        });

        let output =
            run_binary(&self.binary_path, &input).map_err(|e| Box::new(e) as Box<dyn Error>)?;

        let days: Vec<DayPlan> = output["days"]
            .as_array()
            .ok_or("Missing days")?
            .iter()
            .map(|d| DayPlan {
                name: d["name"].as_str().unwrap_or("").to_string(),
                meals: d["meals"]
                    .as_array()
                    .map(|arr| {
                        arr.iter()
                            .map(|m| Meal {
                                name: m["name"].as_str().unwrap_or("").to_string(),
                                recipe_id: m["recipe_id"].as_i64().unwrap_or(0),
                                calories: m["calories"].as_f64().unwrap_or(0.0),
                            })
                            .collect()
                    })
                    .unwrap_or_default(),
            })
            .collect();

        Ok(WeeklyMealPlan { days })
    }
}

/// Run binary and return JSON output
fn run_binary(binary_path: &str, input: &Value) -> Result<Value, Box<dyn Error>> {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_path, e))?;

    let mut stdin = child.stdin.take().unwrap();
    stdin
        .write_all(input.to_string().as_bytes())
        .map_err(|e| e.to_string())?;
    drop(stdin);

    let output = child.wait_with_output().map_err(|e| e.to_string())?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Binary failed: {}", stderr).into());
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| e.to_string().into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_recipe_creation() {
        let recipe = TestRecipe {
            id: 1,
            name: "Test Recipe".to_string(),
            ingredients: vec![TestIngredient {
                name: "chicken".to_string(),
                amount: 200.0,
                unit: "g".to_string(),
            }],
        };

        assert_eq!(recipe.id, 1);
        assert_eq!(recipe.name, "Test Recipe");
        assert_eq!(recipe.ingredients.len(), 1);
    }

    #[test]
    fn test_nutrition_result() {
        let result = NutritionResult {
            success: true,
            calories: Some(500.0),
            protein: Some(30.0),
            carbohydrates: Some(50.0),
            fat: Some(15.0),
            failed_ingredients: vec![],
        };

        assert!(result.success);
        assert_eq!(result.calories, Some(500.0));
    }

    #[test]
    fn test_dsl_error() {
        let error = DSLError::new("Test error", Layer::DSL);
        assert!(error.to_string().contains("Layer 2: DSL"));
        assert!(error.to_string().contains("Test error"));
    }

    #[test]
    fn test_weekly_meal_plan() {
        let plan = WeeklyMealPlan {
            days: vec![DayPlan {
                name: "Monday".to_string(),
                meals: vec![Meal {
                    name: "Breakfast".to_string(),
                    recipe_id: 1,
                    calories: 400.0,
                }],
            }],
        };

        assert_eq!(plan.days.len(), 1);
        assert_eq!(plan.days[0].meals.len(), 1);
    }
}
