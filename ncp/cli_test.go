package ncp

import (
	"os"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

func TestSyncCommand_StoresData(t *testing.T) {
	// Skip if no credentials (integration test)
	if os.Getenv("CRONOMETER_USERNAME") == "" {
		t.Skip("Skipping integration test: CRONOMETER_EMAIL not set")
	}

	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	config := CronometerConfig{
		Username:    os.Getenv("CRONOMETER_USERNAME"),
		Password: os.Getenv("CRONOMETER_PASSWORD"),
	}

	// Run sync for today
	today := time.Now()
	err := SyncNutritionData(db, config, today, today)
	if err != nil {
		t.Fatalf("Sync failed: %v", err)
	}

	// Verify data was stored
	state, err := GetNutritionState(db, today)
	if err != nil {
		t.Fatalf("Failed to retrieve synced data: %v", err)
	}

	if state.Consumed.Calories == 0 && state.Consumed.Protein == 0 {
		t.Log("Warning: synced data has zero values (may be expected if no food logged today)")
	}
}

func TestSyncNutritionData_InvalidCredentials(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	config := CronometerConfig{
		Username:    "invalid@example.com",
		Password: "wrongpassword",
	}

	today := time.Now()
	err := SyncNutritionData(db, config, today, today)

	// Should fail with invalid credentials
	if err == nil {
		t.Error("Expected error for invalid credentials, got nil")
	}
}

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

// Helper to set up test BadgerDB
func setupCLITestDB(t *testing.T) (*badger.DB, func()) {
	t.Helper()

	tmpDir, err := os.MkdirTemp("", "ncp_cli_test_*")
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
