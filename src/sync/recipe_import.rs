//! Recipe Import Module
//!
//! This module provides functionality for importing FatSecret recipes and foods
//! into Tandoor Recipes.

use crate::sync::errors::{SyncError, SyncResult};
use crate::sync::types::NutritionData;
use crate::sync::units::UnitConverter;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Configuration for recipe import operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportConfig {
    /// Default number of servings for imported recipes
    pub default_servings: i32,
    /// Whether to include nutrition data in imported recipes
    pub include_nutrition: bool,
    /// Whether to create ingredients that don't exist in Tandoor
    pub create_missing_ingredients: bool,
    /// Default unit for ingredients without clear units
    pub default_unit: String,
    /// Prefix for imported recipe names
    pub recipe_name_prefix: Option<String>,
    /// Suffix for imported recipe names
    pub recipe_name_suffix: Option<String>,
    /// Whether to import step instructions (if available)
    pub import_instructions: bool,
    /// Default prep time in minutes for imported recipes
    pub default_prep_time: Option<i32>,
    /// Default cook time in minutes for imported recipes
    pub default_cook_time: Option<i32>,
    /// Whether to mark imported recipes with a specific keyword
    pub import_keyword: Option<String>,
    /// Maximum ingredients per recipe (for validation)
    pub max_ingredients: usize,
    /// Whether to merge duplicate ingredients
    pub merge_duplicates: bool,
    /// Minimum nutrition data completeness (0.0-1.0)
    pub min_nutrition_completeness: f64,
}

impl Default for ImportConfig {
    fn default() -> Self {
        Self {
            default_servings: 1,
            include_nutrition: true,
            create_missing_ingredients: true,
            default_unit: "g".to_string(),
            recipe_name_prefix: None,
            recipe_name_suffix: None,
            import_instructions: true,
            default_prep_time: None,
            default_cook_time: None,
            import_keyword: Some("imported-from-fatsecret".to_string()),
            max_ingredients: 50,
            merge_duplicates: true,
            min_nutrition_completeness: 0.5,
        }
    }
}

impl ImportConfig {
    /// Create config with strict validation
    #[must_use]
    pub fn strict() -> Self {
        Self {
            min_nutrition_completeness: 0.8,
            max_ingredients: 30,
            merge_duplicates: true,
            ..Self::default()
        }
    }

    /// Create config for quick imports without validation
    #[must_use]
    pub fn lenient() -> Self {
        Self {
            min_nutrition_completeness: 0.0,
            max_ingredients: 100,
            create_missing_ingredients: true,
            ..Self::default()
        }
    }

    /// Builder: set default servings
    #[must_use]
    pub fn with_servings(mut self, servings: i32) -> Self {
        self.default_servings = servings;
        self
    }

    /// Builder: set recipe name prefix
    #[must_use]
    pub fn with_prefix(mut self, prefix: impl Into<String>) -> Self {
        self.recipe_name_prefix = Some(prefix.into());
        self
    }

    /// Builder: set import keyword
    #[must_use]
    pub fn with_keyword(mut self, keyword: impl Into<String>) -> Self {
        self.import_keyword = Some(keyword.into());
        self
    }

    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.default_servings < 1 {
            return Err(SyncError::validation("default_servings must be at least 1"));
        }
        if self.max_ingredients == 0 {
            return Err(SyncError::validation("max_ingredients must be positive"));
        }
        if !(0.0..=1.0).contains(&self.min_nutrition_completeness) {
            return Err(SyncError::validation(
                "min_nutrition_completeness must be between 0.0 and 1.0",
            ));
        }
        Ok(())
    }
}

/// Serving information for a food item (local type for recipe import)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportServing {
    /// Serving description (e.g., "1 cup")
    pub description: String,
    /// Metric amount in grams (if known)
    pub metric_grams: Option<f64>,
    /// Calories per serving
    pub calories: Option<f64>,
    /// Protein per serving
    pub protein: Option<f64>,
    /// Carbohydrate per serving
    pub carbohydrate: Option<f64>,
    /// Fat per serving
    pub fat: Option<f64>,
    /// Fiber per serving
    pub fiber: Option<f64>,
}

