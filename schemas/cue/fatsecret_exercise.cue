// FatSecret Exercise Domain Binary Contracts
// Binaries: exercise_entries_get, exercise_entry_create, exercise_entry_edit,
//           exercise_entry_delete, exercise_month_summary

package mealplanner

// =============================================================================
// fatsecret_exercise_entries_get
// Get all exercise entries for a specific date
// OAuth: 3-legged (requires user access token)
// =============================================================================

#ExerciseEntriesGetInput: {
	#FatSecret3LeggedInput
	date_int: #DateInt  // days since Unix epoch
}

#ExerciseEntriesGetOutput: {
	success: true
	entries: [..._]  // array of ExerciseEntry objects
} | #ErrorOutput

// =============================================================================
// fatsecret_exercise_entry_create
// Create a new exercise entry
// OAuth: 3-legged (requires user access token)
// =============================================================================

#ExerciseEntryCreateInput: {
	#FatSecret3LeggedInput
	exercise_id:  #ExerciseId    // exercise type ID
	duration_min: int & >0       // duration in minutes
	date_int:     #DateInt       // entry date
}

#ExerciseEntryCreateOutput: {
	success:           true
	exercise_entry_id: #ExerciseEntryId
} | #ErrorOutput

// =============================================================================
// fatsecret_exercise_entry_edit
// Edit an existing exercise entry
// OAuth: 3-legged (requires user access token)
// At least one of exercise_id or duration_min should be provided
// =============================================================================

#ExerciseEntryEditInput: {
	#FatSecret3LeggedInput
	exercise_entry_id: #ExerciseEntryId
	exercise_id?:      #ExerciseId
	duration_min?:     int & >0
}

#ExerciseEntryEditOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_exercise_entry_delete
// Delete an exercise entry
// OAuth: 3-legged (requires user access token)
// =============================================================================

#ExerciseEntryDeleteInput: {
	#FatSecret3LeggedInput
	exercise_entry_id: #ExerciseEntryId
}

#ExerciseEntryDeleteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_exercise_month_summary
// Get exercise summary for an entire month
// OAuth: 3-legged (requires user access token)
// =============================================================================

#ExerciseMonthSummaryInput: {
	#FatSecret3LeggedInput
	year:  int & >=2000 & <=2100
	month: int & >=1 & <=12
}

#ExerciseMonthSummaryOutput: {
	success:       true
	month_summary: _  // monthly exercise summary
} | #ErrorOutput

// =============================================================================
// EXERCISE ENTRY OBJECT SCHEMA
// =============================================================================

#ExerciseEntry: {
	exercise_entry_id: #ExerciseEntryId
	exercise_id:       #ExerciseId
	exercise_name:     string
	duration_min:      int
	calories:          number
	date_int:          #DateInt
	...
}
