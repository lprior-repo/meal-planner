//! Weekly Meal Planning with Nutrition Targets
//!
//! This module provides weekly meal planning functionality including:
//!
//! - Nutrition target setting (calories, macros)
//! - Weekly plan generation
//! - Meal slot management
//! - Recipe selection based on nutrition
//! - Plan optimization and balancing
//!
//! # Planning Flow
//!
//! 1. Set nutrition targets (daily/weekly)
//! 2. Define available meal slots
//! 3. Add constraints (dietary restrictions, preferences)
//! 4. Generate or manually build plan
//! 5. Calculate and validate nutrition

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::errors::{SyncError, SyncResult};
use super::types::{MacroRatio, MealCategory, NutritionData, TandoorRecipe, TandoorRecipeId};

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Weekly planning configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyPlanConfig {
    /// Number of days in the plan
    pub days: usize,
    /// Default meals per day
    pub meals_per_day: usize,
    /// Allow recipes to repeat
    pub allow_repeats: bool,
    /// Minimum days between repeats
    pub repeat_gap_days: usize,
    /// Maximum deviation from target (percentage)
    pub max_deviation_percent: f64,
    /// Whether to balance macros across days
    pub balance_macros: bool,
}

impl Default for WeeklyPlanConfig {
    fn default() -> Self {
        Self {
            days: 7,
            meals_per_day: 3,
            allow_repeats: true,
            repeat_gap_days: 2,
            max_deviation_percent: 15.0,
            balance_macros: true,
        }
    }
}

impl WeeklyPlanConfig {
    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.days == 0 {
            return Err(SyncError::config_invalid("days", "Must be at least 1"));
        }
        if self.meals_per_day == 0 {
            return Err(SyncError::config_invalid(
                "meals_per_day",
                "Must be at least 1",
            ));
        }
        if self.max_deviation_percent < 0.0 {
            return Err(SyncError::config_invalid(
                "max_deviation_percent",
                "Cannot be negative",
            ));
        }
        Ok(())
    }

    /// Total meal slots in the plan
    #[must_use]
    pub fn total_slots(&self) -> usize {
        self.days * self.meals_per_day
    }
}

// =============================================================================
// NUTRITION TARGETS
// =============================================================================

/// Daily nutrition target
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutritionTarget {
    /// Target calories
    pub calories: f64,
    /// Target protein (grams)
    pub protein: f64,
    /// Target fat (grams)
    pub fat: f64,
    /// Target carbohydrate (grams)
    pub carbohydrate: f64,
    /// Target fiber (grams, optional)
    pub fiber: Option<f64>,
    /// Target sodium (mg, optional)
    pub sodium: Option<f64>,
}

impl NutritionTarget {
    /// Create from calorie and macro ratio
    #[must_use]
    pub fn from_calories_and_ratio(calories: f64, ratio: &MacroRatio) -> Self {
        // Calories from macros: protein = 4 cal/g, carbs = 4 cal/g, fat = 9 cal/g
        let protein_cals = calories * (ratio.protein_percent / 100.0);
        let fat_cals = calories * (ratio.fat_percent / 100.0);
        let carb_cals = calories * (ratio.carb_percent / 100.0);

        Self {
            calories,
            protein: protein_cals / 4.0,
            fat: fat_cals / 9.0,
            carbohydrate: carb_cals / 4.0,
            fiber: None,
            sodium: None,
        }
    }

    /// Create a balanced target (40/30/30 ratio)
    #[must_use]
    pub fn balanced(calories: f64) -> Self {
        Self::from_calories_and_ratio(
            calories,
            &MacroRatio {
                protein_percent: 30.0,
                fat_percent: 30.0,
                carb_percent: 40.0,
            },
        )
    }

    /// Create a high protein target (40/25/35)
    #[must_use]
    pub fn high_protein(calories: f64) -> Self {
        Self::from_calories_and_ratio(calories, &MacroRatio::high_protein())
    }

    /// Create a keto target (20/75/5)
    #[must_use]
    pub fn keto(calories: f64) -> Self {
        Self::from_calories_and_ratio(calories, &MacroRatio::keto())
    }

