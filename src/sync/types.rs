//! Core Type Definitions for Sync Layer
//!
//! This module contains all fundamental types used across the sync layer.
//! All types are designed to be:
//! - Immutable where possible
//! - Serializable for JSON I/O
//! - Clone-able for functional transformations
//! - Comparable for testing and caching

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::str::FromStr;

// =============================================================================
// NUTRITION TYPES
// =============================================================================

/// Comprehensive nutrition data for a food item
///
/// All values are per serving or per 100g depending on context.
/// Uses Option<f64> for fields that may not be available from all sources.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NutritionData {
    /// Energy in kilocalories
    pub calories: f64,
    /// Protein in grams
    pub protein: f64,
    /// Total fat in grams
    pub fat: f64,
    /// Total carbohydrates in grams
    pub carbohydrate: f64,
    /// Dietary fiber in grams (optional)
    pub fiber: Option<f64>,
    /// Sugars in grams (optional)
    pub sugar: Option<f64>,
    /// Saturated fat in grams (optional)
    pub saturated_fat: Option<f64>,
    /// Monounsaturated fat in grams (optional)
    pub monounsaturated_fat: Option<f64>,
    /// Polyunsaturated fat in grams (optional)
    pub polyunsaturated_fat: Option<f64>,
    /// Trans fat in grams (optional)
    pub trans_fat: Option<f64>,
    /// Cholesterol in milligrams (optional)
    pub cholesterol: Option<f64>,
    /// Sodium in milligrams (optional)
    pub sodium: Option<f64>,
    /// Potassium in milligrams (optional)
    pub potassium: Option<f64>,
    /// Calcium in milligrams (optional)
    pub calcium: Option<f64>,
    /// Iron in milligrams (optional)
    pub iron: Option<f64>,
    /// Vitamin A in IU (optional)
    pub vitamin_a: Option<f64>,
    /// Vitamin C in milligrams (optional)
    pub vitamin_c: Option<f64>,
}

impl NutritionData {
    /// Create nutrition data with only macronutrients
    #[must_use]
    pub fn macros_only(calories: f64, protein: f64, fat: f64, carbohydrate: f64) -> Self {
        Self {
            calories,
            protein,
            fat,
            carbohydrate,
            fiber: None,
            sugar: None,
            saturated_fat: None,
            monounsaturated_fat: None,
            polyunsaturated_fat: None,
            trans_fat: None,
            cholesterol: None,
            sodium: None,
            potassium: None,
            calcium: None,
            iron: None,
            vitamin_a: None,
            vitamin_c: None,
        }
    }

    /// Create empty nutrition data (all zeros)
    #[must_use]
    pub fn zero() -> Self {
        Self::macros_only(0.0, 0.0, 0.0, 0.0)
    }

    /// Scale nutrition by a multiplier
    #[must_use]
    pub fn scale(&self, multiplier: f64) -> Self {
        Self {
            calories: self.calories * multiplier,
            protein: self.protein * multiplier,
            fat: self.fat * multiplier,
            carbohydrate: self.carbohydrate * multiplier,
            fiber: self.fiber.map(|v| v * multiplier),
            sugar: self.sugar.map(|v| v * multiplier),
            saturated_fat: self.saturated_fat.map(|v| v * multiplier),
            monounsaturated_fat: self.monounsaturated_fat.map(|v| v * multiplier),
            polyunsaturated_fat: self.polyunsaturated_fat.map(|v| v * multiplier),
            trans_fat: self.trans_fat.map(|v| v * multiplier),
            cholesterol: self.cholesterol.map(|v| v * multiplier),
            sodium: self.sodium.map(|v| v * multiplier),
            potassium: self.potassium.map(|v| v * multiplier),
            calcium: self.calcium.map(|v| v * multiplier),
            iron: self.iron.map(|v| v * multiplier),
            vitamin_a: self.vitamin_a.map(|v| v * multiplier),
            vitamin_c: self.vitamin_c.map(|v| v * multiplier),
        }
    }

