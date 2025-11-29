package ncp

// GenerateAdjustments creates an adjustment plan based on deviation and available recipes
// It scores recipes against the deviation and returns the top suggestions
func GenerateAdjustments(deviation DeviationResult, recipes []ScoredRecipe, limit int) AdjustmentPlan {
	suggestions := SelectTopRecipes(deviation, recipes, limit)

	return AdjustmentPlan{
		Deviation:   deviation,
		Suggestions: suggestions,
	}
}
