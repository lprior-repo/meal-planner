package ncp

import (
	"testing"
)

func TestAdjustmentPlan_Empty(t *testing.T) {
	plan := AdjustmentPlan{}

	if len(plan.Suggestions) != 0 {
		t.Errorf("Expected empty suggestions, got %d", len(plan.Suggestions))
	}
}

func TestAdjustmentPlan_WithSuggestions(t *testing.T) {
	plan := AdjustmentPlan{
		Deviation: DeviationResult{
			ProteinPct: -20.0,
			FatPct:     5.0,
			CarbsPct:   0.0,
		},
		Suggestions: []RecipeSuggestion{
			{
				RecipeName: "Grilled Chicken Breast",
				Reason:     "High protein to address -20% deficit",
				Score:      0.85,
			},
		},
	}

	if len(plan.Suggestions) != 1 {
		t.Fatalf("Expected 1 suggestion, got %d", len(plan.Suggestions))
	}

	if plan.Suggestions[0].RecipeName != "Grilled Chicken Breast" {
		t.Errorf("Expected recipe name 'Grilled Chicken Breast', got %s", plan.Suggestions[0].RecipeName)
	}

	if plan.Suggestions[0].Score != 0.85 {
		t.Errorf("Expected score 0.85, got %f", plan.Suggestions[0].Score)
	}
}

func TestRecipeSuggestion_Fields(t *testing.T) {
	suggestion := RecipeSuggestion{
		RecipeName: "Salmon with Vegetables",
		Reason:     "Balanced macros",
		Score:      0.72,
	}

	if suggestion.RecipeName != "Salmon with Vegetables" {
		t.Errorf("Expected RecipeName 'Salmon with Vegetables', got %s", suggestion.RecipeName)
	}

	if suggestion.Reason != "Balanced macros" {
		t.Errorf("Expected Reason 'Balanced macros', got %s", suggestion.Reason)
	}

	if suggestion.Score != 0.72 {
		t.Errorf("Expected Score 0.72, got %f", suggestion.Score)
	}
}
