//! FatSecret Food Diary API
//!
//! 3-legged OAuth authenticated API calls for food diary management.
//! All operations require user OAuth access token.

mod client;
mod types;

pub use client::{
    commit_day, copy_entries, copy_meal, create_food_entry, delete_food_entry, edit_food_entry,
    get_food_entries, get_food_entry, get_month_summary, save_template,
};
pub use types::{
    DaySummary, FoodEntry, FoodEntryId, FoodEntryInput, FoodEntryUpdate, MealType, MonthSummary,
};
