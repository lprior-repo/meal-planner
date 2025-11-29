package ncp

import (
	"os"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// Integration tests for the full NCP reconciliation flow

func setupIntegrationDB(t *testing.T) (*badger.DB, func()) {
	t.Helper()

	tmpDir, err := os.MkdirTemp("", "ncp_integration_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}

	opts := badger.DefaultOptions(tmpDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		os.RemoveAll(tmpDir)
		t.Fatalf("Failed to open test DB: %v", err)
	}

	cleanup := func() {
		db.Close()
		os.RemoveAll(tmpDir)
	}

	return db, cleanup
}

func TestIntegration_FullReconciliationFlow(t *testing.T) {
	db, cleanup := setupIntegrationDB(t)
	defer cleanup()

	// Step 1: Store nutrition data (simulating sync)
	baseDate := time.Date(2024, 11, 23, 0, 0, 0, 0, time.UTC)
	for i := 0; i < 7; i++ {
		date := baseDate.AddDate(0, 0, i)
		state := NutritionState{
			Date: date,
			Consumed: NutritionData{
				Date:     date,
				Protein:  140.0 + float64(i*5), // 140-170g range
				Fat:      50.0 + float64(i*2),  // 50-62g range
				Carbs:    200.0 + float64(i*5), // 200-230g range
				Calories: 1800.0 + float64(i*50),
			},
			SyncedAt: time.Now(),
		}
		if err := StoreNutritionState(db, state); err != nil {
			t.Fatalf("Failed to store state for day %d: %v", i, err)
		}
	}

	// Step 2: Retrieve history
	endDate := baseDate.AddDate(0, 0, 6)
	history, err := GetNutritionHistory(db, baseDate, endDate)
	if err != nil {
		t.Fatalf("Failed to get history: %v", err)
	}

	if len(history) != 7 {
		t.Fatalf("Expected 7 days of history, got %d", len(history))
	}

	// Step 3: Set up goals
	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2500.0,
	}

	// Step 4: Set up recipes
	recipes := []ScoredRecipe{
		{Name: "Grilled Chicken Breast", Macros: RecipeMacros{Protein: 45, Fat: 8, Carbs: 2, Calories: 260}},
		{Name: "Salmon with Vegetables", Macros: RecipeMacros{Protein: 40, Fat: 20, Carbs: 15, Calories: 400}},
		{Name: "Beef Stir Fry", Macros: RecipeMacros{Protein: 35, Fat: 15, Carbs: 25, Calories: 375}},
		{Name: "Greek Yogurt Bowl", Macros: RecipeMacros{Protein: 20, Fat: 5, Carbs: 30, Calories: 245}},
		{Name: "Rice and Beans", Macros: RecipeMacros{Protein: 12, Fat: 3, Carbs: 55, Calories: 295}},
	}

	// Step 5: Run full reconciliation with tight tolerance (10%)
	result := RunReconciliation(history, goals, recipes, 10.0, 3)

	// Verify results
	// Average protein should be around 155g ((140+145+150+155+160+165+170)/7)
	expectedAvgProtein := 155.0
	if !floatEquals(result.AverageConsumed.Protein, expectedAvgProtein, 1.0) {
		t.Errorf("Expected average protein ~%f, got %f", expectedAvgProtein, result.AverageConsumed.Protein)
	}

	// Deviation should be negative (under goal)
	if result.Deviation.ProteinPct >= 0 {
		t.Errorf("Expected negative protein deviation, got %f", result.Deviation.ProteinPct)
	}

	// Should not be within tolerance (protein is ~14% under, tolerance is 10%)
	if result.WithinTolerance {
		t.Errorf("Expected to be outside 10%% tolerance, protein deviation: %f", result.Deviation.ProteinPct)
	}

	// Should have suggestions
	if len(result.Plan.Suggestions) == 0 {
		t.Error("Expected recipe suggestions")
	}

	// High protein recipes should be prioritized
	if result.Plan.Suggestions[0].RecipeName != "Grilled Chicken Breast" &&
		result.Plan.Suggestions[0].RecipeName != "Salmon with Vegetables" {
		t.Errorf("Expected high protein recipe first, got %s", result.Plan.Suggestions[0].RecipeName)
	}
}

func TestIntegration_WithinToleranceNoSuggestions(t *testing.T) {
	db, cleanup := setupIntegrationDB(t)
	defer cleanup()

	// Store data that's close to goals
	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)
	state := NutritionState{
		Date: date,
		Consumed: NutritionData{
			Date:     date,
			Protein:  175.0, // Close to 180
			Fat:      58.0,  // Close to 60
			Carbs:    245.0, // Close to 250
			Calories: 2450.0,
		},
		SyncedAt: time.Now(),
	}
	if err := StoreNutritionState(db, state); err != nil {
		t.Fatalf("Failed to store state: %v", err)
	}

	history, _ := GetNutritionHistory(db, date, date)

	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2500.0,
	}

	result := RunReconciliation(history, goals, []ScoredRecipe{}, 10.0, 3)

	if !result.WithinTolerance {
		t.Errorf("Expected within tolerance, deviations: P=%f F=%f C=%f",
			result.Deviation.ProteinPct, result.Deviation.FatPct, result.Deviation.CarbsPct)
	}
}