impl Default for ImportServing {
    fn default() -> Self {
        Self {
            description: "1 serving".to_string(),
            metric_grams: None,
            calories: None,
            protein: None,
            carbohydrate: None,
            fat: None,
            fiber: None,
        }
    }
}

/// A FatSecret saved meal (collection of foods)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FatSecretMeal {
    /// Meal ID from FatSecret
    pub meal_id: Option<i64>,
    /// Meal name
    pub name: String,
    /// Description of the meal
    pub description: Option<String>,
    /// Foods in this meal
    pub foods: Vec<FatSecretMealFood>,
}

/// A food item within a FatSecret meal
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FatSecretMealFood {
    /// FatSecret food ID
    pub food_id: i64,
    /// Food name
    pub food_name: String,
    /// Brand name (if branded food)
    pub brand_name: Option<String>,
    /// Serving used
    pub serving: ImportServing,
    /// Number of servings consumed
    pub number_of_servings: f64,
    /// Nutrition for this amount
    pub nutrition: NutritionData,
}

/// Mapping between FatSecret food and Tandoor ingredient
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IngredientMapping {
    /// FatSecret food ID
    pub fatsecret_food_id: i64,
    /// FatSecret food name
    pub fatsecret_name: String,
    /// Tandoor ingredient ID (if mapped)
    pub tandoor_ingredient_id: Option<i64>,
    /// Tandoor ingredient name
    pub tandoor_name: Option<String>,
    /// Whether this is an exact match
    pub is_exact_match: bool,
    /// Confidence score (0.0-1.0)
    pub confidence: f64,
    /// Whether to create ingredient if not found
    pub create_if_missing: bool,
}

impl IngredientMapping {
    /// Create a new exact mapping
    #[must_use]
    pub fn exact(fatsecret_id: i64, fatsecret_name: String, tandoor_id: i64, tandoor_name: String) -> Self {
        Self {
            fatsecret_food_id: fatsecret_id,
            fatsecret_name,
            tandoor_ingredient_id: Some(tandoor_id),
            tandoor_name: Some(tandoor_name),
            is_exact_match: true,
            confidence: 1.0,
            create_if_missing: false,
        }
    }

    /// Create an unmapped entry (will create new ingredient)
    #[must_use]
    pub fn unmapped(fatsecret_id: i64, fatsecret_name: String) -> Self {
        Self {
            fatsecret_food_id: fatsecret_id,
            fatsecret_name,
            tandoor_ingredient_id: None,
            tandoor_name: None,
            is_exact_match: false,
            confidence: 0.0,
            create_if_missing: true,
        }
    }
}

/// Mapping between FatSecret serving and Tandoor unit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnitMapping {
    /// FatSecret serving description
    pub fatsecret_serving: String,
    /// Tandoor unit ID
    pub tandoor_unit_id: Option<i64>,
    /// Tandoor unit name
    pub tandoor_unit_name: String,
    /// Conversion factor (FatSecret amount * factor = Tandoor amount)
    pub conversion_factor: f64,
}

impl UnitMapping {
    /// Create a direct 1:1 mapping
    #[must_use]
    pub fn direct(serving: impl Into<String>, unit_id: i64, unit_name: impl Into<String>) -> Self {
        Self {
            fatsecret_serving: serving.into(),
            tandoor_unit_id: Some(unit_id),
            tandoor_unit_name: unit_name.into(),
            conversion_factor: 1.0,
        }
    }
}

/// An ingredient ready for import to Tandoor
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportedIngredient {
    /// Ingredient name
    pub name: String,
    /// Amount in the recipe
    pub amount: f64,
    /// Unit name
    pub unit: String,
    /// Tandoor ingredient ID (if exists)
    pub ingredient_id: Option<i64>,
    /// Tandoor unit ID (if exists)
    pub unit_id: Option<i64>,
    /// Optional note (e.g., brand name)
    pub note: Option<String>,
    /// Nutrition per the specified amount
    pub nutrition: NutritionData,
    /// Original FatSecret food ID
    pub fatsecret_food_id: i64,
    /// Order in ingredient list
    pub order: i32,
}