    /// Convert to `NutritionData`
    #[must_use]
    pub fn to_nutrition_data(&self) -> NutritionData {
        NutritionData {
            calories: self.calories,
            protein: self.protein,
            fat: self.fat,
            carbohydrate: self.carbohydrate,
            fiber: self.fiber,
            sugar: None,
            saturated_fat: None,
            monounsaturated_fat: None,
            polyunsaturated_fat: None,
            trans_fat: None,
            cholesterol: None,
            sodium: self.sodium,
            potassium: None,
            calcium: None,
            iron: None,
            vitamin_a: None,
            vitamin_c: None,
        }
    }

    /// Scale target by a factor
    #[must_use]
    pub fn scale(&self, factor: f64) -> Self {
        Self {
            calories: self.calories * factor,
            protein: self.protein * factor,
            fat: self.fat * factor,
            carbohydrate: self.carbohydrate * factor,
            fiber: self.fiber.map(|f| f * factor),
            sodium: self.sodium.map(|s| s * factor),
        }
    }

    /// Split target across meals
    #[must_use]
    pub fn split_by_meal(&self, distribution: &MealDistribution) -> HashMap<MealCategory, NutritionTarget> {
        let mut result = HashMap::new();

        for (meal, percent) in distribution.percentages.iter() {
            result.insert(*meal, self.scale(percent / 100.0));
        }

        result
    }
}

impl Default for NutritionTarget {
    fn default() -> Self {
        Self::balanced(2000.0)
    }
}

/// Distribution of calories across meals
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealDistribution {
    /// Percentage of daily calories per meal
    pub percentages: HashMap<MealCategory, f64>,
}

impl MealDistribution {
    /// Standard 3-meal distribution (25/35/40)
    #[must_use]
    pub fn standard() -> Self {
        let mut percentages = HashMap::new();
        percentages.insert(MealCategory::Breakfast, 25.0);
        percentages.insert(MealCategory::Lunch, 35.0);
        percentages.insert(MealCategory::Dinner, 40.0);
        Self { percentages }
    }

    /// Even distribution
    #[must_use]
    pub fn even(meal_count: usize) -> Self {
        let percent = 100.0 / meal_count as f64;
        let mut percentages = HashMap::new();

        let meals = [
            MealCategory::Breakfast,
            MealCategory::Lunch,
            MealCategory::Dinner,
            MealCategory::Other,
        ];

        for (_i, meal) in meals.iter().enumerate().take(meal_count) {
            percentages.insert(*meal, percent);
        }

        Self { percentages }
    }

    /// Validate that percentages sum to 100
    #[must_use]
    pub fn is_valid(&self) -> bool {
        let sum: f64 = self.percentages.values().sum();
        (sum - 100.0).abs() < 0.01
    }
}

impl Default for MealDistribution {
    fn default() -> Self {
        Self::standard()
    }
}

/// A set of nutrition targets for the week
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutritionTargetSet {
    /// Daily target
    pub daily: NutritionTarget,
    /// Weekly target (daily * 7)
    pub weekly: NutritionTarget,
    /// Per-meal targets
    pub per_meal: HashMap<MealCategory, NutritionTarget>,
    /// Meal distribution
    pub distribution: MealDistribution,
}

impl NutritionTargetSet {
    /// Create from daily target
    #[must_use]
    pub fn from_daily(daily: NutritionTarget) -> Self {
        let weekly = daily.scale(7.0);
        let distribution = MealDistribution::standard();
        let per_meal = daily.split_by_meal(&distribution);

        Self {
            daily,
            weekly,
            per_meal,
            distribution,
        }
    }

    /// Create with custom distribution
    #[must_use]
    pub fn with_distribution(daily: NutritionTarget, distribution: MealDistribution) -> Self {
        let weekly = daily.scale(7.0);
        let per_meal = daily.split_by_meal(&distribution);

        Self {
            daily,
            weekly,
            per_meal,
            distribution,
        }
    }

    /// Get target for a specific meal
    #[must_use]
    pub fn for_meal(&self, meal: MealCategory) -> Option<&NutritionTarget> {
        self.per_meal.get(&meal)
    }
}

impl Default for NutritionTargetSet {
    fn default() -> Self {
        Self::from_daily(NutritionTarget::default())
    }
}