func TestIntegration_StorageRoundTrip(t *testing.T) {
	db, cleanup := setupIntegrationDB(t)
	defer cleanup()

	original := NutritionState{
		Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		Consumed: NutritionData{
			Date:     time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
			Protein:  167.5,
			Fat:      52.3,
			Carbs:    198.7,
			Calories: 1923.4,
		},
		SyncedAt: time.Now(),
	}

	// Store
	if err := StoreNutritionState(db, original); err != nil {
		t.Fatalf("Failed to store: %v", err)
	}

	// Retrieve
	retrieved, err := GetNutritionState(db, original.Date)
	if err != nil {
		t.Fatalf("Failed to retrieve: %v", err)
	}

	// Verify
	if retrieved.Consumed.Protein != original.Consumed.Protein {
		t.Errorf("Protein mismatch: got %f, want %f", retrieved.Consumed.Protein, original.Consumed.Protein)
	}
	if retrieved.Consumed.Fat != original.Consumed.Fat {
		t.Errorf("Fat mismatch: got %f, want %f", retrieved.Consumed.Fat, original.Consumed.Fat)
	}
	if retrieved.Consumed.Carbs != original.Consumed.Carbs {
		t.Errorf("Carbs mismatch: got %f, want %f", retrieved.Consumed.Carbs, original.Consumed.Carbs)
	}
	if retrieved.Consumed.Calories != original.Consumed.Calories {
		t.Errorf("Calories mismatch: got %f, want %f", retrieved.Consumed.Calories, original.Consumed.Calories)
	}
}

func TestIntegration_HistoryOrdering(t *testing.T) {
	db, cleanup := setupIntegrationDB(t)
	defer cleanup()

	// Store in random order
	dates := []time.Time{
		time.Date(2024, 11, 27, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 25, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 26, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 28, 0, 0, 0, 0, time.UTC),
	}

	for i, date := range dates {
		state := NutritionState{
			Date: date,
			Consumed: NutritionData{
				Protein: float64(100 + i*10),
			},
			SyncedAt: time.Now(),
		}
		StoreNutritionState(db, state)
	}

	// Retrieve range
	start := time.Date(2024, 11, 25, 0, 0, 0, 0, time.UTC)
	end := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	history, err := GetNutritionHistory(db, start, end)
	if err != nil {
		t.Fatalf("Failed to get history: %v", err)
	}

	if len(history) != 5 {
		t.Fatalf("Expected 5 entries, got %d", len(history))
	}

	// Verify ordering (should be chronological due to key format)
	for i := 1; i < len(history); i++ {
		if history[i].Date.Before(history[i-1].Date) {
			t.Errorf("History not in chronological order at index %d", i)
		}
	}
}

