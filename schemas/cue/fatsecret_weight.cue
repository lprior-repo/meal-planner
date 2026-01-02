// FatSecret Weight Domain Binary Contracts
// Binaries: weight_update, weight_month_summary

package mealplanner

// =============================================================================
// fatsecret_weight_update
// Update user's weight entry for a date
// OAuth: 3-legged (requires user access token)
// =============================================================================

#WeightUpdateInput: {
	#FatSecret3LeggedInput
	current_weight_kg: number & >0    // weight in kilograms
	date_int:          #DateInt       // entry date
	goal_weight_kg?:   number & >0    // optional goal weight
	height_cm?:        number & >0    // optional height in cm
	comment?:          string         // optional comment
}

#WeightUpdateOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_weight_month_summary
// Get weight summary for an entire month
// OAuth: 3-legged (requires user access token)
// =============================================================================

#WeightMonthSummaryInput: {
	#FatSecret3LeggedInput
	date_int: #DateInt  // any day in the target month
}

#WeightMonthSummaryOutput: {
	success:       true
	month_summary: _  // monthly weight summary with entries
} | #ErrorOutput

// =============================================================================
// WEIGHT ENTRY OBJECT SCHEMA
// =============================================================================

#WeightEntry: {
	date_int:          #DateInt
	weight_kg:         number
	weight_comment?:   string
	goal_weight_kg?:   number
	height_cm?:        number
	...
}