// =============================================================================
// MEAL SLOTS
// =============================================================================

/// A slot for a meal in the plan
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealSlot {
    /// Day index (0-based)
    pub day: usize,
    /// Meal type
    pub meal: MealCategory,
    /// Assigned recipe (if any)
    pub recipe: Option<SlotRecipe>,
    /// Locked (cannot be changed)
    pub locked: bool,
    /// Notes
    pub notes: Option<String>,
}

impl MealSlot {
    /// Create a new empty slot
    #[must_use]
    pub fn new(day: usize, meal: MealCategory) -> Self {
        Self {
            day,
            meal,
            recipe: None,
            locked: false,
            notes: None,
        }
    }

    /// Assign a recipe to the slot
    pub fn assign(&mut self, recipe: SlotRecipe) {
        if !self.locked {
            self.recipe = Some(recipe);
        }
    }

    /// Clear the slot
    pub fn clear(&mut self) {
        if !self.locked {
            self.recipe = None;
        }
    }

    /// Check if slot is filled
    #[must_use]
    pub fn is_filled(&self) -> bool {
        self.recipe.is_some()
    }

    /// Get nutrition for this slot
    #[must_use]
    pub fn nutrition(&self) -> Option<NutritionData> {
        self.recipe.as_ref().map(|r| r.scaled_nutrition.clone())
    }
}

/// A recipe assigned to a slot
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlotRecipe {
    /// Recipe ID
    pub recipe_id: TandoorRecipeId,
    /// Recipe name
    pub name: String,
    /// Servings for this slot
    pub servings: f64,
    /// Nutrition scaled to servings
    pub scaled_nutrition: NutritionData,
}

impl SlotRecipe {
    /// Create from a recipe
    #[must_use]
    pub fn from_recipe(recipe: &TandoorRecipe, servings: f64) -> Option<Self> {
        let per_serving = recipe.nutrition_per_serving()?;
        let scaled_nutrition = per_serving.scale(servings);

        Some(Self {
            recipe_id: TandoorRecipeId::new(recipe.id),
            name: recipe.name.clone(),
            servings,
            scaled_nutrition,
        })
    }
}

// =============================================================================
// DAY PLAN
// =============================================================================

/// Plan for a single day
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DayPlan {
    /// Day index (0-based)
    pub day: usize,
    /// Date string (optional)
    pub date: Option<String>,
    /// Meal slots
    pub slots: Vec<MealSlot>,
    /// Total nutrition for the day
    pub total_nutrition: NutritionData,
}

impl DayPlan {
    /// Create a new day plan
    #[must_use]
    pub fn new(day: usize, meals: &[MealCategory]) -> Self {
        let slots = meals
            .iter()
            .map(|&meal| MealSlot::new(day, meal))
            .collect();

        Self {
            day,
            date: None,
            slots,
            total_nutrition: NutritionData::zero(),
        }
    }

    /// Create with date
    #[must_use]
    pub fn with_date(day: usize, date: &str, meals: &[MealCategory]) -> Self {
        let mut plan = Self::new(day, meals);
        plan.date = Some(date.to_string());
        plan
    }

    /// Recalculate total nutrition
    pub fn recalculate(&mut self) {
        self.total_nutrition = self
            .slots
            .iter()
            .filter_map(MealSlot::nutrition)
            .fold(NutritionData::zero(), |acc, n| acc.add(&n));
    }

    /// Get slot for a specific meal
    #[must_use]
    pub fn get_slot(&self, meal: MealCategory) -> Option<&MealSlot> {
        self.slots.iter().find(|s| s.meal == meal)
    }

    /// Get mutable slot for a specific meal
    pub fn get_slot_mut(&mut self, meal: MealCategory) -> Option<&mut MealSlot> {
        self.slots.iter_mut().find(|s| s.meal == meal)
    }

    /// Count filled slots
    #[must_use]
    pub fn filled_count(&self) -> usize {
        self.slots.iter().filter(|s| s.is_filled()).count()
    }

    /// Check if fully planned
    #[must_use]
    pub fn is_complete(&self) -> bool {
        self.slots.iter().all(MealSlot::is_filled)
    }
}