    /// Add nutrition data from another source
    #[must_use]
    pub fn add(&self, other: &Self) -> Self {
        Self {
            calories: self.calories + other.calories,
            protein: self.protein + other.protein,
            fat: self.fat + other.fat,
            carbohydrate: self.carbohydrate + other.carbohydrate,
            fiber: add_optional(self.fiber, other.fiber),
            sugar: add_optional(self.sugar, other.sugar),
            saturated_fat: add_optional(self.saturated_fat, other.saturated_fat),
            monounsaturated_fat: add_optional(self.monounsaturated_fat, other.monounsaturated_fat),
            polyunsaturated_fat: add_optional(self.polyunsaturated_fat, other.polyunsaturated_fat),
            trans_fat: add_optional(self.trans_fat, other.trans_fat),
            cholesterol: add_optional(self.cholesterol, other.cholesterol),
            sodium: add_optional(self.sodium, other.sodium),
            potassium: add_optional(self.potassium, other.potassium),
            calcium: add_optional(self.calcium, other.calcium),
            iron: add_optional(self.iron, other.iron),
            vitamin_a: add_optional(self.vitamin_a, other.vitamin_a),
            vitamin_c: add_optional(self.vitamin_c, other.vitamin_c),
        }
    }

    /// Calculate macronutrient ratio (protein:fat:carb)
    #[must_use]
    pub fn macro_ratio(&self) -> MacroRatio {
        let total = self.protein + self.fat + self.carbohydrate;
        if total <= 0.0 {
            return MacroRatio::balanced();
        }

        MacroRatio {
            protein_percent: (self.protein / total) * 100.0,
            fat_percent: (self.fat / total) * 100.0,
            carb_percent: (self.carbohydrate / total) * 100.0,
        }
    }

    /// Check if nutrition data is valid (no negative values)
    #[must_use]
    pub fn is_valid(&self) -> bool {
        self.calories >= 0.0
            && self.protein >= 0.0
            && self.fat >= 0.0
            && self.carbohydrate >= 0.0
    }

    /// Calculate caloric contribution from macros
    #[must_use]
    pub fn calculated_calories(&self) -> f64 {
        self.fat.mul_add(9.0, self.protein.mul_add(4.0, self.carbohydrate * 4.0))
    }

    /// Alias for carbohydrate field (compatibility)
    #[must_use]
    pub fn carbohydrates(&self) -> f64 {
        self.carbohydrate
    }

    /// Calculate data completeness (0.0 to 1.0)
    ///
    /// Returns the ratio of non-null optional fields to total optional fields.
    /// Core macros (calories, protein, fat, carbs) always count as present.
    #[must_use]
    pub fn completeness(&self) -> f64 {
        let optional_fields = [
            self.fiber,
            self.sugar,
            self.saturated_fat,
            self.monounsaturated_fat,
            self.polyunsaturated_fat,
            self.trans_fat,
            self.cholesterol,
            self.sodium,
            self.potassium,
            self.calcium,
            self.iron,
            self.vitamin_a,
            self.vitamin_c,
        ];

        let present: usize = optional_fields.iter().filter(|f| f.is_some()).count();
        let _total = optional_fields.len();

        // Core macros are 4 fields always present, optionals are 13
        // Return weighted completeness: 4 core + present optional out of 17 total
        #[allow(clippy::cast_precision_loss)]
        {
            (4.0 + present as f64) / 17.0
        }
    }
}

impl Default for NutritionData {
    fn default() -> Self {
        Self::zero()
    }
}

/// Helper to add two optional values
fn add_optional(a: Option<f64>, b: Option<f64>) -> Option<f64> {
    match (a, b) {
        (Some(x), Some(y)) => Some(x + y),
        (Some(x), None) => Some(x),
        (None, Some(y)) => Some(y),
        (None, None) => None,
    }
}

