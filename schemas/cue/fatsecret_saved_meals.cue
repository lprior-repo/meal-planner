// FatSecret Saved Meals Domain Binary Contracts
// Binaries: saved_meals_get, saved_meals_get_items, saved_meals_create,
//           saved_meals_edit, saved_meals_delete

package mealplanner

// =============================================================================
// fatsecret_saved_meals_get
// Get user's saved meal templates
// OAuth: 3-legged (requires user access token)
// =============================================================================

#SavedMealsGetInput: {
	#FatSecret3LeggedInput
	meal?: #MealType  // optional filter by meal type
}

#SavedMealsGetOutput: {
	success:     true
	saved_meals: [..._]  // array of saved meal objects
} | #ErrorOutput

// =============================================================================
// fatsecret_saved_meals_get_items
// Get items (foods) in a saved meal
// OAuth: 3-legged (requires user access token)
// =============================================================================

#SavedMealsGetItemsInput: {
	#FatSecret3LeggedInput
	saved_meal_id: #SavedMealId
}

#SavedMealsGetItemsOutput: {
	success: true
	items:   [..._]  // array of food items in the saved meal
} | #ErrorOutput

// =============================================================================
// fatsecret_saved_meals_create
// Create a new saved meal template
// OAuth: 3-legged (requires user access token)
// =============================================================================

#SavedMealsCreateInput: {
	#FatSecret3LeggedInput
	saved_meal_name:        string & !=""
	saved_meal_description?: string
	meals:                  string  // comma-separated: "breakfast,lunch,dinner,other"
}

#SavedMealsCreateOutput: {
	success:       true
	saved_meal_id: #SavedMealId
} | #ErrorOutput

// =============================================================================
// fatsecret_saved_meals_edit
// Edit an existing saved meal template
// OAuth: 3-legged (requires user access token)
// All fields except credentials and ID are optional
// =============================================================================

#SavedMealsEditInput: {
	#FatSecret3LeggedInput
	saved_meal_id:          #SavedMealId
	saved_meal_name?:        string & !=""
	saved_meal_description?: string
	meals?:                  string  // comma-separated
}

#SavedMealsEditOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_saved_meals_delete
// Delete a saved meal template
// OAuth: 3-legged (requires user access token)
// =============================================================================

#SavedMealsDeleteInput: {
	#FatSecret3LeggedInput
	saved_meal_id: #SavedMealId
}

#SavedMealsDeleteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// SAVED MEAL OBJECT SCHEMA
// =============================================================================

#SavedMeal: {
	saved_meal_id:          #SavedMealId
	saved_meal_name:        string
	saved_meal_description: string
	meals:                  string  // comma-separated meal types
	...
}
