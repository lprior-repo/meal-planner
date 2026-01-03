//! ATDD Layer 3: Protocol Driver for recipe selection
//!
//! This module provides the protocol driver that translates between the DSL layer
//! and the binary interface. It handles:
//! - Serialization/deserialization of requests/responses
//! - Binary invocation (or mocking for testing)
//! - Swappable implementations for testing vs production
//!
//! Layer 3 responsibilities:
//! - Translate DSL inputs to binary format
//! - Manage I/O boundaries
//! - Handle serialization/deserialization
//! - Support both real binary and mock implementations

use crate::helpers::recipe_selection_dsl::{RecipeSelectionItem, RecipeSelectionResult};
use std::io::Write;
use std::process::{Command, Stdio};

#[derive(Debug, Clone, serde::Serialize)]
pub struct RecipeSelectionRequest {
    pub target_calories: u32,
    pub tolerance: u32,
    pub count: usize,
    pub recipes: Vec<RecipeSelectionItem>,
}

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct RecipeSelectionResponse {
    pub recipes: Vec<RecipeSelectionItem>,
    pub total_calories: u32,
    pub warning: Option<String>,
}

#[derive(Debug, Clone)]
pub enum RecipeSelectionDriverImpl {
    Binary { path: String },
    Mock(Vec<RecipeSelectionItem>),
    InMemory,
}

impl Default for RecipeSelectionDriverImpl {
    fn default() -> Self {
        Self::InMemory
    }
}

pub struct RecipeSelectionDriver {
    implementation: RecipeSelectionDriverImpl,
}

impl RecipeSelectionDriver {
    pub fn new(implementation: RecipeSelectionDriverImpl) -> Self {
        Self { implementation }
    }

    pub fn with_binary(path: impl Into<String>) -> Self {
        Self {
            implementation: RecipeSelectionDriverImpl::Binary {
                path: path.into(),
            },
        }
    }

    pub fn with_mock(recipes: Vec<RecipeSelectionItem>) -> Self {
        Self {
            implementation: RecipeSelectionDriverImpl::Mock(recipes),
        }
    }

    pub fn in_memory() -> Self {
        Self {
            implementation: RecipeSelectionDriverImpl::InMemory,
        }
    }

    pub fn select_recipes(
        &self,
        target_calories: u32,
        tolerance: u32,
        count: usize,
        recipes: &[RecipeSelectionItem],
    ) -> RecipeSelectionResult {
        match &self.implementation {
            RecipeSelectionDriverImpl::Binary { path } => {
                self.call_binary(path, target_calories, tolerance, count, recipes)
            }
            RecipeSelectionDriverImpl::Mock(mock_recipes) => {
                self.run_mock(mock_recipes, target_calories, tolerance, count)
            }
            RecipeSelectionDriverImpl::InMemory => {
                self.run_in_memory(recipes, target_calories, tolerance, count)
            }
        }
    }

    fn call_binary(
        &self,
        path: &str,
        target_calories: u32,
        tolerance: u32,
        count: usize,
        recipes: &[RecipeSelectionItem],
    ) -> RecipeSelectionResult {
        let request = RecipeSelectionRequest {
            target_calories,
            tolerance,
            count,
            recipes: recipes.to_vec(),
        };

        let request_json = match serde_json::to_string(&request) {
            Ok(json) => json,
            Err(e) => {
                return RecipeSelectionResult::new(
                    Vec::new(),
                    Some(format!("serialization error: {}", e)),
                );
            }
        };

        let mut child = match Command::new(path)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
        {
            Ok(child) => child,
            Err(e) => {
                return RecipeSelectionResult::new(
                    Vec::new(),
                    Some(format!("failed to spawn binary: {}", e)),
                );
            }
        };

        {
            let stdin = child.stdin.as_mut().expect("stdin should exist");
            if let Err(e) = stdin.write_all(request_json.as_bytes()) {
                return RecipeSelectionResult::new(
                    Vec::new(),
                    Some(format!("failed to write to stdin: {}", e)),
                );
            }
        }

        let output = match child.wait_with_output() {
            Ok(output) => output,
            Err(e) => {
                return RecipeSelectionResult::new(
                    Vec::new(),
                    Some(format!("failed to read output: {}", e)),
                );
            }
        };

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return RecipeSelectionResult::new(
                Vec::new(),
                Some(format!("binary failed: {}", stderr)),
            );
        }

        let response_json = String::from_utf8_lossy(&output.stdout);
        match serde_json::from_str::<RecipeSelectionResponse>(&response_json) {
            Ok(response) => RecipeSelectionResult {
                recipes: response.recipes,
                total_calories: response.total_calories,
                warning: response.warning,
            },
            Err(e) => RecipeSelectionResult::new(
                Vec::new(),
                Some(format!("deserialization error: {}", e)),
            ),
        }
    }

    fn run_mock(
        &self,
        mock_recipes: &[RecipeSelectionItem],
        target_calories: u32,
        tolerance: u32,
        count: usize,
    ) -> RecipeSelectionResult {
        self.run_in_memory(mock_recipes, target_calories, tolerance, count)
    }

    fn run_in_memory(
        &self,
        recipes: &[RecipeSelectionItem],
        target_calories: u32,
        tolerance: u32,
        count: usize,
    ) -> RecipeSelectionResult {
        let lower = target_calories.saturating_sub(tolerance);
        let upper = target_calories.saturating_add(tolerance);
        let mut matching: Vec<_> = recipes
            .iter()
            .filter(|recipe| recipe.calories >= lower && recipe.calories <= upper)
            .cloned()
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
            fastrand::Rng::new().shuffle(&mut pool);
            pool.into_iter().take(count).collect()
        };

        let warning = if selected.len() < count {
            Some(format!("only {} recipes found", selected.len()))
        } else {
            None
        };

        let total_calories = selected.iter().map(|recipe| recipe.calories).sum();
        RecipeSelectionResult {
            recipes: selected,
            total_calories,
            warning,
        }
    }
}

impl Default for RecipeSelectionDriver {
    fn default() -> Self {
        Self::in_memory()
    }
}