/// Macronutrient ratio as percentages
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MacroRatio {
    /// Protein percentage (0-100)
    pub protein_percent: f64,
    /// Fat percentage (0-100)
    pub fat_percent: f64,
    /// Carbohydrate percentage (0-100)
    pub carb_percent: f64,
}

impl MacroRatio {
    /// Create a balanced macro ratio (33/33/33)
    #[must_use]
    pub fn balanced() -> Self {
        Self {
            protein_percent: 33.33,
            fat_percent: 33.33,
            carb_percent: 33.34,
        }
    }

    /// Create a keto macro ratio (high fat, low carb)
    #[must_use]
    pub fn keto() -> Self {
        Self {
            protein_percent: 20.0,
            fat_percent: 75.0,
            carb_percent: 5.0,
        }
    }

    /// Create a high protein macro ratio
    #[must_use]
    pub fn high_protein() -> Self {
        Self {
            protein_percent: 40.0,
            fat_percent: 30.0,
            carb_percent: 30.0,
        }
    }

    /// Check if ratios sum to approximately 100%
    #[must_use]
    pub fn is_valid(&self) -> bool {
        let sum = self.protein_percent + self.fat_percent + self.carb_percent;
        (99.0..=101.0).contains(&sum)
    }
}

impl Default for MacroRatio {
    fn default() -> Self {
        Self::balanced()
    }
}

// =============================================================================
// FOOD ITEM TYPES
// =============================================================================

/// A food item from FatSecret
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FatSecretFood {
    /// FatSecret food ID
    pub food_id: String,
    /// Food name
    pub name: String,
    /// Brand name (if applicable)
    pub brand: Option<String>,
    /// Food type (generic, brand, restaurant)
    pub food_type: FoodType,
    /// Available servings
    pub servings: Vec<ServingInfo>,
    /// Nutrition per default serving
    pub nutrition: NutritionData,
    /// Food description
    pub description: Option<String>,
}

impl FatSecretFood {
    /// Get nutrition for a specific serving size
    #[must_use]
    pub fn nutrition_for_serving(&self, serving_id: &str) -> Option<NutritionData> {
        self.servings
            .iter()
            .find(|s| s.serving_id == serving_id)
            .map(|s| self.nutrition.scale(s.multiplier))
    }

    /// Get the default serving
    #[must_use]
    pub fn default_serving(&self) -> Option<&ServingInfo> {
        self.servings.iter().find(|s| s.is_default)
            .or_else(|| self.servings.first())
    }

    /// Get gram-based serving if available
    #[must_use]
    pub fn gram_serving(&self) -> Option<&ServingInfo> {
        self.servings.iter().find(|s| {
            s.unit.to_lowercase() == "g" || s.unit.to_lowercase() == "gram"
        })
    }
}

/// Food type classification
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum FoodType {
    /// Generic/unbranded food
    #[default]
    Generic,
    /// Branded food product
    Brand,
    /// Restaurant menu item
    Restaurant,
}

/// Serving size information
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ServingInfo {
    /// Serving ID
    pub serving_id: String,
    /// Serving description (e.g., "1 cup")
    pub description: String,
    /// Unit name (e.g., "cup", "g")
    pub unit: String,
    /// Amount in this serving
    pub amount: f64,
    /// Weight in grams (if known)
    pub grams: Option<f64>,
    /// Multiplier to apply to base nutrition
    pub multiplier: f64,
    /// Whether this is the default serving
    pub is_default: bool,
}

impl ServingInfo {
    /// Create a gram-based serving
    #[must_use]
    #[allow(clippy::cast_possible_truncation)]
    pub fn grams(amount: f64) -> Self {
        Self {
            serving_id: format!("g_{}", amount.round() as i64),
            description: format!("{} g", amount),
            unit: "g".to_string(),
            amount,
            grams: Some(amount),
            multiplier: amount / 100.0,
            is_default: false,
        }
    }

