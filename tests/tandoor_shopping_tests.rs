#![allow(clippy::indexing_slicing)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::option_if_let_else)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
//! Shopping list tests for Tandoor API client
//!
//! Tests shopping list entry CRUD operations and recipe additions.
//!
//! This module includes focused test modules:
//! - tests::tandoor::shopping_list_entry_tests
//! - tests::tandoor::shopping_list_recipe_tests

#[cfg(test)]
mod tandoor {
    pub mod shopping_list_entry_tests;
    pub mod shopping_list_recipe_tests;
}
