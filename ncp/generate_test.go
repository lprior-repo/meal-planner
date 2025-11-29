package ncp

import (
	"testing"
)

func TestGenerateAdjustments_ProteinDeficit(t *testing.T) {
	deviation := DeviationResult{
		ProteinPct:  -25.0,
		FatPct:      5.0,
		CarbsPct:    -5.0,
		CaloriesPct: -15.0,
	}

	recipes := []ScoredRecipe{
		{Name: "Grilled Chicken", Macros: RecipeMacros{Protein: 45, Fat: 8, Carbs: 2, Calories: 260}},
		{Name: "Salmon Fillet", Macros: RecipeMacros{Protein: 40, Fat: 20, Carbs: 0, Calories: 350}},
		{Name: "Rice Bowl", Macros: RecipeMacros{Protein: 5, Fat: 2, Carbs: 60, Calories: 280}},
	}

	plan := GenerateAdjustments(deviation, recipes, 2)

	if len(plan.Suggestions) != 2 {
		t.Fatalf("Expected 2 suggestions, got %d", len(plan.Suggestions))
	}

	// High protein recipes should be suggested first
	if plan.Suggestions[0].RecipeName != "Grilled Chicken" && plan.Suggestions[0].RecipeName != "Salmon Fillet" {
		t.Errorf("Expected high protein recipe first, got %s", plan.Suggestions[0].RecipeName)
	}

	// Verify deviation is stored
	if plan.Deviation.ProteinPct != -25.0 {
		t.Errorf("Expected deviation protein -25.0, got %f", plan.Deviation.ProteinPct)
	}
}

func TestGenerateAdjustments_NoRecipes(t *testing.T) {
	deviation := DeviationResult{ProteinPct: -20.0}
	recipes := []ScoredRecipe{}

	plan := GenerateAdjustments(deviation, recipes, 3)

	if len(plan.Suggestions) != 0 {
		t.Errorf("Expected 0 suggestions for empty recipes, got %d", len(plan.Suggestions))
	}
}

func TestGenerateAdjustments_AlreadyWithinGoals(t *testing.T) {
	deviation := DeviationResult{
		ProteinPct:  2.0,
		FatPct:      -1.0,
		CarbsPct:    3.0,
		CaloriesPct: 0.5,
	}

	recipes := []ScoredRecipe{
		{Name: "Any Recipe", Macros: RecipeMacros{Protein: 30, Fat: 15, Carbs: 40, Calories: 420}},
	}

	plan := GenerateAdjustments(deviation, recipes, 3)

	// When already at goals, suggestions might still be returned but with low scores
	if len(plan.Suggestions) > 0 && plan.Suggestions[0].Score > 0.5 {
		t.Errorf("Expected low scores when already at goals, got %f", plan.Suggestions[0].Score)
	}
}