    /// Create a default serving
    #[must_use]
    pub fn default_serving(description: &str, grams: f64) -> Self {
        Self {
            serving_id: "default".to_string(),
            description: description.to_string(),
            unit: "serving".to_string(),
            amount: 1.0,
            grams: Some(grams),
            multiplier: 1.0,
            is_default: true,
        }
    }
}

// =============================================================================
// TANDOOR RECIPE TYPES
// =============================================================================

/// A recipe from Tandoor
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TandoorRecipe {
    /// Tandoor recipe ID
    pub id: i64,
    /// Recipe name
    pub name: String,
    /// Recipe description
    pub description: Option<String>,
    /// Number of servings
    pub servings: i32,
    /// Active cooking time in minutes
    pub working_time: Option<i32>,
    /// Passive time (marinating, resting) in minutes
    pub waiting_time: Option<i32>,
    /// Recipe ingredients
    pub ingredients: Vec<TandoorIngredient>,
    /// Recipe steps
    pub steps: Vec<TandoorStep>,
    /// Recipe keywords/tags
    pub keywords: Vec<String>,
    /// Recipe nutrition (if calculated)
    pub nutrition: Option<NutritionData>,
    /// Source URL
    pub source_url: Option<String>,
    /// Image URL
    pub image_url: Option<String>,
}

impl TandoorRecipe {
    /// Calculate total cooking time
    #[must_use]
    pub fn total_time(&self) -> Option<i32> {
        match (self.working_time, self.waiting_time) {
            (Some(w), Some(wt)) => Some(w + wt),
            (Some(w), None) => Some(w),
            (None, Some(wt)) => Some(wt),
            (None, None) => None,
        }
    }

    /// Get nutrition per serving
    #[must_use]
    pub fn nutrition_per_serving(&self) -> Option<NutritionData> {
        self.nutrition.as_ref().map(|n| {
            let divisor = if self.servings > 0 {
                f64::from(self.servings)
            } else {
                1.0
            };
            n.scale(1.0 / divisor)
        })
    }

    /// Get unique ingredient names
    #[must_use]
    pub fn unique_ingredients(&self) -> Vec<String> {
        let mut names: Vec<String> = self.ingredients
            .iter()
            .map(|i| i.food_name.to_lowercase())
            .collect();
        names.sort();
        names.dedup();
        names
    }
}

/// An ingredient in a Tandoor recipe
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TandoorIngredient {
    /// Ingredient ID
    pub id: Option<i64>,
    /// Food name
    pub food_name: String,
    /// Unit name
    pub unit: Option<String>,
    /// Amount
    pub amount: Option<f64>,
    /// Note
    pub note: Option<String>,
    /// Nutrition data (if known)
    pub nutrition: Option<NutritionData>,
}

impl TandoorIngredient {
    /// Create a new ingredient
    #[must_use]
    pub fn new(food_name: &str, amount: Option<f64>, unit: Option<&str>) -> Self {
        Self {
            id: None,
            food_name: food_name.to_string(),
            unit: unit.map(str::to_string),
            amount,
            note: None,
            nutrition: None,
        }
    }

    /// Get ingredient amount in grams (estimated)
    #[must_use]
    pub fn estimated_grams(&self) -> Option<f64> {
        let amount = self.amount?;
        let unit = self.unit.as_deref().unwrap_or("g");
        Some(crate::sync::units::convert_to_grams(amount, unit))
    }
}

/// A step in a Tandoor recipe
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TandoorStep {
    /// Step ID
    pub id: Option<i64>,
    /// Step order
    pub order: i32,
    /// Step instruction
    pub instruction: String,
    /// Ingredients used in this step
    pub ingredient_ids: Vec<i64>,
    /// Time for this step in minutes
    pub time: Option<i32>,
}

// =============================================================================
// MEAL PLAN TYPES
// =============================================================================

