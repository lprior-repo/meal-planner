package ncp

// AverageNutritionHistory calculates the average nutrition across a history of states
func AverageNutritionHistory(history []NutritionState) NutritionData {
	if len(history) == 0 {
		return NutritionData{}
	}

	var total NutritionData
	for _, state := range history {
		total.Protein += state.Consumed.Protein
		total.Fat += state.Consumed.Fat
		total.Carbs += state.Consumed.Carbs
		total.Calories += state.Consumed.Calories
	}

	n := float64(len(history))
	return NutritionData{
		Protein:  total.Protein / n,
		Fat:      total.Fat / n,
		Carbs:    total.Carbs / n,
		Calories: total.Calories / n,
	}
}