func TestIntegration_DeviationCalculation(t *testing.T) {
	goals := NutritionGoals{
		DailyProtein:  200.0,
		DailyFat:      80.0,
		DailyCarbs:    300.0,
		DailyCalories: 3000.0,
	}

	testCases := []struct {
		name        string
		consumed    NutritionData
		wantProtein float64
		wantFat     float64
		wantCarbs   float64
	}{
		{
			name:        "50% under all",
			consumed:    NutritionData{Protein: 100, Fat: 40, Carbs: 150, Calories: 1500},
			wantProtein: -50.0,
			wantFat:     -50.0,
			wantCarbs:   -50.0,
		},
		{
			name:        "25% over all",
			consumed:    NutritionData{Protein: 250, Fat: 100, Carbs: 375, Calories: 3750},
			wantProtein: 25.0,
			wantFat:     25.0,
			wantCarbs:   25.0,
		},
		{
			name:        "exact match",
			consumed:    NutritionData{Protein: 200, Fat: 80, Carbs: 300, Calories: 3000},
			wantProtein: 0.0,
			wantFat:     0.0,
			wantCarbs:   0.0,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			deviation := CalculateDeviation(goals, tc.consumed)

			if !floatEquals(deviation.ProteinPct, tc.wantProtein, 0.1) {
				t.Errorf("Protein: got %f, want %f", deviation.ProteinPct, tc.wantProtein)
			}
			if !floatEquals(deviation.FatPct, tc.wantFat, 0.1) {
				t.Errorf("Fat: got %f, want %f", deviation.FatPct, tc.wantFat)
			}
			if !floatEquals(deviation.CarbsPct, tc.wantCarbs, 0.1) {
				t.Errorf("Carbs: got %f, want %f", deviation.CarbsPct, tc.wantCarbs)
			}
		})
	}
}

func TestIntegration_ScoringPrioritizesProtein(t *testing.T) {
	// Significant protein deficit
	deviation := DeviationResult{
		ProteinPct:  -30.0,
		FatPct:      0.0,
		CarbsPct:    0.0,
		CaloriesPct: -15.0,
	}

	recipes := []ScoredRecipe{
		{Name: "High Carb Rice", Macros: RecipeMacros{Protein: 5, Fat: 2, Carbs: 80, Calories: 360}},
		{Name: "High Protein Chicken", Macros: RecipeMacros{Protein: 50, Fat: 8, Carbs: 0, Calories: 270}},
		{Name: "Balanced Meal", Macros: RecipeMacros{Protein: 25, Fat: 15, Carbs: 30, Calories: 355}},
	}

	suggestions := SelectTopRecipes(deviation, recipes, 3)

	if len(suggestions) != 3 {
		t.Fatalf("Expected 3 suggestions, got %d", len(suggestions))
	}

	// High protein recipe should be first
	if suggestions[0].RecipeName != "High Protein Chicken" {
		t.Errorf("Expected High Protein Chicken first, got %s", suggestions[0].RecipeName)
	}

	// High carb recipe should be last (doesn't address protein deficit)
	if suggestions[2].RecipeName != "High Carb Rice" {
		t.Errorf("Expected High Carb Rice last, got %s", suggestions[2].RecipeName)
	}
}

func TestIntegration_GenerateAdjustmentsStoresDeviation(t *testing.T) {
	deviation := DeviationResult{
		ProteinPct:  -20.0,
		FatPct:      10.0,
		CarbsPct:    -5.0,
		CaloriesPct: -10.0,
	}

	recipes := []ScoredRecipe{
		{Name: "Test Recipe", Macros: RecipeMacros{Protein: 30, Fat: 10, Carbs: 20, Calories: 290}},
	}

	plan := GenerateAdjustments(deviation, recipes, 1)

	// Verify deviation is preserved in plan
	if plan.Deviation.ProteinPct != -20.0 {
		t.Errorf("Expected deviation protein -20.0, got %f", plan.Deviation.ProteinPct)
	}
	if plan.Deviation.FatPct != 10.0 {
		t.Errorf("Expected deviation fat 10.0, got %f", plan.Deviation.FatPct)
	}
}

func TestIntegration_FormatOutputContainsKeyInfo(t *testing.T) {
	result := ReconciliationResult{
		Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		AverageConsumed: NutritionData{
			Protein:  150.0,
			Fat:      55.0,
			Carbs:    220.0,
			Calories: 2000.0,
		},
		Goals: NutritionGoals{
			DailyProtein:  180.0,
			DailyFat:      60.0,
			DailyCarbs:    250.0,
			DailyCalories: 2500.0,
		},
		Deviation: DeviationResult{
			ProteinPct:  -16.7,
			FatPct:      -8.3,
			CarbsPct:    -12.0,
			CaloriesPct: -20.0,
		},
		WithinTolerance: false,
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Chicken", Reason: "High protein", Score: 0.85},
			},
		},
	}

	output := FormatStatusOutput(result)

	// Check for key components
	checks := []string{
		"Protein",
		"Fat",
		"Carbs",
		"180.0",        // Goal
		"150.0",        // Actual
		"-16.7",        // Deviation (approximately)
		"Grilled Chicken",
	}

	for _, check := range checks {
		if !containsSubstring(output, check) {
			t.Errorf("Output missing expected content: %s", check)
		}
	}
}

func containsSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
