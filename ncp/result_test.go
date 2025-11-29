package ncp

import (
	"testing"
	"time"
)

func TestReconciliationResult_Fields(t *testing.T) {
	result := ReconciliationResult{
		Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		AverageConsumed: NutritionData{
			Protein:  160.0,
			Fat:      55.0,
			Carbs:    220.0,
			Calories: 2050.0,
		},
		Goals: NutritionGoals{
			DailyProtein:  180.0,
			DailyFat:      60.0,
			DailyCarbs:    250.0,
			DailyCalories: 2500.0,
		},
		Deviation: DeviationResult{
			ProteinPct:  -11.1,
			FatPct:      -8.3,
			CarbsPct:    -12.0,
			CaloriesPct: -18.0,
		},
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Salmon", Score: 0.8},
			},
		},
		WithinTolerance: false,
	}

	if result.Date.Year() != 2024 {
		t.Errorf("Expected year 2024, got %d", result.Date.Year())
	}

	if result.AverageConsumed.Protein != 160.0 {
		t.Errorf("Expected protein 160.0, got %f", result.AverageConsumed.Protein)
	}

	if result.Goals.DailyProtein != 180.0 {
		t.Errorf("Expected goal protein 180.0, got %f", result.Goals.DailyProtein)
	}

	if result.WithinTolerance {
		t.Error("Expected WithinTolerance to be false")
	}

	if len(result.Plan.Suggestions) != 1 {
		t.Errorf("Expected 1 suggestion, got %d", len(result.Plan.Suggestions))
	}
}

func TestReconciliationResult_Empty(t *testing.T) {
	result := ReconciliationResult{}

	if !result.Date.IsZero() {
		t.Error("Expected zero date for empty result")
	}

	if result.WithinTolerance {
		t.Error("Expected WithinTolerance to be false for empty result")
	}
}
