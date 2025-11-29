package ncp

// RecipeSuggestion represents a recommended recipe to address nutritional deviation
type RecipeSuggestion struct {
	RecipeName string  `json:"recipe_name"`
	Reason     string  `json:"reason"`
	Score      float64 `json:"score"` // 0.0-1.0, higher is better match
}

// AdjustmentPlan contains recipe suggestions to correct nutritional deviations
type AdjustmentPlan struct {
	Deviation   DeviationResult    `json:"deviation"`
	Suggestions []RecipeSuggestion `json:"suggestions"`
}
