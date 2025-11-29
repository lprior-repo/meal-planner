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


func TestScoreRecipeForDeviation_FatPenalty(t *testing.T) {
	// Over on fat by more than 10%
	deviation := DeviationResult{
		ProteinPct: -20.0,
		FatPct:     15.0, // Over by 15%
		CarbsPct:   -10.0,
	}

	// High fat recipe when already over on fat
	macros := RecipeMacros{
		Protein: 30.0,
		Fat:     25.0, // > 20g, should trigger penalty
		Carbs:   20.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Should have lower score due to fat penalty
	if score > 0.5 {
		t.Errorf("Expected reduced score due to fat penalty, got %f", score)
	}
}

func TestScoreRecipeForDeviation_CarbsPenalty(t *testing.T) {
	// Over on carbs by more than 10%
	deviation := DeviationResult{
		ProteinPct: -20.0,
		FatPct:     -5.0,
		CarbsPct:   15.0, // Over by 15%
	}

	// High carb recipe when already over on carbs
	macros := RecipeMacros{
		Protein: 30.0,
		Fat:     10.0,
		Carbs:   40.0, // > 30g, should trigger penalty
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Should have lower score due to carbs penalty
	if score > 0.5 {
		t.Errorf("Expected reduced score due to carbs penalty, got %f", score)
	}
}

func TestScoreRecipeForDeviation_ScoreClamping(t *testing.T) {
	// Test that score doesn't exceed 1.0
	deviation := DeviationResult{
		ProteinPct: -50.0,
		FatPct:     -50.0,
		CarbsPct:   -50.0,
	}

	// Very high macro recipe
	macros := RecipeMacros{
		Protein: 100.0,
		Fat:     50.0,
		Carbs:   100.0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	if score > 1.0 {
		t.Errorf("Score should be clamped to 1.0, got %f", score)
	}
	if score < 0 {
		t.Errorf("Score should not be negative, got %f", score)
	}
}

func TestScoreRecipeForDeviation_NegativeScoreClamping(t *testing.T) {
	// Test that excessive penalties don't make score negative
	deviation := DeviationResult{
		ProteinPct: 5.0,  // Slightly over
		FatPct:     20.0, // Over
		CarbsPct:   20.0, // Over
	}

	// High fat/carb recipe with penalties
	macros := RecipeMacros{
		Protein: 5.0,
		Fat:     30.0, // Triggers penalty
		Carbs:   50.0, // Triggers penalty
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	if score < 0 {
		t.Errorf("Score should be clamped to 0, got %f", score)
	}
}


func TestScoreRecipeForDeviation_ZeroMacros(t *testing.T) {
	// Under on macros but recipe has zero macros
	deviation := DeviationResult{
		ProteinPct: -20.0,
		FatPct:     -20.0,
		CarbsPct:   -20.0,
	}

	// Zero macro recipe
	macros := RecipeMacros{
		Protein: 0,
		Fat:     0,
		Carbs:   0,
	}

	score := ScoreRecipeForDeviation(deviation, macros)

	// Should get 0 score since recipe doesn't help with any deficit
	if score > 0.2 {
		t.Errorf("Expected low score for zero macro recipe, got %f", score)
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


func TestGenerateReason_ProteinDeficit(t *testing.T) {
	tests := []struct {
		name        string
		deviation   DeviationResult
		macros      RecipeMacros
		expected    string
	}{
		{
			name:      "high protein deficit with high protein recipe",
			deviation: DeviationResult{ProteinPct: -15},
			macros:    RecipeMacros{Protein: 25},
			expected:  "High protein to address deficit",
		},
		{
			name:      "protein exactly at -10 boundary (not triggered)",
			deviation: DeviationResult{ProteinPct: -10},
			macros:    RecipeMacros{Protein: 25},
			expected:  "Balanced macros",
		},
		{
			name:      "protein below -10 but recipe has only 20g (not triggered)",
			deviation: DeviationResult{ProteinPct: -15},
			macros:    RecipeMacros{Protein: 20},
			expected:  "Balanced macros",
		},
		{
			name:      "protein below -10 and recipe has 21g (triggered)",
			deviation: DeviationResult{ProteinPct: -11},
			macros:    RecipeMacros{Protein: 21},
			expected:  "High protein to address deficit",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generateReason(tt.deviation, tt.macros)
			if result != tt.expected {
				t.Errorf("generateReason() = %q, want %q", result, tt.expected)
			}
		})
	}
}

func TestGenerateReason_CarbsDeficit(t *testing.T) {
	tests := []struct {
		name        string
		deviation   DeviationResult
		macros      RecipeMacros
		expected    string
	}{
		{
			name:      "high carbs deficit with high carb recipe",
			deviation: DeviationResult{CarbsPct: -15},
			macros:    RecipeMacros{Carbs: 40},
			expected:  "Good carbs to address deficit",
		},
		{
			name:      "carbs exactly at -10 boundary (not triggered)",
			deviation: DeviationResult{CarbsPct: -10},
			macros:    RecipeMacros{Carbs: 40},
			expected:  "Balanced macros",
		},
		{
			name:      "carbs below -10 but recipe has only 30g (not triggered)",
			deviation: DeviationResult{CarbsPct: -15},
			macros:    RecipeMacros{Carbs: 30},
			expected:  "Balanced macros",
		},
		{
			name:      "carbs below -10 and recipe has 31g (triggered)",
			deviation: DeviationResult{CarbsPct: -11},
			macros:    RecipeMacros{Carbs: 31},
			expected:  "Good carbs to address deficit",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generateReason(tt.deviation, tt.macros)
			if result != tt.expected {
				t.Errorf("generateReason() = %q, want %q", result, tt.expected)
			}
		})
	}
}

func TestGenerateReason_FatDeficit(t *testing.T) {
	tests := []struct {
		name        string
		deviation   DeviationResult
		macros      RecipeMacros
		expected    string
	}{
		{
			name:      "high fat deficit with high fat recipe",
			deviation: DeviationResult{FatPct: -15},
			macros:    RecipeMacros{Fat: 20},
			expected:  "Healthy fats to address deficit",
		},
		{
			name:      "fat exactly at -10 boundary (not triggered)",
			deviation: DeviationResult{FatPct: -10},
			macros:    RecipeMacros{Fat: 20},
			expected:  "Balanced macros",
		},
		{
			name:      "fat below -10 but recipe has only 15g (not triggered)",
			deviation: DeviationResult{FatPct: -15},
			macros:    RecipeMacros{Fat: 15},
			expected:  "Balanced macros",
		},
		{
			name:      "fat below -10 and recipe has 16g (triggered)",
			deviation: DeviationResult{FatPct: -11},
			macros:    RecipeMacros{Fat: 16},
			expected:  "Healthy fats to address deficit",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generateReason(tt.deviation, tt.macros)
			if result != tt.expected {
				t.Errorf("generateReason() = %q, want %q", result, tt.expected)
			}
		})
	}
}

func TestGenerateReason_Priority(t *testing.T) {
	// When multiple deficits exist, protein should take priority
	deviation := DeviationResult{
		ProteinPct: -15,
		CarbsPct:   -15,
		FatPct:     -15,
	}
	macros := RecipeMacros{Protein: 30, Carbs: 40, Fat: 20}

	result := generateReason(deviation, macros)
	if result != "High protein to address deficit" {
		t.Errorf("Expected protein priority, got %q", result)
	}
}
