package ncp

import "math"

// RecipeMacros represents the nutritional macros of a recipe
type RecipeMacros struct {
	Protein  float64 `json:"protein"`
	Fat      float64 `json:"fat"`
	Carbs    float64 `json:"carbs"`
	Calories float64 `json:"calories"`
}

// ScoreRecipeForDeviation calculates how well a recipe addresses a nutritional deviation.
// Returns a score from 0.0 to 1.0, where higher scores indicate better fit.
// Prioritizes protein, then considers overall macro balance.
func ScoreRecipeForDeviation(deviation DeviationResult, macros RecipeMacros) float64 {
	// If no deviation, any food has low value
	totalDeviation := math.Abs(deviation.ProteinPct) + math.Abs(deviation.FatPct) + math.Abs(deviation.CarbsPct)
	if totalDeviation < 5.0 {
		return 0.1
	}

	// If over on all macros, adding food is bad
	if deviation.ProteinPct > 0 && deviation.FatPct > 0 && deviation.CarbsPct > 0 {
		return 0.1
	}

	var score float64

	// Protein is prioritized (weight: 0.5)
	if deviation.ProteinPct < 0 && macros.Protein > 0 {
		// Recipe helps address protein deficit
		proteinScore := math.Min(macros.Protein/40.0, 1.0) // Normalize: 40g protein = max score
		score += 0.5 * proteinScore
	}

	// Fat contribution (weight: 0.25)
	if deviation.FatPct < 0 && macros.Fat > 0 {
		fatScore := math.Min(macros.Fat/25.0, 1.0) // Normalize: 25g fat = max score
		score += 0.25 * fatScore
	} else if deviation.FatPct > 10 && macros.Fat > 20 {
		// Penalize high fat when already over
		score -= 0.1
	}

	// Carbs contribution (weight: 0.25)
	if deviation.CarbsPct < 0 && macros.Carbs > 0 {
		carbsScore := math.Min(macros.Carbs/50.0, 1.0) // Normalize: 50g carbs = max score
		score += 0.25 * carbsScore
	} else if deviation.CarbsPct > 10 && macros.Carbs > 30 {
		// Penalize high carbs when already over
		score -= 0.1
	}

	// Clamp to valid range
	if score < 0 {
		score = 0
	}
	if score > 1.0 {
		score = 1.0
	}

	return score
}
