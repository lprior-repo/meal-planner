//! Shopping List Nutrition Calculator
//!
//! This module provides functionality for calculating the total nutrition
//! of a shopping list by looking up each ingredient in FatSecret.
//!
//! # Features
//!
//! - Calculate nutrition for individual shopping items
//! - Aggregate nutrition across the entire shopping list
//! - Handle unit conversions for accurate calculations
//! - Group nutrition by food category
//! - Estimate cost-per-calorie and cost-per-protein metrics
//!
//! # Architecture
//!
//! ```text
//! Tandoor Shopping List → ShoppingNutritionCalculator → Aggregated Nutrition
//!         ↓                        ↓
//!   ┌─────────────┐        ┌─────────────────┐
//!   │ Shopping    │        │ FatSecret       │
//!   │ Items       │───────→│ Nutrition       │
//!   └─────────────┘        │ Lookup          │
//!                          └─────────────────┘
//! ```
//!
//! # Example
//!
//! ```rust,no_run
//! use meal_planner::sync::shopping::{
//!     ShoppingNutritionCalculator, ShoppingConfig, ShoppingItem,
//! };
//!
//! let config = ShoppingConfig::default();
//! let calculator = ShoppingNutritionCalculator::new(config);
//!
//! let items = vec![
//!     ShoppingItem::new("Chicken Breast", 500.0, "g"),
//!     ShoppingItem::new("Brown Rice", 1.0, "kg"),
//! ];
//!
//! let result = calculator.calculate_list_nutrition(&items);
//! ```

use crate::sync::errors::{SyncError, SyncResult};
use crate::sync::types::NutritionData;
use crate::sync::units::{UnitConverter, convert_to_grams};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Configuration for shopping nutrition calculations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShoppingConfig {
    /// Whether to include items without nutrition data in totals
    pub include_unknown: bool,
    /// Default serving size in grams for items without unit info
    pub default_serving_grams: f64,
    /// Whether to group results by category
    pub group_by_category: bool,
    /// Whether to calculate per-unit metrics (cost per calorie, etc.)
    pub calculate_metrics: bool,
    /// Minimum confidence for nutrition lookups
    pub min_lookup_confidence: f64,
    /// Whether to cache lookup results
    pub enable_cache: bool,
    /// Maximum items to process in a single batch
    pub max_batch_size: usize,
}

impl Default for ShoppingConfig {
    fn default() -> Self {
        Self {
            include_unknown: false,
            default_serving_grams: 100.0,
            group_by_category: true,
            calculate_metrics: true,
            min_lookup_confidence: 0.7,
            enable_cache: true,
            max_batch_size: 100,
        }
    }
}

impl ShoppingConfig {
    /// Create config for quick calculations without grouping
    #[must_use]
    pub fn quick() -> Self {
        Self {
            group_by_category: false,
            calculate_metrics: false,
            enable_cache: true,
            ..Self::default()
        }
    }

    /// Create config for detailed analysis
    #[must_use]
    pub fn detailed() -> Self {
        Self {
            group_by_category: true,
            calculate_metrics: true,
            include_unknown: true,
            ..Self::default()
        }
    }

    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.default_serving_grams <= 0.0 {
            return Err(SyncError::validation(
                "default_serving_grams must be positive",
            ));
        }
        if !(0.0..=1.0).contains(&self.min_lookup_confidence) {
            return Err(SyncError::validation(
                "min_lookup_confidence must be between 0.0 and 1.0",
            ));
        }
        if self.max_batch_size == 0 {
            return Err(SyncError::validation("max_batch_size must be positive"));
        }
        Ok(())
    }
}

/// A shopping list item from Tandoor
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShoppingItem {
    /// Item ID from Tandoor
    pub id: Option<i64>,
    /// Ingredient/food name
    pub name: String,
    /// Amount to purchase
    pub amount: f64,
    /// Unit of measurement
    pub unit: String,
    /// Food category (produce, dairy, meat, etc.)
    pub category: Option<String>,
    /// Whether item is checked/purchased
    pub checked: bool,
    /// Associated recipe IDs
    pub recipe_ids: Vec<i64>,
    /// Estimated price (optional)
    pub price: Option<f64>,
    /// FatSecret food ID if already mapped
    pub fatsecret_food_id: Option<i64>,
}

impl ShoppingItem {
    /// Create a new shopping item
    #[must_use]
    pub fn new(name: impl Into<String>, amount: f64, unit: impl Into<String>) -> Self {
        Self {
            id: None,
            name: name.into(),
            amount,
            unit: unit.into(),
            category: None,
            checked: false,
            recipe_ids: Vec::new(),
            price: None,
            fatsecret_food_id: None,
        }
    }

    /// Create from Tandoor shopping list entry
    #[must_use]
    pub fn from_tandoor(
        id: i64,
        name: String,
        amount: f64,
        unit: String,
        checked: bool,
    ) -> Self {
        Self {
            id: Some(id),
            name,
            amount,
            unit,
            category: None,
            checked,
            recipe_ids: Vec::new(),
            price: None,
            fatsecret_food_id: None,
        }
    }