/// A meal plan entry
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MealPlanEntry {
    /// Entry ID
    pub id: i64,
    /// Date (YYYY-MM-DD)
    pub date: String,
    /// Meal type
    pub meal_type: MealTypeId,
    /// Recipe ID
    pub recipe_id: i64,
    /// Recipe name
    pub recipe_name: String,
    /// Number of servings
    pub servings: f64,
    /// Nutrition for this entry
    pub nutrition: Option<NutritionData>,
    /// Note
    pub note: Option<String>,
}

impl MealPlanEntry {
    /// Calculate nutrition for the specified servings
    #[must_use]
    pub fn calculate_nutrition(&self, recipe_nutrition: &NutritionData, recipe_servings: i32) -> NutritionData {
        let per_serving = recipe_nutrition.scale(1.0 / f64::from(recipe_servings));
        per_serving.scale(self.servings)
    }
}

/// Meal type identifier
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MealTypeId {
    /// Meal type ID
    pub id: i64,
    /// Meal type name
    pub name: String,
}

impl MealTypeId {
    /// Create a breakfast meal type
    #[must_use]
    pub fn breakfast() -> Self {
        Self { id: 1, name: "Breakfast".to_string() }
    }

    /// Create a lunch meal type
    #[must_use]
    pub fn lunch() -> Self {
        Self { id: 2, name: "Lunch".to_string() }
    }

    /// Create a dinner meal type
    #[must_use]
    pub fn dinner() -> Self {
        Self { id: 3, name: "Dinner".to_string() }
    }

    /// Create a snack meal type
    #[must_use]
    pub fn snack() -> Self {
        Self { id: 4, name: "Snack".to_string() }
    }
}

// =============================================================================
// DIARY ENTRY TYPES
// =============================================================================

/// A food diary entry for syncing
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DiaryEntry {
    /// Entry ID (from FatSecret if synced)
    pub entry_id: Option<String>,
    /// Date (YYYY-MM-DD)
    pub date: String,
    /// Meal type
    pub meal: MealCategory,
    /// Food name
    pub food_name: String,
    /// Serving description
    pub serving_description: String,
    /// Number of servings
    pub servings: f64,
    /// Nutrition data
    pub nutrition: NutritionData,
    /// Source (tandoor recipe ID, fatsecret food ID, etc.)
    pub source: DiaryEntrySource,
}

/// Source of a diary entry
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum DiaryEntrySource {
    /// Entry came from a Tandoor recipe
    TandoorRecipe { recipe_id: i64 },
    /// Entry came from a FatSecret food
    FatSecretFood { food_id: String },
    /// Entry was manually created
    Manual,
    /// Entry came from a saved meal
    SavedMeal { meal_id: String },
}

/// Meal category for diary entries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
pub enum MealCategory {
    Breakfast,
    Lunch,
    Dinner,
    #[default]
    Other,
}

impl MealCategory {
    /// Convert to FatSecret API string
    #[must_use]
    pub fn to_api_string(self) -> &'static str {
        match self {
            Self::Breakfast => "breakfast",
            Self::Lunch => "lunch",
            Self::Dinner => "dinner",
            Self::Other => "other",
        }
    }
}

impl FromStr for MealCategory {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "breakfast" => Ok(Self::Breakfast),
            "lunch" => Ok(Self::Lunch),
            "dinner" => Ok(Self::Dinner),
            "other" | "snack" => Ok(Self::Other),
            _ => Err(format!("Unknown meal category: {s}")),
        }
    }
}

// =============================================================================
// DATE AND TIME TYPES
// =============================================================================

/// A date in YYYY-MM-DD format
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct DateString(String);

impl DateString {
    /// Create a new date string
    pub fn new(date: &str) -> Result<Self, String> {
        if is_valid_date_format(date) {
            Ok(Self(date.to_string()))
        } else {
            Err(format!("Invalid date format: {date}. Expected YYYY-MM-DD"))
        }
    }

    /// Get the date as a string reference
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Get the year
    #[must_use]
    pub fn year(&self) -> Option<i32> {
        self.0.get(0..4)?.parse().ok()
    }

