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

impl Default for MatchCriteria {
    fn default() -> Self {
        MatchCriteria {
            calorie_tolerance: 0.15,
            macro_tolerance: 0.2,
            name_similarity_threshold: 0.6,
        }
    }
}

impl MatchCriteria {
    /// Create match criteria with default values
    pub fn new_default() -> Self {
        Self::default()
    }
}

/// Calculate normalized calorie similarity score (0.0 to 1.0)
/// Returns 1.0 for perfect match, 0.0 if difference exceeds tolerance
fn calculate_nutrition_similarity(
    diary_nutrition: &Nutrition,
    plan_nutrition: &Nutrition,
    calorie_tolerance: f64,
) -> f64 {
    if diary_nutrition.calories == 0.0 || plan_nutrition.calories == 0.0 {
        return 0.5; // Unknown nutrition, neutral score
    }

    let calorie_diff = (diary_nutrition.calories - plan_nutrition.calories).abs();
    let calorie_percent_diff = calorie_diff / plan_nutrition.calories.max(diary_nutrition.calories);

    if calorie_percent_diff > calorie_tolerance {
        return 0.0;
    }

    // Score from 1.0 (perfect match) to 0.0 (at tolerance limit)
    1.0 - (calorie_percent_diff / calorie_tolerance)
}

/// Calculate normalized macro similarity score (0.0 to 1.0)
/// Considers carbs, protein, and fat differences
#[allow(dead_code)]
fn calculate_macro_similarity(
    diary_nutrition: &Nutrition,
    plan_nutrition: &Nutrition,
    macro_tolerance: f64,
) -> f64 {
    let total_diary = diary_nutrition.carbohydrates
        + diary_nutrition.protein
        + diary_nutrition.fat;
    let total_plan = plan_nutrition.carbohydrates
        + plan_nutrition.protein
        + plan_nutrition.fat;

    if total_diary == 0.0 || total_plan == 0.0 {
        return 0.5; // Unknown macros, neutral score
    }

    let macro_diff = (total_diary - total_plan).abs();
    let macro_percent_diff = macro_diff / total_plan.max(total_diary);

    if macro_percent_diff > macro_tolerance {
        return 0.0;
    }

    1.0 - (macro_percent_diff / macro_tolerance)
}

/// Calculate string similarity using simple normalized edit distance
/// Returns score from 0.0 to 1.0
fn calculate_string_similarity(s1: &str, s2: &str) -> f64 {
    let s1 = s1.to_lowercase();
    let s2 = s2.to_lowercase();

    if s1 == s2 {
        return 1.0;
    }

    if s1.is_empty() || s2.is_empty() {
        return 0.0;
    }

    // Simple substring matching heuristic
    if s1.contains(&s2) || s2.contains(&s1) {
        return 0.9;
    }

    // Count common words
    let words1: std::collections::HashSet<&str> = s1.split_whitespace().collect();
    let words2: std::collections::HashSet<&str> = s2.split_whitespace().collect();
    let common = words1.intersection(&words2).count();
    let total = words1.union(&words2).count();

    if total == 0 {
        return 0.0;
    }

    common as f64 / total as f64
}

/// Calculate meal type match (1.0 if match, 0.0 if mismatch, 0.5 if unknown)
fn calculate_meal_type_match(diary_type: &DiaryMealType, plan_type_name: &str) -> f64 {
    let plan_type_lower = plan_type_name.to_lowercase();
    let diary_type_str = match diary_type {
        DiaryMealType::Breakfast => "breakfast",
        DiaryMealType::Lunch => "lunch",
        DiaryMealType::Dinner => "dinner",
        DiaryMealType::Snack => "snack",
        DiaryMealType::Other => "other",
    };

    if plan_type_lower.contains(diary_type_str) || diary_type_str.contains(&plan_type_lower) {
        1.0
    } else if plan_type_lower.contains("other") || diary_type_str == "other" {
        0.5
    } else {
        0.0
    }
}