    /// Builder: set category
    #[must_use]
    pub fn with_category(mut self, category: impl Into<String>) -> Self {
        self.category = Some(category.into());
        self
    }

    /// Builder: set price
    #[must_use]
    pub fn with_price(mut self, price: f64) -> Self {
        self.price = Some(price);
        self
    }

    /// Builder: set FatSecret food ID
    #[must_use]
    pub fn with_fatsecret_id(mut self, food_id: i64) -> Self {
        self.fatsecret_food_id = Some(food_id);
        self
    }

    /// Builder: add recipe ID
    #[must_use]
    pub fn with_recipe(mut self, recipe_id: i64) -> Self {
        self.recipe_ids.push(recipe_id);
        self
    }
}

/// Nutrition data for a single shopping item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShoppingItemNutrition {
    /// The shopping item
    pub item: ShoppingItem,
    /// Nutrition for the specified amount
    pub nutrition: NutritionData,
    /// FatSecret food ID used for lookup
    pub fatsecret_food_id: Option<i64>,
    /// FatSecret food name matched
    pub fatsecret_food_name: Option<String>,
    /// Match confidence (0.0-1.0)
    pub confidence: f64,
    /// Amount in grams (normalized)
    pub amount_grams: f64,
    /// Whether nutrition was successfully calculated
    pub success: bool,
    /// Error message if calculation failed
    pub error: Option<String>,
}

impl ShoppingItemNutrition {
    /// Create a successful nutrition result
    #[must_use]
    pub fn success(
        item: ShoppingItem,
        nutrition: NutritionData,
        food_id: i64,
        food_name: String,
        confidence: f64,
        amount_grams: f64,
    ) -> Self {
        Self {
            item,
            nutrition,
            fatsecret_food_id: Some(food_id),
            fatsecret_food_name: Some(food_name),
            confidence,
            amount_grams,
            success: true,
            error: None,
        }
    }

    /// Create a failed nutrition result
    #[must_use]
    pub fn failure(item: ShoppingItem, error: impl Into<String>) -> Self {
        Self {
            item,
            nutrition: NutritionData::zero(),
            fatsecret_food_id: None,
            fatsecret_food_name: None,
            confidence: 0.0,
            amount_grams: 0.0,
            success: false,
            error: Some(error.into()),
        }
    }

    /// Create an unknown result (no lookup attempted)
    #[must_use]
    pub fn unknown(item: ShoppingItem) -> Self {
        Self {
            item,
            nutrition: NutritionData::zero(),
            fatsecret_food_id: None,
            fatsecret_food_name: None,
            confidence: 0.0,
            amount_grams: 0.0,
            success: false,
            error: Some("No nutrition lookup performed".to_string()),
        }
    }
}

/// Aggregated nutrition for the shopping list
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AggregatedNutrition {
    /// Total nutrition across all items
    pub total: NutritionData,
    /// Number of items with successful nutrition lookup
    pub items_with_nutrition: usize,
    /// Number of items without nutrition data
    pub items_without_nutrition: usize,
    /// Total weight in grams
    pub total_weight_grams: f64,
    /// Total estimated cost (if prices provided)
    pub total_cost: Option<f64>,
    /// Coverage percentage (items with nutrition / total items)
    pub coverage: f64,
}

impl AggregatedNutrition {
    /// Create empty aggregation
    #[must_use]
    pub fn empty() -> Self {
        Self {
            total: NutritionData::zero(),
            items_with_nutrition: 0,
            items_without_nutrition: 0,
            total_weight_grams: 0.0,
            total_cost: None,
            coverage: 0.0,
        }
    }

    /// Add nutrition from an item
    pub fn add(&mut self, item_nutrition: &ShoppingItemNutrition) {
        if item_nutrition.success {
            self.total = self.total.add(&item_nutrition.nutrition);
            self.items_with_nutrition += 1;
            self.total_weight_grams += item_nutrition.amount_grams;

            if let Some(price) = item_nutrition.item.price {
                *self.total_cost.get_or_insert(0.0) += price;
            }
        } else {
            self.items_without_nutrition += 1;
        }

        self.update_coverage();
    }

    /// Update coverage percentage
    fn update_coverage(&mut self) {
        let total = self.items_with_nutrition + self.items_without_nutrition;
        if total > 0 {
            #[allow(clippy::cast_precision_loss)]
            {
                self.coverage = self.items_with_nutrition as f64 / total as f64;
            }
        }
    }

    /// Get calories per dollar (if cost available)
    #[must_use]
    pub fn calories_per_dollar(&self) -> Option<f64> {
        self.total_cost.filter(|&c| c > 0.0).map(|cost| self.total.calories / cost)
    }

    /// Get protein per dollar (if cost available)
    #[must_use]
    pub fn protein_per_dollar(&self) -> Option<f64> {
        self.total_cost.filter(|&c| c > 0.0).map(|cost| self.total.protein / cost)
    }

