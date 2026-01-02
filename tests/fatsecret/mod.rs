/* FatSecret integration tests module
 *
 * Run with: cargo test --test fatsecret_food_tests
 */

pub mod food_id_tests;
pub mod food_deserialization_tests;
pub mod serving_tests;
pub mod search_response_tests;
pub mod autocomplete_tests;
pub mod nutrition_tests;

pub mod fatsecret_binary_existence_tests;
pub mod fatsecret_error_handling_tests;
pub mod fatsecret_api_validation_tests;

pub mod fatsecret_profile_tests;
pub mod fatsecret_most_eaten_tests;
pub mod fatsecret_recently_eaten_tests;
pub mod fatsecret_weight_binary_tests;
pub mod fatsecret_saved_meals_binary_tests;
pub mod fatsecret_recipe_binary_tests;
pub mod fatsecret_recipe_favorites_tests;
pub mod fatsecret_recipe_types_tests;

#[path = "../common.rs"]
pub mod common;