/// A step in the imported recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportedStep {
    /// Step instruction text
    pub instruction: String,
    /// Step order (1-indexed)
    pub order: i32,
    /// Time for this step in minutes (if known)
    pub time: Option<i32>,
}

/// A recipe ready for import to Tandoor
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportedRecipe {
    /// Recipe name
    pub name: String,
    /// Recipe description
    pub description: Option<String>,
    /// Number of servings
    pub servings: i32,
    /// Prep time in minutes
    pub prep_time: Option<i32>,
    /// Cook time in minutes
    pub cook_time: Option<i32>,
    /// Recipe ingredients
    pub ingredients: Vec<ImportedIngredient>,
    /// Recipe steps
    pub steps: Vec<ImportedStep>,
    /// Total nutrition for the recipe
    pub nutrition: NutritionData,
    /// Keywords to apply
    pub keywords: Vec<String>,
    /// Source information
    pub source: ImportSource,
    /// Validation warnings (non-fatal issues)
    pub warnings: Vec<String>,
}

impl ImportedRecipe {
    /// Get nutrition per serving
    #[must_use]
    pub fn nutrition_per_serving(&self) -> NutritionData {
        if self.servings > 0 {
            #[allow(clippy::cast_precision_loss)]
            self.nutrition.scale(1.0 / self.servings as f64)
        } else {
            self.nutrition.clone()
        }
    }

    /// Check if recipe has complete nutrition
    #[must_use]
    pub fn nutrition_completeness(&self) -> f64 {
        self.nutrition.completeness()
    }

    /// Get total ingredient count
    #[must_use]
    pub fn ingredient_count(&self) -> usize {
        self.ingredients.len()
    }
}

/// Source information for imported recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportSource {
    /// Source system
    pub system: String,
    /// Original ID in source system
    pub original_id: Option<i64>,
    /// Import timestamp (ISO 8601)
    pub imported_at: String,
}

impl ImportSource {
    /// Create a FatSecret source
    #[must_use]
    pub fn fatsecret(meal_id: Option<i64>) -> Self {
        Self {
            system: "FatSecret".to_string(),
            original_id: meal_id,
            imported_at: chrono::Utc::now().to_rfc3339(),
        }
    }
}

/// Result of an import operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportResult {
    /// Whether import was successful
    pub success: bool,
    /// Imported recipe (if successful)
    pub recipe: Option<ImportedRecipe>,
    /// Tandoor recipe ID (if created)
    pub tandoor_recipe_id: Option<i64>,
    /// Errors encountered
    pub errors: Vec<String>,
    /// Warnings (non-fatal)
    pub warnings: Vec<String>,
    /// Number of ingredients successfully mapped
    pub ingredients_mapped: usize,
    /// Number of ingredients that needed creation
    pub ingredients_created: usize,
}

impl ImportResult {
    /// Create a successful result
    #[must_use]
    pub fn success(recipe: ImportedRecipe) -> Self {
        let warnings = recipe.warnings.clone();
        let ingredient_count = recipe.ingredients.len();
        Self {
            success: true,
            recipe: Some(recipe),
            tandoor_recipe_id: None,
            errors: Vec::new(),
            warnings,
            ingredients_mapped: ingredient_count,
            ingredients_created: 0,
        }
    }

    /// Create a failed result
    #[must_use]
    pub fn failure(error: impl Into<String>) -> Self {
        Self {
            success: false,
            recipe: None,
            tandoor_recipe_id: None,
            errors: vec![error.into()],
            warnings: Vec::new(),
            ingredients_mapped: 0,
            ingredients_created: 0,
        }
    }
}