    /// Get calories per gram
    #[must_use]
    pub fn calories_per_gram(&self) -> f64 {
        if self.total_weight_grams > 0.0 {
            self.total.calories / self.total_weight_grams
        } else {
            0.0
        }
    }
}

/// Nutrition grouped by category
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CategoryNutrition {
    /// Category name
    pub category: String,
    /// Aggregated nutrition for this category
    pub nutrition: AggregatedNutrition,
    /// Items in this category
    pub items: Vec<ShoppingItemNutrition>,
    /// Percentage of total calories from this category
    pub calorie_percentage: f64,
    /// Percentage of total protein from this category
    pub protein_percentage: f64,
}

impl CategoryNutrition {
    /// Create a new category nutrition grouping
    #[must_use]
    pub fn new(category: impl Into<String>) -> Self {
        Self {
            category: category.into(),
            nutrition: AggregatedNutrition::empty(),
            items: Vec::new(),
            calorie_percentage: 0.0,
            protein_percentage: 0.0,
        }
    }

    /// Add an item to this category
    pub fn add_item(&mut self, item: ShoppingItemNutrition) {
        self.nutrition.add(&item);
        self.items.push(item);
    }

    /// Update percentages based on total nutrition
    pub fn update_percentages(&mut self, total: &NutritionData) {
        if total.calories > 0.0 {
            self.calorie_percentage = self.nutrition.total.calories / total.calories * 100.0;
        }
        if total.protein > 0.0 {
            self.protein_percentage = self.nutrition.total.protein / total.protein * 100.0;
        }
    }
}

/// Complete shopping nutrition result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShoppingNutrition {
    /// Individual item nutrition
    pub items: Vec<ShoppingItemNutrition>,
    /// Aggregated totals
    pub aggregated: AggregatedNutrition,
    /// Nutrition by category (if grouped)
    pub by_category: Option<Vec<CategoryNutrition>>,
    /// Metrics and insights
    pub metrics: Option<ShoppingMetrics>,
    /// Processing warnings
    pub warnings: Vec<String>,
}

impl ShoppingNutrition {
    /// Create a new shopping nutrition result
    #[must_use]
    pub fn new(items: Vec<ShoppingItemNutrition>) -> Self {
        let mut aggregated = AggregatedNutrition::empty();
        for item in &items {
            aggregated.add(item);
        }

        Self {
            items,
            aggregated,
            by_category: None,
            metrics: None,
            warnings: Vec::new(),
        }
    }

    /// Add category grouping
    #[must_use]
    pub fn with_categories(mut self, categories: Vec<CategoryNutrition>) -> Self {
        self.by_category = Some(categories);
        self
    }

    /// Add metrics
    #[must_use]
    pub fn with_metrics(mut self, metrics: ShoppingMetrics) -> Self {
        self.metrics = Some(metrics);
        self
    }

    /// Get total calories
    #[must_use]
    pub fn total_calories(&self) -> f64 {
        self.aggregated.total.calories
    }

    /// Get total protein
    #[must_use]
    pub fn total_protein(&self) -> f64 {
        self.aggregated.total.protein
    }

    /// Get items that failed nutrition lookup
    #[must_use]
    pub fn failed_items(&self) -> Vec<&ShoppingItemNutrition> {
        self.items.iter().filter(|i| !i.success).collect()
    }

    /// Get items by category
    #[must_use]
    pub fn items_by_category(&self, category: &str) -> Vec<&ShoppingItemNutrition> {
        self.items
            .iter()
            .filter(|i| i.item.category.as_deref() == Some(category))
            .collect()
    }
}

/// Shopping list metrics and insights
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShoppingMetrics {
    /// Calories per dollar spent
    pub calories_per_dollar: Option<f64>,
    /// Protein per dollar spent
    pub protein_per_dollar: Option<f64>,
    /// Average calories per gram
    pub calories_per_gram: f64,
    /// Average protein per gram
    pub protein_per_gram: f64,
    /// Macro ratios (protein/carbs/fat percentages)
    pub macro_ratio: MacroRatio,
    /// Estimated days of food (at 2000 cal/day)
    pub estimated_days: f64,
    /// Highest calorie item
    pub highest_calorie_item: Option<String>,
    /// Highest protein item
    pub highest_protein_item: Option<String>,
    /// Category with most calories
    pub top_calorie_category: Option<String>,
}

/// Macronutrient ratio
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MacroRatio {
    /// Protein percentage of calories
    pub protein_pct: f64,
    /// Carbohydrate percentage of calories
    pub carb_pct: f64,
    /// Fat percentage of calories
    pub fat_pct: f64,
}

impl MacroRatio {
    /// Calculate from nutrition data
    #[must_use]
    pub fn from_nutrition(nutrition: &NutritionData) -> Self {
        // Calories from each macro: protein/carbs = 4 cal/g, fat = 9 cal/g
        let protein_cal = nutrition.protein * 4.0;
        let carb_cal = nutrition.carbohydrates() * 4.0;
        let fat_cal = nutrition.fat * 9.0;
        let total_cal = protein_cal + carb_cal + fat_cal;

        if total_cal > 0.0 {
            Self {
                protein_pct: protein_cal / total_cal * 100.0,
                carb_pct: carb_cal / total_cal * 100.0,
                fat_pct: fat_cal / total_cal * 100.0,
            }
        } else {
            Self {
                protein_pct: 0.0,
                carb_pct: 0.0,
                fat_pct: 0.0,
            }
        }
    }

