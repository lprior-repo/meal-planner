//! Add recipe to shopping list
//!
//! Adds all ingredients from a recipe to shopping list for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "recipe_id": 456, "servings": 4.0}`
//!
//! JSON stdout: `{"success": true, "entries": [...]}`
//!
//! # Architecture: Functional Core / Imperative Shell
//!
//! ## Functional Core (src/tandoor/shopping/mod.rs)
//! Pure functions with no I/O:
//! - `parse_input()` - JSON parsing
//! - `validate_input()` - Input validation
//! - `format_success()` - Success output formatting
//! - `format_error()` - Error output formatting
//!
//! ## Imperative Shell (this file)
//! All I/O operations:
//! - `read_stdin()` / `read_cli_arg()` - Input reading
//! - `write_stdout()` - Output writing
//! - `create_client()` - HTTP client creation
//! - `call_api()` - API calls

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::shopping::{
    format_error, format_success, parse_input, validate_input, AddRecipeInput, AddRecipeOutput,
};
use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use std::io::{self, Read};

/// Read input from stdin
///
/// # Function Size: 6 lines (≤25 ✓)
fn read_stdin() -> Result<String, String> {
    let mut s = String::new();
    io::stdin()
        .read_to_string(&mut s)
        .map_err(|e| e.to_string())?;
    Ok(s)
}

/// Read input from CLI argument
///
/// # Function Size: 2 lines (≤25 ✓)
fn read_cli_arg() -> Option<String> {
    std::env::args().nth(1)
}

/// Write output to stdout
///
/// # Function Size: 5 lines (≤25 ✓)
fn write_stdout(output: &AddRecipeOutput) {
    let json = serde_json::to_string(output).expect("Failed to serialize output JSON");
    println!("{}", json);
}

/// Create Tandoor HTTP client
///
/// # Function Size: 3 lines (≤25 ✓)
fn create_client(config: &TandoorConfig) -> Result<TandoorClient, String> {
    TandoorClient::new(config).map_err(|e| e.to_string())
}

/// Call Tandoor API to add recipe to shopping list
///
/// # Function Size: 4 lines (≤25 ✓)
fn call_api(
    client: &TandoorClient,
    mealplan_id: i64,
    recipe_id: i64,
    servings: f64,
) -> Result<Vec<meal_planner::tandoor::ShoppingListRecipe>, String> {
    client
        .add_recipe_to_shopping_list(mealplan_id, recipe_id, servings)
        .map_err(|e| e.to_string())
}

/// Convert core Input to TandoorConfig
///
/// # Function Size: 3 lines (≤25 ✓)
fn to_tandoor_config(input: &AddRecipeInput) -> TandoorConfig {
    TandoorConfig {
        base_url: input.tandoor.base_url.clone(),
        api_token: input.tandoor.api_token.clone(),
    }
}

/// Read input (CLI or stdin)
///
/// # Function Size: 7 lines (≤25 ✓)
fn read_input() -> Result<String, String> {
    match read_cli_arg() {
        Some(arg) => Ok(arg),
        None => read_stdin(),
    }
}

/// Main execution flow (imperative shell)
///
/// # Function Size: 18 lines (≤25 ✓)
fn run() -> AddRecipeOutput {
    let input_str = match read_input() {
        Ok(s) => s,
        Err(e) => return format_error(&e),
    };

    let input = match parse_input(&input_str) {
        Ok(i) => i,
        Err(e) => return format_error(&e),
    };

    if let Err(e) = validate_input(&input) {
        return format_error(&e);
    }

    let config = to_tandoor_config(&input);
    let client = match create_client(&config) {
        Ok(c) => c,
        Err(e) => return format_error(&e),
    };

    match call_api(&client, input.mealplan_id, input.recipe_id, input.servings) {
        Ok(entries) => format_success(&entries),
        Err(e) => format_error(&e),
    }
}

fn main() {
    let output = run();
    write_stdout(&output);
    if !output.success {
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use meal_planner::tandoor::shopping::{AddRecipeInput, TandoorConfigInput};

    #[test]
    fn test_read_cli_arg_returns_none() {
        let result = read_cli_arg();
        assert!(result.is_none() || result.unwrap().is_empty());
    }

    #[test]
    fn test_to_tandoor_config() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost:8080".to_string(),
                api_token: "test_token".to_string(),
            },
            mealplan_id: 1,
            recipe_id: 2,
            servings: 4.0,
        };
        let config = to_tandoor_config(&input);
        assert_eq!(config.base_url, "http://localhost:8080");
        assert_eq!(config.api_token, "test_token");
    }

    #[test]
    fn test_write_stdout_does_not_panic() {
        let output = AddRecipeOutput {
            success: true,
            entries: None,
            error: None,
        };
        write_stdout(&output);
    }
}
