//! Calculate Shopping List Nutrition
#![allow(clippy::unused_async)]
#![allow(clippy::map_unwrap_or)]
//!
//! This binary calculates the total nutrition for a shopping list
//! by looking up each ingredient's nutrition data.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//! ```json
//! {
//!   "items": [
//!     {"name": "Chicken Breast", "amount": 500, "unit": "g", "category": "Meat"},
//!     {"name": "Brown Rice", "amount": 1000, "unit": "g", "category": "Grains"}
//!   ],
//!   "nutrition_data": {
//!     "chicken breast": {"calories": 165, "protein": 31, "carbohydrate": 0, "fat": 3.6}
//!   },
//!   "group_by_category": true
//! }
//! ```
//!
//! JSON stdout:
//! ```json
//! {
//!   "success": true,
//!   "total_calories": 15000,
//!   "total_protein": 800,
//!   "items": [...],
//!   "by_category": {...}
//! }
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::sync::shopping::{
    ShoppingNutritionCalculator, ShoppingConfig, ShoppingItem,
};
use meal_planner::sync::types::NutritionData;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{self, Read};

#[derive(Deserialize)]
struct ItemInput {
    name: String,
    amount: f64,
    unit: String,
    category: Option<String>,
}

#[derive(Deserialize)]
struct NutritionInput {
    calories: f64,
    protein: f64,
    carbohydrate: f64,
    fat: f64,
    fiber: Option<f64>,
}

#[derive(Deserialize)]
struct Input {
    /// Shopping list items
    items: Vec<ItemInput>,
    /// Pre-loaded nutrition data (name -> nutrition per 100g)
    nutrition_data: Option<HashMap<String, NutritionInput>>,
    /// Whether to group by category
    group_by_category: Option<bool>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    total_items: usize,
    items_with_nutrition: usize,
    items_without_nutrition: usize,
    coverage_percent: f64,
    total_nutrition: NutritionOutput,
    macro_ratio: MacroOutput,
    estimated_days: f64,
    items: Vec<ItemOutput>,
    by_category: Option<Vec<CategoryOutput>>,
    warnings: Vec<String>,
}

#[derive(Serialize)]
struct NutritionOutput {
    calories: f64,
    protein: f64,
    carbohydrates: f64,
    fat: f64,
    fiber: Option<f64>,
}

#[derive(Serialize)]
struct MacroOutput {
    protein_pct: f64,
    carb_pct: f64,
    fat_pct: f64,
    is_balanced: bool,
}

#[derive(Serialize)]
struct ItemOutput {
    name: String,
    amount: f64,
    unit: String,
    calories: f64,
    protein: f64,
    category: Option<String>,
    has_nutrition: bool,
}

#[derive(Serialize)]
struct CategoryOutput {
    category: String,
    item_count: usize,
    total_calories: f64,
    total_protein: f64,
    calorie_percent: f64,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    // Convert input items to ShoppingItems
    let items: Vec<ShoppingItem> = input
        .items
        .into_iter()
        .map(|i| {
            let mut item = ShoppingItem::new(&i.name, i.amount, &i.unit);
            if let Some(cat) = i.category {
                item = item.with_category(cat);
            }
            item
        })
        .collect();

    // Set up calculator with nutrition data
    let config = ShoppingConfig {
        group_by_category: input.group_by_category.unwrap_or(true),
        include_unknown: true,
        ..ShoppingConfig::default()
    };

    let mut calculator = ShoppingNutritionCalculator::new(config);

    // Load pre-provided nutrition data
    if let Some(nutrition_map) = input.nutrition_data {
        for (name, nutrition) in nutrition_map {
            calculator.add_nutrition(
                &name,
                NutritionData {
                    calories: nutrition.calories,
                    protein: nutrition.protein,
                    carbohydrate: nutrition.carbohydrate,
                    fat: nutrition.fat,
                    fiber: nutrition.fiber,
                    ..NutritionData::zero()
                },
            );
        }
    }

    // Add common food nutrition data (per 100g)
    add_common_nutrition_data(&mut calculator);