    /// Check if this is a balanced ratio (roughly 30/40/30)
    #[must_use]
    pub fn is_balanced(&self) -> bool {
        (25.0..=35.0).contains(&self.protein_pct)
            && (35.0..=45.0).contains(&self.carb_pct)
            && (25.0..=35.0).contains(&self.fat_pct)
    }

    /// Check if this is high protein (>35%)
    #[must_use]
    pub fn is_high_protein(&self) -> bool {
        self.protein_pct > 35.0
    }

    /// Check if this is low carb (<25%)
    #[must_use]
    pub fn is_low_carb(&self) -> bool {
        self.carb_pct < 25.0
    }
}

/// Shopping list nutrition calculator (functional core)
#[derive(Debug, Clone)]
pub struct ShoppingNutritionCalculator {
    /// Configuration
    config: ShoppingConfig,
    /// Unit converter (reserved for future use)
    _unit_converter: UnitConverter,
    /// Nutrition per 100g for known foods (simplified lookup)
    nutrition_per_100g: HashMap<String, NutritionData>,
}

impl ShoppingNutritionCalculator {
    /// Create a new calculator
    #[must_use]
    pub fn new(config: ShoppingConfig) -> Self {
        Self {
            config,
            _unit_converter: UnitConverter::new(),
            nutrition_per_100g: HashMap::new(),
        }
    }

