pub mod client;
pub mod types;

pub use client::{
    autocomplete_foods, autocomplete_foods_with_options, find_food_by_barcode, get_food,
    list_foods_with_options, search_foods, search_foods_simple,
};
pub use types::{
    Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse, FoodSearchResult, FoodSuggestion,
    Nutrition, Serving, ServingId,
};