// =============================================================================
// WEEKLY PLAN
// =============================================================================

/// A complete weekly meal plan
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyPlan {
    /// Configuration used
    pub config: WeeklyPlanConfig,
    /// Nutrition targets
    pub targets: NutritionTargetSet,
    /// Days in the plan
    pub days: Vec<DayPlan>,
    /// Total nutrition for the week
    pub total_nutrition: NutritionData,
    /// Recipes used (with counts)
    pub recipe_usage: HashMap<i64, usize>,
}

impl WeeklyPlan {
    /// Create a new empty plan
    #[must_use]
    pub fn new(config: WeeklyPlanConfig, targets: NutritionTargetSet) -> Self {
        let meals = vec![MealCategory::Breakfast, MealCategory::Lunch, MealCategory::Dinner];

        let days = (0..config.days)
            .map(|day| DayPlan::new(day, &meals[..config.meals_per_day.min(3)]))
            .collect();

        Self {
            config,
            targets,
            days,
            total_nutrition: NutritionData::zero(),
            recipe_usage: HashMap::new(),
        }
    }

    /// Create with dates
    #[must_use]
    pub fn with_dates(
        config: WeeklyPlanConfig,
        targets: NutritionTargetSet,
        start_date: &str,
    ) -> Self {
        let meals = vec![MealCategory::Breakfast, MealCategory::Lunch, MealCategory::Dinner];

        // Simple date increment (would use chrono in production)
        let days = (0..config.days)
            .map(|day| {
                let date = format!("{start_date}+{day}"); // Placeholder
                DayPlan::with_date(day, &date, &meals[..config.meals_per_day.min(3)])
            })
            .collect();

        Self {
            config,
            targets,
            days,
            total_nutrition: NutritionData::zero(),
            recipe_usage: HashMap::new(),
        }
    }

    /// Recalculate all nutrition totals
    pub fn recalculate(&mut self) {
        self.recipe_usage.clear();

        for day in &mut self.days {
            day.recalculate();

            for slot in &day.slots {
                if let Some(ref recipe) = slot.recipe {
                    *self.recipe_usage.entry(recipe.recipe_id.as_i64()).or_insert(0) += 1;
                }
            }
        }

        self.total_nutrition = self
            .days
            .iter()
            .fold(NutritionData::zero(), |acc, d| acc.add(&d.total_nutrition));
    }

    /// Assign a recipe to a specific slot
    pub fn assign_recipe(&mut self, day: usize, meal: MealCategory, recipe: SlotRecipe) -> bool {
        if day >= self.days.len() {
            return false;
        }

        if let Some(slot) = self.days.get_mut(day).and_then(|d| d.get_slot_mut(meal)) {
            slot.assign(recipe);
            self.recalculate();
            return true;
        }

        false
    }

    /// Get completion percentage
    #[must_use]
    pub fn completion_percent(&self) -> f64 {
        let total_slots = self.config.total_slots();
        if total_slots == 0 {
            return 100.0;
        }

        let filled: usize = self.days.iter().map(DayPlan::filled_count).sum();
        (filled as f64 / total_slots as f64) * 100.0
    }

    /// Check if plan meets targets
    #[must_use]
    pub fn meets_targets(&self) -> bool {
        let deviation = self.target_deviation_percent();
        deviation <= self.config.max_deviation_percent
    }

    /// Calculate deviation from weekly target
    #[must_use]
    pub fn target_deviation_percent(&self) -> f64 {
        let target = &self.targets.weekly;
        if target.calories == 0.0 {
            return 0.0;
        }

        ((self.total_nutrition.calories - target.calories).abs() / target.calories) * 100.0
    }