    /// Create with default config
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(ShoppingConfig::default())
    }

    /// Add nutrition data for a food (per 100g)
    pub fn add_nutrition(&mut self, food_name: &str, nutrition: NutritionData) {
        self.nutrition_per_100g.insert(food_name.to_lowercase(), nutrition);
    }

    /// Load nutrition data from a map
    pub fn load_nutrition_data(&mut self, data: HashMap<String, NutritionData>) {
        for (name, nutrition) in data {
            self.add_nutrition(&name, nutrition);
        }
    }

    /// Calculate nutrition for a single item
    pub fn calculate_item_nutrition(
        &self,
        item: &ShoppingItem,
    ) -> ShoppingItemNutrition {
        // Try to find nutrition data
        let food_key = item.name.to_lowercase();

        if let Some(nutrition_per_100g) = self.nutrition_per_100g.get(&food_key) {
            // Convert amount to grams
            let amount_grams = self.convert_to_grams(item.amount, &item.unit)
                .unwrap_or(item.amount * self.config.default_serving_grams);

            // Scale nutrition to actual amount
            let scale = amount_grams / 100.0;
            let nutrition = nutrition_per_100g.scale(scale);

            ShoppingItemNutrition::success(
                item.clone(),
                nutrition,
                item.fatsecret_food_id.unwrap_or(0),
                item.name.clone(),
                1.0, // Confidence
                amount_grams,
            )
        } else if self.config.include_unknown {
            ShoppingItemNutrition::unknown(item.clone())
        } else {
            ShoppingItemNutrition::failure(
                item.clone(),
                format!("No nutrition data found for '{}'", item.name),
            )
        }
    }

    /// Convert amount to grams
    fn convert_to_grams(&self, amount: f64, unit: &str) -> Option<f64> {
        let grams = convert_to_grams(amount, unit);
        // Return None if conversion resulted in 0 for non-zero input (unknown unit)
        if amount > 0.0 && grams == 0.0 {
            None
        } else {
            Some(grams)
        }
    }

    /// Calculate nutrition for entire shopping list
    pub fn calculate_list_nutrition(
        &self,
        items: &[ShoppingItem],
    ) -> SyncResult<ShoppingNutrition> {
        if items.len() > self.config.max_batch_size {
            return Err(SyncError::validation(format!(
                "Too many items ({} > {}). Process in smaller batches.",
                items.len(),
                self.config.max_batch_size
            )));
        }

        let mut item_results = Vec::with_capacity(items.len());
        let mut warnings = Vec::new();

        for item in items {
            let result = self.calculate_item_nutrition(item);
            if !result.success && !self.config.include_unknown {
                warnings.push(format!(
                    "Could not find nutrition for: {}",
                    item.name
                ));
            }
            item_results.push(result);
        }

        let mut nutrition = ShoppingNutrition::new(item_results);
        nutrition.warnings = warnings;

        // Group by category if configured
        if self.config.group_by_category {
            let categories = self.group_by_category(&nutrition.items, &nutrition.aggregated.total);
            nutrition = nutrition.with_categories(categories);
        }

        // Calculate metrics if configured
        if self.config.calculate_metrics {
            let metrics = self.calculate_metrics(&nutrition);
            nutrition = nutrition.with_metrics(metrics);
        }

        Ok(nutrition)
    }

    /// Group items by category
    fn group_by_category(
        &self,
        items: &[ShoppingItemNutrition],
        total: &NutritionData,
    ) -> Vec<CategoryNutrition> {
        let mut categories: HashMap<String, CategoryNutrition> = HashMap::new();

        for item in items {
            let category_name = item
                .item
                .category
                .clone()
                .unwrap_or_else(|| "Uncategorized".to_string());

            let category = categories
                .entry(category_name.clone())
                .or_insert_with(|| CategoryNutrition::new(&category_name));

            category.add_item(item.clone());
        }

        // Update percentages
        let mut result: Vec<CategoryNutrition> = categories.into_values().collect();
        for category in &mut result {
            category.update_percentages(total);
        }

        // Sort by calories (descending)
        result.sort_by(|a, b| {
            b.nutrition.total.calories
                .partial_cmp(&a.nutrition.total.calories)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        result
    }

    /// Calculate shopping metrics
    fn calculate_metrics(&self, nutrition: &ShoppingNutrition) -> ShoppingMetrics {
        let total = &nutrition.aggregated.total;

        // Find highest calorie and protein items
        let highest_calorie = nutrition
            .items
            .iter()
            .filter(|i| i.success)
            .max_by(|a, b| {
                a.nutrition.calories
                    .partial_cmp(&b.nutrition.calories)
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .map(|i| i.item.name.clone());

        let highest_protein = nutrition
            .items
            .iter()
            .filter(|i| i.success)
            .max_by(|a, b| {
                a.nutrition.protein
                    .partial_cmp(&b.nutrition.protein)
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .map(|i| i.item.name.clone());

        // Find top category
        let top_category = nutrition
            .by_category
            .as_ref()
            .and_then(|cats| cats.first())
            .map(|c| c.category.clone());

        ShoppingMetrics {
            calories_per_dollar: nutrition.aggregated.calories_per_dollar(),
            protein_per_dollar: nutrition.aggregated.protein_per_dollar(),
            calories_per_gram: nutrition.aggregated.calories_per_gram(),
            protein_per_gram: if nutrition.aggregated.total_weight_grams > 0.0 {
                total.protein / nutrition.aggregated.total_weight_grams
            } else {
                0.0
            },
            macro_ratio: MacroRatio::from_nutrition(total),
            estimated_days: total.calories / 2000.0,
            highest_calorie_item: highest_calorie,
            highest_protein_item: highest_protein,
            top_calorie_category: top_category,
        }
    }

    /// Estimate nutrition when exact data is unavailable
    pub fn estimate_nutrition(
        &self,
        item: &ShoppingItem,
        similar_items: &[(&str, NutritionData)],
    ) -> ShoppingItemNutrition {
        if similar_items.is_empty() {
            return ShoppingItemNutrition::failure(
                item.clone(),
                "No similar items for estimation",
            );
        }

        // Average the nutrition of similar items
        let mut total = NutritionData::zero();
        for (_, nutrition) in similar_items {
            total = total.add(nutrition);
        }

        #[allow(clippy::cast_precision_loss)]
        let avg = total.scale(1.0 / similar_items.len() as f64);

        // Convert amount to grams
        let amount_grams = self.convert_to_grams(item.amount, &item.unit)
            .unwrap_or(item.amount * self.config.default_serving_grams);

        // Scale to actual amount
        let scaled = avg.scale(amount_grams / 100.0);

        ShoppingItemNutrition {
            item: item.clone(),
            nutrition: scaled,
            fatsecret_food_id: None,
            fatsecret_food_name: Some(format!("Estimated from {} items", similar_items.len())),
            confidence: 0.5, // Lower confidence for estimates
            amount_grams,
            success: true,
            error: None,
        }
    }

    /// Merge duplicate items in shopping list
    #[must_use]
    pub fn merge_duplicates(&self, items: Vec<ShoppingItem>) -> Vec<ShoppingItem> {
        let mut merged: HashMap<String, ShoppingItem> = HashMap::new();

        for item in items {
            let key = format!("{}:{}", item.name.to_lowercase(), item.unit.to_lowercase());

            if let Some(existing) = merged.get_mut(&key) {
                existing.amount += item.amount;
                existing.recipe_ids.extend(item.recipe_ids);
                if item.price.is_some() {
                    if let Some(ref mut price) = existing.price {
                        *price += item.price.unwrap_or(0.0);
                    } else {
                        existing.price = item.price;
                    }
                }
            } else {
                merged.insert(key, item);
            }
        }

        merged.into_values().collect()
    }

    /// Filter items by category
    #[must_use]
    pub fn filter_by_category<'a>(
        &self,
        items: &'a [ShoppingItem],
        category: &str,
    ) -> Vec<&'a ShoppingItem> {
        items
            .iter()
            .filter(|i| i.category.as_deref() == Some(category))
            .collect()
    }

    /// Get unchecked items only
    #[must_use]
    pub fn unchecked_items<'a>(&self, items: &'a [ShoppingItem]) -> Vec<&'a ShoppingItem> {
        items.iter().filter(|i| !i.checked).collect()
    }

    /// Calculate cost breakdown by category
    #[must_use]
    pub fn cost_by_category(&self, items: &[ShoppingItem]) -> HashMap<String, f64> {
        let mut costs: HashMap<String, f64> = HashMap::new();

        for item in items {
            if let Some(price) = item.price {
                let category = item.category.clone().unwrap_or_else(|| "Other".to_string());
                *costs.entry(category).or_insert(0.0) += price;
            }
        }

        costs
    }
}

/// Shopping list builder for creating test data
#[derive(Debug, Default)]
pub struct ShoppingListBuilder {
    items: Vec<ShoppingItem>,
}

impl ShoppingListBuilder {
    /// Create a new builder
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Add an item
    #[must_use]
    pub fn add(mut self, name: impl Into<String>, amount: f64, unit: impl Into<String>) -> Self {
        self.items.push(ShoppingItem::new(name, amount, unit));
        self
    }

    /// Add an item with category
    #[must_use]
    pub fn add_with_category(
        mut self,
        name: impl Into<String>,
        amount: f64,
        unit: impl Into<String>,
        category: impl Into<String>,
    ) -> Self {
        self.items.push(
            ShoppingItem::new(name, amount, unit).with_category(category),
        );
        self
    }

    /// Add an item with price
    #[must_use]
    pub fn add_with_price(
        mut self,
        name: impl Into<String>,
        amount: f64,
        unit: impl Into<String>,
        price: f64,
    ) -> Self {
        self.items.push(
            ShoppingItem::new(name, amount, unit).with_price(price),
        );
        self
    }

    /// Build the shopping list
    #[must_use]
    pub fn build(self) -> Vec<ShoppingItem> {
        self.items
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_nutrition() -> NutritionData {
        NutritionData {
            calories: 165.0,
            protein: 31.0,
            carbohydrate: 0.0,
            fat: 3.6,
            fiber: Some(0.0),
            sugar: Some(0.0),
            sodium: Some(74.0),
            ..NutritionData::zero()
        }
    }

    #[test]
    fn test_shopping_config_default() {
        let config = ShoppingConfig::default();
        assert!(!config.include_unknown);
        assert!(config.group_by_category);
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_shopping_config_quick() {
        let config = ShoppingConfig::quick();
        assert!(!config.group_by_category);
        assert!(!config.calculate_metrics);
    }

    #[test]
    fn test_shopping_config_validation() {
        let mut config = ShoppingConfig::default();
        config.default_serving_grams = 0.0;
        assert!(config.validate().is_err());

        config.default_serving_grams = 100.0;
        config.min_lookup_confidence = 1.5;
        assert!(config.validate().is_err());
    }

    #[test]
    fn test_shopping_item_new() {
        let item = ShoppingItem::new("Chicken", 500.0, "g");
        assert_eq!(item.name, "Chicken");
        assert!((item.amount - 500.0).abs() < 1e-10);
        assert_eq!(item.unit, "g");
        assert!(!item.checked);
    }

    #[test]
    fn test_shopping_item_builder() {
        let item = ShoppingItem::new("Rice", 1.0, "kg")
            .with_category("Grains")
            .with_price(3.50)
            .with_recipe(1)
            .with_recipe(2);

        assert_eq!(item.category, Some("Grains".to_string()));
        assert_eq!(item.price, Some(3.50));
        assert_eq!(item.recipe_ids.len(), 2);
    }

    #[test]
    fn test_shopping_item_nutrition_success() {
        let item = ShoppingItem::new("Test", 100.0, "g");
        let result = ShoppingItemNutrition::success(
            item,
            sample_nutrition(),
            123,
            "Test Food".to_string(),
            0.95,
            100.0,
        );

        assert!(result.success);
        assert_eq!(result.fatsecret_food_id, Some(123));
        assert!((result.confidence - 0.95).abs() < 1e-10);
    }

    #[test]
    fn test_shopping_item_nutrition_failure() {
        let item = ShoppingItem::new("Unknown", 100.0, "g");
        let result = ShoppingItemNutrition::failure(item, "Not found");

        assert!(!result.success);
        assert!(result.error.is_some());
    }

    #[test]
    fn test_aggregated_nutrition() {
        let mut agg = AggregatedNutrition::empty();
        assert_eq!(agg.items_with_nutrition, 0);

        let item = ShoppingItem::new("Test", 100.0, "g").with_price(5.0);
        let nutrition = ShoppingItemNutrition::success(
            item,
            sample_nutrition(),
            1,
            "Test".to_string(),
            1.0,
            100.0,
        );

        agg.add(&nutrition);
        assert_eq!(agg.items_with_nutrition, 1);
        assert!((agg.total.calories - 165.0).abs() < 1e-10);
        assert_eq!(agg.total_cost, Some(5.0));
        assert!((agg.coverage - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_aggregated_nutrition_metrics() {
        let mut agg = AggregatedNutrition::empty();
        let item = ShoppingItem::new("Test", 100.0, "g").with_price(10.0);
        let nutrition = ShoppingItemNutrition::success(
            item,
            NutritionData {
                calories: 200.0,
                protein: 20.0,
                ..NutritionData::zero()
            },
            1,
            "Test".to_string(),
            1.0,
            100.0,
        );

        agg.add(&nutrition);

        assert_eq!(agg.calories_per_dollar(), Some(20.0));
        assert_eq!(agg.protein_per_dollar(), Some(2.0));
        assert!((agg.calories_per_gram() - 2.0).abs() < 1e-10);
    }

    #[test]
    fn test_category_nutrition() {
        let mut cat = CategoryNutrition::new("Meat");
        assert_eq!(cat.category, "Meat");

        let item = ShoppingItem::new("Chicken", 100.0, "g");
        let nutrition = ShoppingItemNutrition::success(
            item,
            sample_nutrition(),
            1,
            "Chicken".to_string(),
            1.0,
            100.0,
        );

        cat.add_item(nutrition);
        assert_eq!(cat.items.len(), 1);
        assert!((cat.nutrition.total.calories - 165.0).abs() < 1e-10);
    }

    #[test]
    fn test_macro_ratio() {
        let nutrition = NutritionData {
            calories: 400.0,
            protein: 30.0,  // 120 cal
            carbohydrate: 40.0, // 160 cal
            fat: 13.3,  // ~120 cal
            ..NutritionData::zero()
        };

        let ratio = MacroRatio::from_nutrition(&nutrition);
        assert!((ratio.protein_pct - 30.0).abs() < 1.0);
        assert!((ratio.carb_pct - 40.0).abs() < 1.0);
        assert!((ratio.fat_pct - 30.0).abs() < 1.0);
        assert!(ratio.is_balanced());
    }

    #[test]
    fn test_macro_ratio_high_protein() {
        let nutrition = NutritionData {
            protein: 50.0,
            carbohydrate: 20.0,
            fat: 10.0,
            ..NutritionData::zero()
        };

        let ratio = MacroRatio::from_nutrition(&nutrition);
        assert!(ratio.is_high_protein());
    }

    #[test]
    fn test_calculator_new() {
        let calc = ShoppingNutritionCalculator::with_defaults();
        assert!(calc.nutrition_per_100g.is_empty());
    }

    #[test]
    fn test_calculator_add_nutrition() {
        let mut calc = ShoppingNutritionCalculator::with_defaults();
        calc.add_nutrition("chicken", sample_nutrition());

        assert!(calc.nutrition_per_100g.contains_key("chicken"));
    }

    #[test]
    fn test_calculate_item_nutrition() {
        let mut calc = ShoppingNutritionCalculator::with_defaults();
        calc.add_nutrition("chicken breast", sample_nutrition());

        let item = ShoppingItem::new("Chicken Breast", 200.0, "g");
        let result = calc.calculate_item_nutrition(&item);

        assert!(result.success);
        assert!((result.amount_grams - 200.0).abs() < 1e-10);
        assert!((result.nutrition.calories - 330.0).abs() < 1e-10); // 165 * 2
    }

    #[test]
    fn test_calculate_item_nutrition_unknown() {
        let calc = ShoppingNutritionCalculator::with_defaults();
        let item = ShoppingItem::new("Unknown Food", 100.0, "g");
        let result = calc.calculate_item_nutrition(&item);

        assert!(!result.success);
    }

    #[test]
    fn test_calculate_list_nutrition() {
        let mut calc = ShoppingNutritionCalculator::new(ShoppingConfig::quick());
        calc.add_nutrition("chicken", sample_nutrition());
        calc.add_nutrition("rice", NutritionData {
            calories: 130.0,
            protein: 2.7,
            carbohydrate: 28.0,
            fat: 0.3,
            ..NutritionData::zero()
        });

        let items = vec![
            ShoppingItem::new("Chicken", 200.0, "g"),
            ShoppingItem::new("Rice", 100.0, "g"),
        ];

        let result = calc.calculate_list_nutrition(&items);
        assert!(result.is_ok());

        let nutrition = result.expect("Should succeed");
        assert_eq!(nutrition.items.len(), 2);
        assert_eq!(nutrition.aggregated.items_with_nutrition, 2);
        // 165 * 2 + 130 = 460
        assert!((nutrition.aggregated.total.calories - 460.0).abs() < 1e-10);
    }

    #[test]
    fn test_calculate_list_with_categories() {
        let mut calc = ShoppingNutritionCalculator::new(ShoppingConfig::default());
        calc.add_nutrition("chicken", sample_nutrition());
        calc.add_nutrition("rice", NutritionData {
            calories: 130.0,
            protein: 2.7,
            carbohydrate: 28.0,
            fat: 0.3,
            ..NutritionData::zero()
        });

        let items = vec![
            ShoppingItem::new("Chicken", 100.0, "g").with_category("Meat"),
            ShoppingItem::new("Rice", 100.0, "g").with_category("Grains"),
        ];

        let result = calc.calculate_list_nutrition(&items).expect("Should succeed");
        assert!(result.by_category.is_some());

        let categories = result.by_category.expect("Should have categories");
        assert_eq!(categories.len(), 2);
    }

    #[test]
    fn test_merge_duplicates() {
        let calc = ShoppingNutritionCalculator::with_defaults();

        let items = vec![
            ShoppingItem::new("Chicken", 200.0, "g"),
            ShoppingItem::new("Chicken", 300.0, "g"),
            ShoppingItem::new("Rice", 100.0, "g"),
        ];

        let merged = calc.merge_duplicates(items);
        assert_eq!(merged.len(), 2);

        let chicken = merged.iter().find(|i| i.name == "Chicken");
        assert!(chicken.is_some());
        assert!((chicken.expect("Should exist").amount - 500.0).abs() < 1e-10);
    }

    #[test]
    fn test_filter_by_category() {
        let calc = ShoppingNutritionCalculator::with_defaults();

        let items = vec![
            ShoppingItem::new("Chicken", 100.0, "g").with_category("Meat"),
            ShoppingItem::new("Beef", 200.0, "g").with_category("Meat"),
            ShoppingItem::new("Rice", 100.0, "g").with_category("Grains"),
        ];

        let meat = calc.filter_by_category(&items, "Meat");
        assert_eq!(meat.len(), 2);
    }

    #[test]
    fn test_unchecked_items() {
        let calc = ShoppingNutritionCalculator::with_defaults();

        let items = vec![
            ShoppingItem {
                id: None,
                name: "Chicken".to_string(),
                amount: 100.0,
                unit: "g".to_string(),
                category: None,
                checked: true,
                recipe_ids: vec![],
                price: None,
                fatsecret_food_id: None,
            },
            ShoppingItem::new("Rice", 100.0, "g"),
        ];

        let unchecked = calc.unchecked_items(&items);
        assert_eq!(unchecked.len(), 1);
        assert_eq!(unchecked[0].name, "Rice");
    }

    #[test]
    fn test_cost_by_category() {
        let calc = ShoppingNutritionCalculator::with_defaults();

        let items = vec![
            ShoppingItem::new("Chicken", 100.0, "g")
                .with_category("Meat")
                .with_price(5.0),
            ShoppingItem::new("Beef", 200.0, "g")
                .with_category("Meat")
                .with_price(8.0),
            ShoppingItem::new("Rice", 100.0, "g")
                .with_category("Grains")
                .with_price(2.0),
        ];

        let costs = calc.cost_by_category(&items);
        assert_eq!(costs.get("Meat"), Some(&13.0));
        assert_eq!(costs.get("Grains"), Some(&2.0));
    }

    #[test]
    fn test_shopping_list_builder() {
        let items = ShoppingListBuilder::new()
            .add("Chicken", 500.0, "g")
            .add_with_category("Rice", 1.0, "kg", "Grains")
            .add_with_price("Eggs", 12.0, "count", 4.50)
            .build();

        assert_eq!(items.len(), 3);
        assert_eq!(items[0].name, "Chicken");
        assert_eq!(items[1].category, Some("Grains".to_string()));
        assert_eq!(items[2].price, Some(4.50));
    }

    #[test]
    fn test_shopping_nutrition_failed_items() {
        let items = vec![
            ShoppingItemNutrition::success(
                ShoppingItem::new("Chicken", 100.0, "g"),
                sample_nutrition(),
                1,
                "Chicken".to_string(),
                1.0,
                100.0,
            ),
            ShoppingItemNutrition::failure(
                ShoppingItem::new("Unknown", 100.0, "g"),
                "Not found",
            ),
        ];

        let nutrition = ShoppingNutrition::new(items);
        let failed = nutrition.failed_items();

        assert_eq!(failed.len(), 1);
        assert_eq!(failed[0].item.name, "Unknown");
    }

    #[test]
    fn test_estimate_nutrition() {
        let calc = ShoppingNutritionCalculator::with_defaults();
        let item = ShoppingItem::new("Similar Food", 100.0, "g");

        let similar = vec![
            ("Food A", NutritionData {
                calories: 100.0,
                protein: 10.0,
                ..NutritionData::zero()
            }),
            ("Food B", NutritionData {
                calories: 200.0,
                protein: 20.0,
                ..NutritionData::zero()
            }),
        ];

        let result = calc.estimate_nutrition(&item, &similar);
        assert!(result.success);
        assert!((result.nutrition.calories - 150.0).abs() < 1e-10); // Average
        assert!((result.confidence - 0.5).abs() < 1e-10);
    }

    #[test]
    fn test_batch_size_validation() {
        let config = ShoppingConfig {
            max_batch_size: 2,
            ..ShoppingConfig::default()
        };
        let calc = ShoppingNutritionCalculator::new(config);

        let items = vec![
            ShoppingItem::new("A", 1.0, "g"),
            ShoppingItem::new("B", 1.0, "g"),
            ShoppingItem::new("C", 1.0, "g"),
        ];

        let result = calc.calculate_list_nutrition(&items);
        assert!(result.is_err());
    }
}