/// Calculate match confidence between a diary entry and meal plan
pub fn calculate_match_confidence(
    diary_entry: &FoodEntry,
    meal_plan: &MealPlan,
    criteria: &MatchCriteria,
) -> f64 {
    // Meal type match is a hard requirement - if it's 0.0, confidence is 0.0
    let meal_type_score = calculate_meal_type_match(&diary_entry.meal_type, &meal_plan.meal_type_name);
    if meal_type_score == 0.0 {
        return 0.0;
    }

    // Calculate name similarity based on food name and plan title
    let name_score = calculate_string_similarity(&diary_entry.food_name, &meal_plan.title)
        .max(calculate_string_similarity(
            &diary_entry.food_name,
            &meal_plan.recipe_name,
        ));

    // If name similarity is below threshold, confidence is very low
    if name_score < criteria.name_similarity_threshold {
        return name_score * 0.3; // Low confidence if names don't match
    }

    // Calculate nutrition similarity if available
    let nutrition_score = if let (Some(_diary_nutrition), Some(_)) =
        (&diary_entry.nutrition, &meal_plan.recipe)
    {
        // Estimate plan nutrition from recipe if available
        // For now, use a neutral score if we can't calculate
        0.7
    } else if let Some(diary_nutrition) = &diary_entry.nutrition {
        // Use neutral score if we lack plan nutrition info
        if diary_nutrition.calories > 0.0 {
            0.6 // Partial confidence with nutrition data
        } else {
            0.5
        }
    } else {
        0.5 // Neutral if no nutrition data
    };

    // Combine scores: name (40%), nutrition (40%), meal type (20%)
    let combined = (name_score * 0.4) + (nutrition_score * 0.4) + (meal_type_score * 0.2);

    // Clamp to [0.0, 1.0]
    combined.max(0.0).min(1.0)
}