    /// Get the month (1-12)
    #[must_use]
    pub fn month(&self) -> Option<u32> {
        self.0.get(5..7)?.parse().ok()
    }

    /// Get the day (1-31)
    #[must_use]
    pub fn day(&self) -> Option<u32> {
        self.0.get(8..10)?.parse().ok()
    }

    /// Convert to FatSecret date_int format (days since 1970-01-01)
    #[must_use]
    pub fn to_date_int(&self) -> Option<i32> {
        let year = self.year()?;
        let month = self.month()?;
        let day = self.day()?;
        Some(calculate_date_int(year, month, day))
    }
}

impl std::fmt::Display for DateString {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Validate date format
fn is_valid_date_format(date: &str) -> bool {
    if date.len() != 10 {
        return false;
    }
    let chars: Vec<char> = date.chars().collect();
    chars.get(4) == Some(&'-') && chars.get(7) == Some(&'-')
}

/// Calculate FatSecret date_int from year/month/day
#[allow(clippy::integer_division)] // Intentional: calculating leap years since 1970
fn calculate_date_int(year: i32, month: u32, day: u32) -> i32 {
    // Simplified calculation (actual implementation would use chrono)
    let days_from_year = (year - 1970) * 365 + (year - 1969) / 4;
    let days_from_month = match month {
        2 => 31,
        3 => 59,
        4 => 90,
        5 => 120,
        6 => 151,
        7 => 181,
        8 => 212,
        9 => 243,
        10 => 273,
        11 => 304,
        12 => 334,
        _ => 0, // January and invalid months
    };
    #[allow(clippy::cast_possible_wrap)]
    let result = days_from_year + days_from_month + day as i32;
    result
}

/// A date range
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DateRange {
    /// Start date (inclusive)
    pub start: DateString,
    /// End date (inclusive)
    pub end: DateString,
}

impl DateRange {
    /// Create a new date range
    pub fn new(start: DateString, end: DateString) -> Result<Self, String> {
        if start.as_str() > end.as_str() {
            return Err("Start date must be before or equal to end date".to_string());
        }
        Ok(Self { start, end })
    }

    /// Get the number of days in the range
    #[must_use]
    pub fn days(&self) -> i32 {
        let start_int = self.start.to_date_int().unwrap_or(0);
        let end_int = self.end.to_date_int().unwrap_or(0);
        end_int - start_int + 1
    }
}

// =============================================================================
// SYNC STATUS TYPES
// =============================================================================

/// Status of a sync operation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum SyncStatus {
    /// Sync completed successfully
    Success,
    /// Sync completed with partial failures
    PartialSuccess,
    /// Sync failed completely
    Failed,
    /// Sync is in progress
    #[default]
    InProgress,
    /// Sync was cancelled
    Cancelled,
}

/// Summary of a sync operation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncSummary {
    /// Status of the sync
    pub status: SyncStatus,
    /// Number of items processed
    pub processed: usize,
    /// Number of items successfully synced
    pub succeeded: usize,
    /// Number of items that failed
    pub failed: usize,
    /// Number of items skipped
    pub skipped: usize,
    /// Duration in milliseconds
    pub duration_ms: u64,
    /// Error messages for failed items
    pub errors: Vec<String>,
}

impl SyncSummary {
    /// Create a successful summary
    #[must_use]
    pub fn success(processed: usize, duration_ms: u64) -> Self {
        Self {
            status: SyncStatus::Success,
            processed,
            succeeded: processed,
            failed: 0,
            skipped: 0,
            duration_ms,
            errors: Vec::new(),
        }
    }

    /// Create a failed summary
    #[must_use]
    pub fn failed(error: String, duration_ms: u64) -> Self {
        Self {
            status: SyncStatus::Failed,
            processed: 0,
            succeeded: 0,
            failed: 1,
            skipped: 0,
            duration_ms,
            errors: vec![error],
        }
    }

