package ncp

import (
	"math"
	"sort"
)

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


// ScoredRecipe represents a recipe with its nutritional macros for scoring
type ScoredRecipe struct {
	Name   string       `json:"name"`
	Macros RecipeMacros `json:"macros"`
}

// SelectTopRecipes scores recipes against a deviation and returns the top N by score
func SelectTopRecipes(deviation DeviationResult, recipes []ScoredRecipe, limit int) []RecipeSuggestion {
	if len(recipes) == 0 {
		return []RecipeSuggestion{}
	}

	// Score all recipes
	type scoredItem struct {
		recipe ScoredRecipe
		score  float64
	}
	scored := make([]scoredItem, len(recipes))
	for i, r := range recipes {
		scored[i] = scoredItem{
			recipe: r,
			score:  ScoreRecipeForDeviation(deviation, r.Macros),
		}
	}

	// Sort by score descending
	sort.Slice(scored, func(i, j int) bool {
		return scored[i].score > scored[j].score
	})

	// Take top N
	if limit > len(scored) {
		limit = len(scored)
	}

	suggestions := make([]RecipeSuggestion, limit)
	for i := 0; i < limit; i++ {
		suggestions[i] = RecipeSuggestion{
			RecipeName: scored[i].recipe.Name,
			Reason:     generateReason(deviation, scored[i].recipe.Macros),
			Score:      scored[i].score,
		}
	}

	return suggestions
}

// generateReason creates a human-readable reason for the suggestion
func generateReason(deviation DeviationResult, macros RecipeMacros) string {
	if deviation.ProteinPct < -10 && macros.Protein > 20 {
		return "High protein to address deficit"
	}
	if deviation.CarbsPct < -10 && macros.Carbs > 30 {
		return "Good carbs to address deficit"
	}
	if deviation.FatPct < -10 && macros.Fat > 15 {
		return "Healthy fats to address deficit"
	}
	return "Balanced macros"
}
