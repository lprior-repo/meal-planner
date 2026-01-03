//! ATDD Layer 2: Domain Specific Language for recipe selection tests
//!
//! This shares the domain vocabulary used by the calorie-selection acceptance tests.
//!
//! Layer responsibilities:
//! - Tests speak in terms of recipes, calories, and warnings.
//! - This DSL remains implementation-agnostic and delegates to Layer 3 (Protocol Driver).
//! - The driver handles serialization, binary invocation, and I/O boundaries.

use crate::helpers::recipe_selection_driver::RecipeSelectionDriver;
use crate::helpers::recipe_selection_driver::RecipeSelectionDriverImpl;

use fastrand::Rng;

#[derive(Clone, Debug)]
struct RecipeRecord {
    id: u32,
    name: String,
    calories: u32,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RecipeSelectionItem {
    pub id: u32,
    pub name: String,
    pub calories: u32,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RecipeSelectionResult {
    pub recipes: Vec<RecipeSelectionItem>,
    pub total_calories: u32,
    pub warning: Option<String>,
}

impl RecipeSelectionResult {
    fn new(recipes: Vec<RecipeSelectionItem>, warning: Option<String>) -> Self {
        let total_calories = recipes.iter().map(|recipe| recipe.calories).sum();
        Self {
            recipes,
            total_calories,
            warning,
        }
    }
}

pub struct RecipeSelectionDSL {
    driver: RecipeSelectionDriver,
    recipes: Vec<RecipeRecord>,
    next_id: u32,
}

impl RecipeSelectionDSL {
    pub fn new() -> Self {
        Self {
            driver: RecipeSelectionDriver::in_memory(),
            recipes: Vec::new(),
            next_id: 1,
        }
    }

    pub fn with_driver(driver: RecipeSelectionDriver) -> Self {
        Self {
            driver,
            recipes: Vec::new(),
            next_id: 1,
        }
    }

    pub fn with_binary(path: impl Into<String>) -> Self {
        Self {
            driver: RecipeSelectionDriver::with_binary(path),
            recipes: Vec::new(),
            next_id: 1,
        }
    }

    pub fn with_mock(recipes: Vec<RecipeSelectionItem>) -> Self {
        Self {
            driver: RecipeSelectionDriver::with_mock(recipes),
            recipes: Vec::new(),
            next_id: 1,
        }
    }

    pub fn ensure_recipes_with_calories<N>(&mut self, entries: Vec<(u32, N)>)
    where
        N: AsRef<str>,
    {
        for (calories, name) in entries {
            self.recipes.push(RecipeRecord {
                id: self.next_id,
                name: name.as_ref().to_string(),
                calories,
            });
            self.next_id = self.next_id.saturating_add(1);
        }
    }

    pub fn select_recipes_by_calories(
        &mut self,
        target_calories: u32,
        tolerance: u32,
        count: usize,
    ) -> RecipeSelectionResult {
        let lower = target_calories.saturating_sub(tolerance);
        let upper = target_calories.saturating_add(tolerance);
        let mut matching: Vec<_> = self
            .recipes
            .iter()
            .cloned()
            .filter(|recipe| recipe.calories >= lower && recipe.calories <= upper)
            .collect();

        if matching.is_empty() || count == 0 {
            let warning = if matching.is_empty() {
                Some("no recipes found".to_string())
            } else {
                None
            };
            return RecipeSelectionResult::new(Vec::new(), warning);
        }

        let selected = if matching.len() <= count {
            matching
                .into_iter()
                .map(Self::record_to_item)
                .collect::<Vec<_>>()
        } else {
            matching.sort_by(|left, right| {
                let left_diff = (left.calories as i64 - target_calories as i64).abs();
                let right_diff = (right.calories as i64 - target_calories as i64).abs();
                left_diff
                    .cmp(&right_diff)
                    .then_with(|| left.name.cmp(&right.name))
            });

            let pool_limit = count.checked_mul(3).unwrap_or(count);
            let pool_size = pool_limit.min(matching.len());
            let mut pool = matching.into_iter().take(pool_size).collect::<Vec<_>>();
            self.rng.shuffle(&mut pool);
            pool.into_iter()
                .take(count)
                .map(Self::record_to_item)
                .collect::<Vec<_>>()
        };

        let warning = if selected.len() < count {
            Some(format!("only {} recipes found", selected.len()))
        } else {
            None
        };

        RecipeSelectionResult::new(selected, warning)
    }

    fn record_to_item(record: RecipeRecord) -> RecipeSelectionItem {
        RecipeSelectionItem {
            id: record.id,
            name: record.name,
            calories: record.calories,
        }
    }

    pub fn verify_recipe_count(&self, result: &RecipeSelectionResult, expected: usize) {
        assert_eq!(
            result.recipes.len(),
            expected,
            "expected {} recipes but selected {}",
            expected,
            result.recipes.len()
        );
    }

    pub fn verify_all_in_calorie_range(
        &self,
        result: &RecipeSelectionResult,
        target: u32,
        tolerance: u32,
    ) {
        let lower = target.saturating_sub(tolerance);
        let upper = target.saturating_add(tolerance);
        for recipe in &result.recipes {
            assert!(
                recipe.calories >= lower && recipe.calories <= upper,
                "recipe {} calorie {} outside of range {}-{}",
                recipe.name,
                recipe.calories,
                lower,
                upper
            );
        }
    }

    pub fn verify_total_calories_close_to(
        &self,
        result: &RecipeSelectionResult,
        expected_total: u32,
        tolerance: u32,
    ) {
        let difference = result.total_calories.abs_diff(expected_total);
        assert!(
            difference <= tolerance,
            "total calories {} differs from expected {} by more than {}",
            result.total_calories,
            expected_total,
            tolerance
        );
    }

    pub fn verify_warning_contains(&self, result: &RecipeSelectionResult, expected: &str) {
        let warning = result.warning.as_deref().unwrap_or_default();
        assert!(
            warning.contains(expected),
            "expected warning containing {:?}, got {:?}",
            expected,
            warning
        );
    }

    pub fn verify_different_selections(
        &self,
        first: &RecipeSelectionResult,
        second: &RecipeSelectionResult,
    ) {
        assert_ne!(
            first.recipes,
            second.recipes,
            "two sequential selections returned identical recipes"
        );
    }
}