    /// Calculate success rate as percentage
    #[must_use]
    #[allow(clippy::cast_precision_loss)] // Acceptable: calculating percentage for display
    pub fn success_rate(&self) -> f64 {
        if self.processed == 0 {
            return 0.0;
        }
        (self.succeeded as f64 / self.processed as f64) * 100.0
    }
}

impl Default for SyncSummary {
    fn default() -> Self {
        Self {
            status: SyncStatus::InProgress,
            processed: 0,
            succeeded: 0,
            failed: 0,
            skipped: 0,
            duration_ms: 0,
            errors: Vec::new(),
        }
    }
}

// =============================================================================
// IDENTIFIER TYPES (Type-safe IDs)
// =============================================================================

/// FatSecret food ID (newtype wrapper)
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct FatSecretFoodId(String);

impl FatSecretFoodId {
    /// Create a new food ID
    #[must_use]
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Get the ID as a string reference
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Display for FatSecretFoodId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Tandoor recipe ID (newtype wrapper)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct TandoorRecipeId(i64);

impl TandoorRecipeId {
    /// Create a new recipe ID
    #[must_use]
    pub const fn new(id: i64) -> Self {
        Self(id)
    }

    /// Get the ID as i64
    #[must_use]
    pub const fn as_i64(&self) -> i64 {
        self.0
    }
}

impl std::fmt::Display for TandoorRecipeId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// FatSecret entry ID (newtype wrapper)
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct FatSecretEntryId(String);

impl FatSecretEntryId {
    /// Create a new entry ID
    #[must_use]
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Get the ID as a string reference
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Display for FatSecretEntryId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

// =============================================================================
// MAPPING TYPES
// =============================================================================

/// Mapping between Tandoor ingredient and FatSecret food
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct IngredientFoodMapping {
    /// Tandoor ingredient name (normalized)
    pub ingredient_name: String,
    /// Matched FatSecret food ID
    pub food_id: FatSecretFoodId,
    /// Match confidence (0.0 - 1.0)
    pub confidence: f64,
    /// Whether this mapping was manually verified
    pub verified: bool,
    /// Preferred serving for this mapping
    pub preferred_serving: Option<String>,
}

impl IngredientFoodMapping {
    /// Check if mapping is high confidence
    #[must_use]
    pub fn is_high_confidence(&self) -> bool {
        self.confidence >= 0.8 || self.verified
    }

    /// Check if mapping needs review
    #[must_use]
    pub fn needs_review(&self) -> bool {
        !self.verified && self.confidence < 0.6
    }
}

/// A collection of ingredient-to-food mappings
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct MappingDatabase {
    /// Mappings indexed by normalized ingredient name
    pub mappings: HashMap<String, IngredientFoodMapping>,
    /// Mapping version for cache invalidation
    pub version: u32,
}

impl MappingDatabase {
    /// Create a new empty database
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a mapping
    pub fn add(&mut self, mapping: IngredientFoodMapping) {
        self.mappings.insert(mapping.ingredient_name.clone(), mapping);
        self.version = self.version.wrapping_add(1);
    }

    /// Get a mapping by ingredient name
    #[must_use]
    pub fn get(&self, ingredient: &str) -> Option<&IngredientFoodMapping> {
        self.mappings.get(&ingredient.to_lowercase())
    }

    /// Get mappings that need review
    #[must_use]
    pub fn needs_review(&self) -> Vec<&IngredientFoodMapping> {
        self.mappings.values().filter(|m| m.needs_review()).collect()
    }

