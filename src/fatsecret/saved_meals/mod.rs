//! `FatSecret` Saved Meals API domain
//!
//! This module provides functionality for managing meal templates in `FatSecret` Platform.
//! Saved meals are reusable meal combinations that users can quickly log to their
//! food diary, making nutrition tracking more efficient for frequently eaten meals.
//!
//! # Overview
//!
//! Saved meals (also called "meal templates") allow users to:
//! - Create meal combinations from foods or recipes
//! - Quickly log entire meals with a single API call
//! - Modify serving sizes when logging
//! - Maintain a library of favorite meal combinations
//!
//! # Use Cases
//!
//! ## Common Meal Patterns
//! - "Morning oatmeal with berries and nuts"
//! - "Post-workout protein shake with banana"
//! - "Standard lunch: sandwich, apple, chips"
//! - "Friday pizza night"
//!
//! ## Benefits
//! - **Speed**: Log complex meals in one API call vs multiple food entries
//! - **Consistency**: Ensure same nutritional profile each time
//! - **Flexibility**: Adjust portions when logging
//! - **Convenience**: Quick access to frequently eaten combinations
//!
//! # Key Types
//!
//! - [`SavedMeal`] - A meal template with items, default servings, and metadata
//! - [`SavedMealItem`] - Individual food/recipe item within a saved meal
//! - [`SavedMealId`] - Type-safe identifier for saved meals
//! - [`SavedMealItemId`] - Type-safe identifier for meal items
//! - [`SavedMealItemInput`] - Input for creating new meal items
//! - [MealType] - Breakfast, Lunch, Dinner, or Snack classification
//!
//! # API Functions
//!
//! ## Meal Management
//!
//! - [`client::get_saved_meals`] - List all saved meals with pagination
//! - [`client::get_saved_meal`] - Get details of a specific saved meal
//! - [`client::create_saved_meal`] - Create a new meal template
//! - [`client::delete_saved_meal`] - Remove a saved meal
//!
//! ## Meal Item Management
//!
//! - [`client::get_saved_meal_items`] - Get items within a saved meal
//! - [`client::create_saved_meal_item`] - Add item to existing meal
//! - [`client::delete_saved_meal_item`] - Remove item from meal
//!
//! ## Quick Logging
//!
//! - [`client::log_saved_meal`] - Log entire saved meal to food diary
//!   (This creates multiple food entries in one operation)
//!
//! # Authentication
//!
//! All operations require **3-legged OAuth** authentication with user authorization.
//! Users must have granted your app access to their diary data.
//!
//! # Date Handling
//!
//! When logging saved meals, dates use date_int format (days since Unix epoch).
//! Use helper functions from other modules for date conversion.
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::saved_meals::{
//!     create_saved_meal, create_saved_meal_item, get_saved_meals,
//!     SavedMealItemInput, MealType,
//! };
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::core::oauth::AccessToken;
//! use meal_planner::fatsecret::foods::FoodId;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let token = AccessToken::new("user_token", "user_secret");
//!
//! // Create a saved meal for "Morning Protein Shake"
//! let meal_id = create_saved_meal(
//!     &config,
//!     &token,
//!     "Morning Protein Shake".to_string(),
//!     MealType::Breakfast,
//! ).await?;
//!
//! // Add items to the meal
//! let protein_powder = SavedMealItemInput::FromFood {
//!     food_id: FoodId::new("12345"),
//!     serving_id: "67890".to_string(),
//!     number_of_units: 1.0,
//! };
//! create_saved_meal_item(&config, &token, &meal_id, protein_powder).await?;
//!
//! let banana = SavedMealItemInput::FromFood {
//!     food_id: FoodId::new("54321"),
//!     serving_id: "09876".to_string(),
//!     number_of_units: 1.0,
//! };
//! create_saved_meal_item(&config, &token, &meal_id, banana).await?;
//!
//! // List all saved meals
//! let meals = get_saved_meals(&config, &token, Some(20), None).await?;
//! for meal in meals.saved_meals {
//!     println!("{}: {} items", meal.saved_meal_name, meal.number_of_items);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Advanced Usage
//!
//! ## Customizing Portions When Logging
//!
//! Saved meals store default serving sizes, but you can adjust when logging:
//!
//! ```rust,no_run
//! # use meal_planner::fatsecret::saved_meals::log_saved_meal;
//! # use meal_planner::fatsecret::core::config::FatSecretConfig;
//! # use meal_planner::fatsecret::core::oauth::AccessToken;
//! # use meal_planner::fatsecret::saved_meals::SavedMealId;
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! # let config = FatSecretConfig::from_env()?;
//! # let token = AccessToken::new("user_token", "user_secret");
//! # let meal_id = SavedMealId::new("123");
//! // Log with double the protein powder
//! log_saved_meal(
//!     &config,
//!     &token,
//!     &meal_id,
//!     Some(19723),  // date_int for 2024-01-01
//!     Some(vec![
//!         ("12345", 2.0),  // Double protein powder (item_id, multiplier)
//!         ("54321", 1.0),  // Normal banana
//!     ]),
//! ).await?;
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All functions return `Result<T, FatSecretError>` with common errors:
//! - **AuthError**: Invalid OAuth token, expired credentials
//! - **ApiError**: Invalid meal/item ID, meal not found
//! - **ValidationError**: Invalid serving sizes, required fields missing
//! - **HttpError**: Network connectivity issues
//!
//! # Best Practices
//!
//! ## Meal Organization
//! - Use descriptive meal names ("Post-Workout Recovery Shake")
//! - Assign appropriate meal types for better organization
//! - Include common variations (e.g., with/without supplements)
//!
//! ## Serving Size Strategy
//! - Store realistic default portions
//! - Consider creating multiple versions for different portion sizes
//! - Document any preparation notes in the meal name
//!
//! ## Performance Considerations
//! - Use saved meals for frequently eaten combinations
//! - Consider batch operations when managing many items
//! - Cache meal definitions for UI applications
//!
//! # API Method Mapping
//!
//! This module maps to these `FatSecret` API methods:
//! - `saved_meals.get` - List saved meals
//! - `saved_meal.get` - Get specific meal
//! - `saved_meal.create` - Create new meal
//! - `saved_meal.delete` - Remove meal
//! - `saved_meal_items.get` - Get meal items
//! - `saved_meal_item.create` - Add item to meal
//! - `saved_meal_item.delete` - Remove item from meal
//! - `saved_meal.log` - Log meal to diary
//!
//! # See Also
//!
//! - [`client`] - HTTP client implementation
//! - [`types`] - Type definitions and validation
//! - [`fatsecret::foods`] - For food lookup when creating meals
//! - [`fatsecret::diary`] - For viewing logged meal entries

pub mod client;
pub mod types;

pub use client::*;
pub use types::*;