/// Recipe importer service (functional core)
#[derive(Debug, Clone)]
pub struct RecipeImporter {
    /// Configuration
    config: ImportConfig,
    /// Unit converter (reserved for future use)
    _unit_converter: UnitConverter,
    /// Known ingredient mappings
    ingredient_mappings: HashMap<i64, IngredientMapping>,
    /// Known unit mappings
    unit_mappings: HashMap<String, UnitMapping>,
}

impl RecipeImporter {
    /// Create a new recipe importer
    #[must_use]
    pub fn new(config: ImportConfig) -> Self {
        Self {
            config,
            _unit_converter: UnitConverter::new(),
            ingredient_mappings: HashMap::new(),
            unit_mappings: HashMap::new(),
        }
    }

    /// Create with default config
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(ImportConfig::default())
    }

    /// Add an ingredient mapping
    pub fn add_ingredient_mapping(&mut self, mapping: IngredientMapping) {
        self.ingredient_mappings.insert(mapping.fatsecret_food_id, mapping);
    }

    /// Add a unit mapping
    pub fn add_unit_mapping(&mut self, mapping: UnitMapping) {
        self.unit_mappings.insert(mapping.fatsecret_serving.clone(), mapping);
    }

    /// Prepare a recipe import from a FatSecret meal (pure function)
    pub fn prepare_recipe_import(&self, meal: &FatSecretMeal) -> SyncResult<ImportedRecipe> {
        // Validate meal
        if meal.foods.is_empty() {
            return Err(SyncError::validation("Meal has no foods to import"));
        }
        if meal.foods.len() > self.config.max_ingredients {
            return Err(SyncError::validation(format!(
                "Meal has too many foods ({} > {})",
                meal.foods.len(),
                self.config.max_ingredients
            )));
        }

        let mut warnings = Vec::new();

        // Build recipe name
        let name = self.build_recipe_name(&meal.name);

        // Convert foods to ingredients
        let mut ingredients = Vec::new();
        let mut total_nutrition = NutritionData::zero();

        for (idx, food) in meal.foods.iter().enumerate() {
            let ingredient = self.convert_food_to_ingredient(food, idx);
            total_nutrition = total_nutrition.add(&ingredient.nutrition);
            ingredients.push(ingredient);
        }

        // Merge duplicates if configured
        if self.config.merge_duplicates {
            ingredients = self.merge_duplicate_ingredients(ingredients);
        }

        // Validate nutrition completeness
        let completeness = total_nutrition.completeness();
        if completeness < self.config.min_nutrition_completeness {
            warnings.push(format!(
                "Nutrition data is only {:.0}% complete (minimum: {:.0}%)",
                completeness * 100.0,
                self.config.min_nutrition_completeness * 100.0
            ));
        }

        // Build steps
        let steps = self.build_default_steps(&ingredients);

        // Build keywords
        let mut keywords = Vec::new();
        if let Some(ref keyword) = self.config.import_keyword {
            keywords.push(keyword.clone());
        }

        // Create imported recipe
        let recipe = ImportedRecipe {
            name,
            description: meal.description.clone(),
            servings: self.config.default_servings,
            prep_time: self.config.default_prep_time,
            cook_time: self.config.default_cook_time,
            ingredients,
            steps,
            nutrition: total_nutrition,
            keywords,
            source: ImportSource::fatsecret(meal.meal_id),
            warnings,
        };

        Ok(recipe)
    }

    /// Convert a single FatSecret food to an ingredient
    fn convert_food_to_ingredient(
        &self,
        food: &FatSecretMealFood,
        order: usize,
    ) -> ImportedIngredient {
        // Get or create ingredient mapping
        let mapping = self.get_or_create_ingredient_mapping(food);

        // Get or infer unit mapping
        let unit_mapping = self.get_or_infer_unit_mapping(&food.serving);

        // Calculate amount
        let amount = food.number_of_servings * unit_mapping.conversion_factor;

        // Build note with brand if present
        let note = food.brand_name.clone();

        #[allow(clippy::cast_possible_truncation)]
        ImportedIngredient {
            name: mapping.tandoor_name.clone().unwrap_or_else(|| food.food_name.clone()),
            amount,
            unit: unit_mapping.tandoor_unit_name.clone(),
            ingredient_id: mapping.tandoor_ingredient_id,
            unit_id: unit_mapping.tandoor_unit_id,
            note,
            nutrition: food.nutrition.clone(),
            fatsecret_food_id: food.food_id,
            order: order as i32,
        }
    }

    /// Get or create ingredient mapping for a food
    fn get_or_create_ingredient_mapping(&self, food: &FatSecretMealFood) -> IngredientMapping {
        if let Some(mapping) = self.ingredient_mappings.get(&food.food_id) {
            mapping.clone()
        } else {
            IngredientMapping::unmapped(food.food_id, food.food_name.clone())
        }
    }

    /// Get or infer unit mapping for a serving
    fn get_or_infer_unit_mapping(&self, serving: &ImportServing) -> UnitMapping {
        // Check known mappings first
        if let Some(mapping) = self.unit_mappings.get(&serving.description) {
            return mapping.clone();
        }

        // Try to infer from serving description
        let inferred = self.infer_unit_from_serving(serving);

        UnitMapping {
            fatsecret_serving: serving.description.clone(),
            tandoor_unit_id: None,
            tandoor_unit_name: inferred.0,
            conversion_factor: inferred.1,
        }
    }

    /// Infer Tandoor unit from FatSecret serving description
    fn infer_unit_from_serving(&self, serving: &ImportServing) -> (String, f64) {
        let desc_lower = serving.description.to_lowercase();

        // Check for gram-based servings
        if desc_lower.contains("gram") || desc_lower.ends_with(" g") || desc_lower == "g" {
            if let Some(grams) = serving.metric_grams {
                return ("g".to_string(), grams);
            }
            return ("g".to_string(), 1.0);
        }

        // Check for common units
        if desc_lower.contains("cup") {
            return ("cup".to_string(), 1.0);
        }
        if desc_lower.contains("tablespoon") || desc_lower.contains("tbsp") {
            return ("tbsp".to_string(), 1.0);
        }
        if desc_lower.contains("teaspoon") || desc_lower.contains("tsp") {
            return ("tsp".to_string(), 1.0);
        }

        // Default: use description as-is
        (self.config.default_unit.clone(), serving.metric_grams.unwrap_or(1.0))
    }

    /// Build recipe name with prefix/suffix
    fn build_recipe_name(&self, base_name: &str) -> String {
        let mut name = base_name.to_string();

        if let Some(ref prefix) = self.config.recipe_name_prefix {
            name = format!("{} {}", prefix, name);
        }
        if let Some(ref suffix) = self.config.recipe_name_suffix {
            name = format!("{} {}", name, suffix);
        }

        name
    }

    /// Build default steps for imported recipe
    fn build_default_steps(&self, ingredients: &[ImportedIngredient]) -> Vec<ImportedStep> {
        if !self.config.import_instructions {
            return Vec::new();
        }

        let ingredient_list: Vec<String> = ingredients
            .iter()
            .map(|i| format!("{:.1} {} {}", i.amount, i.unit, i.name))
            .collect();

        vec![
            ImportedStep {
                instruction: format!(
                    "Combine the following ingredients:\n- {}",
                    ingredient_list.join("\n- ")
                ),
                order: 1,
                time: self.config.default_prep_time,
            },
        ]
    }

    /// Merge duplicate ingredients by name
    fn merge_duplicate_ingredients(&self, ingredients: Vec<ImportedIngredient>) -> Vec<ImportedIngredient> {
        let mut merged: HashMap<String, ImportedIngredient> = HashMap::new();

        for ingredient in ingredients {
            let key = ingredient.name.to_lowercase();

            if let Some(existing) = merged.get_mut(&key) {
                if existing.unit == ingredient.unit {
                    existing.amount += ingredient.amount;
                    existing.nutrition = existing.nutrition.add(&ingredient.nutrition);
                } else {
                    let new_key = format!("{} ({})", ingredient.name, ingredient.unit);
                    merged.insert(new_key, ingredient);
                }
            } else {
                merged.insert(key, ingredient);
            }
        }

        let mut result: Vec<ImportedIngredient> = merged.into_values().collect();
        result.sort_by_key(|i| i.order);

        for (idx, ingredient) in result.iter_mut().enumerate() {
            #[allow(clippy::cast_possible_truncation)]
            {
                ingredient.order = idx as i32;
            }
        }

        result
    }

    /// Build Tandoor API request body for recipe creation
    #[must_use]
    pub fn build_tandoor_request(&self, recipe: &ImportedRecipe) -> serde_json::Value {
        let mut request = serde_json::json!({
            "name": recipe.name,
            "servings": recipe.servings,
            "keywords": recipe.keywords.iter().map(|k| {
                serde_json::json!({"name": k})
            }).collect::<Vec<_>>(),
        });

        if let Some(ref desc) = recipe.description {
            request["description"] = serde_json::json!(desc);
        }
        if let Some(prep) = recipe.prep_time {
            request["working_time"] = serde_json::json!(prep);
        }
        if let Some(cook) = recipe.cook_time {
            request["waiting_time"] = serde_json::json!(cook);
        }

        // Add steps
        let steps: Vec<serde_json::Value> = recipe.steps.iter().map(|step| {
            let mut step_json = serde_json::json!({
                "instruction": step.instruction,
                "order": step.order,
            });

            if step.order == 1 {
                let ingredients: Vec<serde_json::Value> = recipe.ingredients.iter().map(|ing| {
                    let mut ing_json = serde_json::json!({
                        "amount": ing.amount,
                        "order": ing.order,
                    });

                    if let Some(id) = ing.ingredient_id {
                        ing_json["food"] = serde_json::json!({"id": id});
                    } else {
                        ing_json["food"] = serde_json::json!({"name": &ing.name});
                    }

                    if let Some(id) = ing.unit_id {
                        ing_json["unit"] = serde_json::json!({"id": id});
                    } else {
                        ing_json["unit"] = serde_json::json!({"name": &ing.unit});
                    }

                    if let Some(ref note) = ing.note {
                        ing_json["note"] = serde_json::json!(note);
                    }

                    ing_json
                }).collect();

                step_json["ingredients"] = serde_json::json!(ingredients);
            }

            step_json
        }).collect();

        request["steps"] = serde_json::json!(steps);

        // Add nutrition if configured
        if self.config.include_nutrition {
            let per_serving = recipe.nutrition_per_serving();
            request["nutrition"] = serde_json::json!({
                "calories": per_serving.calories,
                "proteins": per_serving.protein,
                "carbohydrates": per_serving.carbohydrate,
                "fats": per_serving.fat,
            });
        }

        request
    }

    /// Validate an imported recipe
    pub fn validate_recipe(&self, recipe: &ImportedRecipe) -> SyncResult<Vec<String>> {
        let mut warnings = Vec::new();

        if recipe.name.is_empty() {
            return Err(SyncError::validation("Recipe name cannot be empty"));
        }

        if recipe.ingredients.is_empty() {
            return Err(SyncError::validation("Recipe must have at least one ingredient"));
        }

        if recipe.ingredients.len() > self.config.max_ingredients {
            return Err(SyncError::validation(format!(
                "Recipe has too many ingredients ({} > {})",
                recipe.ingredients.len(),
                self.config.max_ingredients
            )));
        }

        let unmapped: Vec<&str> = recipe
            .ingredients
            .iter()
            .filter(|i| i.ingredient_id.is_none())
            .map(|i| i.name.as_str())
            .collect();

        if !unmapped.is_empty() && !self.config.create_missing_ingredients {
            return Err(SyncError::validation(format!(
                "The following ingredients are not mapped: {}",
                unmapped.join(", ")
            )));
        }

        if !unmapped.is_empty() {
            warnings.push(format!(
                "{} ingredient(s) will be created: {}",
                unmapped.len(),
                unmapped.join(", ")
            ));
        }

        Ok(warnings)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_meal_food() -> FatSecretMealFood {
        FatSecretMealFood {
            food_id: 123,
            food_name: "Chicken Breast".to_string(),
            brand_name: None,
            serving: ImportServing {
                description: "1 cup".to_string(),
                metric_grams: Some(240.0),
                calories: Some(150.0),
                protein: Some(10.0),
                carbohydrate: Some(20.0),
                fat: Some(5.0),
                fiber: Some(2.0),
            },
            number_of_servings: 2.0,
            nutrition: NutritionData::macros_only(300.0, 20.0, 10.0, 40.0),
        }
    }

    fn sample_meal() -> FatSecretMeal {
        FatSecretMeal {
            meal_id: Some(456),
            name: "My Lunch".to_string(),
            description: Some("A healthy lunch".to_string()),
            foods: vec![sample_meal_food()],
        }
    }

    #[test]
    fn test_import_config_default() {
        let config = ImportConfig::default();
        assert_eq!(config.default_servings, 1);
        assert!(config.include_nutrition);
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_import_config_strict() {
        let config = ImportConfig::strict();
        assert!((config.min_nutrition_completeness - 0.8).abs() < 1e-10);
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_ingredient_mapping_exact() {
        let mapping = IngredientMapping::exact(
            1, "Chicken".to_string(),
            100, "Chicken Breast".to_string(),
        );
        assert!(mapping.is_exact_match);
        assert!((mapping.confidence - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_ingredient_mapping_unmapped() {
        let mapping = IngredientMapping::unmapped(1, "New Ingredient".to_string());
        assert!(mapping.create_if_missing);
        assert!(mapping.tandoor_ingredient_id.is_none());
    }

    #[test]
    fn test_recipe_importer_new() {
        let config = ImportConfig::default();
        let importer = RecipeImporter::new(config);
        assert!(importer.ingredient_mappings.is_empty());
    }

    #[test]
    fn test_prepare_recipe_import() {
        let importer = RecipeImporter::with_defaults();
        let meal = sample_meal();

        let result = importer.prepare_recipe_import(&meal);
        assert!(result.is_ok());

        let recipe = result.expect("Should succeed");
        assert_eq!(recipe.name, "My Lunch");
        assert_eq!(recipe.ingredients.len(), 1);
    }

    #[test]
    fn test_prepare_recipe_import_empty_meal() {
        let importer = RecipeImporter::with_defaults();
        let meal = FatSecretMeal {
            meal_id: None,
            name: "Empty".to_string(),
            description: None,
            foods: vec![],
        };

        let result = importer.prepare_recipe_import(&meal);
        assert!(result.is_err());
    }

    #[test]
    fn test_nutrition_per_serving() {
        let recipe = ImportedRecipe {
            name: "Test".to_string(),
            description: None,
            servings: 2,
            prep_time: None,
            cook_time: None,
            ingredients: vec![],
            steps: vec![],
            nutrition: NutritionData::macros_only(400.0, 40.0, 10.0, 20.0),
            keywords: vec![],
            source: ImportSource::fatsecret(None),
            warnings: vec![],
        };

        let per_serving = recipe.nutrition_per_serving();
        assert!((per_serving.calories - 200.0).abs() < 1e-10);
        assert!((per_serving.protein - 20.0).abs() < 1e-10);
    }

    #[test]
    fn test_build_tandoor_request() {
        let importer = RecipeImporter::with_defaults();
        let meal = sample_meal();
        let recipe = importer.prepare_recipe_import(&meal).expect("Should succeed");

        let request = importer.build_tandoor_request(&recipe);

        assert_eq!(request["name"], "My Lunch");
        assert_eq!(request["servings"], 1);
    }

    #[test]
    fn test_validate_recipe() {
        let importer = RecipeImporter::with_defaults();
        let meal = sample_meal();
        let recipe = importer.prepare_recipe_import(&meal).expect("Should succeed");

        let result = importer.validate_recipe(&recipe);
        assert!(result.is_ok());
    }
}
