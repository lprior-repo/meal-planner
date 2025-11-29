package ncp

import (
	"testing"
	"time"
)

func TestRunReconciliation_Basic(t *testing.T) {
	// Set up test data
	history := []NutritionState{
		{
			Date: time.Date(2024, 11, 27, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  140.0,
				Fat:      50.0,
				Carbs:    200.0,
				Calories: 1900.0,
			},
		},
		{
			Date: time.Date(2024, 11, 28, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  160.0,
				Fat:      55.0,
				Carbs:    220.0,
				Calories: 2100.0,
			},
		},
	}

	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2500.0,
	}

	recipes := []ScoredRecipe{
		{Name: "Grilled Chicken", Macros: RecipeMacros{Protein: 45, Fat: 8, Carbs: 2, Calories: 260}},
		{Name: "Salmon Fillet", Macros: RecipeMacros{Protein: 40, Fat: 20, Carbs: 0, Calories: 350}},
	}

	result := RunReconciliation(history, goals, recipes, 25.0, 2)

	// Check average was calculated: (140+160)/2 = 150 protein
	if result.AverageConsumed.Protein != 150.0 {
		t.Errorf("Expected average protein 150.0, got %f", result.AverageConsumed.Protein)
	}

	// Check deviation was calculated: (150-180)/180*100 = -16.67%
	expectedProteinDev := ((150.0 - 180.0) / 180.0) * 100
	if !floatEquals(result.Deviation.ProteinPct, expectedProteinDev, 0.1) {
		t.Errorf("Expected protein deviation %f, got %f", expectedProteinDev, result.Deviation.ProteinPct)
	}

	// Check goals are stored
	if result.Goals.DailyProtein != 180.0 {
		t.Errorf("Expected goals protein 180.0, got %f", result.Goals.DailyProtein)
	}

	// Check suggestions were generated
	if len(result.Plan.Suggestions) == 0 {
		t.Error("Expected suggestions to be generated")
	}
}

func TestRunReconciliation_WithinTolerance(t *testing.T) {
	history := []NutritionState{
		{
			Date: time.Date(2024, 11, 28, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  175.0,  // Close to 180
				Fat:      58.0,   // Close to 60
				Carbs:    245.0,  // Close to 250
				Calories: 2450.0, // Close to 2500
			},
		},
	}

	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2500.0,
	}

	recipes := []ScoredRecipe{}

	result := RunReconciliation(history, goals, recipes, 10.0, 2)

	// All macros within 10% tolerance
	if !result.WithinTolerance {
		t.Errorf("Expected within tolerance, deviations: P=%f F=%f C=%f",
			result.Deviation.ProteinPct, result.Deviation.FatPct, result.Deviation.CarbsPct)
	}
}

func TestRunReconciliation_EmptyHistory(t *testing.T) {
	history := []NutritionState{}

	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2500.0,
	}

	recipes := []ScoredRecipe{}

	result := RunReconciliation(history, goals, recipes, 25.0, 2)

	// Empty history should result in 0 consumed and negative deviation
	if result.AverageConsumed.Protein != 0 {
		t.Errorf("Expected 0 protein for empty history, got %f", result.AverageConsumed.Protein)
	}
}