    /// Get all high confidence mappings
    #[must_use]
    pub fn high_confidence(&self) -> Vec<&IngredientFoodMapping> {
        self.mappings.values().filter(|m| m.is_high_confidence()).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nutrition_data_scale() {
        let nutrition = NutritionData::macros_only(100.0, 10.0, 5.0, 20.0);
        let scaled = nutrition.scale(2.0);

        assert!((scaled.calories - 200.0).abs() < 0.001);
        assert!((scaled.protein - 20.0).abs() < 0.001);
        assert!((scaled.fat - 10.0).abs() < 0.001);
        assert!((scaled.carbohydrate - 40.0).abs() < 0.001);
    }

    #[test]
    fn test_nutrition_data_add() {
        let a = NutritionData::macros_only(100.0, 10.0, 5.0, 20.0);
        let b = NutritionData::macros_only(50.0, 5.0, 2.5, 10.0);
        let sum = a.add(&b);

        assert!((sum.calories - 150.0).abs() < 0.001);
        assert!((sum.protein - 15.0).abs() < 0.001);
        assert!((sum.fat - 7.5).abs() < 0.001);
        assert!((sum.carbohydrate - 30.0).abs() < 0.001);
    }

    #[test]
    fn test_nutrition_data_macro_ratio() {
        let nutrition = NutritionData::macros_only(400.0, 40.0, 20.0, 40.0);
        let ratio = nutrition.macro_ratio();

        assert!((ratio.protein_percent - 40.0).abs() < 0.001);
        assert!((ratio.fat_percent - 20.0).abs() < 0.001);
        assert!((ratio.carb_percent - 40.0).abs() < 0.001);
    }

    #[test]
    fn test_date_string_parsing() {
        let date = DateString::new("2025-01-15").expect("Valid date");
        assert_eq!(date.year(), Some(2025));
        assert_eq!(date.month(), Some(1));
        assert_eq!(date.day(), Some(15));
    }

    #[test]
    fn test_date_string_invalid() {
        assert!(DateString::new("2025-1-15").is_err());
        assert!(DateString::new("not-a-date").is_err());
    }

    #[test]
    fn test_meal_category_from_str() {
        assert_eq!(MealCategory::from_str("breakfast"), Ok(MealCategory::Breakfast));
        assert_eq!(MealCategory::from_str("LUNCH"), Ok(MealCategory::Lunch));
        assert_eq!(MealCategory::from_str("Dinner"), Ok(MealCategory::Dinner));
        assert_eq!(MealCategory::from_str("snack"), Ok(MealCategory::Other));
        assert!(MealCategory::from_str("invalid").is_err());
    }

    #[test]
    fn test_sync_summary_success_rate() {
        let summary = SyncSummary {
            status: SyncStatus::PartialSuccess,
            processed: 10,
            succeeded: 8,
            failed: 2,
            skipped: 0,
            duration_ms: 1000,
            errors: vec!["error 1".to_string(), "error 2".to_string()],
        };

        assert!((summary.success_rate() - 80.0).abs() < 0.001);
    }

    #[test]
    fn test_mapping_database() {
        let mut db = MappingDatabase::new();

        let mapping = IngredientFoodMapping {
            ingredient_name: "chicken breast".to_string(),
            food_id: FatSecretFoodId::new("123456"),
            confidence: 0.95,
            verified: true,
            preferred_serving: Some("100g".to_string()),
        };

        db.add(mapping);

        assert!(db.get("chicken breast").is_some());
        assert!(db.get("CHICKEN BREAST").is_some());
        assert_eq!(db.high_confidence().len(), 1);
        assert!(db.needs_review().is_empty());
    }

    #[test]
    fn test_tandoor_recipe_unique_ingredients() {
        let recipe = TandoorRecipe {
            id: 1,
            name: "Test Recipe".to_string(),
            description: None,
            servings: 4,
            working_time: Some(30),
            waiting_time: None,
            ingredients: vec![
                TandoorIngredient::new("Chicken", Some(200.0), Some("g")),
                TandoorIngredient::new("chicken", Some(100.0), Some("g")),
                TandoorIngredient::new("Onion", Some(1.0), None),
            ],
            steps: Vec::new(),
            keywords: Vec::new(),
            nutrition: None,
            source_url: None,
            image_url: None,
        };

        let unique = recipe.unique_ingredients();
        assert_eq!(unique.len(), 2);
        assert!(unique.contains(&"chicken".to_string()));
        assert!(unique.contains(&"onion".to_string()));
    }
}
