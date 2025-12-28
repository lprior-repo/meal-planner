//! FatSecret Sync Automation - Diary to Meal Plan Matching
//!
//! Matches FatSecret diary entries to Tandoor meal plans based on:
//! - Nutrition profile similarity
//! - Name matching
//! - Meal type alignment

use serde::{Deserialize, Serialize};

/// Complete meal plan entry with all metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealPlan {
    /// Tandoor meal plan ID
    pub id: i32,
    /// Meal plan title (max 64 characters)
    pub title: String,
    /// Optional recipe reference (can be null if just a note/reminder)
    pub recipe: Option<RecipeOverview>,
    /// Number of servings for this meal
    pub servings: f64,
    /// Plain text note about the meal
    pub note: String,
    /// Markdown-formatted note (read-only, computed from note)
    pub note_markdown: String,
    /// Start date/time for the meal (ISO 8601 format)
    pub from_date: String,
    /// End date/time for the meal (ISO 8601 format)
    pub to_date: String,
    /// Meal type categorization (breakfast, lunch, dinner, etc)
    pub meal_type: MealType,
    /// User ID who created this meal plan
    pub created_by: i32,
    /// Users this meal plan is shared with
    pub shared: Option<Vec<User>>,
    /// Recipe name (read-only, denormalized for performance)
    pub recipe_name: String,
    /// Meal type name (read-only, denormalized for performance)
    pub meal_type_name: String,
    /// Whether this meal plan is on the shopping list
    pub shopping: bool,
}

/// Simplified recipe overview
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeOverview {
    /// Tandoor recipe ID
    pub id: i32,
    /// Recipe name
    pub name: String,
    /// Recipe description
    pub description: String,
    /// Recipe image URL
    pub image: Option<String>,
    /// Keywords associated with the recipe
    pub keywords: Vec<Keyword>,
    /// Recipe rating
    pub rating: Option<f64>,
    /// Last time the recipe was cooked
    pub last_cooked: Option<String>,
}

/// Keyword associated with a recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Keyword {
    /// Keyword ID
    pub id: i32,
    /// Keyword name
    pub name: String,
    /// Keyword description
    pub description: String,
}

/// Meal type categorization (breakfast, lunch, dinner, etc)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealType {
    /// Tandoor meal type ID
    pub id: i32,
    /// Meal type name (e.g., "Breakfast", "Lunch", "Dinner")
    pub name: String,
    /// Display order for sorting meal types
    pub order: i32,
    /// Optional time of day for this meal type (HH:MM format)
    pub time: Option<String>,
    /// Optional color hex code for UI display (e.g., "#FF5733")
    pub color: Option<String>,
    /// Whether this is the default meal type for the user
    pub default: bool,
    /// User ID who created this meal type
    pub created_by: i32,
}

/// Simplified user type for meal plan sharing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    /// Tandoor user ID
    pub id: i32,
    /// Username (required, 150 chars max, letters/digits/@/./+/-/_ only)
    pub username: String,
    /// User's first name
    pub first_name: String,
    /// User's last name
    pub last_name: String,
    /// Display name (computed from first/last name or username)
    pub display_name: String,
    /// Whether user has admin/staff permissions
    pub is_staff: bool,
    /// Whether user has superuser permissions
    pub is_superuser: bool,
    /// Whether user account is active
    pub is_active: bool,
}

/// FatSecret Food Diary Entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodEntry {
    /// FatSecret food entry ID
    pub id: String,
    /// Food name
    pub food_name: String,
    /// Food description
    pub food_description: String,
    /// Food brand name
    pub brand_name: Option<String>,
    /// Meal type for the entry
    pub meal_type: DiaryMealType,
    /// Date and time of the entry
    pub entry_date: String,
    /// Serving size
    pub serving: Option<Serving>,
    /// Nutritional information
    pub nutrition: Option<Nutrition>,
}

/// Diary meal type categorization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DiaryMealType {
    Breakfast,
    Lunch,
    Dinner,
    Snack,
    Other,
}

/// Serving size option for a food
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Serving {
    /// Serving ID
    pub id: String,
    /// Serving name
    pub serving_name: String,
    /// Number of grams in the serving
    pub grams: f64,
    /// Number of calories in the serving
    pub calories: f64,
    /// Carbohydrates in the serving
    pub carbohydrates: f64,
    /// Protein in the serving
    pub protein: f64,
    /// Fat in the serving
    pub fat: f64,
}

/// Nutrition information for a food serving
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Nutrition {
    /// Number of calories
    pub calories: f64,
    /// Carbohydrates in grams
    pub carbohydrates: f64,
    /// Protein in grams
    pub protein: f64,
    /// Fat in grams
    pub fat: f64,
    /// Fiber in grams
    pub fiber: f64,
    /// Sugar in grams
    pub sugar: f64,
    /// Sodium in milligrams
    pub sodium: f64,
}

/// Result of sync operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    /// Successfully matched entries
    pub matched: Vec<MatchedEntry>,
    /// Diary entries that couldn't be matched
    pub unmatched_diary: Vec<FoodEntry>,
    /// Meal plans that couldn't be matched
    pub unmatched_plan: Vec<MealPlan>,
}

/// Successfully matched entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchedEntry {
    /// Diary entry that was matched
    pub diary_entry: FoodEntry,
    /// Meal plan that was matched
    pub plan_entry: MealPlan,
    /// Confidence level of the match (0.0 to 1.0)
    pub confidence: f64,
}

/// Match criteria for matching diary entries to meal plans
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchCriteria {
    /// Tolerance for calorie differences (0.0 to 1.0)
    pub calorie_tolerance: f64,
    /// Tolerance for macro differences (0.0 to 1.0)
    pub macro_tolerance: f64,
    /// Minimum similarity threshold for name matching (0.0 to 1.0)
    pub name_similarity_threshold: f64,
}

impl MatchCriteria {
    /// Default match criteria
    pub fn default() -> Self {
        MatchCriteria {
            calorie_tolerance: 0.15,
            macro_tolerance: 0.2,
            name_similarity_threshold: 0.6,
        }
    }
}

/// Calculate match confidence between a diary entry and meal plan
pub fn calculate_match_confidence(
    _diary_entry: &FoodEntry,
    _meal_plan: &MealPlan,
    _criteria: &MatchCriteria,
) -> f64 {
    // Placeholder implementation - in a real implementation this would:
    // 1. Compare nutrition profiles
    // 2. Compare food names
    // 3. Compare meal types
    // 4. Return confidence score (0.0 to 1.0)
    
    0.0
}

/// Sync diary entries to meal plans
pub fn sync_diary_to_plan(
    diary_entries: Vec<FoodEntry>,
    meal_plans: Vec<MealPlan>,
    criteria: MatchCriteria,
) -> SyncResult {
    // Placeholder implementation - in a real implementation this would:
    // 1. Match diary entries to meal plans based on criteria
    // 2. Return matched entries and unmatched items
    
    SyncResult {
        matched: Vec::new(),
        unmatched_diary: diary_entries,
        unmatched_plan: meal_plans,
    }
}