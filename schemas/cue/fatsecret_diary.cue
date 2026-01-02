// FatSecret Diary Domain Binary Contracts
// Binaries: food_entries_get, food_entries_get_month, food_entry_create,
//           food_entry_edit, food_entry_delete

package mealplanner

// =============================================================================
// fatsecret_food_entries_get
// Get all food diary entries for a specific date
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodEntriesGetInput: {
	#FatSecret3LeggedInput
	date_int: #DateInt  // days since Unix epoch
}

#FoodEntriesGetOutput: {
	success: true
	entries: _  // array of FoodEntry objects
} | #ErrorOutput

// =============================================================================
// fatsecret_food_entries_get_month
// Get food diary summary for an entire month
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodEntriesGetMonthInput: {
	#FatSecret3LeggedInput
	date_int: #DateInt  // any day in the target month
}

#FoodEntriesGetMonthOutput: {
	success: true
	month:   _  // month summary with daily totals
} | #ErrorOutput

// =============================================================================
// fatsecret_food_entry_create
// Create a new food diary entry
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodEntryCreateInput: {
	#FatSecret3LeggedInput
	food_id:         #FoodId         // from FatSecret database
	food_entry_name: string & !=""   // display name
	serving_id:      #ServingId      // serving size ID
	number_of_units: number & >0     // servings consumed
	meal:            #MealType       // meal type
	date_int:        #DateInt        // entry date
}

#FoodEntryCreateOutput: {
	success:       true
	food_entry_id: #FoodEntryId
} | #ErrorOutput

// =============================================================================
// fatsecret_food_entry_edit
// Edit an existing food diary entry
// OAuth: 3-legged (requires user access token)
// At least one of number_of_units or meal must be provided
// =============================================================================

#FoodEntryEditInput: {
	#FatSecret3LeggedInput
	food_entry_id:    #FoodEntryId
	number_of_units?: number & >0
	meal?:            #MealType
}

#FoodEntryEditOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_food_entry_delete
// Delete a food diary entry
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodEntryDeleteInput: {
	#FatSecret3LeggedInput
	food_entry_id: #FoodEntryId
}

#FoodEntryDeleteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// FOOD ENTRY OBJECT SCHEMA
// Returned in entries arrays
// =============================================================================

#FoodEntry: {
	food_entry_id:       #FoodEntryId
	food_entry_name:     string
	food_id:             #FoodId
	serving_id:          #ServingId
	number_of_units:     number
	meal:                #MealType
	date_int:            #DateInt
	calories:            number
	carbohydrate:        number
	protein:             number
	fat:                 number
	serving_description: string
	...
}