    /// Get recipes that can be added (respecting repeat rules)
    #[must_use]
    pub fn available_recipes<'a>(&self, day: usize, recipes: &'a [TandoorRecipe]) -> Vec<&'a TandoorRecipe> {
        recipes
            .iter()
            .filter(|r| self.can_use_recipe(day, r.id))
            .collect()
    }

    /// Check if a recipe can be used on a given day
    #[must_use]
    pub fn can_use_recipe(&self, target_day: usize, recipe_id: i64) -> bool {
        if !self.config.allow_repeats {
            return !self.recipe_usage.contains_key(&recipe_id);
        }

        // Check repeat gap
        for (day_idx, day) in self.days.iter().enumerate() {
            let day_diff = if target_day >= day_idx {
                target_day - day_idx
            } else {
                day_idx - target_day
            };

            if day_diff < self.config.repeat_gap_days {
                for slot in &day.slots {
                    if let Some(ref recipe) = slot.recipe {
                        if recipe.recipe_id.as_i64() == recipe_id {
                            return false;
                        }
                    }
                }
            }
        }

        true
    }

    /// Get remaining nutrition needed
    #[must_use]
    pub fn remaining_nutrition(&self) -> NutritionData {
        let target = self.targets.weekly.to_nutrition_data();
        NutritionData {
            calories: (target.calories - self.total_nutrition.calories).max(0.0),
            protein: (target.protein - self.total_nutrition.protein).max(0.0),
            fat: (target.fat - self.total_nutrition.fat).max(0.0),
            carbohydrate: (target.carbohydrate - self.total_nutrition.carbohydrate).max(0.0),
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
}

// =============================================================================
// CONSTRAINTS
// =============================================================================

/// A constraint on the meal plan
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanningConstraint {
    /// Constraint type
    pub constraint_type: ConstraintType,
    /// Priority (higher = more important)
    pub priority: u8,
    /// Whether constraint is hard (must be satisfied) or soft (preferred)
    pub hard: bool,
}

/// Types of planning constraints
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConstraintType {
    /// Maximum calories per meal
    MaxCaloriesPerMeal(f64),
    /// Minimum protein per meal
    MinProteinPerMeal(f64),
    /// Exclude certain ingredients
    ExcludeIngredients(Vec<String>),
    /// Require certain keywords
    RequireKeywords(Vec<String>),
    /// Maximum cooking time
    MaxCookingTime(i32),
    /// Preferred recipes
    PreferRecipes(Vec<i64>),
    /// Avoid recipes
    AvoidRecipes(Vec<i64>),
}

impl PlanningConstraint {
    /// Check if a recipe satisfies this constraint
    #[must_use]
    pub fn check_recipe(&self, recipe: &TandoorRecipe) -> bool {
        match &self.constraint_type {
            ConstraintType::MaxCaloriesPerMeal(max) => {
                recipe.nutrition_per_serving().map_or(true, |n| n.calories <= *max)
            }
            ConstraintType::MinProteinPerMeal(min) => {
                recipe.nutrition_per_serving().map_or(true, |n| n.protein >= *min)
            }
            ConstraintType::ExcludeIngredients(ingredients) => {
                !recipe.ingredients.iter().any(|i| {
                    ingredients.iter().any(|exc| i.food_name.to_lowercase().contains(&exc.to_lowercase()))
                })
            }
            ConstraintType::RequireKeywords(keywords) => {
                keywords.iter().all(|kw| recipe.keywords.iter().any(|rk| rk.to_lowercase() == kw.to_lowercase()))
            }
            ConstraintType::MaxCookingTime(max) => {
                recipe.total_time().map_or(true, |t| t <= *max)
            }
            ConstraintType::PreferRecipes(ids) => ids.contains(&recipe.id),
            ConstraintType::AvoidRecipes(ids) => !ids.contains(&recipe.id),
        }
    }
}

// =============================================================================
// WEEKLY PLANNER
// =============================================================================

/// Service for creating and managing weekly meal plans
#[derive(Debug, Clone)]
pub struct WeeklyPlanner {
    config: WeeklyPlanConfig,
}

impl WeeklyPlanner {
    /// Create a new planner
    #[must_use]
    pub fn new(config: WeeklyPlanConfig) -> Self {
        Self { config }
    }

    /// Create with defaults
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(WeeklyPlanConfig::default())
    }

    /// Create an empty plan
    #[must_use]
    pub fn create_empty_plan(&self, targets: NutritionTargetSet) -> WeeklyPlan {
        WeeklyPlan::new(self.config.clone(), targets)
    }

    /// Score a recipe for a slot based on how well it fits the target
    #[must_use]
    pub fn score_recipe_for_slot(
        &self,
        recipe: &TandoorRecipe,
        target: &NutritionTarget,
        servings: f64,
    ) -> f64 {
        let nutrition = match recipe.nutrition_per_serving() {
            Some(n) => n.scale(servings),
            None => return 0.0,
        };

        // Score based on how close to target
        let cal_diff = (nutrition.calories - target.calories).abs() / target.calories;
        let prot_diff = (nutrition.protein - target.protein).abs() / target.protein.max(1.0);
        let fat_diff = (nutrition.fat - target.fat).abs() / target.fat.max(1.0);
        let carb_diff = (nutrition.carbohydrate - target.carbohydrate).abs() / target.carbohydrate.max(1.0);

        let avg_diff = (cal_diff + prot_diff + fat_diff + carb_diff) / 4.0;
        (1.0 - avg_diff).max(0.0)
    }

    /// Filter recipes by constraints
    #[must_use]
    pub fn filter_by_constraints<'a>(
        &self,
        recipes: &'a [TandoorRecipe],
        constraints: &[PlanningConstraint],
    ) -> Vec<&'a TandoorRecipe> {
        recipes
            .iter()
            .filter(|r| {
                constraints
                    .iter()
                    .filter(|c| c.hard)
                    .all(|c| c.check_recipe(r))
            })
            .collect()
    }

    /// Sort recipes by how well they match constraints
    #[must_use]
    pub fn rank_recipes(
        &self,
        recipes: &[TandoorRecipe],
        target: &NutritionTarget,
        constraints: &[PlanningConstraint],
    ) -> Vec<(usize, f64)> {
        let mut scored: Vec<(usize, f64)> = recipes
            .iter()
            .enumerate()
            .map(|(idx, recipe)| {
                let base_score = self.score_recipe_for_slot(recipe, target, 1.0);

                // Apply soft constraint bonuses
                let constraint_bonus: f64 = constraints
                    .iter()
                    .filter(|c| !c.hard && c.check_recipe(recipe))
                    .map(|c| f64::from(c.priority) * 0.1)
                    .sum();

                (idx, (base_score + constraint_bonus).min(1.0))
            })
            .collect();

        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        scored
    }
}