/// Sync diary entries to meal plans
pub fn sync_diary_to_plan(
    diary_entries: Vec<FoodEntry>,
    meal_plans: Vec<MealPlan>,
    criteria: MatchCriteria,
) -> SyncResult {
    let mut matched = Vec::new();
    let mut unmatched_diary = Vec::new();
    let mut unmatched_plan = meal_plans.clone();

    // For each diary entry, find the best matching meal plan
    'diary_loop: for diary_entry in diary_entries {
        let mut best_match: Option<(usize, f64)> = None;

        for (idx, plan) in unmatched_plan.iter().enumerate() {
            let confidence = calculate_match_confidence(&diary_entry, plan, &criteria);

            // Only consider matches above the name similarity threshold
            if confidence >= criteria.name_similarity_threshold {
                match best_match {
                    None => best_match = Some((idx, confidence)),
                    Some((_, best_confidence)) if confidence > best_confidence => {
                        best_match = Some((idx, confidence));
                    }
                    _ => {}
                }
            }
        }

        if let Some((idx, confidence)) = best_match {
            let matched_plan = unmatched_plan.remove(idx);
            matched.push(MatchedEntry {
                diary_entry: diary_entry.clone(),
                plan_entry: matched_plan,
                confidence,
            });
            continue 'diary_loop;
        }

        unmatched_diary.push(diary_entry);
    }

    SyncResult {
        matched,
        unmatched_diary,
        unmatched_plan,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_nutrition(calories: f64, carbs: f64, protein: f64, fat: f64) -> Nutrition {
        Nutrition {
            calories,
            carbohydrates: carbs,
            protein,
            fat,
            fiber: 0.0,
            sugar: 0.0,
            sodium: 0.0,
        }
    }

    fn create_test_food_entry(
        name: &str,
        meal_type: DiaryMealType,
        calories: f64,
    ) -> FoodEntry {
        FoodEntry {
            id: uuid::Uuid::new_v4().to_string(),
            food_name: name.to_string(),
            food_description: format!("{} description", name),
            brand_name: None,
            meal_type,
            entry_date: "2025-12-28T12:00:00Z".to_string(),
            serving: None,
            nutrition: Some(create_test_nutrition(calories, 50.0, 30.0, 20.0)),
        }
    }

    fn create_test_meal_plan(title: &str, meal_type: &str, id: i32) -> MealPlan {
        MealPlan {
            id,
            title: title.to_string(),
            recipe: None,
            servings: 1.0,
            note: String::new(),
            note_markdown: String::new(),
            from_date: "2025-12-28T12:00:00Z".to_string(),
            to_date: "2025-12-28T13:00:00Z".to_string(),
            meal_type: MealType {
                id: 1,
                name: meal_type.to_string(),
                order: 1,
                time: None,
                color: None,
                default: false,
                created_by: 1,
            },
            created_by: 1,
            shared: None,
            recipe_name: title.to_string(),
            meal_type_name: meal_type.to_string(),
            shopping: false,
        }
    }

    #[test]
    fn test_string_similarity_exact_match() {
        assert_eq!(calculate_string_similarity("chicken", "chicken"), 1.0);
        assert_eq!(calculate_string_similarity("Chicken", "chicken"), 1.0);
    }

    #[test]
    fn test_string_similarity_substring() {
        assert_eq!(calculate_string_similarity("chicken breast", "chicken"), 0.9);
        assert_eq!(calculate_string_similarity("chicken", "chicken breast"), 0.9);
    }

    #[test]
    fn test_string_similarity_partial_match() {
        let score = calculate_string_similarity("grilled chicken", "chicken salad");
        assert!(score > 0.3 && score < 0.7);
    }

    #[test]
    fn test_string_similarity_no_match() {
        assert_eq!(calculate_string_similarity("chicken", "beef"), 0.0);
    }

    #[test]
    fn test_meal_type_match_breakfast() {
        assert_eq!(calculate_meal_type_match(&DiaryMealType::Breakfast, "Breakfast"), 1.0);
        assert_eq!(calculate_meal_type_match(&DiaryMealType::Breakfast, "breakfast"), 1.0);
    }

    #[test]
    fn test_meal_type_match_mismatch() {
        assert_eq!(calculate_meal_type_match(&DiaryMealType::Breakfast, "Lunch"), 0.0);
    }

    #[test]
    fn test_meal_type_match_other() {
        let score = calculate_meal_type_match(&DiaryMealType::Breakfast, "Other");
        assert_eq!(score, 0.5);
    }

    #[test]
    fn test_calculate_match_confidence_perfect_match() {
        let diary = create_test_food_entry("Grilled Chicken", DiaryMealType::Lunch, 500.0);
        let plan = create_test_meal_plan("Grilled Chicken", "Lunch", 1);
        let criteria = MatchCriteria::new_default();

        let confidence = calculate_match_confidence(&diary, &plan, &criteria);
        assert!(confidence > 0.8, "Perfect match should have high confidence");
    }

    #[test]
    fn test_calculate_match_confidence_meal_type_mismatch() {
        let diary = create_test_food_entry("Chicken", DiaryMealType::Breakfast, 500.0);
        let plan = create_test_meal_plan("Chicken", "Lunch", 1);
        let criteria = MatchCriteria::new_default();

        let confidence = calculate_match_confidence(&diary, &plan, &criteria);
        assert_eq!(confidence, 0.0, "Meal type mismatch should result in 0 confidence");
    }

    #[test]
    fn test_calculate_match_confidence_name_mismatch() {
        let diary = create_test_food_entry("Beef Steak", DiaryMealType::Lunch, 500.0);
        let plan = create_test_meal_plan("Chicken Breast", "Lunch", 1);
        let criteria = MatchCriteria::new_default();

        let confidence = calculate_match_confidence(&diary, &plan, &criteria);
        assert!(confidence < 0.6, "Name mismatch should result in low confidence");
    }

    #[test]
    fn test_sync_diary_to_plan_single_match() {
        let diary_entries = vec![create_test_food_entry("Chicken", DiaryMealType::Lunch, 500.0)];
        let meal_plans = vec![create_test_meal_plan("Chicken", "Lunch", 1)];
        let criteria = MatchCriteria::new_default();

        let result = sync_diary_to_plan(diary_entries, meal_plans, criteria);

        assert_eq!(result.matched.len(), 1);
        assert_eq!(result.unmatched_diary.len(), 0);
        assert_eq!(result.unmatched_plan.len(), 0);
        assert!(result.matched[0].confidence > 0.7);
    }

    #[test]
    fn test_sync_diary_to_plan_no_match() {
        let diary_entries = vec![create_test_food_entry("Beef", DiaryMealType::Lunch, 500.0)];
        let meal_plans = vec![create_test_meal_plan("Chicken", "Lunch", 1)];
        let criteria = MatchCriteria::new_default();

        let result = sync_diary_to_plan(diary_entries.clone(), meal_plans.clone(), criteria);

        assert_eq!(result.matched.len(), 0);
        assert_eq!(result.unmatched_diary.len(), 1);
        assert_eq!(result.unmatched_plan.len(), 1);
    }

    #[test]
    fn test_sync_diary_to_plan_multiple_entries() {
        let diary_entries = vec![
            create_test_food_entry("Chicken", DiaryMealType::Lunch, 500.0),
            create_test_food_entry("Pasta", DiaryMealType::Dinner, 600.0),
        ];
        let meal_plans = vec![
            create_test_meal_plan("Chicken Breast", "Lunch", 1),
            create_test_meal_plan("Pasta Carbonara", "Dinner", 2),
        ];
        let criteria = MatchCriteria::new_default();

        let result = sync_diary_to_plan(diary_entries, meal_plans, criteria);

        assert_eq!(result.matched.len(), 2);
        assert_eq!(result.unmatched_diary.len(), 0);
        assert_eq!(result.unmatched_plan.len(), 0);
    }

    #[test]
    fn test_sync_diary_to_plan_best_match() {
        let diary_entries = vec![create_test_food_entry("Chicken", DiaryMealType::Lunch, 500.0)];
        let meal_plans = vec![
            create_test_meal_plan("Beef", "Lunch", 1),
            create_test_meal_plan("Chicken Salad", "Lunch", 2),
            create_test_meal_plan("Chicken Sandwich", "Lunch", 3),
        ];
        let criteria = MatchCriteria::new_default();

        let result = sync_diary_to_plan(diary_entries, meal_plans, criteria);

        assert_eq!(result.matched.len(), 1);
        // Should match the most similar one
        let matched_plan = &result.matched[0].plan_entry;
        assert!(
            matched_plan.title.contains("Chicken"),
            "Should match a chicken dish"
        );
    }

    #[test]
    fn test_nutrition_similarity_perfect() {
        let n1 = create_test_nutrition(500.0, 50.0, 30.0, 20.0);
        let n2 = create_test_nutrition(500.0, 50.0, 30.0, 20.0);
        let score = calculate_nutrition_similarity(&n1, &n2, 0.15);
        assert_eq!(score, 1.0);
    }

    #[test]
    fn test_nutrition_similarity_within_tolerance() {
        let n1 = create_test_nutrition(500.0, 50.0, 30.0, 20.0);
        let n2 = create_test_nutrition(575.0, 50.0, 30.0, 20.0); // 15% difference
        let score = calculate_nutrition_similarity(&n1, &n2, 0.15);
        assert!(score > 0.0 && score < 1.0);
    }

    #[test]
    fn test_nutrition_similarity_exceeds_tolerance() {
        let n1 = create_test_nutrition(500.0, 50.0, 30.0, 20.0);
        let n2 = create_test_nutrition(700.0, 50.0, 30.0, 20.0); // 40% difference
        let score = calculate_nutrition_similarity(&n1, &n2, 0.15);
        assert_eq!(score, 0.0);
    }
}