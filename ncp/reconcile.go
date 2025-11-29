package ncp

import "time"

// RunReconciliation performs the full nutrition reconciliation flow:
// 1. Calculates average consumption from history
// 2. Computes deviation from goals
// 3. Generates recipe suggestions to address deviations
// 4. Returns comprehensive result
func RunReconciliation(
	history []NutritionState,
	goals NutritionGoals,
	recipes []ScoredRecipe,
	tolerancePct float64,
	suggestionLimit int,
) ReconciliationResult {
	// Calculate average consumption
	avgConsumed := AverageNutritionHistory(history)

	// Calculate deviation from goals
	deviation := CalculateDeviation(goals, avgConsumed)

	// Check if within tolerance
	withinTolerance := deviation.IsWithinTolerance(tolerancePct)

	// Generate adjustment plan
	plan := GenerateAdjustments(deviation, recipes, suggestionLimit)

	return ReconciliationResult{
		Date:            time.Now(),
		AverageConsumed: avgConsumed,
		Goals:           goals,
		Deviation:       deviation,
		Plan:            plan,
		WithinTolerance: withinTolerance,
	}
}