    // Calculate nutrition
    let result = calculator.calculate_list_nutrition(&items)?;

    // Build output
    let mut item_outputs: Vec<ItemOutput> = result
        .items
        .iter()
        .map(|item| ItemOutput {
            name: item.item.name.clone(),
            amount: item.item.amount,
            unit: item.item.unit.clone(),
            calories: item.nutrition.calories,
            protein: item.nutrition.protein,
            category: item.item.category.clone(),
            has_nutrition: item.success,
        })
        .collect();

    // Sort by calories (descending)
    item_outputs.sort_by(|a, b| {
        b.calories.partial_cmp(&a.calories).unwrap_or(std::cmp::Ordering::Equal)
    });

    // Build category output
    let by_category = if result.by_category.is_some() {
        Some(
            result
                .by_category
                .as_ref()
                .unwrap()
                .iter()
                .map(|cat| CategoryOutput {
                    category: cat.category.clone(),
                    item_count: cat.items.len(),
                    total_calories: cat.nutrition.total.calories,
                    total_protein: cat.nutrition.total.protein,
                    calorie_percent: cat.calorie_percentage,
                })
                .collect(),
        )
    } else {
        None
    };

    let macro_ratio = result
        .metrics
        .as_ref()
        .map(|m| MacroOutput {
            protein_pct: m.macro_ratio.protein_pct,
            carb_pct: m.macro_ratio.carb_pct,
            fat_pct: m.macro_ratio.fat_pct,
            is_balanced: m.macro_ratio.is_balanced(),
        })
        .unwrap_or(MacroOutput {
            protein_pct: 0.0,
            carb_pct: 0.0,
            fat_pct: 0.0,
            is_balanced: false,
        });

    let estimated_days = result
        .metrics
        .as_ref()
        .map(|m| m.estimated_days)
        .unwrap_or(0.0);

    Ok(Output {
        success: true,
        total_items: items.len(),
        items_with_nutrition: result.aggregated.items_with_nutrition,
        items_without_nutrition: result.aggregated.items_without_nutrition,
        coverage_percent: result.aggregated.coverage * 100.0,
        total_nutrition: NutritionOutput {
            calories: result.aggregated.total.calories,
            protein: result.aggregated.total.protein,
            carbohydrates: result.aggregated.total.carbohydrates(),
            fat: result.aggregated.total.fat,
            fiber: result.aggregated.total.fiber,
        },
        macro_ratio,
        estimated_days,
        items: item_outputs,
        by_category,
        warnings: result.warnings,
    })
}

