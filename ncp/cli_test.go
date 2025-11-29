package ncp

import (
	"testing"
	"time"
)

func TestFormatStatusOutput_WithinTolerance(t *testing.T) {
	result := ReconciliationResult{
		Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		AverageConsumed: NutritionData{
			Protein:  175.0,
			Fat:      58.0,
			Carbs:    245.0,
			Calories: 2450.0,
		},
		Goals: NutritionGoals{
			DailyProtein:  180.0,
			DailyFat:      60.0,
			DailyCarbs:    250.0,
			DailyCalories: 2500.0,
		},
		Deviation: DeviationResult{
			ProteinPct:  -2.8,
			FatPct:      -3.3,
			CarbsPct:    -2.0,
			CaloriesPct: -2.0,
		},
		WithinTolerance: true,
	}

	output := FormatStatusOutput(result)

	if output == "" {
		t.Error("Expected non-empty output")
	}

	// Should contain key information
	if !containsString(output, "Within tolerance") && !containsString(output, "✓") {
		t.Error("Expected output to indicate within tolerance")
	}
}

func TestFormatStatusOutput_OutsideTolerance(t *testing.T) {
	result := ReconciliationResult{
		Deviation: DeviationResult{
			ProteinPct: -25.0,
			FatPct:     10.0,
			CarbsPct:   -15.0,
		},
		WithinTolerance: false,
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Chicken", Score: 0.85},
			},
		},
	}

	output := FormatStatusOutput(result)

	if !containsString(output, "Grilled Chicken") {
		t.Error("Expected output to contain recipe suggestions")
	}
}

func TestFormatReconcileOutput_WithSuggestions(t *testing.T) {
	result := ReconciliationResult{
		Deviation: DeviationResult{
			ProteinPct: -25.0,
			FatPct:     10.0,
			CarbsPct:   -15.0,
		},
		WithinTolerance: false,
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Chicken", Score: 0.85},
				{RecipeName: "Salmon Bowl", Score: 0.75},
			},
		},
	}

	output := FormatReconcileOutput(result)

	// Should contain adjustment plan section
	if !containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected output to contain ADJUSTMENT PLAN")
	}

	// Should contain all recipe suggestions
	if !containsString(output, "Grilled Chicken") {
		t.Error("Expected output to contain Grilled Chicken")
	}
	if !containsString(output, "Salmon Bowl") {
		t.Error("Expected output to contain Salmon Bowl")
	}

	// Should contain the bullet point format
	if !containsString(output, "•") {
		t.Error("Expected output to contain bullet points")
	}
}

func TestFormatReconcileOutput_WithinTolerance(t *testing.T) {
	result := ReconciliationResult{
		WithinTolerance: true,
		Plan:            AdjustmentPlan{},
	}

	output := FormatReconcileOutput(result)

	// Should NOT contain adjustment plan when within tolerance
	if containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected no ADJUSTMENT PLAN when within tolerance")
	}
}

func TestFormatReconcileOutput_NoSuggestions(t *testing.T) {
	result := ReconciliationResult{
		WithinTolerance: false,
		Plan:            AdjustmentPlan{Suggestions: []RecipeSuggestion{}},
	}

	output := FormatReconcileOutput(result)

	// Should NOT contain adjustment plan when no suggestions
	if containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected no ADJUSTMENT PLAN with empty suggestions")
	}
}

func containsString(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsStringHelper(s, substr))
}

func containsStringHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
