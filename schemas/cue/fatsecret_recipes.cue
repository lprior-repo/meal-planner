// FatSecret Recipes Domain Binary Contracts
// Binaries: recipes_search, recipe_get, recipe_types_get,
//           recipes_get_favorites, recipe_add_favorite, recipe_delete_favorite

package mealplanner

// =============================================================================
// fatsecret_recipes_search
// Search the FatSecret recipe database
// OAuth: 2-legged (no user token required)
// =============================================================================

#RecipesSearchInput: {
	#FatSecret2LeggedInput
	search_expression: string & !=""  // e.g., "chicken soup"
	max_results?:      int & >=1 & <=50
	page_number?:      int & >=0
	recipe_type?:      string  // filter by recipe type
}

#RecipesSearchOutput: {
	success: true
	recipes: _  // search results with pagination
} | #ErrorOutput

// =============================================================================
// fatsecret_recipe_get
// Get detailed recipe information by ID
// OAuth: 2-legged (no user token required)
// =============================================================================

#RecipeGetInput: {
	#FatSecret2LeggedInput
	recipe_id: #RecipeId
}

#RecipeGetOutput: {
	success: true
	recipe:  _  // Recipe object with ingredients, directions, nutrition
} | #ErrorOutput

// =============================================================================
// fatsecret_recipe_types_get
// Get all available recipe types/categories
// OAuth: 2-legged (no user token required)
// =============================================================================

#RecipeTypesGetInput: {
	#FatSecret2LeggedInput
}

#RecipeTypesGetOutput: {
	success:      true
	recipe_types: [..._]  // array of recipe type objects
} | #ErrorOutput

// =============================================================================
// fatsecret_recipes_get_favorites
// Get user's favorite recipes
// OAuth: 3-legged (requires user access token)
// =============================================================================

#RecipesGetFavoritesInput: {
	#FatSecret3LeggedInput
	max_results?: int & >=1 & <=50
	page_number?: int & >=0
}

#RecipesGetFavoritesOutput: {
	success: true
	recipes: [..._]  // array of favorite recipe objects
} | #ErrorOutput

// =============================================================================
// fatsecret_recipe_add_favorite
// Add a recipe to user's favorites
// OAuth: 3-legged (requires user access token)
// =============================================================================

#RecipeAddFavoriteInput: {
	#FatSecret3LeggedInput
	recipe_id: #RecipeId
}

#RecipeAddFavoriteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_recipe_delete_favorite
// Remove a recipe from user's favorites
// OAuth: 3-legged (requires user access token)
// =============================================================================

#RecipeDeleteFavoriteInput: {
	#FatSecret3LeggedInput
	recipe_id: #RecipeId
}

#RecipeDeleteFavoriteOutput: {
	success: true
} | #ErrorOutput