/// Add common food nutrition data (per 100g)
fn add_common_nutrition_data(calculator: &mut ShoppingNutritionCalculator) {
    // Proteins
    calculator.add_nutrition("chicken breast", NutritionData {
        calories: 165.0, protein: 31.0, carbohydrate: 0.0, fat: 3.6,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("chicken", NutritionData {
        calories: 165.0, protein: 31.0, carbohydrate: 0.0, fat: 3.6,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("beef", NutritionData {
        calories: 250.0, protein: 26.0, carbohydrate: 0.0, fat: 15.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("salmon", NutritionData {
        calories: 208.0, protein: 20.0, carbohydrate: 0.0, fat: 13.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("eggs", NutritionData {
        calories: 155.0, protein: 13.0, carbohydrate: 1.0, fat: 11.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("tofu", NutritionData {
        calories: 76.0, protein: 8.0, carbohydrate: 2.0, fat: 4.0,
        ..NutritionData::zero()
    });

    // Grains
    calculator.add_nutrition("rice", NutritionData {
        calories: 130.0, protein: 2.7, carbohydrate: 28.0, fat: 0.3,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("pasta", NutritionData {
        calories: 131.0, protein: 5.0, carbohydrate: 25.0, fat: 1.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("bread", NutritionData {
        calories: 265.0, protein: 9.0, carbohydrate: 49.0, fat: 3.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("oats", NutritionData {
        calories: 389.0, protein: 17.0, carbohydrate: 66.0, fat: 7.0,
        ..NutritionData::zero()
    });

    // Vegetables
    calculator.add_nutrition("broccoli", NutritionData {
        calories: 34.0, protein: 2.8, carbohydrate: 7.0, fat: 0.4,
        fiber: Some(2.6), ..NutritionData::zero()
    });
    calculator.add_nutrition("spinach", NutritionData {
        calories: 23.0, protein: 2.9, carbohydrate: 3.6, fat: 0.4,
        fiber: Some(2.2), ..NutritionData::zero()
    });
    calculator.add_nutrition("carrots", NutritionData {
        calories: 41.0, protein: 0.9, carbohydrate: 10.0, fat: 0.2,
        fiber: Some(2.8), ..NutritionData::zero()
    });
    calculator.add_nutrition("onions", NutritionData {
        calories: 40.0, protein: 1.1, carbohydrate: 9.0, fat: 0.1,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("potatoes", NutritionData {
        calories: 77.0, protein: 2.0, carbohydrate: 17.0, fat: 0.1,
        fiber: Some(2.2), ..NutritionData::zero()
    });
    calculator.add_nutrition("tomatoes", NutritionData {
        calories: 18.0, protein: 0.9, carbohydrate: 3.9, fat: 0.2,
        ..NutritionData::zero()
    });

    // Dairy
    calculator.add_nutrition("milk", NutritionData {
        calories: 42.0, protein: 3.4, carbohydrate: 5.0, fat: 1.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("cheese", NutritionData {
        calories: 402.0, protein: 25.0, carbohydrate: 1.3, fat: 33.0,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("yogurt", NutritionData {
        calories: 59.0, protein: 10.0, carbohydrate: 3.6, fat: 0.7,
        ..NutritionData::zero()
    });
    calculator.add_nutrition("butter", NutritionData {
        calories: 717.0, protein: 0.9, carbohydrate: 0.1, fat: 81.0,
        ..NutritionData::zero()
    });

    // Fruits
    calculator.add_nutrition("apples", NutritionData {
        calories: 52.0, protein: 0.3, carbohydrate: 14.0, fat: 0.2,
        fiber: Some(2.4), ..NutritionData::zero()
    });
    calculator.add_nutrition("bananas", NutritionData {
        calories: 89.0, protein: 1.1, carbohydrate: 23.0, fat: 0.3,
        fiber: Some(2.6), ..NutritionData::zero()
    });
    calculator.add_nutrition("oranges", NutritionData {
        calories: 47.0, protein: 0.9, carbohydrate: 12.0, fat: 0.1,
        fiber: Some(2.4), ..NutritionData::zero()
    });

    // Oils
    calculator.add_nutrition("olive oil", NutritionData {
        calories: 884.0, protein: 0.0, carbohydrate: 0.0, fat: 100.0,
        ..NutritionData::zero()
    });
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        Ok(serde_json::from_str(&arg)?)
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        Ok(serde_json::from_str(&input_str)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            total_items: 10,
            items_with_nutrition: 8,
            items_without_nutrition: 2,
            coverage_percent: 80.0,
            total_nutrition: NutritionOutput {
                calories: 15000.0,
                protein: 800.0,
                carbohydrates: 1500.0,
                fat: 500.0,
                fiber: Some(150.0),
            },
            macro_ratio: MacroOutput {
                protein_pct: 30.0,
                carb_pct: 40.0,
                fat_pct: 30.0,
                is_balanced: true,
            },
            estimated_days: 7.5,
            items: vec![],
            by_category: None,
            warnings: vec![],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"total_items\":10"));
    }

    #[test]
    fn test_item_output_serialize() {
        let item = ItemOutput {
            name: "Chicken Breast".to_string(),
            amount: 500.0,
            unit: "g".to_string(),
            calories: 825.0,
            protein: 155.0,
            category: Some("Meat".to_string()),
            has_nutrition: true,
        };
        let json = serde_json::to_string(&item).expect("Failed to serialize");
        assert!(json.contains("\"name\":\"Chicken Breast\""));
    }

    #[test]
    fn test_error_serialize() {
        let error = ErrorOutput {
            success: false,
            error: "Test error".to_string(),
        };
        let json = serde_json::to_string(&error).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
    }
}
