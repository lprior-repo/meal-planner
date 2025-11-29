package ncp

import (
	"testing"
)

func TestScoreRecipeForDeviation_HighProteinNeed(t *testing.T) {
	// Deviation shows protein deficit
	deviation := DeviationResult{
		ProteinPct:  -25.0, // Need more protein
		FatPct:      5.0,
		CarbsPct:    0.0,
		CaloriesPct: -10.0,
	}

	// High protein recipe
	macros := RecipeMacros{
		Protein:  45.0,
		Fat:      10.0,
		Carbs:    5.0,
		Calories: 290.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// High protein recipe should score well for protein deficit
	if score < 0.5 {
		t.Errorf("Expected high score (>0.5) for protein-rich recipe with protein deficit, got %f", score)
	}
}

func TestScoreRecipeForDeviation_BalancedNeeds(t *testing.T) {
	// Deviation shows balanced deficit
	deviation := DeviationResult{
		ProteinPct:  -10.0,
		FatPct:      -10.0,
		CarbsPct:    -10.0,
		CaloriesPct: -10.0,
	}

	// Balanced macros recipe
	macros := RecipeMacros{
		Protein:  30.0,
		Fat:      15.0,
		Carbs:    40.0,
		Calories: 415.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Balanced recipe should score reasonably for balanced deficit
	if score < 0.3 || score > 1.0 {
		t.Errorf("Expected reasonable score (0.3-1.0) for balanced recipe, got %f", score)
	}
}

func TestScoreRecipeForDeviation_NoDeviation(t *testing.T) {
	// No deviation - already at goals
	deviation := DeviationResult{
		ProteinPct:  0.0,
		FatPct:      0.0,
		CarbsPct:    0.0,
		CaloriesPct: 0.0,
	}

	macros := RecipeMacros{
		Protein:  30.0,
		Fat:      15.0,
		Carbs:    40.0,
		Calories: 415.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Any recipe should have low score when no deviation exists
	if score > 0.5 {
		t.Errorf("Expected low score (<0.5) when no deviation exists, got %f", score)
	}
}

func TestScoreRecipeForDeviation_OverEating(t *testing.T) {
	// Already over on all macros
	deviation := DeviationResult{
		ProteinPct:  20.0,
		FatPct:      30.0,
		CarbsPct:    15.0,
		CaloriesPct: 25.0,
	}

	// High calorie recipe
	macros := RecipeMacros{
		Protein:  50.0,
		Fat:      40.0,
		Carbs:    60.0,
		Calories: 800.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Adding more food when over should score very low
	if score > 0.3 {
		t.Errorf("Expected very low score (<0.3) when already over goals, got %f", score)
	}
}

func TestSelectTopRecipes_Basic(t *testing.T) {
	deviation := DeviationResult{
		ProteinPct:  -20.0,
		FatPct:      0.0,
		CarbsPct:    -10.0,
		CaloriesPct: -15.0,
	}

	recipes := []ScoredRecipe{
		{Name: "Low Protein Salad", Macros: RecipeMacros{Protein: 5, Fat: 10, Carbs: 20, Calories: 190}},
		{Name: "Grilled Chicken", Macros: RecipeMacros{Protein: 45, Fat: 8, Carbs: 2, Calories: 260}},
		{Name: "Beef Stir Fry", Macros: RecipeMacros{Protein: 35, Fat: 15, Carbs: 25, Calories: 375}},
		{Name: "Plain Rice", Macros: RecipeMacros{Protein: 4, Fat: 1, Carbs: 45, Calories: 205}},
	}

	top := SelectTopRecipes(deviation, recipes, 2)

	if len(top) != 2 {
		t.Fatalf("Expected 2 recipes, got %d", len(top))
	}

	// High protein recipes should be at top
	if top[0].RecipeName != "Grilled Chicken" && top[0].RecipeName != "Beef Stir Fry" {
		t.Errorf("Expected high protein recipe first, got %s", top[0].RecipeName)
	}
}

func TestSelectTopRecipes_EmptyInput(t *testing.T) {
	deviation := DeviationResult{ProteinPct: -10.0}
	recipes := []ScoredRecipe{}

	top := SelectTopRecipes(deviation, recipes, 3)

	if len(top) != 0 {
		t.Errorf("Expected empty result for empty input, got %d", len(top))
	}
}

func TestSelectTopRecipes_LimitExceedsAvailable(t *testing.T) {
	deviation := DeviationResult{ProteinPct: -10.0}
	recipes := []ScoredRecipe{
		{Name: "Recipe 1", Macros: RecipeMacros{Protein: 30}},
		{Name: "Recipe 2", Macros: RecipeMacros{Protein: 20}},
	}

	top := SelectTopRecipes(deviation, recipes, 10)

	if len(top) != 2 {
		t.Errorf("Expected 2 recipes (all available), got %d", len(top))
	}
}