impl Default for WeeklyPlanner {
    fn default() -> Self {
        Self::with_defaults()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::sync::types::TandoorIngredient;

    fn create_test_recipe(id: i64, name: &str, calories: f64) -> TandoorRecipe {
        TandoorRecipe {
            id,
            name: name.to_string(),
            description: None,
            servings: 1,
            working_time: Some(30),
            waiting_time: None,
            ingredients: Vec::new(),
            steps: Vec::new(),
            keywords: Vec::new(),
            nutrition: Some(NutritionData::macros_only(calories, calories / 10.0, calories / 20.0, calories / 5.0)),
            source_url: None,
            image_url: None,
        }
    }

    #[test]
    fn test_nutrition_target_from_ratio() {
        let target = NutritionTarget::from_calories_and_ratio(
            2000.0,
            &MacroRatio {
                protein_percent: 30.0,
                fat_percent: 30.0,
                carb_percent: 40.0,
            },
        );

        assert!((target.calories - 2000.0).abs() < 0.01);
        // Protein: 2000 * 0.30 / 4 = 150g
        assert!((target.protein - 150.0).abs() < 0.1);
        // Fat: 2000 * 0.30 / 9 = 66.67g
        assert!((target.fat - 66.67).abs() < 0.1);
        // Carbs: 2000 * 0.40 / 4 = 200g
        assert!((target.carbohydrate - 200.0).abs() < 0.1);
    }

    #[test]
    fn test_meal_distribution() {
        let dist = MealDistribution::standard();
        assert!(dist.is_valid());

        let breakfast = dist.percentages.get(&MealCategory::Breakfast).unwrap();
        assert!((breakfast - 25.0).abs() < 0.01);
    }

    #[test]
    fn test_nutrition_target_split() {
        let daily = NutritionTarget::balanced(2000.0);
        let dist = MealDistribution::standard();
        let per_meal = daily.split_by_meal(&dist);

        let breakfast_target = per_meal.get(&MealCategory::Breakfast).unwrap();
        assert!((breakfast_target.calories - 500.0).abs() < 0.01); // 25% of 2000
    }

    #[test]
    fn test_weekly_plan_creation() {
        let config = WeeklyPlanConfig::default();
        let targets = NutritionTargetSet::default();
        let plan = WeeklyPlan::new(config, targets);

        assert_eq!(plan.days.len(), 7);
        assert_eq!(plan.completion_percent(), 0.0);
    }

    #[test]
    fn test_weekly_plan_assign_recipe() {
        let config = WeeklyPlanConfig::default();
        let targets = NutritionTargetSet::default();
        let mut plan = WeeklyPlan::new(config, targets);

        let recipe = create_test_recipe(1, "Test Recipe", 500.0);
        let slot_recipe = SlotRecipe::from_recipe(&recipe, 1.0).unwrap();

        let success = plan.assign_recipe(0, MealCategory::Breakfast, slot_recipe);
        assert!(success);
        assert!(plan.completion_percent() > 0.0);
        assert!((plan.total_nutrition.calories - 500.0).abs() < 0.01);
    }

    #[test]
    fn test_weekly_plan_repeat_rules() {
        let config = WeeklyPlanConfig {
            allow_repeats: true,
            repeat_gap_days: 2,
            ..WeeklyPlanConfig::default()
        };
        let targets = NutritionTargetSet::default();
        let mut plan = WeeklyPlan::new(config, targets);

        let recipe = create_test_recipe(1, "Test Recipe", 500.0);
        let slot_recipe = SlotRecipe::from_recipe(&recipe, 1.0).unwrap();

        plan.assign_recipe(0, MealCategory::Breakfast, slot_recipe.clone());

        // Can't use same recipe on day 1 (gap < 2)
        assert!(!plan.can_use_recipe(1, 1));

        // Can use on day 2 (gap >= 2)
        assert!(plan.can_use_recipe(2, 1));
    }

    #[test]
    fn test_constraint_check() {
        let recipe = TandoorRecipe {
            id: 1,
            name: "Chicken Salad".to_string(),
            description: None,
            servings: 1,
            working_time: Some(20),
            waiting_time: None,
            ingredients: vec![TandoorIngredient::new("chicken", Some(200.0), Some("g"))],
            steps: Vec::new(),
            keywords: vec!["healthy".to_string(), "quick".to_string()],
            nutrition: Some(NutritionData::macros_only(400.0, 40.0, 15.0, 20.0)),
            source_url: None,
            image_url: None,
        };

        let max_cal = PlanningConstraint {
            constraint_type: ConstraintType::MaxCaloriesPerMeal(500.0),
            priority: 1,
            hard: true,
        };
        assert!(max_cal.check_recipe(&recipe));

        let min_protein = PlanningConstraint {
            constraint_type: ConstraintType::MinProteinPerMeal(30.0),
            priority: 1,
            hard: true,
        };
        assert!(min_protein.check_recipe(&recipe));

        let exclude = PlanningConstraint {
            constraint_type: ConstraintType::ExcludeIngredients(vec!["beef".to_string()]),
            priority: 1,
            hard: true,
        };
        assert!(exclude.check_recipe(&recipe));

        let exclude_chicken = PlanningConstraint {
            constraint_type: ConstraintType::ExcludeIngredients(vec!["chicken".to_string()]),
            priority: 1,
            hard: true,
        };
        assert!(!exclude_chicken.check_recipe(&recipe));
    }

    #[test]
    fn test_planner_score_recipe() {
        let planner = WeeklyPlanner::with_defaults();
        let recipe = create_test_recipe(1, "Test", 500.0);
        let target = NutritionTarget::balanced(500.0);

        let score = planner.score_recipe_for_slot(&recipe, &target, 1.0);
        // Should be high since nutrition matches target
        assert!(score > 0.5);
    }

    #[test]
    fn test_config_validation() {
        let valid = WeeklyPlanConfig::default();
        assert!(valid.validate().is_ok());

        let invalid = WeeklyPlanConfig {
            days: 0,
            ..WeeklyPlanConfig::default()
        };
        assert!(invalid.validate().is_err());
    }
}
